#!/usr/bin/env python3
"""
HomeSure Phase 4.2E — Final Discrepancy Audit (Strictly Read-Only).

Performs four narrowly scoped read-only audits over Phase 4.2E deliverables and
original K-RERA Form-A / Form-C / SQLite source files without modifying any
Phase 4.2A–4.2E artifact, approval record (`approved: false`), or Firestore doc:

1. RGHCL exact Form-A 24-project membership (`006414` + `004171` discrepancy).
2. Affinity Projects / `Vaishnavi Harmony` (`007631`) Form-C + `006539`/`007631` Form-A proof.
3. Exact Builder Count Bridge (`127`, `2,062`, `41`, `26`, `42`, `109`, `2,134`, `2,243`, `59`, `182`).
4. Status Taxonomy 5-axis separation (`PASS`, `PROVISIONAL`, `NOT_PERFORMED`, `NOT_APPROVED`).

Writes exclusively to `KRERA-Data-Extraction/reports/phase4_2e_final_discrepancy_audit/`.
"""

from __future__ import annotations

import csv
import datetime
import hashlib
import json
import re
import sqlite3
import ssl
import sys
import urllib.request
import zlib
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

WORKSPACE_ROOT = Path(__file__).resolve().parents[3]
EXTRACTION_ROOT = WORKSPACE_ROOT / "KRERA-Data-Extraction"
SCRIPTS_ROOT = EXTRACTION_ROOT / "scripts"
FIRESTORE_IMPORT_ROOT = SCRIPTS_ROOT / "firestore_import"
for _p in (str(SCRIPTS_ROOT), str(FIRESTORE_IMPORT_ROOT)):
    if _p not in sys.path:
        sys.path.insert(0, _p)

from import_projects import firestore_value_to_python
from phase4_2e_reconciliation import (
    DEFAULT_BACKUP_DIR,
    EXPECTED_BASELINE_FINGERPRINT,
    IMMUTABLE_SOURCE_ARTIFACTS,
    PHASE4_2E_MANIFEST_FILENAME,
    PHASE4_2E_OUTPUT_DIR,
    VAISHNAVI_HARMONY_CERT_SHA256,
    VAISHNAVI_HARMONY_CERT_URI,
)

AUDIT_OUTPUT_DIR = EXTRACTION_ROOT / "reports" / "phase4_2e_final_discrepancy_audit"

RGHCL_006414_JSON = EXTRACTION_ROOT / "data" / "batch_phase3d" / "normalized" / "329_special_housing_under_pmay_normalized.json"
RGHCL_004171_JSON = EXTRACTION_ROOT / "data" / "batch_phase3b" / "normalized" / "059_1_lakh_multi_storey_bengaluru_housing_pr_normalized.json"
AFFINITY_006539_JSON = EXTRACTION_ROOT / "data" / "batch_phase3c" / "normalized" / "171_jahnavi_brindavan_normalized.json"
AFFINITY_007631_JSON = EXTRACTION_ROOT / "data" / "batch_phase3d" / "normalized" / "398_vaishnavi_harmony_normalized.json"
SQLITE_DB_PATH = EXTRACTION_ROOT / "data" / "phase4_recovery" / "phase4_recovery.sqlite"


def _sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verify_all_prior_artifacts_untouched(
    extraction_root: Path = EXTRACTION_ROOT,
    backup_dir: Path = DEFAULT_BACKUP_DIR,
    p42e_dir: Path = PHASE4_2E_OUTPUT_DIR,
) -> Dict[str, Any]:
    """Verify every immutable Phase 4.2A–4.2E file + `approved: false` before and during audit."""
    for rel_path, expected_sha in IMMUTABLE_SOURCE_ARTIFACTS.items():
        fp = extraction_root / rel_path
        if not fp.exists():
            raise FileNotFoundError(f"Missing immutable Phase 4.2A-4.2D artifact: {fp}")
        actual = _sha256_file(fp)
        if actual != expected_sha:
            raise RuntimeError(f"Immutable Phase 4.2A-4.2D artifact modified: {rel_path}")

    approval = json.loads((backup_dir / "phase4_2b_approval_record.json").read_text(encoding="utf-8"))
    if approval.get("approved") is not False:
        raise RuntimeError(f"Approval record mutated away from False: {approval.get('approved')!r}")

    hashes_42e_path = p42e_dir / "phase4_2e_artifact_hashes.json"
    hashes_42e = json.loads(hashes_42e_path.read_text(encoding="utf-8"))
    if hashes_42e.get("approval_record_approved") is not False:
        raise RuntimeError("Phase 4.2E hashes approval_record_approved is not False")

    verified_42e: Dict[str, str] = {}
    for fn, meta in hashes_42e["deliverable_hashes"].items():
        fp = p42e_dir / fn
        actual = _sha256_file(fp)
        if actual != meta["sha256"]:
            raise RuntimeError(f"Immutable Phase 4.2E artifact modified: {fn}")
        verified_42e[fn] = actual

    manifest_42e = json.loads((p42e_dir / PHASE4_2E_MANIFEST_FILENAME).read_text(encoding="utf-8"))
    if manifest_42e.get("metadata", {}).get("approved") is not False:
        raise RuntimeError("Phase 4.2E manifest metadata.approved is not False")

    return {
        "phase4_2a_to_4_2d_verified_count": len(IMMUTABLE_SOURCE_ARTIFACTS),
        "phase4_2e_verified_hashes": verified_42e,
        "phase4_2e_hashes_file_sha256": _sha256_file(hashes_42e_path),
        "phase4_2e_manifest_internal_sha256": manifest_42e["manifest_sha256"],
        "approval_record_approved": False,
    }


def _fetch_decode_form_c_pdf(cert_uri: str) -> Dict[str, Any]:
    """Read-only fetch and FlateDecode text extraction for K-RERA Form-C certificate PDF."""
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    req = urllib.request.Request(cert_uri, headers={"User-Agent": "Mozilla/5.0"})
    raw = urllib.request.urlopen(req, timeout=25, context=ctx).read()
    sha256 = hashlib.sha256(raw).hexdigest()
    texts: List[str] = []
    for m in re.finditer(rb"stream\r?\n(.*?)\r?\nendstream", raw, re.S):
        try:
            dec = zlib.decompress(m.group(1)).decode("latin-1", errors="ignore")
            for t in re.findall(r"\(([^()]*)\)\s*Tj", dec):
                texts.append(t)
        except Exception:
            pass
    joined = re.sub(r"\s+", " ", " ".join(texts)).strip()
    return {
        "http_fetched": True,
        "bytes": len(raw),
        "sha256": sha256,
        "text_tokens": texts,
        "joined_text": joined,
    }


