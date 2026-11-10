#!/usr/bin/env python3
"""
HomeSure Phase 1 — Canonical SQLite & Normalized JSON to Cloud Firestore Importer.

Supports:
  --dry-run          Validate, transform, and generate dry-run report without writing to Firestore.
  --project-id       Import one or more specific projects (by registration_number, project_key, or doc_id).
  --all-selected     Import all verified projects from detail_extraction_checkpoints (875 projects).
  --cohort           Optional subset selector: 'all' (875, default), 'first8', 'central8', 'pilot5'.
  --force-update     Overwrite existing Firestore documents even if content_hash is unchanged.
  --with-subcollections  Also populate regulatory_tabs, documents, complaints, and towers subcollections.
"""

import argparse
import datetime
import hashlib
import json
import os
import re
import sqlite3
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

WORKSPACE_ROOT = Path(__file__).resolve().parents[3]
EXTRACTION_ROOT = WORKSPACE_ROOT / "KRERA-Data-Extraction"
SQLITE_DB_PATH = EXTRACTION_ROOT / "data" / "k_rera_extraction.sqlite"
FIREBASE_PROJECT_ID = "homesureai-51893"
FIRESTORE_DATABASE = "(default)"
SCHEMA_VERSION = "1.0.0"

CENTRAL_8_REG_NUMBERS = [
    "PRM/KA/RERA/1251/309/PR/171014/000662",  # ecopolis Block-2
    "PRM/KA/RERA/1251/446/PR/170824/000057",  # PRESTIGE BOULEVARD
    "PRM/KA/RERA/1251/446/PR/170902/000083",  # SNN Raj Etternia
    "PRM/KA/RERA/1251/308/PR/180504/001616",  # HASIRU VISTHARA
    "PRM/KA/RERA/1251/310/PR/171014/000450",  # TOTAL ENVIRONMENT LEARNING TO FLY
    "PRM/KA/RERA/1251/446/PR/171014/000548",  # SALARPURIA SATTVA EAST CREST
    "PRM/KA/RERA/1251/310/PR/170905/000143",  # Salarpuria Sattva Magnus
    "PRM/KA/RERA/1251/309/PR/180131/001126",  # DS-MAX SKYCITY
]

FIRST_8_REG_NUMBERS = [
    "PRM/KA/RERA/1251/446/PR/171010/000003",  # Godrej United
    "PRM/KA/RERA/1251/446/PR/170819/000006",  # Godrej Air
    "PRM/KA/RERA/1251/446/PR/171015/000268",  # Polaris
    "PRM/KA/RERA/1251/309/PR/170913/000144",  # vajram tiara
    "PRM/KA/RERA/1251/310/PR/170824/000049",  # Chartered Hummingbird
    "PRM/KA/RERA/1251/308/PR/171222/000932",  # ARATT GRAND TOWN
    "PRM/KA/RERA/1251/309/PR/171014/000662",  # ecopolis Block-2
    "PRM/KA/RERA/1251/446/PR/170824/000057",  # PRESTIGE BOULEVARD
]


def make_deterministic_project_id(project_key: str, registration_number: str) -> str:
    """Create a deterministic, collision-free Firestore document ID from RERA registration number."""
    base = project_key if project_key else f"REG::{registration_number}"
    sanitized = re.sub(r"[^A-Za-z0-9]+", "_", base.strip()).strip("_")
    return sanitized


def parse_date_to_iso(raw_date: Optional[str]) -> Optional[str]:
    """Parse DD/MM/YYYY, DD-MM-YYYY, or YYYY-MM-DD into ISO YYYY-MM-DD without guessing ambiguous dates."""
    if not raw_date or not isinstance(raw_date, str):
        return None
    s = raw_date.strip()
    if not s or s.upper() in ("NA", "N/A", "NONE", "NULL", "-"):
        return None
    for fmt in ("%Y-%m-%d", "%d/%m/%Y", "%d-%m-%Y", "%d.%m.%Y"):
        try:
            dt = datetime.datetime.strptime(s[:10], fmt)
            return dt.strftime("%Y-%m-%d")
        except ValueError:
            continue
    return None


def build_search_tokens(*texts: Optional[str]) -> List[str]:
    """Generate normalized lowercase search tokens for Firestore array-contains queries."""
    tokens = set()
    for text in texts:
        if not text or not isinstance(text, str):
            continue
        lower = text.lower().strip()
        if not lower:
            continue
        tokens.add(lower)
        compact = re.sub(r"[^a-z0-9]+", "", lower)
        if len(compact) >= 3:
            tokens.add(compact)
        words = re.split(r"[^a-z0-9]+", lower)
        for w in words:
            if len(w) >= 2:
                tokens.add(w)
                # Add 3..8 char prefixes for prefix-like token matching on project/builder names
                for prefix_len in range(3, min(len(w), 9)):
                    tokens.add(w[:prefix_len])
    return sorted(list(tokens))[:120]


def normalize_slug(label: str, prefix: str = "tab") -> str:
    slug = re.sub(r"[^a-z0-9]+", "_", label.lower().strip()).strip("_")
    return f"{prefix}_{slug}" if slug else f"{prefix}_unknown"