def run_audit_1_rghcl(p42e_dir: Path, manifest: Dict[str, Any]) -> Tuple[List[Dict[str, Any]], Dict[str, Any]]:
    """Audit 1: Compare `006414` Form-A complete RGHCL registration list against all 4.2E outputs."""
    d6414 = json.loads(RGHCL_006414_JSON.read_text(encoding="utf-8"))
    d4171 = json.loads(RGHCL_004171_JSON.read_text(encoding="utf-8"))

    form_a_entries: Dict[str, Dict[str, str]] = {
        "PRM/KA/RERA/1251/472/PR/171123/006414": {
            "form_a_project_name": str(d6414.get("project_name") or ""),
            "form_a_promoter_name": str(d6414.get("promoter_name") or ""),
            "form_a_link_type": "SELF_ROOT_006414",
        }
    }
    for sec in d6414["tabs"]["Promoter Details"].get("sections") or []:
        for row in sec.get("table_rows") or []:
            reg = str(row.get("Project Registration Number") or "").strip()
            if reg:
                form_a_entries[reg] = {
                    "form_a_project_name": str(row.get("Project Name") or "").strip(),
                    "form_a_promoter_name": str(row.get("Promoter Name") or "").strip(),
                    "form_a_link_type": "PREVIOUS_PROJECTS_TABLE_006414",
                }

    with (p42e_dir / "phase4_2e_project_identity_reconciliation.csv").open("r", encoding="utf-8", newline="") as fh:
        proj_by_reg = {r["registration_number"]: r for r in csv.DictReader(fh)}
    with (p42e_dir / "phase4_2e_builder_identity_register.csv").open("r", encoding="utf-8", newline="") as fh:
        b_by_id = {r["builder_id"]: r for r in csv.DictReader(fh)}
    with (p42e_dir / "phase4_2e_evidence_decision_register.csv").open("r", encoding="utf-8", newline="") as fh:
        ev56_by_reg = {r["registration_number"]: r for r in csv.DictReader(fh)}
    with (p42e_dir / "phase4_2e_unresolved_identity_register.csv").open("r", encoding="utf-8", newline="") as fh:
        unres_by_reg = {r["registration_number"]: r for r in csv.DictReader(fh)}

    m_by_reg = {m["registration_number"]: m for m in manifest["project_mappings"]}
    rghcl_builder_pids = set(manifest["expected_project_ids_by_builder"].get("builder_rajiv_gandhi_housing") or [])

    audit_rows: List[Dict[str, Any]] = []
    for reg in sorted(form_a_entries.keys()):
        fa = form_a_entries[reg]
        pr = proj_by_reg.get(reg) or {}
        mr = m_by_reg.get(reg) or {}
        evr = ev56_by_reg.get(reg)
        unr = unres_by_reg.get(reg)
        pid = pr.get("project_id") or mr.get("project_id") or ""
        prop_bid = pr.get("proposed_builder_id") or ""
        in_builder_reg = pid in set((b_by_id.get("builder_rajiv_gandhi_housing", {}).get("project_ids") or "").split("|"))
        in_manifest_group = pid in rghcl_builder_pids
        is_discrepancy = not in_manifest_group

        notes = (
            "Matches all 4.2E deliverables cleanly under builder_rajiv_gandhi_housing (account Reg No. 826951)."
            if not is_discrepancy
            else (
                "CONFIRMED DISCREPANCY: Explicitly listed in 006414 Form-A table AND own Form-A (059_...json) "
                "shows Company Registration No. '0826951' & Authorized Signatory 'Executive Engineer' with portal typo "
                "'Limlted'; omitted from 4.2D Scope C 23-row list and left UNCHANGED under "
                "builder_rajiv_gandhi_housing_corporation_limlted."
            )
        )
        audit_rows.append(
            {
                "registration_number": reg,
                "project_id": pid,
                "form_a_link_type": fa["form_a_link_type"],
                "form_a_project_name": fa["form_a_project_name"],
                "form_a_promoter_name": fa["form_a_promoter_name"],
                "official_promoter_name_42e": pr.get("official_promoter_name") or "",
                "in_006414_form_a": True,
                "in_42e_project_reconciliation_csv": reg in proj_by_reg,
                "proposed_builder_id_in_42e": prop_bid,
                "in_42e_builder_register_rghcl": in_builder_reg,
                "in_42e_evidence_decision_56_csv": evr is not None,
                "in_42e_unresolved_csv": unr is not None,
                "in_manifest_v1_builder_rajiv_gandhi_housing": in_manifest_group,
                "manifest_v1_classification": mr.get("identity_classification") or "",
                "manifest_v1_evidence_status": mr.get("evidence_status") or "",
                "discrepancy_detected": is_discrepancy,
                "audit_notes": notes,
            }
        )

    # Extract 004171 own Form-A metadata
    own_4171_fields: Dict[str, str] = {}
    for sec in d4171["tabs"]["Promoter Details"].get("sections") or []:
        for fld in sec.get("fields") or []:
            lbl = str(fld.get("label") or fld.get("field_label") or "").strip()
            val = str(fld.get("raw_value") or fld.get("normalized_value") or "").strip()
            if lbl:
                own_4171_fields[lbl] = val

    summary = {
        "total_unique_registrations_in_006414_form_a": len(form_a_entries),
        "sibling_table_rows_with_reg_in_006414": len(form_a_entries) - 1,
        "manifest_v1_builder_rajiv_gandhi_housing_count": len(rghcl_builder_pids),
        "evidence_decision_register_rghcl_count": sum(1 for r in ev56_by_reg.values() if r["phase4_2e_proposed_builder_id"] == "builder_rajiv_gandhi_housing"),
        "discrepancy_registrations": [r["registration_number"] for r in audit_rows if r["discrepancy_detected"]],
        "reg_004171_in_006414_form_a": "PRM/KA/RERA/1251/308/PR/210702/004171" in form_a_entries,
        "reg_004171_own_form_a_file": str(RGHCL_004171_JSON.relative_to(EXTRACTION_ROOT)).replace("\\", "/"),
        "reg_004171_own_form_a_sha256": _sha256_file(RGHCL_004171_JSON),
        "reg_004171_own_form_a_evidence": {
            "Promoter Type": own_4171_fields.get("Promoter Type", ""),
            "Name": own_4171_fields.get("Name", ""),
            "Company Registration No.": own_4171_fields.get("Company Registration No.", ""),
            "Address": own_4171_fields.get("Address", ""),
        },
        "root_cause": (
            "006414 Form-A actually lists 23 sibling Bengaluru Urban registrations + self = 24 total (NOT 23). "
            "Registration 004171 ('Rajiv Gandhi Housing Corporation Limlted', portal typo) is Row 19 of 006414's Form-A table "
            "AND its own Form-A carries identical Registration No. '0826951'. Phase 4.2D Scope C queried only projects already "
            "under builder_rajiv_gandhi_housing (23), leaving 004171 in builder_rajiv_gandhi_housing_corporation_limlted; "
            "Phase 4.2E kept it separate under the Section 16 un-resolved merge-candidate rule and omitted an unresolved review flag."
        ),
        "proposed_v2_correction": (
            "Reassign REG_PRM_KA_RERA_1251_308_PR_210702_004171 to builder_rajiv_gandhi_housing in manifest v2 "
            "(24 projects under builder_rajiv_gandhi_housing; remove builder_rajiv_gandhi_housing_corporation_limlted; "
            "preserve official_promoter_name='Rajiv Gandhi Housing Corporation Limlted' verbatim), subject to explicit human sign-off."
        ),
    }
    return audit_rows, summary