def extract_summary_metrics_and_structures(
    normalized_data: Dict[str, Any]
) -> Tuple[Dict[str, Any], List[Dict[str, Any]], List[Dict[str, Any]], List[Dict[str, Any]], Dict[str, Any]]:
    """
    Extract canonical summary_metrics, inventory_configurations, towers_list,
    key_sections, and unit_hierarchy_status from normalized project JSON.
    """
    tabs = normalized_data.get("tabs") or {}
    unlinked = normalized_data.get("unlinked_dom_panes") or {}

    # Flatten all fields from all tabs for deterministic metric lookup
    field_lookup: Dict[str, Dict[str, Any]] = {}
    for tab_name, tab_obj in tabs.items():
        for sec in tab_obj.get("sections") or []:
            for f in sec.get("fields") or []:
                lbl = (f.get("field_label") or "").strip()
                if lbl and lbl not in field_lookup:
                    field_lookup[lbl] = f

    def find_metric(candidate_labels: List[str], default_label: str) -> Dict[str, Any]:
        for candidate in candidate_labels:
            for actual_lbl, f_obj in field_lookup.items():
                if actual_lbl.lower() == candidate.lower():
                    return {
                        "value": f_obj.get("normalized_value"),
                        "raw_value": f_obj.get("raw_value"),
                        "raw_label": actual_lbl,
                        "observation_state": f_obj.get("observation_state", "present_with_data"),
                        "source_tab": f_obj.get("tab_label"),
                        "source_section": f_obj.get("section_label"),
                    }
        # Fallback substring check
        for candidate in candidate_labels:
            for actual_lbl, f_obj in field_lookup.items():
                if candidate.lower() in actual_lbl.lower():
                    return {
                        "value": f_obj.get("normalized_value"),
                        "raw_value": f_obj.get("raw_value"),
                        "raw_label": actual_lbl,
                        "observation_state": f_obj.get("observation_state", "present_with_data"),
                        "source_tab": f_obj.get("tab_label"),
                        "source_section": f_obj.get("section_label"),
                    }
        return {
            "value": None,
            "raw_value": None,
            "raw_label": default_label,
            "observation_state": "not_present",
            "source_tab": None,
            "source_section": None,
        }

    summary_metrics = {
        "total_land_area_sq_m": find_metric(
            ["Total Area Of Land (Sq Mtr)", "Total Area Of Land (Sq Mtr) (A1+A2)", "Total Extent of Land (Sq Mtr)"],
            "Total Area Of Land (Sq Mtr)",
        ),
        "total_covered_area_sq_m": find_metric(
            ["Total Coverd Area (Sq Mtr)", "Total Coverd Area (Sq Mtr) (A2)", "Total Covered Area (Sq Mtr)", "Total Built-up Area of all the Floors (Sq Mtr)"],
            "Total Covered Area (Sq Mtr)",
        ),
        "total_open_area_sq_m": find_metric(
            ["Total Open Area (Sq Mtr)", "Total Open Area (Sq Mtr) (A1)"],
            "Total Open Area (Sq Mtr)",
        ),
        "total_carpet_area_sq_m": find_metric(
            ["Total Carpet Area of all the Floors (Sq Mtr)", "Carpet Area (Sq Mtr)"],
            "Total Carpet Area (Sq Mtr)",
        ),
        "total_units_inventories": find_metric(
            ["Total Number of Inventories/Flats/Villas", "No of Inventory", "Total No. of Units", "Total Flats/Units"],
            "Total Number of Inventories/Flats/Villas",
        ),
        "total_towers_blocks": find_metric(
            ["Number of Towers", "No. of Towers", "Number of Blocks"],
            "Number of Towers/Blocks",
        ),
        "total_project_cost_inr": find_metric(
            ["Total Project Cost (INR)", "Total Project Cost (INR) (C1+C2)"],
            "Total Project Cost (INR)",
        ),
        "cost_of_land_inr": find_metric(
            ["Cost of Land (INR)", "Cost of Land (INR) (C1)( As Certified by CA in Form 1 )"],
            "Cost of Land (INR)",
        ),
        "cost_of_construction_inr": find_metric(
            ["Estimated Cost of Construction (INR)", "Cost of Layout Development (INR) (C2)( As Certified by CA in Form 1 )"],
            "Estimated Cost of Construction (INR)",
        ),
        "project_start_date": find_metric(
            ["Project Start Date"],
            "Project Start Date",
        ),
        "proposed_completion_date": find_metric(
            ["Proposed Project Completion Date", "Proposed Completion Date"],
            "Proposed Project Completion Date",
        ),
        "project_address": find_metric(
            ["Project Address"],
            "Project Address",
        ),
        "project_description": find_metric(
            ["Project Description"],
            "Project Description",
        ),
        "approving_authority": find_metric(
            ["Approving Authority"],
            "Approving Authority",
        ),
        "approved_plan_number": find_metric(
            ["Approved Plan Number"],
            "Approved Plan Number",
        ),
        "plan_approval_date": find_metric(
            ["Plan Approval Date"],
            "Plan Approval Date",
        ),
        "escrow_bank_name": find_metric(
            ["Bank Name"],
            "Escrow Bank Name",
        ),
        "escrow_bank_branch": find_metric(
            ["Branch"],
            "Escrow Bank Branch",
        ),
        "escrow_ifsc_code": find_metric(
            ["ifscCode", "IFSC Code"],
            "Escrow IFSC Code",
        ),
        "latitude": find_metric(
            ["Latitude", "North Latitude"],
            "Latitude",
        ),
        "longitude": find_metric(
            ["Longitude", "North Longitude"],
            "Longitude",
        ),
        "covered_parking_count": find_metric(
            ["No. of Covered Parking", "No of Garage for Sale"],
            "Covered Parking / Garage Count",
        ),
        "open_parking_count": find_metric(
            ["No. of Open Parking", "No of Parking for Sale"],
            "Open Parking Count",
        ),
        "land_litigation_flag": find_metric(
            ["Is there any Litigations on Land/Property/Khatha?"],
            "Land Litigation Flag",
        ),
    }

    # Parse inventory configurations & towers from Project Details -> Development Details
    inventory_configs: List[Dict[str, Any]] = []
    towers_list: List[Dict[str, Any]] = []
    unit_rows_observed_count = 0

    pd_tab = tabs.get("Project Details") or {}
    for sec in pd_tab.get("sections") or []:
        sec_label = (sec.get("section_label") or "").strip()
        if "Development Details" in sec_label:
            # 1. Check fields for older K-RERA format (where 1 BHK, 2 BHK, etc. are sequential fields)
            sec_fields = sec.get("fields") or []
            current_inv: Dict[str, Any] = {}
            for f in sec_fields:
                fl = (f.get("field_label") or "").strip()
                val = f.get("normalized_value")
                if fl == "Type of Inventory":
                    if current_inv.get("type_of_inventory"):
                        inventory_configs.append(current_inv)
                    current_inv = {
                        "type_of_inventory": str(val) if val is not None else "",
                        "no_of_inventory": None,
                        "carpet_area_sq_m": None,
                        "balcony_area_sq_m": None,
                        "terrace_area_sq_m": None,
                        "source_type": "KRERA_PORTAL",
                        "observation_state": f.get("observation_state", "present_with_data"),
                    }
                elif fl in ("No of Inventory", "No. of Inventory") and current_inv:
                    current_inv["no_of_inventory"] = val
                elif "Carpet Area" in fl and current_inv:
                    current_inv["carpet_area_sq_m"] = val
                elif "balcony" in fl.lower() and current_inv:
                    current_inv["balcony_area_sq_m"] = val
                elif "terrace" in fl.lower() and current_inv:
                    current_inv["terrace_area_sq_m"] = val
            if current_inv.get("type_of_inventory"):
                inventory_configs.append(current_inv)

            # 2. Check table_rows for newer K-RERA format (inventory table + tower headers + unit rows)
            current_tower: Optional[Dict[str, Any]] = None
            for row in sec.get("table_rows") or []:
                if "Type of Inventory" in row:
                    inventory_configs.append({
                        "type_of_inventory": str(row.get("Type of Inventory") or "").strip(),
                        "no_of_inventory": row.get("No. of Inventory"),
                        "carpet_area_sq_m": row.get("Carpet Area (Sq Mtr)"),
                        "balcony_area_sq_m": row.get("Area of exclusive balcony/verandah (Sq Mtr)"),
                        "terrace_area_sq_m": row.get("Area of exclusive open Terrace (Sq Mtr)"),
                        "source_type": "KRERA_PORTAL",
                        "observation_state": "present_with_data",
                    })
                elif row.get("Column_1") == "Tower Name":
                    if current_tower:
                        towers_list.append(current_tower)
                    current_tower = {
                        "tower_id": normalize_slug(str(row.get("Column_2") or f"tower_{len(towers_list)+1}"), "tower"),
                        "tower_name": str(row.get("Column_2") or "").strip(),
                        "tower_type": str(row.get("Column_4") or "").strip(),
                        "total_floors": None,
                        "total_units": None,
                        "stilts": None,
                        "basements": None,
                        "total_parking": None,
                        "height_meters": None,
                        "source_type": "KRERA_PORTAL",
                        "observation_state": "present_with_data",
                    }
                elif current_tower and row.get("Column_1") == "No. of Floors":
                    current_tower["total_floors"] = row.get("Column_2")
                    current_tower["total_units"] = row.get("Column_4")
                elif current_tower and row.get("Column_1") == "No. of Stilts":
                    current_tower["stilts"] = row.get("Column_2")
                elif current_tower and row.get("Column_1") == "No. of Basement":
                    current_tower["basements"] = row.get("Column_2")
                    current_tower["total_parking"] = row.get("Column_4")
                elif current_tower and "Height of the Tower" in str(row.get("Column_1") or ""):
                    current_tower["height_meters"] = row.get("Column_2")
                elif "Column_9" in row and str(row.get("Column_1") or "").isdigit():
                    unit_rows_observed_count += 1
            if current_tower:
                towers_list.append(current_tower)

    # If total_units_inventories was not a top-level field, sum inventory_configs if available
    if summary_metrics["total_units_inventories"]["observation_state"] == "not_present" and inventory_configs:
        total_inv = 0
        for ic in inventory_configs:
            raw_cnt = ic.get("no_of_inventory")
            try:
                total_inv += int(str(raw_cnt).strip())
            except (ValueError, TypeError):
                pass
        if total_inv > 0:
            summary_metrics["total_units_inventories"] = {
                "value": total_inv,
                "raw_value": str(total_inv),
                "raw_label": "Sum of Registered Inventory Configurations",
                "observation_state": "present_with_data",
                "source_tab": "Project Details",
                "source_section": "Development Details",
            }

    # Build compact key_sections for fast single-document rendering in PropertyDetailsScreen
    key_sections: List[Dict[str, Any]] = []
    for tab_label, tab_obj in tabs.items():
        for sec in tab_obj.get("sections") or []:
            compact_fields = []
            for f in (sec.get("fields") or [])[:45]:
                compact_fields.append({
                    "label": f.get("field_label"),
                    "value": f.get("normalized_value"),
                    "raw_value": f.get("raw_value"),
                    "data_type": f.get("data_type"),
                    "observation_state": f.get("observation_state", "present_with_data"),
                })
            # Keep compact table preview (up to 15 rows per section in root doc; full rows in subcollection)
            raw_rows = sec.get("table_rows") or []
            compact_docs = []
            for doc in (sec.get("documents") or [])[:30]:
                compact_docs.append({
                    "category": doc.get("document_category"),
                    "filename": doc.get("displayed_filename"),
                    "source_url": doc.get("source_url"),
                    "approval_date": doc.get("approval_date_normalized") or doc.get("approval_date_raw"),
                    "observation_state": doc.get("observation_state", "present_with_data"),
                })
            key_sections.append({
                "tab_label": tab_label,
                "section_label": sec.get("section_label"),
                "section_type": sec.get("section_type"),
                "observation_state": sec.get("observation_state", "present_with_data"),
                "empty_message": sec.get("empty_message"),
                "field_count": len(sec.get("fields") or []),
                "table_row_count": len(raw_rows),
                "document_count": len(sec.get("documents") or []),
                "fields": compact_fields,
                "table_headers": sec.get("table_headers") or [],
                "table_rows_preview": raw_rows[:15],
                "documents_preview": compact_docs,
            })

    unit_hierarchy_status = {
        "phases_state": "not_available",
        "towers_state": "present_with_data" if towers_list else "not_available",
        "towers_count": len(towers_list),
        "inventory_configs_state": "present_with_data" if inventory_configs else "not_available",
        "inventory_configs_count": len(inventory_configs),
        "portal_unit_rows_state": "present_with_data" if unit_rows_observed_count > 0 else "not_available",
        "portal_unit_rows_count": unit_rows_observed_count,
        "buyer_units_enabled": True,
        "notes": (
            f"Observed {len(towers_list)} towers, {len(inventory_configs)} inventory configurations, "
            f"and {unit_rows_observed_count} portal unit rows in K-RERA Project Details."
        ),
    }

    return summary_metrics, inventory_configs, towers_list, key_sections, unit_hierarchy_status