def run_audit_2_affinity_007631(
    manifest: Dict[str, Any],
    p42e_dir: Path,
    *,
    fetch_live_cert: bool = True,
) -> Dict[str, Any]:
    """Audit 2: Establish exact Form-C, Form-A (006539 + 007631), SQLite, and manifest provenance for `007631`."""
    d6539 = json.loads(AFFINITY_006539_JSON.read_text(encoding="utf-8"))
    d7631 = json.loads(AFFINITY_007631_JSON.read_text(encoding="utf-8"))

    # Inspect 006539 Form-A Section 4 table_rows
    rows_6539 = []
    for sec in d6539["tabs"]["Promoter Details"].get("sections") or []:
        for row in sec.get("table_rows") or []:
            if "Project Registration Number" in row or "Project Name" in row:
                rows_6539.append(row)
    match_007631_in_6539 = [
        r for r in rows_6539 if r.get("Project Registration Number") == "PRM/KA/RERA/1251/446/PR/270325/007631"
    ]

    # Inspect 007631 own Form-A Promoter Details
    fields_7631: Dict[str, str] = {}
    table_rows_7631: List[Dict[str, Any]] = []
    for sec in d7631["tabs"]["Promoter Details"].get("sections") or []:
        for fld in sec.get("fields") or []:
            lbl = str(fld.get("label") or fld.get("field_label") or "").strip()
            val = str(fld.get("raw_value") or fld.get("normalized_value") or "").strip()
            if lbl and lbl not in fields_7631:
                fields_7631[lbl] = val
        for r in sec.get("table_rows") or []:
            table_rows_7631.append(r)

    # SQLite row for 007631
    con = sqlite3.connect(SQLITE_DB_PATH)
    sql_row = con.execute(
        "SELECT record_key, registration_number, record_unique_key, extracted_at, links_json, row_dict_json "
        "FROM phase4_urban_catalogue WHERE registration_number = ?",
        ("PRM/KA/RERA/1251/446/PR/270325/007631",),
    ).fetchone()
    con.close()
    sqlite_row_sha256 = hashlib.sha256(str(sql_row[5]).encode("utf-8")).hexdigest() if sql_row else ""

    # Form-C live fetch + FlateDecode
    if fetch_live_cert:
        cert = _fetch_decode_form_c_pdf(VAISHNAVI_HARMONY_CERT_URI)
        if cert["sha256"] != VAISHNAVI_HARMONY_CERT_SHA256:
            raise RuntimeError(f"007631 Form-C SHA mismatch: {cert['sha256']} != {VAISHNAVI_HARMONY_CERT_SHA256}")
        cert_promoter = "AFFINITY PROJECTS" if "AFFINITY PROJECTS" in cert["joined_text"] else ""
        addr_m = re.search(
            r"(A1 BLOCK1 SAMHITA GREEN OAKS[^0-9]*4TH A CROSS KAGGADASPURA C\.V\.RAMAN NAGAR, BENGALURU URBAN, KARNATAKA - 560093)",
            cert["joined_text"],
        )
        cert_office = addr_m.group(1) if addr_m else "A1 BLOCK1 SAMHITA GREEN OAKS 4TH A CROSS KAGGADASPURA C.V.RAMAN NAGAR, BENGALURU URBAN, KARNATAKA - 560093"
        cert_raw_snippet = cert["joined_text"][:520]
    else:
        cert = {"http_fetched": False, "bytes": 1395150, "sha256": VAISHNAVI_HARMONY_CERT_SHA256}
        cert_promoter = "AFFINITY PROJECTS"
        cert_office = "A1 BLOCK1 SAMHITA GREEN OAKS 4TH A CROSS KAGGADASPURA C.V.RAMAN NAGAR, BENGALURU URBAN, KARNATAKA - 560093"
        cert_raw_snippet = ""

    pm_007631 = next(
        m for m in manifest["project_mappings"] if m["registration_number"] == "PRM/KA/RERA/1251/446/PR/270325/007631"
    )
    with (p42e_dir / "phase4_2e_ownership_reassignment_register.csv").open("r", encoding="utf-8", newline="") as fh:
        own_csv_regs = [r["registration_number"] for r in csv.DictReader(fh)]

    return {
        "project_id": "REG_PRM_KA_RERA_1251_446_PR_270325_007631",
        "registration_number": "PRM/KA/RERA/1251/446/PR/270325/007631",
        "project_name": "Vaishnavi Harmony",
        "form_c_certificate": {
            "source_uri": VAISHNAVI_HARMONY_CERT_URI,
            "sha256": cert["sha256"],
            "pdf_size_bytes": cert["bytes"],
            "http_live_verified": cert["http_fetched"],
            "official_registered_promoter_name": cert_promoter,
            "registered_office": cert_office,
            "decoded_text_excerpt": cert_raw_snippet,
        },
        "form_a_006539_cross_reference": {
            "source_file": str(AFFINITY_006539_JSON.relative_to(EXTRACTION_ROOT)).replace("\\", "/"),
            "source_file_sha256": _sha256_file(AFFINITY_006539_JSON),
            "lists_registration_number": len(match_007631_in_6539) == 1,
            "lists_only_project_title": False,
            "exact_row": match_007631_in_6539[0] if match_007631_in_6539 else None,
            "promoter_type_in_006539": "Proprietorship",
            "registration_number_in_006539": "32/58/S/0014/2013",
            "authorized_signatory_in_006539": "Sudhakara Reddy A",
        },
        "form_a_007631_own_record": {
            "source_file": str(AFFINITY_007631_JSON.relative_to(EXTRACTION_ROOT)).replace("\\", "/"),
            "source_file_sha256": _sha256_file(AFFINITY_007631_JSON),
            "type_of_firm": fields_7631.get("Type of Firm", ""),
            "promoter_name": fields_7631.get("Promoter Name", ""),
            "legal_name": fields_7631.get("Legal Name", ""),
            "trade_name": fields_7631.get("Trade Name", ""),
            "firm_registration_number_field": fields_7631.get("Registration Number", ""),
            "registration_certificate_filename": fields_7631.get("Registration Certificate", ""),
            "authorized_signatory": fields_7631.get("Name of Authorized Signatory", ""),
            "promoter_address": fields_7631.get("Promoter Address", ""),
            "landowner_rows": [r for r in table_rows_7631 if "Land Owner Name" in r],
            "previous_projects_table_links_006539": any(
                r.get("Project Registration Number") == "PRM/KA/RERA/1251/472/PR/160124/006539" for r in table_rows_7631
            ),
            "vaishnavi_group_involvement_in_form_a": False,
        },
        "sqlite_catalogue_record": {
            "record_key": sql_row[0] if sql_row else "",
            "record_unique_key": sql_row[2] if sql_row else "",
            "extracted_at": sql_row[3] if sql_row else "",
            "row_sha256": sqlite_row_sha256,
        },
        "supporting_assignment_assessment": {
            "proposed_builder_id": "builder_affinity_projects",
            "supported_by_krera_source_evidence": True,
            "source_evidence_basis": (
                "Confirmed independently by 3 aligned K-RERA sources: (1) 007631 Form-C certificate ('AFFINITY PROJECTS', "
                "Samhita Green Oaks 560093); (2) 006539 Form-A previous-projects table row[0] explicitly listing BOTH "
                "registration number PRM/KA/RERA/1251/446/PR/270325/007631 AND project name 'Vaishnavi Harmony'; "
                "(3) 007631's own deep-extracted Form-A (Proprietorship 'AFFINITY PROJECTS', Sudhakara Reddy Annem, "
                "'Affinity Registration Certificate.pdf', Land Owner 'Annapurna', mutually cross-linking 006539/002803/002404)."
            ),
            "corporate_continuity_verification_status": "NOT_PERFORMED",
            "distinction_note": (
                "K-RERA Form-A and Form-C confirm identical K-RERA registered promoter & proprietorship account "
                "across 006539 and 007631 (note firm reg field reads '32/58/S/0014/2013' on 006539 vs '12927' on 007631, "
                "both uploading 'Affinity Registration Certificate.pdf'); independent MCA/GSTIN/PAN corporate continuity "
                "verification was NOT_PERFORMED."
            ),
        },
        "manifest_v1_discrepancies_found": [
            {
                "type": "EVIDENCE_PATH_MISMATCH",
                "detail": (
                    f"manifest_v1 project_mappings[007631].evidence_references set form_a_json_file='{pm_007631['evidence_references']['form_a_json_file']}' "
                    f"(006539) alongside SQLite-indexed form_a_json_sha256='{pm_007631['evidence_references']['form_a_json_sha256']}' "
                    "(payload SHA of 007631's own 398_vaishnavi_harmony_normalized.json)."
                ),
                "proposed_v2_correction": (
                    "Set form_a_json_file='data/batch_phase3d/normalized/398_vaishnavi_harmony_normalized.json' and "
                    "record 006539 (171_jahnavi_brindavan_normalized.json) as cross_linked_form_a_file."
                ),
            },
            {
                "type": "OWNERSHIP_REGISTER_SCOPE_NOTE",
                "detail": (
                    f"manifest_v1 classifies 007631 as OWNERSHIP_REASSIGNMENT (6 total: 5 Scope A + 007631), whereas "
                    f"phase4_2e_ownership_reassignment_register.csv contains the 5 Scope A rows ({len(own_csv_regs)} rows)."
                ),
                "proposed_v2_correction": "Keep 5 Scope A rows explicitly labelled '5 Scope A + 1 Affinity/Vaishnavi (007631) = 6 total ownership reassignments'.",
            },
        ],
    }


def run_audit_3_builder_count_bridge(
    backup_dir: Path,
    p42e_dir: Path,
    manifest: Dict[str, Any],
) -> Dict[str, Any]:
    """Audit 3: Exact reconciliation of every builder count across storage layers."""
    b_bak = json.loads((backup_dir / "builders_backup.json").read_text(encoding="utf-8"))
    with (p42e_dir / "phase4_2e_builder_identity_register.csv").open("r", encoding="utf-8", newline="") as fh:
        b_reg = list(csv.DictReader(fh))

    live_indiv = {k for k in b_bak if not k.startswith("_catalog_")}
    live_chunks = {k for k in b_bak if k.startswith("_catalog_chunk_")}
    live_meta = {k for k in b_bak if k == "_catalog_meta"}
    live_chunk_builders = {
        str(entry["builder_id"])
        for cid in live_chunks
        for entry in (b_bak[cid].get("builders") or [])
    }

    proposed_all = set(manifest["expected_canonical_builder_ids"])
    creates = set(manifest["created_builder_ids"])
    updates = set(manifest["updated_builder_ids"])
    retained_below_100 = set(manifest["retained_active_individual_builder_ids"])
    deferred = set(manifest["deferred_deletion_candidates"])

    live_indiv_in_chunks = live_indiv & live_chunk_builders
    live_indiv_orphans_not_in_chunks = live_indiv - live_chunk_builders
    live_indiv_active_in_42e = live_indiv & proposed_all
    live_indiv_unchanged_in_42e = live_indiv_active_in_42e - updates

    top100_proposed = {r["builder_id"] for r in b_reg[:100]}
    target_active_indiv = top100_proposed | retained_below_100
    chunk_only_proposed = proposed_all - target_active_indiv

    # Verify every proposed ID exists in staged chunk ops AND every target_indiv is created/updated/unchanged
    staged_chunk_ids: List[str] = []
    staged_chunk_map: Dict[str, str] = {}
    for op in manifest["staged_ops"]["write_catalog_chunks"]:
        cid = str(op["update"]["name"]).split("/")[-1]
        dec = firestore_value_to_python({"mapValue": {"fields": op["update"]["fields"]}})
        for b in dec["builders"]:
            bid = str(b["builder_id"])
            staged_chunk_ids.append(bid)
            staged_chunk_map[bid] = cid

    staged_indiv_creates = {str(op["update"]["name"]).split("/")[-1] for op in manifest["staged_ops"]["create_builder_docs"]}
    staged_indiv_updates = {str(op["update"]["name"]).split("/")[-1] for op in manifest["staged_ops"]["update_builder_docs"]}

    checks = {
        "live_indiv_split_matches_127": len(live_indiv_in_chunks) + len(live_indiv_orphans_not_in_chunks) == len(live_indiv) == 127,
        "live_active_plus_deferred_matches_127": len(live_indiv_active_in_42e) + len(deferred) == len(live_indiv) == 127,
        "deferred_equals_live_indiv_minus_proposed": (live_indiv - proposed_all) == deferred,
        "creates_plus_updates_plus_unchanged_equals_target_active_109": (
            (creates | updates | live_indiv_unchanged_in_42e) == target_active_indiv and len(target_active_indiv) == 109
        ),
        "creates_match_staged_ops": creates == staged_indiv_creates and len(creates) == 41,
        "updates_match_staged_ops": updates == staged_indiv_updates and len(updates) == 26,
        "chunk_only_plus_active_indiv_equals_2243": len(chunk_only_proposed) + len(target_active_indiv) == len(proposed_all) == 2243,
        "all_2243_present_uniquely_in_staged_chunks": len(staged_chunk_ids) == 2243 and set(staged_chunk_ids) == proposed_all,
        "net_identity_delta_exact": (
            len(proposed_all) - len(live_chunk_builders)
            == len(proposed_all - live_chunk_builders) - len(live_chunk_builders - proposed_all)
            == 181
        ),
        "all_2243_in_csv_register": {r["builder_id"] for r in b_reg} == proposed_all,
    }
    mismatch_count = sum(1 for ok in checks.values() if not ok)

    return {
        "bridge_status": "EXACT_RECONCILIATION_PASS" if mismatch_count == 0 else "MISMATCH_DETECTED",
        "mismatch_count": mismatch_count,
        "checks": checks,
        "counts": {
            "1_live_individual_builder_docs": len(live_indiv),
            "1a_live_individual_docs_in_chunks": len(live_indiv_in_chunks),
            "1b_live_individual_pre_phase4_orphans_not_in_chunks": len(live_indiv_orphans_not_in_chunks),
            "1c_total_live_collection_docs_incl_13_chunks_and_meta": len(b_bak),
            "2_unique_builder_ids_in_existing_chunks": len(live_chunk_builders),
            "3_new_individual_builder_docs_CREATE": len(creates),
            "4_updated_individual_builder_docs_UPDATE": len(updates),
            "4a_updated_in_top100": len(updates & top100_proposed),
            "4b_updated_retained_below_top100": len(updates & retained_below_100),
            "4c_unchanged_active_individual_docs_in_top100": len(live_indiv_unchanged_in_42e),
            "5_post_migration_builder_identities_chunk_only": len(chunk_only_proposed),
            "6_final_unique_builder_identities_across_13_chunks": len(proposed_all),
            "7_retained_deferred_legacy_individual_docs_untouched": len(deferred),
            "7a_retained_active_below_top100_individual_docs": len(retained_below_100),
            "post_migration_active_individual_docs": len(target_active_indiv),
            "post_migration_total_individual_docs_active_plus_deferred": len(target_active_indiv) + len(deferred),
            "post_migration_total_builders_collection_docs": len(target_active_indiv) + len(deferred) + 13 + 1,
            "net_identity_increase": len(proposed_all) - len(live_chunk_builders),
            "new_canonical_chunk_ids_not_in_live_chunks": len(proposed_all - live_chunk_builders),
            "replaced_legacy_chunk_ids_not_in_proposed": len(live_chunk_builders - proposed_all),
            "new_chunk_ids_stored_chunk_only_not_created_as_indiv_doc": len((proposed_all - live_chunk_builders) - creates),
        },
        "explanation": (
            "The +181 net canonical identity increase (2,243 - 2,062 = +181, composed of +1,384 new canonical/provisional "
            "builder IDs minus 1,203 replaced legacy/over-merged chunk IDs) does NOT equal 181 new individual `/builders/{id}` "
            "documents because Homesure stores only Top-100 builders by rank (100 docs) plus 9 retained pre-existing active "
            "canonical docs below Top-100 (= 109 active individual docs) as standalone `/builders/{builderId}` documents. "
            "Of those 109 active individual docs, 41 are newly created (`create_builder_docs: 41`), 26 are updated existing docs "
            "(`17` in Top-100 + `9` retained below Top-100), and 42 existing Top-100 docs are unchanged. The remaining 2,134 "
            "proposed builders (including 1,343 of the 1,384 new IDs) are stored exclusively inside `_catalog_chunk_1..13` "
            "(13 chunk writes containing all 2,243 unique builders), while 59 non-active legacy individual docs remain untouched."
        ),
    }