def transform_project_record(
    sqlite_row: Dict[str, Any],
    normalized_data: Dict[str, Any],
) -> Tuple[Dict[str, Any], Dict[str, List[Dict[str, Any]]]]:
    """
    Transform a verified SQLite checkpoint + normalized JSON into:
      1. Canonical root Firestore document `projects/{projectId}`
      2. Subcollections dict: `regulatory_tabs`, `documents`, `complaints`, `towers`
    """
    project_key = sqlite_row["project_key"]
    reg_no = normalized_data.get("registration_number") or sqlite_row.get("registration_number") or ""
    ack_no = normalized_data.get("acknowledgement_number") or sqlite_row.get("acknowledgement_number")
    project_id = make_deterministic_project_id(project_key, reg_no)

    project_name = (normalized_data.get("project_name") or sqlite_row.get("project_name") or "").strip()
    promoter_name = (normalized_data.get("promoter_name") or sqlite_row.get("promoter_name") or "").strip()
    district = (normalized_data.get("district") or sqlite_row.get("district") or "Bengaluru Urban").strip()
    taluk = (normalized_data.get("taluk") or sqlite_row.get("taluk") or "").strip()
    project_type = (normalized_data.get("project_type") or sqlite_row.get("project_type") or "").strip()
    status = (normalized_data.get("status") or sqlite_row.get("status") or "").strip()
    approved_on_raw = normalized_data.get("approved_on") or sqlite_row.get("approved_on")
    proposed_completion_raw = (
        normalized_data.get("proposed_completion_date") or sqlite_row.get("proposed_completion_date")
    )

    summary_metrics, inventory_configs, towers_list, key_sections, unit_hierarchy_status = (
        extract_summary_metrics_and_structures(normalized_data)
    )

    # Extract all documents & complaints across tabs and unlinked panes
    tabs = normalized_data.get("tabs") or {}
    unlinked = normalized_data.get("unlinked_dom_panes") or {}

    all_documents: List[Dict[str, Any]] = []
    all_complaints: List[Dict[str, Any]] = []
    regulatory_tabs_subcollection: List[Dict[str, Any]] = []
    tab_observations_summary: Dict[str, Any] = {}
    unlinked_pane_summary: Dict[str, Any] = {}

    total_sections = 0
    total_fields = 0

    def process_tab_tree(tab_dict: Dict[str, Any], is_visible: bool) -> None:
        nonlocal total_sections, total_fields
        for idx, (tab_key, tab_obj) in enumerate(tab_dict.items()):
            sec_list = tab_obj.get("sections") or []
            sec_count = len(sec_list)
            f_count = sum(len(s.get("fields") or []) for s in sec_list)
            t_count = sum(1 for s in sec_list if s.get("table_rows"))
            d_count = sum(len(s.get("documents") or []) for s in sec_list)
            obs_state = tab_obj.get("observation_state", "not_present")

            if is_visible:
                total_sections += sec_count
                total_fields += f_count
                tab_observations_summary[tab_key] = {
                    "label": tab_obj.get("tab_label") or tab_key,
                    "tab_identifier": tab_obj.get("tab_identifier"),
                    "is_visible_tab": True,
                    "observation_state": obs_state,
                    "section_count": sec_count,
                    "field_count": f_count,
                    "table_count": t_count,
                    "document_count": d_count,
                }
            else:
                unlinked_pane_summary[tab_key] = {
                    "label": tab_obj.get("tab_label") or tab_key,
                    "tab_identifier": tab_obj.get("tab_identifier") or tab_key,
                    "is_visible_tab": False,
                    "observation_state": obs_state,
                    "section_count": sec_count,
                    "field_count": f_count,
                    "table_count": t_count,
                    "document_count": d_count,
                }

            # Collect documents and complaints
            for sec in sec_list:
                sec_label = sec.get("section_label") or ""
                for doc in sec.get("documents") or []:
                    doc_idx = len(all_documents) + 1
                    doc_url = doc.get("source_url")
                    doc_cat = doc.get("document_category") or "Other Regulatory Document"
                    doc_hash = hashlib.sha1(
                        f"{tab_key}:{sec_label}:{doc_cat}:{doc_url}:{doc_idx}".encode("utf-8")
                    ).hexdigest()[:8]
                    all_documents.append({
                        "document_id": f"doc_{doc_idx:04d}_{doc_hash}",
                        "project_id": project_id,
                        "document_category": doc_cat,
                        "displayed_filename": doc.get("displayed_filename"),
                        "approval_date_raw": doc.get("approval_date_raw"),
                        "approval_date_normalized": doc.get("approval_date_normalized"),
                        "source_url": doc_url,
                        "document_identifier": doc.get("document_identifier"),
                        "has_downloadable_file": bool(doc_url and str(doc_url).strip()),
                        "observation_state": doc.get("observation_state", "present_with_data"),
                        "source_tab": tab_key,
                        "source_section": sec_label,
                        "is_from_visible_tab": is_visible,
                        "source_type": "KRERA_PORTAL",
                        "display_order": doc_idx,
                    })

                if tab_key == "Complaints" or "complaint" in sec_label.lower():
                    for r_idx, row in enumerate(sec.get("table_rows") or []):
                        cmp_idx = len(all_complaints) + 1
                        cmp_no = row.get("COMPLAINT NO") or row.get("Complaint No") or row.get("Column_2")
                        cmp_hash = hashlib.sha1(
                            f"{project_id}:{sec_label}:{cmp_no}:{cmp_idx}".encode("utf-8")
                        ).hexdigest()[:8]
                        all_complaints.append({
                            "complaint_id": f"cmp_{cmp_idx:04d}_{cmp_hash}",
                            "project_id": project_id,
                            "complaint_scope": "PROJECT" if "project" in sec_label.lower() else "PROMOTER",
                            "section_label": sec_label,
                            "complaint_number": cmp_no,
                            "complainant_name": row.get("COMPLAINT BY") or row.get("Complainant Name"),
                            "complaint_date": row.get("COMPLAINT DATE (DD-MM-YYYY)") or row.get("Complaint Date"),
                            "complaint_subject": row.get("COMPLAINT SUBJECT") or row.get("Subject"),
                            "project_name_in_row": row.get("PROJECT NAME"),
                            "promoter_name_in_row": row.get("PROMOTER NAME"),
                            "complaint_status": row.get("STATUS") or row.get("Status"),
                            "order_by": row.get("ORDER BY"),
                            "raw_row": row,
                            "observation_state": "present_with_data",
                            "source_type": "KRERA_PORTAL",
                            "row_index": r_idx + 1,
                        })

            # Prepare subcollection document for this tab/pane (stripping bloated per-field repetition)
            prefix = "tab" if is_visible else "pane"
            tab_doc_id = normalize_slug(tab_key, prefix)
            cleaned_sections = []
            for sec in sec_list:
                cleaned_fields = [
                    {
                        "field_label": f.get("field_label"),
                        "raw_value": f.get("raw_value"),
                        "normalized_value": f.get("normalized_value"),
                        "data_type": f.get("data_type"),
                        "observation_state": f.get("observation_state"),
                        "source_link": f.get("source_link"),
                    }
                    for f in (sec.get("fields") or [])
                ]
                # Cap table_rows in single subcollection doc at 300 rows so it never exceeds 1 MiB
                t_rows = sec.get("table_rows") or []
                cleaned_sections.append({
                    "section_label": sec.get("section_label"),
                    "section_type": sec.get("section_type"),
                    "observation_state": sec.get("observation_state"),
                    "empty_message": sec.get("empty_message"),
                    "fields": cleaned_fields,
                    "table_headers": sec.get("table_headers") or [],
                    "table_rows": t_rows[:300],
                    "table_rows_total_count": len(t_rows),
                    "table_rows_truncated": len(t_rows) > 300,
                    "document_count": len(sec.get("documents") or []),
                })

            regulatory_tabs_subcollection.append({
                "tab_id": tab_doc_id,
                "project_id": project_id,
                "tab_label": tab_key,
                "tab_identifier": tab_obj.get("tab_identifier"),
                "is_visible_tab": is_visible,
                "dom_presence": tab_obj.get("dom_presence", True),
                "observation_state": obs_state,
                "display_order": idx + (1 if is_visible else 100),
                "section_count": sec_count,
                "field_count": f_count,
                "table_count": t_count,
                "document_count": d_count,
                "sections": cleaned_sections,
            })

    process_tab_tree(tabs, is_visible=True)
    process_tab_tree(unlinked, is_visible=False)

    downloadable_docs = [d for d in all_documents if d.get("has_downloadable_file")]
    visible_tabs_with_data = sum(
        1 for v in tab_observations_summary.values() if v.get("observation_state") == "present_with_data"
    )

    # Search metadata
    address_val = summary_metrics["project_address"].get("value")
    search_tokens = build_search_tokens(
        project_name,
        promoter_name,
        taluk,
        district,
        reg_no,
        ack_no,
        str(address_val) if address_val else None,
    )
    search_metadata = {
        "project_name_lower": project_name.lower(),
        "promoter_name_lower": promoter_name.lower(),
        "taluk_lower": taluk.lower(),
        "district_lower": district.lower(),
        "registration_number_lower": reg_no.lower(),
        "registration_number_compact": re.sub(r"[^a-z0-9]+", "", reg_no.lower()),
        "acknowledgement_number_lower": (ack_no or "").lower(),
        "search_tokens": search_tokens,
    }

    counts = {
        "visible_tabs_total": len(tab_observations_summary),
        "visible_tabs_with_data": visible_tabs_with_data,
        "unlinked_panes_total": len(unlinked_pane_summary),
        "total_sections": total_sections,
        "total_fields": total_fields,
        "total_documents": len(all_documents),
        "downloadable_documents": len(downloadable_docs),
        "total_complaints": len(all_complaints),
        "project_complaints": sum(1 for c in all_complaints if c.get("complaint_scope") == "PROJECT"),
        "promoter_complaints": sum(1 for c in all_complaints if c.get("complaint_scope") == "PROMOTER"),
        "pii_exclusions_count": len(normalized_data.get("pii_exclusions") or []),
        "conflicts_count": len(normalized_data.get("cross_section_conflicts") or []),
    }

    # Compute deterministic content hash for idempotent updates
    canonical_payload_for_hash = {
        "project_id": project_id,
        "registration_number": reg_no,
        "project_name": project_name,
        "promoter_name": promoter_name,
        "status": status,
        "counts": counts,
        "summary_metrics": summary_metrics,
        "schema_version": SCHEMA_VERSION,
    }
    content_hash = hashlib.sha256(
        json.dumps(canonical_payload_for_hash, sort_keys=True, default=str).encode("utf-8")
    ).hexdigest()

    now_iso = datetime.datetime.now(datetime.timezone.utc).isoformat()

    root_project_doc = {
        "project_id": project_id,
        "internal_id": project_key,
        "registration_number": reg_no,
        "acknowledgement_number": ack_no,
        "project_name": project_name,
        "promoter_name": promoter_name,
        "district": district,
        "taluk": taluk,
        "city": "Bengaluru",
        "project_type": project_type,
        "regulatory_status": status,
        "approved_on_raw": approved_on_raw,
        "approved_on_iso": parse_date_to_iso(approved_on_raw) or parse_date_to_iso(
            str(summary_metrics["plan_approval_date"].get("value") or "")
        ),
        "proposed_completion_date_raw": proposed_completion_raw,
        "proposed_completion_date_iso": parse_date_to_iso(proposed_completion_raw) or parse_date_to_iso(
            str(summary_metrics["proposed_completion_date"].get("value") or "")
        ),
        "project_start_date_iso": parse_date_to_iso(
            str(summary_metrics["project_start_date"].get("value") or "")
        ),
        "search_metadata": search_metadata,
        "summary_metrics": summary_metrics,
        "inventory_configurations": inventory_configs[:30],
        "towers_summary": towers_list[:35],
        "tab_observations_summary": tab_observations_summary,
        "unlinked_pane_summary": unlinked_pane_summary,
        "counts": counts,
        "identity_verification": normalized_data.get("identity_verification") or {
            "is_verified": True,
            "status": sqlite_row.get("identity_verification_status", "verified"),
        },
        "catalogue_source_info": normalized_data.get("catalogue_source_info") or {},
        "pii_exclusions": (normalized_data.get("pii_exclusions") or [])[:30],
        "cross_section_conflicts": (normalized_data.get("cross_section_conflicts") or [])[:30],
        "unit_hierarchy_status": unit_hierarchy_status,
        "provenance": {
            "source_type": "KRERA_PORTAL",
            "schema_version": SCHEMA_VERSION,
            "extraction_status": sqlite_row.get("extraction_status", "successful"),
            "extracted_at": normalized_data.get("updated_at") or sqlite_row.get("updated_at"),
            "imported_at": now_iso,
            "content_hash": content_hash,
        },
    }

    detail_bundle_doc = {
        "tab_id": "bundle_all",
        "project_id": project_id,
        "tab_label": "Complete Regulatory Detail Bundle",
        "is_visible_tab": False,
        "observation_state": "present_with_data",
        "display_order": 0,
        "key_sections": key_sections,
        "regulatory_documents": all_documents[:150],
        "complaints_records": all_complaints[:120],
        "towers_summary": towers_list[:50],
        "inventory_configurations": inventory_configs[:50],
        "updated_at": now_iso,
    }

    subcollections = {
        "detail_bundle": [detail_bundle_doc],
        "regulatory_tabs": regulatory_tabs_subcollection,
        "documents": all_documents,
        "complaints": all_complaints,
        "towers": [
            {**t, "project_id": project_id}
            for t in towers_list
        ],
    }

    return root_project_doc, subcollections