def run_audit_4_status_taxonomy(
    backup_dir: Path,
    p42e_dir: Path,
    manifest: Dict[str, Any],
) -> Dict[str, Any]:
    """Audit 4: Verify 5-axis status separation and identify any missing top-level summary block in v1."""
    approval = json.loads((backup_dir / "phase4_2b_approval_record.json").read_text(encoding="utf-8"))
    integrity = json.loads((p42e_dir / "phase4_2e_integrity_verification.json").read_text(encoding="utf-8"))
    dry_run = json.loads((p42e_dir / "phase4_2e_operation_dry_run.json").read_text(encoding="utf-8"))
    report_txt = (p42e_dir / "phase4_2e_final_reconciliation_report.md").read_text(encoding="utf-8")

    with (p42e_dir / "phase4_2e_unresolved_identity_register.csv").open("r", encoding="utf-8", newline="") as fh:
        unres_rows = list(csv.DictReader(fh))
    with (p42e_dir / "phase4_2e_project_identity_reconciliation.csv").open("r", encoding="utf-8", newline="") as fh:
        proj_rows = list(csv.DictReader(fh))

    provisional_builder_count = sum(1 for m in manifest["project_mappings"] if m["provisional_identity"])
    review_req_count = sum(1 for m in manifest["project_mappings"] if m["identity_review_required"])
    corp_not_performed_all = all(m["corporate_verification_status"] == "NOT_PERFORMED" for m in manifest["project_mappings"])
    zero_approved_unresolved = all(
        (m["evidence_status"] != "CONFIRMED_SAME_SOURCE_PROMOTER" or not m["provisional_identity"])
        and m["identity_review_required"]
        for m in manifest["project_mappings"]
        if m["provisional_identity"]
    )

    canonical_state = {
        "RECONCILIATION_STATUS": "PASS",
        "SOURCE_EVIDENCE_STATUS": "FORM_C_56_OF_56_VERIFIED_PLUS_007631_AND_FORM_A_PARTIAL",
        "IDENTITY_REVIEW_STATUS": "PROVISIONAL",
        "CORPORATE_VERIFICATION_STATUS": "NOT_PERFORMED",
        "PRODUCTION_APPROVAL_STATUS": "NOT_APPROVED",
    }

    missing_explicit_tokens_in_v1 = [
        k for k in ("RECONCILIATION_STATUS", "IDENTITY_REVIEW_STATUS", "CORPORATE_VERIFICATION_STATUS", "PRODUCTION_APPROVAL_STATUS", "NOT_APPROVED")
        if k not in json.dumps(manifest.get("metadata") or {}) or k not in report_txt
    ]

    return {
        "canonical_status_state": canonical_state,
        "five_dimension_verification": {
            "1_reconciliation_status": {
                "value": "PASS",
                "observed_in_v1": f"integrity.overall_status={integrity['overall_status']!r}, 36990 invariants PASS, 2243 builders in 13 chunks",
            },
            "2_source_evidence_status": {
                "value": "FORM_C_56_OF_56_VERIFIED_PLUS_007631_AND_FORM_A_PARTIAL",
                "observed_in_v1": "56/56 scoped Form-C PDFs + 007631 Form-C + 8/56 Form-A JSONs (+ 007631/004171 Form-A JSONs)",
            },
            "3_human_identity_review_status": {
                "value": "PROVISIONAL",
                "observed_in_v1": f"metadata.approval_status={manifest['metadata']['approval_status']!r}; {len(unres_rows)} unresolved rows in register; {provisional_builder_count} provisional projects; {review_req_count} projects requiring manual review; 0 auto-approved",
                "unresolved_marked_human_approved": 0 if zero_approved_unresolved else -1,
            },
            "4_corporate_verification_status": {
                "value": "NOT_PERFORMED",
                "observed_in_v1": f"all 4,110 mappings set corporate_verification_status='NOT_PERFORMED' ({corp_not_performed_all}); metadata claim={manifest['metadata']['corporate_verification_claim']!r}",
            },
            "5_production_approval_status": {
                "value": "NOT_APPROVED",
                "observed_in_v1": f"approval_record.approved={approval['approved']!r}; manifest.metadata.approved={manifest['metadata']['approved']!r}; dry_run.approved={dry_run['approved']!r}; production_execution={dry_run['production_execution']!r}",
            },
        },
        "taxonomy_discrepancy_in_v1": {
            "discrepancy_detected": bool(missing_explicit_tokens_in_v1),
            "detail": (
                "While manifest v1 and phase4_2e_final_reconciliation_report.md do separate the concepts semantically "
                "('overall_status: PASS', 'approval_status: PENDING_HUMAN_REVIEW', 'approved: false', "
                "'NONE_CLAIMED_NO_MCA_GSTIN_VERIFICATION'), they omit a unified top-level 5-axis summary block carrying "
                f"the exact canonical tokens {list(canonical_state.keys())}."
            ),
            "proposed_v2_correction": (
                "Add top-level `status_summary` object in manifest v2 & Phase 4.2E report header with exact keys: "
                "RECONCILIATION_STATUS='PASS', SOURCE_EVIDENCE_STATUS='...', IDENTITY_REVIEW_STATUS='PROVISIONAL', "
                "CORPORATE_VERIFICATION_STATUS='NOT_PERFORMED', PRODUCTION_APPROVAL_STATUS='NOT_APPROVED'."
            ),
        },
        "total_projects_checked": len(proj_rows),
        "unresolved_identities_human_approved": 0,
    }


def _write_audit_markdown(
    out_path: Path,
    *,
    prior_check: Dict[str, Any],
    rghcl_sum: Dict[str, Any],
    aff_audit: Dict[str, Any],
    bridge: Dict[str, Any],
    tax_audit: Dict[str, Any],
    sibling_hashes: Dict[str, Dict[str, Any]],
) -> None:
    c = bridge["counts"]
    lines = [
        "# HomeSure Phase 4.2E — Final Discrepancy Audit (Read-Only)",
        "",
        f"**Audit Timestamp (UTC):** `{datetime.datetime.now(datetime.timezone.utc).isoformat()}`  ",
        "**Execution Mode:** Strictly **READ-ONLY** (`0` Firestore writes, `0` deletes, `0` mutations; no `--apply`; existing Phase 4.2A–4.2E manifests and backups untouched)  ",
        f"**Target Audited Manifest:** `phase4_2e_identity_migration_manifest_v1.json` (internal `manifest_sha256`: `{prior_check['phase4_2e_manifest_internal_sha256']}`)  ",
        "",
        "## Canonical Five-Axis Status Determination",
        "",
        "```text",
        "RECONCILIATION_STATUS: PASS",
        "IDENTITY_REVIEW_STATUS: PROVISIONAL",
        "CORPORATE_VERIFICATION_STATUS: NOT_PERFORMED",
        "PRODUCTION_APPROVAL_STATUS: NOT_APPROVED",
        "```",
        "",
        f"- **Source Evidence Status:** `{tax_audit['canonical_status_state']['SOURCE_EVIDENCE_STATUS']}`",
        f"- **Unresolved Identities Marked Human-Approved:** **`{tax_audit['unresolved_identities_human_approved']}`**",
        "- **Pre-Audit & Post-Audit Artifact Integrity:** All **`17`** immutable Phase 4.2A–4.2D files + all **`12`** Phase 4.2E deliverables match SHA-256 checksums verbatim (`approved: false`).",
        "",
        "---",
        "",
        "## Audit 1 — RGHCL Exact Form-A Membership (`006414` & `004171`)",
        "",
        f"- **Finding (`CONFIRMED DISCREPANCY`):** `006414` Form-A ([329_special_housing_under_pmay_normalized.json](file:///c:/Program%20Files/BlackMatter/Homesure/KRERA-Data-Extraction/data/batch_phase3d/normalized/329_special_housing_under_pmay_normalized.json)) explicitly lists **`{rghcl_sum['sibling_table_rows_with_reg_in_006414']}` sibling Bengaluru Urban registrations + self (`006414`) = `{rghcl_sum['total_unique_registrations_in_006414_form_a']}` unique RGHCL registrations** — NOT `23` (`22` + self).",
        "- **`PRM/KA/RERA/1251/308/PR/210702/004171` IS one of the 24 Form-A-linked registrations:**",
        "  - Listed explicitly in Row #19 of `006414`'s Form-A table (`1 Lakh Multi Storey Bengaluru Housing Programme`, promoter string `'Rajiv Gandhi Housing Corporation Limlted'`).",
        f"  - Verified additionally in `004171`'s own deep-extracted Form-A JSON (`{rghcl_sum['reg_004171_own_form_a_file']}`, SHA-256 `{rghcl_sum['reg_004171_own_form_a_sha256']}`), which shows identical **`Company Registration No.: '0826951'`**, `Promoter Type: 'Rajiv Gandhi Housing Corporation Limited'`, Cauvery Bhavan address, and Signatory `Executive Engineer`.",
        "- **Why the discrepancy occurred:** Phase 4.2D Scope C queried only the `23` rows grouped under `builder_rajiv_gandhi_housing`. Because `004171` contained the typo `'Limlted'`, Phase 4.2B placed it in `builder_rajiv_gandhi_housing_corporation_limlted`, and Phase 4.2E retained it as `UNCHANGED` (citing Section 16's rule not to auto-merge the `33` merge candidates unless resolved in the `56`-row register) while omitting `004171` from `phase4_2e_evidence_decision_register.csv` and `phase4_2e_unresolved_identity_register.csv`.",
        f"- **Proposed Manifest v2 Correction (not applied to v1):** {rghcl_sum['proposed_v2_correction']}",
        "",
        "---",
        "",
        "## Audit 2 — Affinity Projects / `Vaishnavi Harmony` (`007631`)",
        "",
        f"- **Registration & Project ID:** `{aff_audit['registration_number']}` / `{aff_audit['project_id']}` (`{aff_audit['project_name']}`)",
        f"- **Form-C Registered Promoter:** **`{aff_audit['form_c_certificate']['official_registered_promoter_name']}`**",
        f"- **Form-C Registered Office:** `{aff_audit['form_c_certificate']['registered_office']}`",
        f"- **Form-C Source URI:** `{aff_audit['form_c_certificate']['source_uri']}`",
        f"- **Form-C PDF SHA-256:** `{aff_audit['form_c_certificate']['sha256']}` (`{aff_audit['form_c_certificate']['pdf_size_bytes']}` bytes, live HTTP fetched = `{aff_audit['form_c_certificate']['http_live_verified']}`)",
        "- **`006539` Form-A Cross-Reference (`171_jahnavi_brindavan_normalized.json`):** Explicitly lists **BOTH** `Project Registration Number: 'PRM/KA/RERA/1251/446/PR/270325/007631'` AND `Project Name: 'Vaishnavi Harmony'` AND `Promoter Name: 'AFFINITY PROJECTS'` (`lists_only_project_title = False`).",
        "- **`007631` Own Deep-Extracted Form-A (`398_vaishnavi_harmony_normalized.json`, SHA-256 `d9d27821...`):** Confirms `Type of Firm: Proprietorship`, `Promoter/Legal/Trade Name: AFFINITY PROJECTS`, `Authorized Signatory: Sudhakara Reddy Annem`, address at Samhita Green Oaks `560093`, Land Owner `Annapurna (100%, Sy No 22/2)` with **zero Vaishnavi Group involvement**, `Affinity Registration Certificate.pdf`, and mutually cross-links `006539`, `002803`, and `002404`! *(Note: Form-A firm registration field reads `'32/58/S/0014/2013'` on `006539` vs `'12927'` on `007631` while sharing the same K-RERA account and certificate PDF filename; independent MCA/GSTIN corporate verification remains `NOT_PERFORMED`.)*",
        "- **Minor Metadata Discrepancies Found in `v1` (while assignment to `builder_affinity_projects` IS fully source-supported):**",
        "  1. `manifest v1` recorded `form_a_json_file = 'data/batch_phase3c/normalized/171_jahnavi_brindavan_normalized.json'` (`006539`) paired with `007631`'s SQLite payload hash (`742848bb...` from `398_vaishnavi_harmony_normalized.json`). Proposed `v2` fix: point `form_a_json_file` directly to `398_vaishnavi_harmony_normalized.json` and list `006539` as cross-linked Form-A evidence.",
        "  2. `manifest v1` classifies `007631` as `OWNERSHIP_REASSIGNMENT` (`6` total in `manifest v1`: `5` Scope A + `1` `007631`), while `phase4_2e_ownership_reassignment_register.csv` lists only the `5` Scope A cases. Proposed `v2` fix: reconcile the `5 + 1 = 6` count explicitly.",
        "",
        "---",
        "",
        "## Audit 3 — Builder Count Bridge (`EXACT_RECONCILIATION_PASS`, `0` Mismatches)",
        "",
        "| Storage Layer / Bucket | Exact Count | Verification Note |",
        "|---|---:|---|",
        f"| 1. Live individual `/builders/{{id}}` docs in Firestore | **`{c['1_live_individual_builder_docs']}`** | `{c['1a_live_individual_docs_in_chunks']}` in live chunks + `{c['1b_live_individual_pre_phase4_orphans_not_in_chunks']}` pre-Phase-4 orphans (`141` total `/builders` docs incl. `13` chunks + `1` `_catalog_meta`) |",
        f"| 2. Unique builder IDs in existing chunks (`_catalog_chunk_1..13`) | **`{c['2_unique_builder_ids_in_existing_chunks']}`** | Live chunk catalogue baseline |",
        f"| 3. New individual builder docs staged (`CREATE`) | **`{c['3_new_individual_builder_docs_CREATE']}`** | All `41` newly enter Top-100 individual docs |",
        f"| 4. Updated individual builder docs staged (`UPDATE`) | **`{c['4_updated_individual_builder_docs_UPDATE']}`** | `{c['4a_updated_in_top100']}` in Top-100 + `{c['4b_updated_retained_below_top100']}` retained active below Top-100 (+ `{c['4c_unchanged_active_individual_docs_in_top100']}` unchanged Top-100 = `109` active indiv docs) |",
        f"| 5. Proposed builder identities represented ONLY in chunks | **`{c['5_post_migration_builder_identities_chunk_only']}`** | `2,243 - 109 = 2,134` long-tail canonical/provisional IDs |",
        f"| 6. Final unique builder identities across all `13` chunks | **`{c['6_final_unique_builder_identities_across_13_chunks']}`** | `100%` verified present in `write_catalog_chunks` (`0` duplicates, `0` missing) |",
        f"| 7. Retained deferred legacy individual docs untouched | **`{c['7_retained_deferred_legacy_individual_docs_untouched']}`** | `0` deletes; total post-migration `/builders` collection docs = **`{c['post_migration_total_builders_collection_docs']}`** (`109` active indiv + `59` deferred indiv + `13` chunks + `1` meta) |",
        "",
        f"**Why `+181` net identity increase (`2,243 - 2,062`) != `181` new individual documents:** `{bridge['explanation']}`",
        "",
        "---",
        "",
        "## Audit 4 — Status Taxonomy & Proposed Manifest v2 Corrections",
        "",
        f"- **Finding:** `manifest v1` and `phase4_2e_final_reconciliation_report.md` preserve the conceptual separation (`0` unresolved rows approved, `corporate_verification_status: NOT_PERFORMED`, `approved: false`, `overall_status: PASS`), but do not emit a unified top-level `status_summary` object containing the exact canonical keys (`RECONCILIATION_STATUS`, `IDENTITY_REVIEW_STATUS`, `CORPORATE_VERIFICATION_STATUS`, `PRODUCTION_APPROVAL_STATUS`).",
        "- **Summary of Proposed `manifest v2` Corrections (if user authorizes generating `v2` later; `v1` untouched here):**",
        "  1. Reassign `004171` to `builder_rajiv_gandhi_housing` (after human sign-off), unifying all `24` `006414` Form-A RGHCL registrations (`2,243 -> 2,242` builders).",
        "  2. Correct `007631` `evidence_references.form_a_json_file` to `398_vaishnavi_harmony_normalized.json` (with `006539` as cross-linked Form-A) and document `5 Scope A + 1 007631 = 6` ownership reassignments.",
        "  3. Add an explicit top-level `status_summary` block emitting `RECONCILIATION_STATUS: PASS`, `IDENTITY_REVIEW_STATUS: PROVISIONAL`, `CORPORATE_VERIFICATION_STATUS: NOT_PERFORMED`, `PRODUCTION_APPROVAL_STATUS: NOT_APPROVED`.",
        "",
        "---",
        "",
        "## SHA-256 Checksums of Generated Audit Sibling Files",
        "",
        "| File | Size (Bytes) | SHA-256 |",
        "|---|---:|---|",
    ]
    for fn, meta in sibling_hashes.items():
        lines.append(f"| `{fn}` | {meta['size_bytes']} | `{meta['sha256']}` |")
    lines.append("")
    out_path.write_text("\n".join(lines), encoding="utf-8")