# ============================================================================
# Firestore REST Batch Commit Client (Uses Firebase CLI OAuth2 Token)
# ============================================================================

def get_firebase_Auth_token() -> str:
    """Retrieve a valid OAuth2 access token for homesureai@gmail.com from Firebase CLI configstore."""
    config_path = Path.home() / ".config" / "configstore" / "firebase-tools.json"
    if not config_path.exists():
        raise RuntimeError(f"Firebase CLI config not found at {config_path}. Run `firebase login`.")
    cfg = json.loads(config_path.read_text(encoding="utf-8"))

    # Check additionalAccounts first for homesureai@gmail.com, then fallback to default tokens
    target_tokens = None
    for acc in cfg.get("additionalAccounts") or []:
        if acc.get("user", {}).get("email") == "homesureai@gmail.com":
            target_tokens = acc.get("tokens")
            break
    if not target_tokens:
        target_tokens = cfg.get("tokens") or {}

    access_token = target_tokens.get("access_token")
    expires_at = target_tokens.get("expires_at", 0)
    # Refresh if expired or within 5 minutes of expiry
    if access_token and expires_at > (time.time() + 300) * 1000:
        return access_token

    # Trigger a lightweight firebase CLI command to auto-refresh token in configstore
    import subprocess
    subprocess.run(
        ["npx", "firebase-tools", "projects:list", "--Account", "homesureai@gmail.com"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        shell=True,
    )
    cfg = json.loads(config_path.read_text(encoding="utf-8"))
    for acc in cfg.get("additionalAccounts") or []:
        if acc.get("user", {}).get("email") == "homesureai@gmail.com":
            return acc["tokens"]["access_token"]
    return cfg["tokens"]["access_token"]


def python_to_firestore_value(val: Any) -> Dict[str, Any]:
    """Convert a Python value into a Firestore REST API Value object."""
    if val is None:
        return {"nullValue": None}
    if isinstance(val, bool):
        return {"booleanValue": val}
    if isinstance(val, int):
        return {"integerValue": str(val)}
    if isinstance(val, float):
        if val != val or val == float("inf") or val == float("-inf"):
            return {"nullValue": None}
        return {"doubleValue": val}
    if isinstance(val, str):
        return {"stringValue": val}
    if isinstance(val, list):
        return {"arrayValue": {"values": [python_to_firestore_value(x) for x in val]}}
    if isinstance(val, dict):
        fields = {}
        for k, v in val.items():
            safe_key = str(k).strip()
            if not safe_key:
                continue
            fields[safe_key] = python_to_firestore_value(v)
        return {"mapValue": {"fields": fields}}
    return {"stringValue": str(val)}


def make_firestore_write_op(doc_rel_path: str, data: Dict[str, Any]) -> Dict[str, Any]:
    """Create a Firestore REST API Write operation for `documents:commit`."""
    full_name = (
        f"projects/{FIREBASE_PROJECT_ID}/databases/{FIRESTORE_DATABASE}/documents/{doc_rel_path}"
    )
    fields = {k: python_to_firestore_value(v) for k, v in data.items() if str(k).strip()}
    return {
        "update": {
            "name": full_name,
            "fields": fields,
        }
    }


def commit_firestore_writes(writes: List[Dict[str, Any]], token: str) -> int:
    """Commit a batch of up to 200 Firestore Write operations with exponential backoff."""
    if not writes:
        return 0
    url = (
        f"https://firestore.googleapis.com/v1/projects/{FIREBASE_PROJECT_ID}"
        f"/databases/{FIRESTORE_DATABASE}/documents:commit"
    )
    body = json.dumps({"writes": writes}).encode("utf-8")
    for attempt in range(1, 5):
        req = urllib.request.Request(
            url,
            data=body,
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                if resp.status == 200:
                    return len(writes)
        except urllib.error.HTTPError as e:
            err_body = e.read().decode("utf-8", errors="replace")
            if e.code in (429, 500, 502, 503, 504) and attempt < 4:
                time.sleep(2 ** attempt)
                continue
            raise RuntimeError(f"Firestore commit HTTP {e.code}: {err_body[:500]}") from e
        except Exception as e:
            if attempt < 4:
                time.sleep(2 ** attempt)
                continue
            raise
    return 0


def load_selected_sqlite_rows(
    conn: sqlite3.Connection,
    project_ids: Optional[List[str]],
    cohort: str,
    limit: Optional[int],
) -> List[Dict[str, Any]]:
    """Query verified extraction rows along with catalogue search metadata from SQLite."""
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    query = """
        SELECT c.*
        FROM detail_extraction_checkpoints c
        WHERE c.extraction_status = 'successful'
        ORDER BY c.catalogue_page_number ASC, c.catalogue_row_order ASC
    """
    rows = [dict(r) for r in cur.execute(query).fetchall()]

    if project_ids:
        wanted = set()
        for pid in project_ids:
            for part in pid.split(","):
                if part.strip():
                    wanted.add(part.strip())
        filtered = []
        for r in rows:
            doc_id = make_deterministic_project_id(r["project_key"], r["registration_number"])
            if (
                r["registration_number"] in wanted
                or r["project_key"] in wanted
                or doc_id in wanted
            ):
                filtered.append(r)
        rows = filtered
    elif cohort == "central8":
        wanted_map = {reg: idx for idx, reg in enumerate(CENTRAL_8_REG_NUMBERS)}
        rows = sorted(
            [r for r in rows if r["registration_number"] in wanted_map],
            key=lambda x: wanted_map[x["registration_number"]],
        )
    elif cohort == "first8":
        wanted_map = {reg: idx for idx, reg in enumerate(FIRST_8_REG_NUMBERS)}
        rows = sorted(
            [r for r in rows if r["registration_number"] in wanted_map],
            key=lambda x: wanted_map[x["registration_number"]],
        )
    elif cohort == "pilot5":
        rows = rows[:5]

    if limit and limit > 0:
        rows = rows[:limit]

    return rows


def main() -> int:
    parser = argparse.ArgumentParser(description="HomeSure K-RERA SQLite-to-Firestore Importer")
    parser.add_argument("--dry-run", action="store_true", help="Run full transformation & validation without writing to Firestore")
    parser.add_argument("--project-id", action="append", help="Specific registration_number, project_key, or Firestore doc_id")
    parser.add_argument("--all-selected", action="store_true", help="Import all selected verified projects")
    parser.add_argument("--cohort", choices=["all", "first8", "central8", "pilot5"], default="all", help="Project cohort to import")
    parser.add_argument("--limit", type=int, default=None, help="Optional cap on number of projects")
    parser.add_argument("--force-update", action="store_true", help="Force update existing Firestore documents")
    parser.add_argument("--with-subcollections", action="store_true", help="Write subcollections for all imported projects")
    args = parser.parse_args()

    if not args.project_id and not args.all_selected:
        print("Error: Specify either --project-id <ID> or --all-selected", file=sys.stderr)
        return 1

    if not SQLITE_DB_PATH.exists():
        print(f"Error: SQLite database not found at {SQLITE_DB_PATH}", file=sys.stderr)
        return 1

    conn = sqlite3.connect(str(SQLITE_DB_PATH))
    selected_rows = load_selected_sqlite_rows(conn, args.project_id, args.cohort, args.limit)
    conn.close()

    print(f"[Importer] Mode: {'DRY-RUN' if args.dry_run else 'LIVE FIRESTORE IMPORT'}")
    print(f"[Importer] Selected projects count: {len(selected_rows)} (cohort={args.cohort})")

    # Always write full subcollections for the 14 showcase/central/first8 projects (or all if --with-subcollections)
    priority_subcollection_regs = set(CENTRAL_8_REG_NUMBERS) | set(FIRST_8_REG_NUMBERS)

    report_items: List[Dict[str, Any]] = []
    pending_writes: List[Dict[str, Any]] = []
    total_root_docs = 0
    total_subcollection_docs = 0
    total_Committed_writes = 0
    errors: List[Dict[str, Any]] = []

    token = None
    if not args.dry_run:
        token = get_firebase_Auth_token()

    start_time = time.time()

    for idx, row in enumerate(selected_rows, start=1):
        norm_rel_path = (row.get("normalized_output_path") or row.get("normalized_json_path") or "").replace("/", os.sep).replace("\\", os.sep)
        norm_path = EXTRACTION_ROOT / norm_rel_path
        if not norm_path.exists():
            errors.append({
                "project_key": row.get("project_key"),
                "error": f"Normalized JSON file missing: {norm_path}",
            })
            continue

        try:
            normalized_data = json.loads(norm_path.read_text(encoding="utf-8"))
            root_doc, subcollections = transform_project_record(row, normalized_data)
            project_id = root_doc["project_id"]
            reg_no = root_doc["registration_number"]

            root_size_bytes = len(json.dumps(root_doc, ensure_ascii=False).encode("utf-8"))
            bundle_doc = subcollections["detail_bundle"][0]
            bundle_size_bytes = len(json.dumps(bundle_doc, ensure_ascii=False).encode("utf-8"))
            if bundle_size_bytes > 850_000:
                bundle_doc["regulatory_documents"] = bundle_doc["regulatory_documents"][:60]
                bundle_doc["complaints_records"] = bundle_doc["complaints_records"][:40]
                for ks in bundle_doc["key_sections"]:
                    ks["table_rows_preview"] = ks["table_rows_preview"][:5]
                bundle_size_bytes = len(json.dumps(bundle_doc, ensure_ascii=False).encode("utf-8"))

            include_subs = (
                args.with_subcollections
                or bool(args.project_id)
                or (reg_no in priority_subcollection_regs)
            )

            sub_counts = {k: len(v) for k, v in subcollections.items()}
            report_items.append({
                "index": idx,
                "project_id": project_id,
                "registration_number": reg_no,
                "acknowledgement_number": root_doc["acknowledgement_number"],
                "project_name": root_doc["project_name"],
                "promoter_name": root_doc["promoter_name"],
                "taluk": root_doc["taluk"],
                "project_type": root_doc["project_type"],
                "regulatory_status": root_doc["regulatory_status"],
                "root_doc_size_kb": round(root_size_bytes / 1024, 2),
                "bundle_doc_size_kb": round(bundle_size_bytes / 1024, 2),
                "visible_tabs": root_doc["counts"]["visible_tabs_total"],
                "visible_tabs_with_data": root_doc["counts"]["visible_tabs_with_data"],
                "total_sections": root_doc["counts"]["total_sections"],
                "total_fields": root_doc["counts"]["total_fields"],
                "total_documents": root_doc["counts"]["total_documents"],
                "downloadable_documents": root_doc["counts"]["downloadable_documents"],
                "total_complaints": root_doc["counts"]["total_complaints"],
                "towers_count": root_doc["unit_hierarchy_status"]["towers_count"],
                "inventory_configs_count": root_doc["unit_hierarchy_status"]["inventory_configs_count"],
                "subcollections_written": include_subs,
                "subcollection_counts": sub_counts if include_subs else {"detail_bundle": 1},
                "content_hash": root_doc["provenance"]["content_hash"][:16],
            })

            total_root_docs += 1

            if not args.dry_run:
                pending_writes.append(make_firestore_write_op(f"projects/{project_id}", root_doc))
                pending_writes.append(
                    make_firestore_write_op(
                        f"projects/{project_id}/regulatory_tabs/bundle_all", bundle_doc
                    )
                )
                total_subcollection_docs += 1
                if include_subs:
                    for tab_doc in subcollections["regulatory_tabs"]:
                        t_id = tab_doc["tab_id"]
                        pending_writes.append(
                            make_firestore_write_op(
                                f"projects/{project_id}/regulatory_tabs/{t_id}", tab_doc
                            )
                        )
                        total_subcollection_docs += 1
                    for doc_item in subcollections["documents"][:150]:
                        d_id = doc_item["document_id"]
                        pending_writes.append(
                            make_firestore_write_op(
                                f"projects/{project_id}/documents/{d_id}", doc_item
                            )
                        )
                        total_subcollection_docs += 1
                    for cmp_item in subcollections["complaints"][:100]:
                        c_id = cmp_item["complaint_id"]
                        pending_writes.append(
                            make_firestore_write_op(
                                f"projects/{project_id}/complaints/{c_id}", cmp_item
                            )
                        )
                        total_subcollection_docs += 1
                    for twr_item in subcollections["towers"][:50]:
                        tw_id = twr_item["tower_id"]
                        pending_writes.append(
                            make_firestore_write_op(
                                f"projects/{project_id}/towers/{tw_id}", twr_item
                            )
                        )
                        total_subcollection_docs += 1

                # Flush batch whenever pending_writes reaches 30 operations
                while len(pending_writes) >= 30:
                    batch = pending_writes[:30]
                    pending_writes = pending_writes[30:]
                    committed = commit_firestore_writes(batch, token)
                    total_Committed_writes += committed
                    print(
                        f"  [Firestore] Committed batch ({committed} writes) | "
                        f"Total writes: {total_Committed_writes} | Projects processed: {idx}/{len(selected_rows)}"
                    )

        except Exception as exc:
            errors.append({
                "project_key": row.get("project_key"),
                "registration_number": row.get("registration_number"),
                "error": str(exc),
            })

    # Flush remaining writes
    if not args.dry_run and pending_writes:
        while pending_writes:
            batch = pending_writes[:30]
            pending_writes = pending_writes[30:]
            committed = commit_firestore_writes(batch, token)
            total_Committed_writes += committed
            print(
                f"  [Firestore] Committed final batch ({committed} writes) | "
                f"Total writes: {total_Committed_writes}"
            )

    elapsed_sec = round(time.time() - start_time, 2)

    summary_report = {
        "mode": "dry_run" if args.dry_run else "live_import",
        "firebase_project_id": FIREBASE_PROJECT_ID,
        "firestore_database": FIRESTORE_DATABASE,
        "schema_version": SCHEMA_VERSION,
        "cohort": args.cohort,
        "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "elapsed_seconds": elapsed_sec,
        "projects_selected": len(selected_rows),
        "projects_transformed_successfully": total_root_docs,
        "subcollection_documents_prepared": total_subcollection_docs,
        "total_firestore_writes_committed": total_Committed_writes,
        "errors_count": len(errors),
        "errors": errors,
        "aggregates": {
            "total_sections": sum(x["total_sections"] for x in report_items),
            "total_fields": sum(x["total_fields"] for x in report_items),
            "total_documents": sum(x["total_documents"] for x in report_items),
            "downloadable_documents": sum(x["downloadable_documents"] for x in report_items),
            "total_complaints": sum(x["total_complaints"] for x in report_items),
            "projects_with_towers": sum(1 for x in report_items if x["towers_count"] > 0),
            "projects_with_inventory_configs": sum(1 for x in report_items if x["inventory_configs_count"] > 0),
            "max_root_doc_size_kb": max((x["root_doc_size_kb"] for x in report_items), default=0),
            "avg_root_doc_size_kb": round(
                sum(x["root_doc_size_kb"] for x in report_items) / max(len(report_items), 1), 2
            ),
        },
        "sample_projects": report_items[:15],
    }

    out_json_name = (
        "firestore_import_dry_run_report.json"
        if args.dry_run
        else "firestore_import_live_report.json"
    )
    out_json_path = EXTRACTION_ROOT / "data" / out_json_name
    out_json_path.write_text(json.dumps({**summary_report, "all_projects": report_items}, indent=2), encoding="utf-8")

    print(f"[Importer] Completed in {elapsed_sec}s. Errors: {len(errors)}. Report saved to {out_json_path}")
    return 0 if not errors else 2


if __name__ == "__main__":
    sys.exit(main())