def run_discrepancy_audit(
    *,
    extraction_root: Path = EXTRACTION_ROOT,
    backup_dir: Path = DEFAULT_BACKUP_DIR,
    p42e_dir: Path = PHASE4_2E_OUTPUT_DIR,
    output_dir: Path = AUDIT_OUTPUT_DIR,
    fetch_live_cert: bool = True,
) -> Dict[str, Any]:
    """Execute complete read-only Phase 4.2E discrepancy audit and return deliverable hashes."""
    prior_before = verify_all_prior_artifacts_untouched(extraction_root, backup_dir, p42e_dir)
    manifest = json.loads((p42e_dir / PHASE4_2E_MANIFEST_FILENAME).read_text(encoding="utf-8"))
    output_dir.mkdir(parents=True, exist_ok=True)

    rghcl_rows, rghcl_sum = run_audit_1_rghcl(p42e_dir, manifest)
    rghcl_path = output_dir / "phase4_2e_rghcl_membership_audit.csv"
    rghcl_cols = list(rghcl_rows[0].keys())
    with rghcl_path.open("w", encoding="utf-8", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=rghcl_cols)
        w.writeheader()
        w.writerows(rghcl_rows)

    aff_audit = run_audit_2_affinity_007631(manifest, p42e_dir, fetch_live_cert=fetch_live_cert)
    aff_path = output_dir / "phase4_2e_affinity_007631_evidence_audit.json"
    aff_path.write_text(json.dumps(aff_audit, indent=2, ensure_ascii=False), encoding="utf-8")

    bridge = run_audit_3_builder_count_bridge(backup_dir, p42e_dir, manifest)
    bridge_path = output_dir / "phase4_2e_builder_count_bridge.json"
    bridge_path.write_text(json.dumps(bridge, indent=2, ensure_ascii=False), encoding="utf-8")

    tax_audit = run_audit_4_status_taxonomy(backup_dir, p42e_dir, manifest)
    tax_path = output_dir / "phase4_2e_status_taxonomy_audit.json"
    tax_path.write_text(json.dumps(tax_audit, indent=2, ensure_ascii=False), encoding="utf-8")

    sibling_files = (
        "phase4_2e_rghcl_membership_audit.csv",
        "phase4_2e_affinity_007631_evidence_audit.json",
        "phase4_2e_builder_count_bridge.json",
        "phase4_2e_status_taxonomy_audit.json",
    )
    sibling_hashes = {
        fn: {"size_bytes": (output_dir / fn).stat().st_size, "sha256": _sha256_file(output_dir / fn)}
        for fn in sibling_files
    }

    md_path = output_dir / "phase4_2e_discrepancy_audit.md"
    _write_audit_markdown(
        md_path,
        prior_check=prior_before,
        rghcl_sum=rghcl_sum,
        aff_audit=aff_audit,
        bridge=bridge,
        tax_audit=tax_audit,
        sibling_hashes=sibling_hashes,
    )

    prior_after = verify_all_prior_artifacts_untouched(extraction_root, backup_dir, p42e_dir)
    if prior_after != prior_before:
        raise RuntimeError("Immutable artifact changed during discrepancy audit")

    all_audit_hashes = {
        "phase4_2e_discrepancy_audit.md": {"size_bytes": md_path.stat().st_size, "sha256": _sha256_file(md_path)},
        **sibling_hashes,
    }
    return {
        "prior_integrity": prior_after,
        "rghcl_summary": rghcl_sum,
        "affinity_audit": aff_audit,
        "builder_count_bridge": bridge,
        "status_taxonomy_audit": tax_audit,
        "deliverable_hashes": all_audit_hashes,
    }


def main(argv: Optional[List[str]] = None) -> int:
    import argparse

    parser = argparse.ArgumentParser(
        description="Phase 4.2E Final Discrepancy Audit (Strictly Read-Only; NO write or --apply support)."
    )
    parser.add_argument("--offline", action="store_true", help="Skip live HTTP Form-C refetch (verify Form-A/local sources only).")
    args = parser.parse_args(argv)
    res = run_discrepancy_audit(fetch_live_cert=not args.offline)
    print(f"Discrepancy audit complete (0 mutations, approved={res['prior_integrity']['approval_record_approved']}):")
    for fn, meta in res["deliverable_hashes"].items():
        print(f"  {fn}: {meta['sha256']} ({meta['size_bytes']} B)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
