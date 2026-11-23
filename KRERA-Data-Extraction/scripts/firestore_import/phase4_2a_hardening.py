#!/usr/bin/env python3
"""
HomeSure Phase 4.2A — Builder Identity Migration Hardening & Preflight Validation.

Resolves Phase 4.2 Blockers 1–4 and Sections 8–9:
- Blocker 1: Traceable SQLite/JSON source evidence auditing & K-RERA vs corporate separation.
- Blocker 2: Strict Manifest Schema v2.0.0 validation, field/path allowlists, SHA-256 tamper
  resistance, and per-document/per-field live Firestore drift detection.
- Blocker 3: Backup integrity verification, Firestore `updateMask` missing-field deletion
  rollback, and concurrent-modification conflict protection.
- Blocker 4: Repository-wide builder document consumer safety & retention of active canonical
  individual `/builders/{builderId}` documents.
- Sections 8–9: Verified commit write-result counts, semantic post-stage postconditions, and
  tamper-evident operation-level checkpoint/resume validation.
"""

from __future__ import annotations

import copy
import datetime
import hashlib
import html
import json
import re
import sqlite3
import sys
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any, Callable, Dict, Iterable, List, Optional, Set, Tuple

WORKSPACE_ROOT = Path(__file__).resolve().parents[3]
EXTRACTION_ROOT = WORKSPACE_ROOT / "KRERA-Data-Extraction"
SCRIPTS_ROOT = EXTRACTION_ROOT / "scripts"
for _p in (str(SCRIPTS_ROOT), str(Path(__file__).resolve().parent)):
    if _p not in sys.path:
        sys.path.insert(0, _p)

from import_projects import (
    FIREBASE_PROJECT_ID,
    FIRESTORE_DATABASE,
    firestore_value_to_python,
    python_to_firestore_value,
)
from name_normalization import normalize_corporate_entity_name

MANIFEST_SCHEMA_VERSION = "2.0.0"
MIGRATION_VERSION_V2 = "phase4_2a_builder_sync_v2"
MANIFEST_SCHEMA_VERSION_V2_2 = "2.2.0"
MIGRATION_VERSION_V2_2 = "phase4_2e_identity_migration_v1"
MIGRATION_VERSION_V2_2_V2 = "phase4_2e_identity_migration_v2"
MISSING_FIELD_SENTINEL = "__MISSING__"
MAX_SAFE_CHUNK_KB = 700.0
CANONICAL_TALUKS = (
    "Anekal",
    "Bengaluru East",
    "Bengaluru North",
    "Bengaluru South",
    "Yelahanka",
)

ALLOWED_PROJECT_CORE_FIELDS = (
    "builder_id",
    "canonical_builder_name",
    "normalizedBuilderName",
    "builderAliases",
    "is_featured_brand",
    "nameNormalizationConfidence",
    "needsManualReview",
)
CONDITIONAL_SEARCH_METADATA_FIELDS = (
    "search_metadata.search_tokens",
    "search_metadata.normalized_builder_name_lower",
)
ALLOWED_PROJECT_UPDATE_FIELDS = frozenset(
    ALLOWED_PROJECT_CORE_FIELDS + CONDITIONAL_SEARCH_METADATA_FIELDS
)
BUILDER_TEXT_TRIGGER_FIELDS = frozenset(
    ("canonical_builder_name", "normalizedBuilderName", "builderAliases")
)
FORBIDDEN_PROJECT_FIELDS = frozenset(
    (
        "project_id",
        "registration_number",
        "acknowledgement_number",
        "officialProjectName",
        "normalizedProjectName",
        "projectAliases",
        "project_name",
        "promoter_name",
        "officialBuilderName",
        "taluk",
        "normalizedTaluk",
        "district",
        "provenance",
        "provenance.data_tier",
        "dataTier",
        "data_tier",
        "extraction_status",
        "summary_metrics",
        "counts",
        "phi_score",
        "tab_observations_summary",
        "towers_summary",
        "inventory_configurations",
    )
)
STAGED_OP_KEYS = (
    "create_builder_docs",
    "update_builder_docs",
    "patch_projects",
    "write_catalog_chunks",
    "write_catalog_meta",
    "delete_stale_builders_docs",
)


class ManifestValidationError(ValueError):
    """Raised when migration manifest schema, hash, allowlists, or stage structure fails."""


class BackupVerificationError(RuntimeError):
    """Raised when pre-migration backup files are missing, corrupted, or mismatched."""


class LiveDriftError(RuntimeError):
    """Raised when live Firestore state diverges from expected baseline snapshot values."""


class RollbackConflictError(RuntimeError):
    """Raised when current state has unrelated concurrent changes incompatible with safe rollback."""


class CheckpointValidationError(RuntimeError):
    """Raised when a resume checkpoint belongs to a different manifest/baseline or hits conflict."""


class CommitCountMismatchError(RuntimeError):
    """Raised when Firestore commit writeResults count does not match submitted writes."""


class PostconditionFailureError(RuntimeError):
    """Raised when semantic stage postconditions fail after writes complete."""


class EvidenceValidationError(ValueError):
    """Raised when identity evidence validation fails gating requirements."""


def compute_canonical_sha256(payload: Any) -> str:
    """Compute deterministic SHA-256 over canonical UTF-8 JSON."""
    raw = json.dumps(payload, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode(
        "utf-8"
    )
    return hashlib.sha256(raw).hexdigest()


def compute_manifest_sha256(manifest: Dict[str, Any]) -> str:
    """
    Compute deterministic SHA-256 of a migration manifest:
    - Schema 2.1.0 / 2.2.0 (two-stage approval): hashes the entire immutable manifest except `manifest_sha256`.
    - Schema 2.0.0: excludes `manifest_sha256` and legacy embedded `human_approval`.
    """
    if manifest.get("manifest_schema_version") in ("2.1.0", "2.2.0"):
        clone = {k: v for k, v in manifest.items() if k != "manifest_sha256"}
    else:
        clone = {k: v for k, v in manifest.items() if k not in ("manifest_sha256", "human_approval")}
    return compute_canonical_sha256(clone)


def compute_baseline_fingerprint(backup_manifest: Dict[str, Any]) -> str:
    """Compute deterministic 64-char baseline fingerprint binding environment and backup hashes."""
    files = backup_manifest.get("files") or {}
    basis = {
        "firebase_project_id": backup_manifest.get("firebase_project_id"),
        "firestore_database": backup_manifest.get("firestore_database"),
        "builders_doc_count": backup_manifest.get("builders_doc_count"),
        "projects_count": backup_manifest.get("projects_count"),
        "builders_sha256": (files.get("builders_backup.json") or {}).get("sha256"),
        "projects_sha256": (files.get("projects_builder_fields_backup.json") or {}).get("sha256"),
    }
    return compute_canonical_sha256(basis)


def derive_snapshot_id(backup_manifest: Dict[str, Any]) -> str:
    """Derive deterministic baseline snapshot identifier from backup metadata."""
    if backup_manifest.get("snapshot_id"):
        return str(backup_manifest["snapshot_id"])
    created = str(backup_manifest.get("created_at_utc") or "")[:10] or "unknown"
    proj = str(backup_manifest.get("firebase_project_id") or "unknown")
    fp = compute_baseline_fingerprint(backup_manifest)[:12]
    return f"{proj}_{created}_{fp}"


def compute_checkpoint_sha256(checkpoint_data: Dict[str, Any]) -> str:
    """Compute integrity hash over a checkpoint document excluding checkpoint_sha256."""
    clone = {k: v for k, v in checkpoint_data.items() if k != "checkpoint_sha256"}
    return compute_canonical_sha256(clone)


def _normalize_ws(text: Optional[str]) -> str:
    return re.sub(r"\s+", " ", html.unescape(text or "")).strip().lower()


def _parse_iso_timestamp(ts: Any, label: str) -> datetime.datetime:
    if not isinstance(ts, str) or not ts.strip():
        raise ManifestValidationError(f"Missing or empty {label} timestamp")
    try:
        return datetime.datetime.fromisoformat(ts.strip().replace("Z", "+00:00"))
    except ValueError as exc:
        raise ManifestValidationError(f"Invalid ISO-8601 {label} timestamp: {ts!r}") from exc


def extract_managed_field(doc: Dict[str, Any], field_path: str) -> Any:
    """Return exact field value or MISSING_FIELD_SENTINEL when key/nested key is absent."""
    if "." not in field_path:
        return doc[field_path] if field_path in doc else MISSING_FIELD_SENTINEL
    top, sub = field_path.split(".", 1)
    container = doc.get(top)
    if not isinstance(container, dict) or sub not in container:
        return MISSING_FIELD_SENTINEL
    return container[sub]


def set_managed_field(doc: Dict[str, Any], field_path: str, value: Any) -> None:
    """Set or delete a managed top-level or nested field in memory using sentinel semantics."""
    if "." not in field_path:
        if value == MISSING_FIELD_SENTINEL:
            doc.pop(field_path, None)
        else:
            doc[field_path] = copy.deepcopy(value)
        return
    top, sub = field_path.split(".", 1)
    if value == MISSING_FIELD_SENTINEL:
        if isinstance(doc.get(top), dict):
            doc[top].pop(sub, None)
    else:
        if not isinstance(doc.get(top), dict):
            doc[top] = {}
        doc[top][sub] = copy.deepcopy(value)


def make_hardened_patch_op(
    doc_rel_path: str,
    data: Dict[str, Any],
    update_mask_fields: List[str],
    delete_fields: Optional[List[str]] = None,
    project_id: str = FIREBASE_PROJECT_ID,
    database: str = FIRESTORE_DATABASE,
) -> Dict[str, Any]:
    """
    Create a Firestore REST Write PATCH operation supporting both value updates and
    explicit missing-field deletion (paths listed in `updateMask.fieldPaths` but
    omitted from `update.fields`).
    """
    full_name = f"projects/{project_id}/databases/{database}/documents/{doc_rel_path}"
    fields: Dict[str, Any] = {}
    top_search_meta: Dict[str, Any] = {}
    active_paths: List[str] = []
    seen_paths: Set[str] = set()

    for fpath in update_mask_fields:
        if fpath in seen_paths:
            continue
        seen_paths.add(fpath)
        if "." not in fpath:
            if fpath in data and data[fpath] != MISSING_FIELD_SENTINEL:
                fields[fpath] = python_to_firestore_value(data[fpath])
                active_paths.append(fpath)
        elif fpath.startswith("search_metadata."):
            subkey = fpath.split(".", 1)[1]
            sm = data.get("search_metadata")
            if isinstance(sm, dict) and subkey in sm and sm[subkey] != MISSING_FIELD_SENTINEL:
                top_search_meta[subkey] = sm[subkey]
                active_paths.append(fpath)

    if top_search_meta:
        fields["search_metadata"] = python_to_firestore_value(top_search_meta)

    for del_path in delete_fields or []:
        if del_path not in seen_paths:
            seen_paths.add(del_path)
            active_paths.append(del_path)

    return {
        "update": {
            "name": full_name,
            "fields": fields,
        },
        "updateMask": {"fieldPaths": active_paths},
    }


def _extract_portal_uri(links_json: Optional[str], fallback_url: Optional[str]) -> str:
    """Return real extracted portal/certificate URI if present; never fabricate one."""
    if links_json:
        try:
            links = json.loads(links_json)
            if isinstance(links, list):
                for item in links:
                    href = str((item or {}).get("href") or "").strip()
                    if href:
                        if href.startswith("/"):
                            return f"https://rera.karnataka.gov.in{href}"
                        return href
        except Exception:
            pass
    return str(fallback_url or "").strip()


# ---------------------------------------------------------------------------
# Blocker 1 — Evidence-Based Identity Validation
# ---------------------------------------------------------------------------

def load_source_evidence_index(extraction_root: Path) -> Dict[str, Dict[str, Any]]:
    """
    Build real SQLite & normalized-JSON provenance index keyed by `registration_number`.
    Never fabricates hashes, timestamps, or URIs.
    """
    data_dir = extraction_root / "data"
    index: Dict[str, Dict[str, Any]] = {}

    # 1. Phase 4 urban catalogue SQLite (`data/phase4_recovery/phase4_recovery.sqlite`)
    p4_db = data_dir / "phase4_recovery" / "phase4_recovery.sqlite"
    if p4_db.exists():
        con = sqlite3.connect(p4_db)
        con.row_factory = sqlite3.Row
        try:
            for row in con.execute(
                "SELECT record_key, registration_number, record_unique_key, page_number, row_order, extracted_at, links_json, row_dict_json FROM phase4_urban_catalogue"
            ):
                reg = str(row["registration_number"] or "").strip()
                if not reg:
                    continue
                raw_json = str(row["row_dict_json"] or "")
                rd = json.loads(raw_json) if raw_json else {}
                prom = str(rd.get("PROMOTER NAME") or rd.get("Promoter Name") or "").strip()
                row_hash = hashlib.sha256(raw_json.encode("utf-8")).hexdigest() if raw_json else ""
                index[reg] = {
                    "registration_number": reg,
                    "original_portal_promoter_name": prom,
                    "source_file": "data/phase4_recovery/phase4_recovery.sqlite#phase4_urban_catalogue",
                    "source_record_id": str(row["record_unique_key"] or row["record_key"] or ""),
                    "source_uri": _extract_portal_uri(row["links_json"], None),
                    "extraction_timestamp": str(row["extracted_at"] or "").strip(),
                    "source_record_hash": row_hash,
                    "detail_source_file": "",
                    "detail_record_id": "",
                    "detail_payload_sha256": "",
                    "detail_timestamp": "",
                }
        finally:
            con.close()

    # 2. Enrich with deep-detail checkpoints & normalized JSON files on disk
    for db_rel in ("k_rera_extraction.sqlite", "phase4_recovery/phase4_recovery.sqlite"):
        db_path = data_dir / db_rel
        if not db_path.exists():
            continue
        con = sqlite3.connect(db_path)
        con.row_factory = sqlite3.Row
        try:
            has_raw = (
                con.execute(
                    "SELECT 1 FROM sqlite_master WHERE type='table' AND name='raw_search_rows'"
                ).fetchone()
                is not None
            )
            if has_raw:
                for row in con.execute(
                    "SELECT id, record_unique_key, row_hash, source_url, extracted_at, row_dict_json FROM raw_search_rows"
                ):
                    rd = json.loads(row["row_dict_json"] or "{}")
                    reg = str(rd.get("REGISTRATION NO") or rd.get("REGISTRATION NUMBER") or "").strip()
                    if not reg:
                        continue
                    rec = index.get(reg)
                    if rec is None:
                        index[reg] = {
                            "registration_number": reg,
                            "original_portal_promoter_name": str(rd.get("PROMOTER NAME") or "").strip(),
                            "source_file": f"data/{db_rel}#raw_search_rows",
                            "source_record_id": str(row["record_unique_key"] or row["id"] or ""),
                            "source_uri": str(row["source_url"] or "").strip(),
                            "extraction_timestamp": str(row["extracted_at"] or "").strip(),
                            "source_record_hash": str(row["row_hash"] or "").strip(),
                            "detail_source_file": "",
                            "detail_record_id": "",
                            "detail_payload_sha256": "",
                            "detail_timestamp": "",
                        }
                    elif not rec["source_uri"] and row["source_url"]:
                        rec["source_uri"] = str(row["source_url"]).strip()

            has_ckpt = (
                con.execute(
                    "SELECT 1 FROM sqlite_master WHERE type='table' AND name='detail_extraction_checkpoints'"
                ).fetchone()
                is not None
            )
            if has_ckpt:
                for row in con.execute(
                    "SELECT project_key, registration_number, portal_detail_element_id, extraction_status, payload_sha256, normalized_output_path, updated_at_utc FROM detail_extraction_checkpoints WHERE extraction_status = 'successful'"
                ):
                    reg = str(row["registration_number"] or "").strip()
                    if not reg or reg not in index:
                        continue
                    norm_rel = str(row["normalized_output_path"] or "").strip()
                    norm_exists = bool(norm_rel and (extraction_root / norm_rel).exists())
                    index[reg]["detail_source_file"] = (
                        norm_rel if norm_exists else f"data/{db_rel}#detail_extraction_checkpoints"
                    )
                    index[reg]["detail_record_id"] = str(
                        row["portal_detail_element_id"] or row["project_key"] or ""
                    )
                    index[reg]["detail_payload_sha256"] = str(row["payload_sha256"] or "").strip()
                    index[reg]["detail_timestamp"] = str(row["updated_at_utc"] or "").strip()
        finally:
            con.close()

    return index


def build_evidence_audit(
    recon: Dict[str, Any],
    projects: List[Dict[str, Any]],
    source_index: Dict[str, Dict[str, Any]],
) -> Dict[str, Any]:
    """
    Produce full traceable evidence audit across all projects, separating K-RERA promoter
    identity from external corporate verification and flagging fallback-only assignments.
    """
    proj_by_id = {str(p.get("_doc_id") or p.get("project_id") or ""): p for p in projects}

    merge_cand_bids: Set[str] = set()
    for mc in recon.get("merge_candidates") or []:
        merge_cand_bids.update(mc.get("builder_ids") or [])

    jv_bids: Set[str] = set()
    for jv in recon.get("jv_brand_overlaps") or []:
        jv_bids.update(jv.get("builder_ids") or [])

    rows: List[Dict[str, Any]] = []
    source_backed_changes = 0
    brand_rule_changes = 0
    fallback_norm_changes = 0
    manual_review_required_changes = 0
    missing_or_invalid_source = 0

    for pr in recon.get("project_rows") or []:
        pid = pr["project_id"]
        reg = pr["registration_number"]
        pdoc = proj_by_id.get(pid) or {}
        src = source_index.get(reg)

        live_promoter = str(
            pdoc.get("officialBuilderName") or pdoc.get("promoter_name") or pr.get("promoter_name") or ""
        ).strip()
        corrected_bid = pr["corrected_builder_id"]
        is_featured = bool(
            (recon.get("new_groups") or {}).get(corrected_bid, [(None, {})])[0][1].get("is_featured_brand")
        )
        conf_level = pr.get("confidence_level") or ""
        needs_manual = bool(conf_level == "needs_manual_review" or conf_level == "manual_review_required")
        rel_change = pr["relationship_change"]
        is_change = rel_change != "UNCHANGED"

        if src is None:
            orig_prom = ""
            src_matches = False
            src_file = ""
            src_rec_id = ""
            src_uri = ""
            src_ts = ""
            src_hash = ""
            detail_file = ""
            detail_hash = ""
            if is_change or True:
                missing_or_invalid_source += 1
        else:
            orig_prom = src.get("original_portal_promoter_name") or ""
            src_matches = bool(orig_prom and _normalize_ws(orig_prom) == _normalize_ws(live_promoter))
            src_file = src.get("detail_source_file") or src.get("source_file") or ""
            src_rec_id = src.get("source_record_id") or ""
            src_uri = src.get("source_uri") or ""
            src_ts = src.get("detail_timestamp") or src.get("extraction_timestamp") or ""
            src_hash = src.get("detail_payload_sha256") or src.get("source_record_hash") or ""
            detail_file = src.get("detail_source_file") or ""
            detail_hash = src.get("detail_payload_sha256") or ""
            if not (src_file and src_rec_id and src_hash and src_ts and src_matches):
                missing_or_invalid_source += 1

        norm_promoter = normalize_corporate_entity_name(orig_prom or live_promoter)
        has_valid_source = bool(src and src_file and src_rec_id and src_hash and src_ts and src_matches)

        if not has_valid_source:
            mechanism = "MANUAL_REVIEW_REQUIRED"
            review_flag = "MISSING_OR_MISMATCHED_SOURCE_EVIDENCE"
            is_fallback = False
        elif is_featured:
            mechanism = "EXPLICIT_BRAND_RULE_SOURCE_BACKED"
            review_flag = "SHORT_PREFIX_ADVISORY" if needs_manual else "SOURCE_VERIFIED_BRAND_RULE"
            is_fallback = False
        else:
            mechanism = "FALLBACK_PROMOTER_NORMALIZATION"
            review_flag = "FALLBACK_SHORT_PREFIX_REVIEW" if needs_manual else "FALLBACK_NORMALIZATION_REVIEW"
            is_fallback = True

        if is_change:
            if has_valid_source:
                source_backed_changes += 1
            if mechanism == "EXPLICIT_BRAND_RULE_SOURCE_BACKED":
                brand_rule_changes += 1
            elif mechanism == "FALLBACK_PROMOTER_NORMALIZATION":
                fallback_norm_changes += 1
            else:
                manual_review_required_changes += 1

        rows.append(
            {
                "project_id": pid,
                "registration_number": reg,
                "project_name": pr["project_name"],
                "relationship_change": rel_change,
                "existing_builder_id": pr["existing_builder_id"],
                "corrected_builder_id": corrected_bid,
                "original_portal_promoter_name": orig_prom,
                "live_firestore_promoter_name": live_promoter,
                "normalized_promoter_name": norm_promoter,
                "source_promoter_matches_live": src_matches,
                "source_file": src_file,
                "source_record_id": src_rec_id,
                "source_uri": src_uri,
                "extraction_timestamp": src_ts,
                "source_record_hash": src_hash,
                "detail_source_file": detail_file,
                "detail_payload_sha256": detail_hash,
                "confidence_classification": conf_level,
                "identity_basis": "KRERA_PROMOTER_IDENTITY",
                "corporate_legal_verification_status": "UNVERIFIED_KRERA_PORTAL_ONLY",
                "assignment_mechanism": mechanism,
                "is_fallback_only": is_fallback,
                "review_flag": review_flag,
                "in_merge_candidate_pair": corrected_bid in merge_cand_bids,
                "in_jv_overlap_pair": corrected_bid in jv_bids,
                "reason": pr["evidence"],
            }
        )

    gate = validate_evidence_gate(rows)
    return {
        "rows": rows,
        "summary": {
            "total_projects": len(rows),
            "changed_projects": source_backed_changes + manual_review_required_changes,
            "source_backed_changes": source_backed_changes,
            "brand_rule_changes": brand_rule_changes,
            "fallback_normalization_changes": fallback_norm_changes,
            "manual_review_required_changes": manual_review_required_changes,
            "missing_or_invalid_source": missing_or_invalid_source,
            "merge_candidates_retained": len(recon.get("merge_candidates") or []),
            "jv_overlaps_retained": len(recon.get("jv_brand_overlaps") or []),
        },
        "gate": gate,
    }


def validate_evidence_gate(evidence_rows: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Strictly verify that every identity change/split/rename carries real structured source
    provenance (not descriptive prose alone) and never misrepresents K-RERA identity as MCA/GSTIN.
    """
    failures: List[Dict[str, str]] = []
    required_structured_fields = (
        "registration_number",
        "original_portal_promoter_name",
        "normalized_promoter_name",
        "source_file",
        "source_record_id",
        "source_record_hash",
        "extraction_timestamp",
    )

    for r in evidence_rows:
        if r.get("relationship_change") == "UNCHANGED":
            continue
        pid = str(r.get("project_id") or "")
        # Check against false corporate verification claims
        basis = str(r.get("identity_basis") or "")
        corp_status = str(r.get("corporate_legal_verification_status") or "")
        if basis != "KRERA_PROMOTER_IDENTITY" or corp_status == "VERIFIED_MCA_CORPORATE":
            failures.append(
                {
                    "project_id": pid,
                    "reason": "Corporate legal verification claimed without external MCA/GSTIN proof.",
                }
            )
            continue

        # Descriptive prose alone MUST NOT pass when structured source evidence is missing
        missing = [f for f in required_structured_fields if not str(r.get(f) or "").strip()]
        if missing or not r.get("source_promoter_matches_live"):
            failures.append(
                {
                    "project_id": pid,
                    "reason": (
                        f"Missing/unmatched structured source evidence ({', '.join(missing) or 'promoter_mismatch'}); "
                        "generated descriptive reason alone cannot satisfy approval gate."
                    ),
                }
            )
        elif r.get("assignment_mechanism") == "MANUAL_REVIEW_REQUIRED":
            failures.append(
                {
                    "project_id": pid,
                    "reason": "Record flagged MANUAL_REVIEW_REQUIRED.",
                }
            )

    return {
        "status": "PASS" if not failures else "BLOCKED",
        "failure_count": len(failures),
        "failures": failures[:50],
    }


# ---------------------------------------------------------------------------
# Blocker 2 — Manifest Schema Validation & Live Drift Protection
# ---------------------------------------------------------------------------

def _parse_doc_path(full_name: Any, expected_project_id: str, expected_database: str) -> Tuple[str, str]:
    if not isinstance(full_name, str) or not full_name:
        raise ManifestValidationError(f"Empty or invalid document name: {full_name!r}")
    prefix = f"projects/{expected_project_id}/databases/{expected_database}/documents/"
    if not full_name.startswith(prefix):
        raise ManifestValidationError(
            f"Document path {full_name!r} does not match expected project/database prefix {prefix!r}"
        )
    rel = full_name[len(prefix) :]
    parts = rel.split("/")
    if len(parts) != 2 or not parts[0] or not parts[1]:
        raise ManifestValidationError(
            f"Unexpected collection/subcollection depth in path {rel!r}; only top-level /builders/{{id}} or /projects/{{id}} permitted"
        )
    col, doc_id = parts
    if col not in ("builders", "projects"):
        raise ManifestValidationError(f"Unexpected Firestore collection {col!r} in {rel!r}")
    return col, doc_id


def validate_migration_manifest(
    manifest: Any,
    expected_project_id: str = FIREBASE_PROJECT_ID,
    expected_database: str = FIRESTORE_DATABASE,
    allow_deletions: bool = False,
) -> Dict[str, Any]:
    """
    Strictly validate a Phase 4.2A v2.0.0 migration manifest before any write executes.
    Raises ManifestValidationError on any schema, hash, allowlist, count, or path violation.
    """
    if not isinstance(manifest, dict):
        raise ManifestValidationError("Manifest must be a JSON object")

    required_top = [
        "manifest_schema_version",
        "migration_version",
        "firebase_project_id",
        "firestore_database",
        "generated_at_utc",
        "hardening_mode",
        "deletions_enabled",
        "baseline_snapshot_id",
        "baseline_fingerprint",
        "backup_references",
        "expected_old_values",
        "staged_ops",
        "op_counts",
        "approval_gate_results",
        "manifest_sha256",
    ]
    schema_ver = manifest.get("manifest_schema_version")
    if schema_ver == "2.0.0":
        required_top.append("human_approval")
    elif schema_ver == "2.1.0":
        required_top.append("approval_model")
    elif schema_ver == "2.2.0":
        required_top.extend(
            [
                "approval_model",
                "metadata",
                "predecessor_manifest",
                "identity_policies",
                "review_status_taxonomy",
                "project_mappings",
                "builder_operations",
            ]
        )

    missing_top = [k for k in required_top if k not in manifest]
    if missing_top:
        raise ManifestValidationError(f"Missing required manifest fields: {missing_top}")

    if schema_ver == "2.0.0":
        if manifest["migration_version"] != MIGRATION_VERSION_V2:
            raise ManifestValidationError(
                f"Unsupported migration_version {manifest['migration_version']!r}; expected {MIGRATION_VERSION_V2!r}"
            )
    elif schema_ver == "2.1.0":
        if manifest["migration_version"] != "phase4_2b_builder_sync_v2_1":
            raise ManifestValidationError(
                f"Unsupported migration_version {manifest['migration_version']!r} for 2.1.0; expected 'phase4_2b_builder_sync_v2_1'"
            )
        if manifest.get("approval_model") != "two_stage_external_record":
            raise ManifestValidationError(
                f"Invalid approval_model {manifest.get('approval_model')!r}; expected 'two_stage_external_record'"
            )
        if "human_approval" in manifest:
            raise ManifestValidationError(
                "Schema 2.1.0 forbids embedded 'human_approval'; authorization must live in separate Stage 2 record"
            )
    elif schema_ver == "2.2.0":
        if manifest["migration_version"] not in (MIGRATION_VERSION_V2_2, MIGRATION_VERSION_V2_2_V2):
            raise ManifestValidationError(
                f"Unsupported migration_version {manifest['migration_version']!r} for 2.2.0; expected {MIGRATION_VERSION_V2_2!r} or {MIGRATION_VERSION_V2_2_V2!r}"
            )
        if manifest["migration_version"] == MIGRATION_VERSION_V2_2_V2:
            ss = manifest.get("status_summary")
            req_ss = (
                "RECONCILIATION_STATUS",
                "SOURCE_EVIDENCE_STATUS",
                "IDENTITY_REVIEW_STATUS",
                "CORPORATE_VERIFICATION_STATUS",
                "PRODUCTION_APPROVAL_STATUS",
            )
            if not isinstance(ss, dict) or any(k not in ss for k in req_ss):
                raise ManifestValidationError(
                    f"Manifest v2 missing required status_summary keys {list(req_ss)}"
                )
        if manifest.get("approval_model") != "two_stage_external_record":
            raise ManifestValidationError(
                f"Invalid approval_model {manifest.get('approval_model')!r}; expected 'two_stage_external_record'"
            )
        if "human_approval" in manifest:
            raise ManifestValidationError(
                "Schema 2.2.0 forbids embedded 'human_approval'; authorization must live in separate Stage 2 record"
            )
    else:
        raise ManifestValidationError(
            f"Unsupported manifest_schema_version {schema_ver!r}; expected {MANIFEST_SCHEMA_VERSION!r}, '2.1.0', or '2.2.0'"
        )
    if manifest["firebase_project_id"] != expected_project_id:
        raise ManifestValidationError(
            f"Wrong firebase_project_id {manifest['firebase_project_id']!r}; expected {expected_project_id!r}"
        )
    if manifest["firestore_database"] != expected_database:
        raise ManifestValidationError(
            f"Wrong firestore_database {manifest['firestore_database']!r}; expected {expected_database!r}"
        )

    _parse_iso_timestamp(manifest["generated_at_utc"], "generated_at_utc")

    if not re.fullmatch(r"[0-9a-f]{64}", str(manifest.get("baseline_fingerprint") or "")):
        raise ManifestValidationError("Invalid baseline_fingerprint (must be 64 lowercase hex chars)")
    if not str(manifest.get("baseline_snapshot_id") or "").strip():
        raise ManifestValidationError("Empty baseline_snapshot_id")

    # Backup reference validation
    brefs = manifest.get("backup_references")
    if not isinstance(brefs, dict) or not brefs.get("backup_dir"):
        raise ManifestValidationError("Missing backup_references.backup_dir")
    for fname in ("builders_backup.json", "projects_builder_fields_backup.json"):
        entry = brefs.get(fname)
        if not isinstance(entry, dict) or not entry.get("sha256") or not isinstance(entry.get("count"), int):
            raise ManifestValidationError(f"Invalid backup_references entry for {fname}")

    # Approval gate structure validation
    gates = manifest.get("approval_gate_results")
    if not isinstance(gates, dict) or not gates:
        raise ManifestValidationError("Missing approval_gate_results")
    if schema_ver == "2.0.0":
        approval = manifest.get("human_approval")
        if not isinstance(approval, dict) or not isinstance(approval.get("approved"), bool):
            raise ManifestValidationError("Invalid human_approval metadata")

    # Manifest integrity hash check
    expected_sha = compute_manifest_sha256(manifest)
    if manifest.get("manifest_sha256") != expected_sha:
        raise ManifestValidationError(
            f"Manifest SHA-256 mismatch (tampered or stale manifest): recorded={manifest.get('manifest_sha256')!r}, computed={expected_sha!r}"
        )

    staged = manifest.get("staged_ops")
    if not isinstance(staged, dict) or set(staged.keys()) != set(STAGED_OP_KEYS):
        raise ManifestValidationError(
            f"Invalid staged_ops stages; expected exact keys {list(STAGED_OP_KEYS)}"
        )

    op_counts = manifest.get("op_counts")
    if not isinstance(op_counts, dict):
        raise ManifestValidationError("Missing op_counts dict")

    stage_to_count_key = {
        "create_builder_docs": "create_builder_docs",
        "update_builder_docs": "update_builder_docs",
        "patch_projects": "patch_projects",
        "write_catalog_chunks": "write_catalog_chunks",
        "write_catalog_meta": "write_catalog_meta",
    }
    computed_total = 0
    for st_key, cnt_key in stage_to_count_key.items():
        ops = staged[st_key]
        if not isinstance(ops, list):
            raise ManifestValidationError(f"Stage {st_key!r} must be a list")
        if op_counts.get(cnt_key) != len(ops):
            raise ManifestValidationError(
                f"Operation count mismatch for {st_key}: op_counts[{cnt_key!r}]={op_counts.get(cnt_key)} vs actual={len(ops)}"
            )
        computed_total += len(ops)

    del_ops = staged["delete_stale_builders_docs"]
    if not isinstance(del_ops, list):
        raise ManifestValidationError("Stage 'delete_stale_builders_docs' must be a list")
    del_declared = int(op_counts.get("delete_stale_chunks", 0)) + int(
        op_counts.get("delete_stale_individual_builder_docs", 0)
    )
    if del_declared != len(del_ops):
        raise ManifestValidationError(
            f"Deletion count mismatch: declared={del_declared} vs actual={len(del_ops)}"
        )
    computed_total += len(del_ops)

    if op_counts.get("total_writes") != computed_total:
        raise ManifestValidationError(
            f"total_writes mismatch: op_counts['total_writes']={op_counts.get('total_writes')} vs actual={computed_total}"
        )

    if (not allow_deletions or manifest.get("hardening_mode") or not manifest.get("deletions_enabled")) and del_ops:
        raise ManifestValidationError(
            f"Deletions are disabled in Phase 4.2A hardening mode, but {len(del_ops)} delete ops were staged"
        )

    # Validate every individual operation, path, updateMask, allowlists & duplicate conflicts
    seen_project_ids: Set[str] = set()
    seen_builder_ids: Set[str] = set()

    for stage_name, ops in staged.items():
        for op in ops:
            if not isinstance(op, dict):
                raise ManifestValidationError(f"Non-dict operation in {stage_name}")
            op_keys = set(op.keys())
            if "delete" in op:
                if op_keys != {"delete"} or stage_name != "delete_stale_builders_docs":
                    raise ManifestValidationError(
                        f"Delete op in unexpected stage {stage_name!r} or malformed keys {sorted(op_keys)}"
                    )
                if not allow_deletions or manifest.get("hardening_mode") or not manifest.get("deletions_enabled"):
                    raise ManifestValidationError("Delete operation forbidden while deletions are disabled")
                col, doc_id = _parse_doc_path(op["delete"], expected_project_id, expected_database)
                if col != "builders":
                    raise ManifestValidationError("Deleting documents outside /builders is strictly forbidden")
                if doc_id in seen_builder_ids:
                    raise ManifestValidationError(f"Duplicate/conflicting builder operation on builders/{doc_id}")
                seen_builder_ids.add(doc_id)
                continue

            if "update" not in op or not op_keys.issubset({"update", "updateMask"}):
                raise ManifestValidationError(
                    f"Unknown/unsupported Firestore write operation keys in {stage_name}: {sorted(op_keys)}"
                )
            upd = op["update"]
            if not isinstance(upd, dict) or not isinstance(upd.get("fields"), dict):
                raise ManifestValidationError(f"Malformed update payload in {stage_name}")
            col, doc_id = _parse_doc_path(upd.get("name"), expected_project_id, expected_database)

            if stage_name == "patch_projects":
                if col != "projects":
                    raise ManifestValidationError(
                        f"Stage 'patch_projects' may only target /projects, got /{col}/{doc_id}"
                    )
                if doc_id in seen_project_ids:
                    raise ManifestValidationError(f"Duplicate/conflicting operation on projects/{doc_id}")
                seen_project_ids.add(doc_id)

                mask_obj = op.get("updateMask")
                if not isinstance(mask_obj, dict) or not isinstance(mask_obj.get("fieldPaths"), list) or not mask_obj["fieldPaths"]:
                    raise ManifestValidationError(
                        f"Project patch projects/{doc_id} MUST specify non-empty updateMask.fieldPaths"
                    )
                field_paths = mask_obj["fieldPaths"]
                if len(set(field_paths)) != len(field_paths):
                    raise ManifestValidationError(f"Duplicate fieldPaths in projects/{doc_id} updateMask")

                field_set = set(field_paths)
                disallowed = field_set - ALLOWED_PROJECT_UPDATE_FIELDS
                if disallowed:
                    raise ManifestValidationError(
                        f"Forbidden field update(s) in projects/{doc_id}: {sorted(disallowed)}"
                    )
                decoded = firestore_value_to_python({"mapValue": {"fields": upd["fields"]}})
                for top_k, top_v in decoded.items():
                    if top_k in FORBIDDEN_PROJECT_FIELDS:
                        raise ManifestValidationError(f"Forbidden field in update payload for projects/{doc_id}: {top_k}")
                    if top_k == "search_metadata":
                        if not isinstance(top_v, dict):
                            raise ManifestValidationError(f"Malformed search_metadata in projects/{doc_id}")
                        for sk in top_v.keys():
                            full_sub = f"search_metadata.{sk}"
                            if full_sub not in field_set:
                                raise ManifestValidationError(
                                    f"Unmasked nested field {full_sub!r} in projects/{doc_id}"
                                )
                    elif top_k not in field_set:
                        raise ManifestValidationError(
                            f"Unmasked top-level field {top_k!r} in projects/{doc_id}"
                        )

                if field_set & set(CONDITIONAL_SEARCH_METADATA_FIELDS):
                    if not (field_set & BUILDER_TEXT_TRIGGER_FIELDS):
                        raise ManifestValidationError(
                            f"Conditional search_metadata update in projects/{doc_id} without builder text/alias change"
                        )
            else:
                if col != "builders":
                    raise ManifestValidationError(
                        f"Stage {stage_name!r} may only target /builders, got /{col}/{doc_id}"
                    )
                if stage_name == "write_catalog_chunks" and not doc_id.startswith("_catalog_chunk_"):
                    raise ManifestValidationError(f"Non-chunk doc {doc_id!r} inside write_catalog_chunks")
                if stage_name == "write_catalog_meta" and doc_id != "_catalog_meta":
                    raise ManifestValidationError(f"Non-meta doc {doc_id!r} inside write_catalog_meta")
                if stage_name in ("create_builder_docs", "update_builder_docs") and doc_id.startswith("_catalog_"):
                    raise ManifestValidationError(f"Catalog system doc {doc_id!r} in {stage_name}")
                if doc_id in seen_builder_ids:
                    raise ManifestValidationError(f"Duplicate/conflicting builder operation on builders/{doc_id}")
                seen_builder_ids.add(doc_id)

    return {
        "status": "VALID",
        "manifest_schema_version": manifest["manifest_schema_version"],
        "migration_version": manifest["migration_version"],
        "manifest_sha256": expected_sha,
        "total_writes_validated": computed_total,
        "deletions_enabled": bool(manifest["deletions_enabled"] and allow_deletions),
    }


def detect_live_drift(
    manifest: Dict[str, Any],
    live_projects: List[Dict[str, Any]],
    live_builders_docs: Dict[str, Dict[str, Any]],
    live_backup_fingerprint: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Compare live Firestore state (read-only) against `manifest['expected_old_values']`
    and `baseline_fingerprint`. Zero writes executed.
    """
    drift_items: List[Dict[str, Any]] = []

    if live_backup_fingerprint and live_backup_fingerprint != manifest.get("baseline_fingerprint"):
        drift_items.append(
            {
                "document_path": "_manifest/baseline_fingerprint",
                "field_path": "baseline_fingerprint",
                "expected_old_value": manifest.get("baseline_fingerprint"),
                "actual_current_value": live_backup_fingerprint,
                "severity": "CRITICAL",
                "recommended_action": "Regenerate Phase 4.2A backup & manifest from current baseline before proceeding.",
            }
        )

    expected_old = manifest.get("expected_old_values") or {}
    exp_projects = expected_old.get("projects") or {}
    exp_builders = expected_old.get("builders") or {}

    live_proj_map = {str(p.get("_doc_id") or p.get("project_id") or ""): p for p in live_projects}

    for pid, exp_fields in sorted(exp_projects.items()):
        live_p = live_proj_map.get(pid)
        if live_p is None:
            drift_items.append(
                {
                    "document_path": f"projects/{pid}",
                    "field_path": "*",
                    "expected_old_value": "EXISTS",
                    "actual_current_value": MISSING_FIELD_SENTINEL,
                    "severity": "CRITICAL",
                    "recommended_action": "Stop migration; investigate missing production project document.",
                }
            )
            continue
        for fpath, exp_val in exp_fields.items():
            cur_val = extract_managed_field(live_p, fpath)
            if cur_val != exp_val:
                drift_items.append(
                    {
                        "document_path": f"projects/{pid}",
                        "field_path": fpath,
                        "expected_old_value": exp_val,
                        "actual_current_value": cur_val,
                        "severity": "HIGH",
                        "recommended_action": "Re-reconcile & regenerate manifest before applying updates.",
                    }
                )

    for bid, exp_meta in sorted(exp_builders.items()):
        cur_b = live_builders_docs.get(bid)
        exp_exists = bool(exp_meta.get("exists"))
        if not exp_exists and cur_b is not None:
            drift_items.append(
                {
                    "document_path": f"builders/{bid}",
                    "field_path": "*",
                    "expected_old_value": MISSING_FIELD_SENTINEL,
                    "actual_current_value": "EXISTS",
                    "severity": "HIGH",
                    "recommended_action": "Builder doc was created since snapshot; re-plan before overwriting.",
                }
            )
        elif exp_exists and cur_b is None:
            drift_items.append(
                {
                    "document_path": f"builders/{bid}",
                    "field_path": "*",
                    "expected_old_value": exp_meta.get("doc_sha256"),
                    "actual_current_value": MISSING_FIELD_SENTINEL,
                    "severity": "CRITICAL",
                    "recommended_action": "Expected builder doc missing in Firestore; halt and refresh backup.",
                }
            )
        elif exp_exists and cur_b is not None:
            clean = {k: v for k, v in cur_b.items() if k != "_doc_id"}
            cur_sha = compute_canonical_sha256(clean)
            if cur_sha != exp_meta.get("doc_sha256"):
                drift_items.append(
                    {
                        "document_path": f"builders/{bid}",
                        "field_path": "document_sha256",
                        "expected_old_value": exp_meta.get("doc_sha256"),
                        "actual_current_value": cur_sha,
                        "severity": "HIGH",
                        "recommended_action": "Builder doc mutated since snapshot; re-run Stage 1–4 reconciliation.",
                    }
                )

    return {
        "status": "CLEAN" if not drift_items else "DRIFT_DETECTED",
        "checked_projects": len(exp_projects),
        "checked_builders": len(exp_builders),
        "drift_count": len(drift_items),
        "drift_items": drift_items,
    }


# ---------------------------------------------------------------------------
# Blocker 3 — Backup Verification & Exact Missing-Field Rollback
# ---------------------------------------------------------------------------

def verify_backup_bundle(
    backup_dir: Path,
    expected_project_id: str = FIREBASE_PROJECT_ID,
    expected_database: str = FIRESTORE_DATABASE,
    expected_checksums: Optional[Dict[str, str]] = None,
    expected_counts: Optional[Dict[str, int]] = None,
) -> Dict[str, Any]:
    """Verify backup directory, JSON parseability, exact record counts, environment, and SHA-256."""
    if not backup_dir.exists() or not backup_dir.is_dir():
        raise BackupVerificationError(f"Backup directory does not exist: {backup_dir}")

    required_files = ("backup_manifest.json", "builders_backup.json", "projects_builder_fields_backup.json")
    for fn in required_files:
        fp = backup_dir / fn
        if not fp.exists() or not fp.is_file():
            raise BackupVerificationError(f"Missing required backup artifact: {fp}")

    try:
        bm = json.loads((backup_dir / "backup_manifest.json").read_text(encoding="utf-8"))
    except Exception as exc:
        raise BackupVerificationError(f"Corrupt backup_manifest.json: {exc}") from exc

    for key in ("created_at_utc", "firebase_project_id", "firestore_database", "builders_doc_count", "projects_count", "files"):
        if key not in bm:
            raise BackupVerificationError(f"Missing field {key!r} in backup_manifest.json")

    if bm["firebase_project_id"] != expected_project_id:
        raise BackupVerificationError(
            f"Backup project mismatch: {bm['firebase_project_id']!r} != {expected_project_id!r}"
        )
    if bm["firestore_database"] != expected_database:
        raise BackupVerificationError(
            f"Backup database mismatch: {bm['firestore_database']!r} != {expected_database!r}"
        )

    try:
        _parse_iso_timestamp(bm["created_at_utc"], "backup_manifest.created_at_utc")
    except ManifestValidationError as exc:
        raise BackupVerificationError(str(exc)) from exc

    verified_files: Dict[str, Dict[str, Any]] = {}
    parsed_data: Dict[str, Any] = {}
    for fn, count_key in (
        ("builders_backup.json", "builders_doc_count"),
        ("projects_builder_fields_backup.json", "projects_count"),
    ):
        raw = (backup_dir / fn).read_bytes()
        actual_sha = hashlib.sha256(raw).hexdigest()
        declared_meta = (bm.get("files") or {}).get(fn) or {}
        declared_sha = declared_meta.get("sha256")
        if actual_sha != declared_sha:
            raise BackupVerificationError(
                f"SHA-256 mismatch for {fn}: actual={actual_sha!r}, backup_manifest={declared_sha!r}"
            )
        if expected_checksums and fn in expected_checksums and actual_sha != expected_checksums[fn]:
            raise BackupVerificationError(
                f"Reference SHA-256 mismatch for {fn}: actual={actual_sha!r}, expected={expected_checksums[fn]!r}"
            )
        data = json.loads(raw.decode("utf-8"))
        actual_cnt = len(data)
        if actual_cnt != bm.get(count_key):
            raise BackupVerificationError(
                f"Record count mismatch in {fn}: actual={actual_cnt}, backup_manifest={bm.get(count_key)}"
            )
        if expected_counts and fn in expected_counts and actual_cnt != expected_counts[fn]:
            raise BackupVerificationError(
                f"Reference record count mismatch in {fn}: actual={actual_cnt}, expected={expected_counts[fn]}"
            )
        verified_files[fn] = {
            "count": actual_cnt,
            "size_bytes": len(raw),
            "sha256": actual_sha,
        }
        parsed_data[fn] = data

    return {
        "status": "VERIFIED",
        "snapshot_id": derive_snapshot_id(bm),
        "baseline_fingerprint": compute_baseline_fingerprint(bm),
        "created_at_utc": bm["created_at_utc"],
        "firebase_project_id": bm["firebase_project_id"],
        "firestore_database": bm["firestore_database"],
        "files": verified_files,
        "backup_manifest": bm,
    }


def _compute_expected_post_migration_projects(
    orig_projects: Dict[str, Dict[str, Any]],
    migration_manifest: Dict[str, Any],
) -> Dict[str, Dict[str, Any]]:
    """Derive exact post-migration expected state of managed project fields from manifest."""
    post: Dict[str, Dict[str, Any]] = {}
    for pid, orig_doc in orig_projects.items():
        post[pid] = {fp: extract_managed_field(orig_doc, fp) for fp in ALLOWED_PROJECT_UPDATE_FIELDS}

    for op in (migration_manifest.get("staged_ops") or {}).get("patch_projects") or []:
        _, pid = _parse_doc_path(
            op["update"]["name"],
            migration_manifest["firebase_project_id"],
            migration_manifest["firestore_database"],
        )
        decoded = firestore_value_to_python({"mapValue": {"fields": op["update"].get("fields", {})}})
        mask_paths = (op.get("updateMask") or {}).get("fieldPaths") or []
        state = post.setdefault(pid, {fp: MISSING_FIELD_SENTINEL for fp in ALLOWED_PROJECT_UPDATE_FIELDS})
        for fp in mask_paths:
            state[fp] = extract_managed_field(decoded, fp)
    return post


def _compute_expected_post_migration_builders(
    orig_builders: Dict[str, Dict[str, Any]],
    migration_manifest: Dict[str, Any],
) -> Tuple[Dict[str, Optional[Dict[str, Any]]], Set[str]]:
    """Return expected post-migration `/builders` map (None = deleted) and created IDs."""
    post: Dict[str, Optional[Dict[str, Any]]] = {k: copy.deepcopy(v) for k, v in orig_builders.items()}
    created_ids: Set[str] = set()
    staged = migration_manifest.get("staged_ops") or {}

    for st_key in ("create_builder_docs", "update_builder_docs", "write_catalog_chunks", "write_catalog_meta"):
        for op in staged.get(st_key) or []:
            _, bid = _parse_doc_path(
                op["update"]["name"],
                migration_manifest["firebase_project_id"],
                migration_manifest["firestore_database"],
            )
            decoded = firestore_value_to_python({"mapValue": {"fields": op["update"].get("fields", {})}})
            if bid not in orig_builders:
                created_ids.add(bid)
            post[bid] = decoded

    for op in staged.get("delete_stale_builders_docs") or []:
        _, bid = _parse_doc_path(
            op["delete"],
            migration_manifest["firebase_project_id"],
            migration_manifest["firestore_database"],
        )
        post[bid] = None

    return post, created_ids


def build_safe_rollback_operations(
    backup_dir: Path,
    migration_manifest: Dict[str, Any],
    current_builders_docs: Dict[str, Dict[str, Any]],
    current_projects: List[Dict[str, Any]],
    expected_project_id: str = FIREBASE_PROJECT_ID,
    expected_database: str = FIRESTORE_DATABASE,
) -> Dict[str, Any]:
    """
    Build deterministic, conflict-checked Firestore rollback operations:
    - Verifies backup hashes & counts first.
    - Deletes fields absent from backup via Firestore `updateMask.fieldPaths` omission.
    - Refuses to overwrite concurrent unrelated edits (`RollbackConflictError`).
    - Deletes ONLY migration-created `/builders` docs, preserving unrelated post-snapshot docs.
    """
    from import_projects import make_firestore_delete_op, make_firestore_write_op

    validate_migration_manifest(
        migration_manifest,
        expected_project_id=expected_project_id,
        expected_database=expected_database,
        allow_deletions=bool(migration_manifest.get("deletions_enabled") and not migration_manifest.get("hardening_mode")),
    )
    verify_backup_bundle(backup_dir, expected_project_id=expected_project_id, expected_database=expected_database)

    orig_builders = json.loads((backup_dir / "builders_backup.json").read_text(encoding="utf-8"))
    orig_projects = json.loads(
        (backup_dir / "projects_builder_fields_backup.json").read_text(encoding="utf-8")
    )

    exp_post_projects = _compute_expected_post_migration_projects(orig_projects, migration_manifest)
    exp_post_builders, created_builder_ids = _compute_expected_post_migration_builders(
        orig_builders, migration_manifest
    )

    conflicts: List[Dict[str, Any]] = []
    ops: List[Dict[str, Any]] = []
    deleted_fields_summary: Dict[str, List[str]] = {}
    preserved_post_snapshot_docs: List[str] = []

    cur_proj_map = {str(p.get("_doc_id") or p.get("project_id") or ""): p for p in current_projects}

    # Check only projects actually targeted by migration patches (and backup projects)
    patched_pids = {
        _parse_doc_path(op["update"]["name"], expected_project_id, expected_database)[1]
        for op in (migration_manifest["staged_ops"].get("patch_projects") or [])
    }

    for pid in sorted(patched_pids):
        orig_doc = orig_projects.get(pid)
        cur_doc = cur_proj_map.get(pid)
        if orig_doc is None or cur_doc is None:
            conflicts.append(
                {
                    "document_path": f"projects/{pid}",
                    "field_path": "*",
                    "reason": "Missing original or current project document during rollback",
                }
            )
            continue

        restore_paths: List[str] = []
        delete_paths: List[str] = []
        post_state = exp_post_projects.get(pid, {})

        for fp in sorted(ALLOWED_PROJECT_UPDATE_FIELDS):
            orig_val = extract_managed_field(orig_doc, fp)
            cur_val = extract_managed_field(cur_doc, fp)
            exp_post_val = post_state.get(fp, orig_val)

            if cur_val != orig_val and cur_val != exp_post_val:
                conflicts.append(
                    {
                        "document_path": f"projects/{pid}",
                        "field_path": fp,
                        "expected_orig": orig_val,
                        "expected_post": exp_post_val,
                        "actual_current": cur_val,
                        "reason": "Concurrent unrelated modification detected after migration",
                    }
                )
                continue

            if cur_val == orig_val:
                continue
            if orig_val == MISSING_FIELD_SENTINEL:
                delete_paths.append(fp)
            else:
                restore_paths.append(fp)

        if restore_paths or delete_paths:
            if delete_paths:
                deleted_fields_summary[pid] = list(delete_paths)
            ops.append(
                make_hardened_patch_op(
                    f"projects/{pid}",
                    orig_doc,
                    restore_paths,
                    delete_fields=delete_paths,
                    project_id=expected_project_id,
                    database=expected_database,
                )
            )

    # Check `/builders` rollback safety
    for bid in sorted(orig_builders.keys()):
        orig_b = orig_builders[bid]
        cur_b_raw = current_builders_docs.get(bid)
        cur_clean = (
            {k: v for k, v in cur_b_raw.items() if k != "_doc_id"}
            if cur_b_raw is not None
            else None
        )
        exp_post_b = exp_post_builders.get(bid)
        if cur_clean != orig_b:
            if cur_clean != exp_post_b and bid != "_catalog_meta":
                conflicts.append(
                    {
                        "document_path": f"builders/{bid}",
                        "field_path": "*",
                        "reason": "Concurrent unrelated modification to builder document after migration",
                    }
                )
            elif bid == "_catalog_meta":
                cur_cmp = {k: v for k, v in (cur_clean or {}).items() if k != "updated_at"}
                exp_cmp = {k: v for k, v in (exp_post_b or {}).items() if k != "updated_at"}
                orig_cmp = {k: v for k, v in orig_b.items() if k != "updated_at"}
                if cur_clean is None or (cur_cmp != exp_cmp and cur_cmp != orig_cmp):
                    conflicts.append(
                        {
                            "document_path": "builders/_catalog_meta",
                            "field_path": "*",
                            "reason": "Concurrent unrelated modification to _catalog_meta",
                        }
                    )
                else:
                    ops.append(make_firestore_write_op(f"builders/{bid}", orig_b))
            else:
                ops.append(make_firestore_write_op(f"builders/{bid}", orig_b))

    for cur_bid in sorted(current_builders_docs.keys()):
        if cur_bid not in orig_builders:
            if cur_bid in created_builder_ids:
                cur_clean = {k: v for k, v in current_builders_docs[cur_bid].items() if k != "_doc_id"}
                if cur_clean != exp_post_builders.get(cur_bid):
                    conflicts.append(
                        {
                            "document_path": f"builders/{cur_bid}",
                            "field_path": "*",
                            "reason": "Migration-created builder doc was concurrently modified; refusing delete",
                        }
                    )
                else:
                    ops.append(make_firestore_delete_op(f"builders/{cur_bid}"))
            else:
                preserved_post_snapshot_docs.append(cur_bid)

    if conflicts:
        raise RollbackConflictError(
            f"Rollback aborted: {len(conflicts)} concurrent conflict(s) detected: {conflicts[:5]}"
        )

    return {
        "operations": ops,
        "deleted_fields_by_project": deleted_fields_summary,
        "preserved_unrelated_post_snapshot_docs": preserved_post_snapshot_docs,
        "deleted_migration_created_builders": sorted(
            b for b in created_builder_ids if b in current_builders_docs
        ),
    }


# ---------------------------------------------------------------------------
# Blocker 4 — Deletion Impact & Active Canonical Individual Doc Protection
# ---------------------------------------------------------------------------

def build_deletion_impact_analysis(
    existing_builders_docs: Dict[str, Dict[str, Any]],
    corrected_builders_list: List[Dict[str, Any]],
    top100_ids: Set[str],
    existing_chunk_builder_ids: Set[str],
) -> Dict[str, Any]:
    """
    Analyze all existing individual `/builders/{builderId}` documents outside the top 100.
    Guarantees that any builder ID still active in the corrected canonical map (including the 8
    identities below rank 100) is RETAINED and updated cleanly rather than deleted.
    """
    corrected_by_id = {b["builder_id"]: b for b in corrected_builders_list}
    outside_top100 = sorted(
        k
        for k in existing_builders_docs.keys()
        if not k.startswith("_catalog_") and k not in top100_ids
    )

    rows: List[Dict[str, Any]] = []
    retain_active_ids: List[str] = []
    deferred_delete_ids: List[str] = []

    for bid in outside_top100:
        old_doc = existing_builders_docs[bid]
        old_name = str(
            old_doc.get("builder_name") or old_doc.get("canonical_builder_name") or ""
        ).strip()
        old_count = int(old_doc.get("project_count") or len(old_doc.get("project_ids") or []))
        was_in_chunks = bid in existing_chunk_builder_ids
        is_active_corrected = bid in corrected_by_id

        if is_active_corrected:
            corr_b = corrected_by_id[bid]
            classification = "ACTIVE_CANONICAL_BELOW_TOP_100"
            decision = "RETAIN_ACTIVE_CANONICAL_INDIVIDUAL_DOC"
            reason = (
                f"Active canonical identity in corrected 2,236-builder catalogue "
                f"({corr_b['project_count']} projects); retain and update individual doc in place to protect any direct lookups."
            )
            retain_active_ids.append(bid)
            new_count = int(corr_b["project_count"])
        elif was_in_chunks:
            classification = "REPLACED_OLD_SLUG_OR_SPLIT_PARENT"
            decision = "DEFER_TO_SEPARATE_APPROVED_CLEANUP"
            reason = (
                "No longer referenced by any corrected project after slug standardization or entity split; "
                "safe to defer deletion until post-migration verification."
            )
            deferred_delete_ids.append(bid)
            new_count = 0
        else:
            classification = "PRE_PHASE4_ORPHAN"
            decision = "DEFER_TO_SEPARATE_APPROVED_CLEANUP"
            reason = (
                "Pre-Phase-4 orphaned individual builder doc absent from both live chunks and corrected catalogue; "
                "defer deletion to separate post-migration cleanup."
            )
            deferred_delete_ids.append(bid)
            new_count = 0

        rows.append(
            {
                "builder_id": bid,
                "document_path": f"builders/{bid}",
                "existing_builder_name": old_name,
                "existing_individual_project_count": old_count,
                "present_in_live_chunks": was_in_chunks,
                "present_in_corrected_catalogue": is_active_corrected,
                "corrected_project_count": new_count,
                "classification": classification,
                "phase4_2a_decision": decision,
                "delete_executed_in_phase4_2a": False,
                "reason": reason,
            }
        )

    return {
        "rows": rows,
        "retain_active_ids": retain_active_ids,
        "deferred_delete_ids": deferred_delete_ids,
    }


# ---------------------------------------------------------------------------
# Sections 8 & 9 — Commit Count Verification, Postconditions & Safe Checkpoints
# ---------------------------------------------------------------------------

def commit_firestore_writes_verified(
    writes: List[Dict[str, Any]],
    token: str,
    http_post_fn: Optional[Callable[[str, bytes, Dict[str, str]], Tuple[int, bytes]]] = None,
) -> Dict[str, Any]:
    """
    Commit Firestore REST `documents:commit` writes and explicitly validate that
    `len(writeResults) == len(writes)`.
    """
    if not writes:
        return {"committed_count": 0, "write_results_count": 0}

    url = (
        f"https://firestore.googleapis.com/v1/projects/{FIREBASE_PROJECT_ID}"
        f"/databases/{FIRESTORE_DATABASE}/documents:commit"
    )
    body = json.dumps({"writes": writes}).encode("utf-8")
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }

    if http_post_fn is not None:
        status, resp_bytes = http_post_fn(url, body, headers)
    else:
        req = urllib.request.Request(url, data=body, headers=headers, method="POST")
        with urllib.request.urlopen(req, timeout=60) as resp:
            status = resp.status
            resp_bytes = resp.read()

    if status != 200:
        raise CommitCountMismatchError(f"Unexpected HTTP status from Firestore commit: {status}")

    payload = json.loads(resp_bytes.decode("utf-8"))
    write_results = payload.get("writeResults")
    if not isinstance(write_results, list) or len(write_results) != len(writes):
        raise CommitCountMismatchError(
            f"Firestore commit writeResults count mismatch: submitted={len(writes)}, received={len(write_results) if isinstance(write_results, list) else 'MISSING'}"
        )

    return {
        "committed_count": len(writes),
        "write_results_count": len(write_results),
    }


def verify_project_stage_postconditions(
    live_projects: List[Dict[str, Any]],
    expected_builder_by_pid: Dict[str, str],
    expected_invariants: Dict[str, Any],
    pre_projects: Optional[List[Dict[str, Any]]] = None,
) -> Dict[str, Any]:
    """Semantic postcondition checks required after `patch_projects` stage."""
    failures: List[str] = []

    pids = [str(p.get("_doc_id") or p.get("project_id") or "") for p in live_projects]
    regs = [str(p.get("registration_number") or "").strip() for p in live_projects]
    if len(live_projects) != expected_invariants["projects_total"]:
        failures.append(
            f"Project count mismatch: expected={expected_invariants['projects_total']}, actual={len(live_projects)}"
        )
    if len(set(pids)) != len(pids):
        failures.append("Duplicate project IDs found after patch_projects stage")
    if len(set(regs)) != len(regs) or any(not r for r in regs):
        failures.append("Duplicate or empty registration numbers found after patch_projects stage")

    tier_counts: Dict[str, int] = {}
    taluk_counts: Dict[str, int] = {}
    district_set: Set[str] = set()
    orphans: List[str] = []
    mismatched_owners: List[str] = []

    for p in live_projects:
        pid = str(p.get("_doc_id") or p.get("project_id") or "")
        bid = str(p.get("builder_id") or "").strip()
        if not bid:
            orphans.append(pid)
        elif pid in expected_builder_by_pid and bid != expected_builder_by_pid[pid]:
            mismatched_owners.append(f"{pid}:{bid}!={expected_builder_by_pid[pid]}")

        tier = str((p.get("provenance") or {}).get("data_tier") or "")
        tier_counts[tier] = tier_counts.get(tier, 0) + 1
        taluk = str(p.get("normalizedTaluk") or p.get("taluk") or "")
        taluk_counts[taluk] = taluk_counts.get(taluk, 0) + 1
        district_set.add(str(p.get("district") or ""))

    if orphans:
        failures.append(f"Orphaned projects with empty builder_id: {orphans[:10]}")
    if mismatched_owners:
        failures.append(f"Project owner mismatches: {mismatched_owners[:10]}")
    if tier_counts != expected_invariants["tier_counts"]:
        failures.append(f"Data tier mutation: expected={expected_invariants['tier_counts']}, actual={tier_counts}")
    if taluk_counts != expected_invariants["taluk_counts"]:
        failures.append(f"Taluk distribution mutation: expected={expected_invariants['taluk_counts']}, actual={taluk_counts}")
    if any("rural" in d.lower() for d in district_set):
        failures.append(f"Bengaluru Rural mixed into /projects districts: {sorted(district_set)}")

    if pre_projects is not None:
        from phase4_2b_verification import ProjectInvariantError, verify_project_invariants_exact
        try:
            verify_project_invariants_exact(pre_projects, live_projects)
        except ProjectInvariantError as exc:
            failures.append(str(exc))

    if failures:
        raise PostconditionFailureError("Project stage postcondition failure: " + " | ".join(failures))
    return {"status": "PASS", "projects_verified": len(live_projects), "tier_counts": tier_counts, "taluk_counts": taluk_counts}


def verify_builder_catalog_postconditions(
    live_builders_docs: Dict[str, Dict[str, Any]],
    expected_builder_ids: Set[str],
    retained_active_individual_ids: Set[str],
    expected_total_projects: int,
    max_chunk_kb: float = MAX_SAFE_CHUNK_KB,
    expected_project_ids_by_builder: Optional[Dict[str, Set[str]]] = None,
) -> Dict[str, Any]:
    """Semantic postcondition checks required after `write_catalog_chunks` + `write_catalog_meta`."""
    failures: List[str] = []
    meta = live_builders_docs.get("_catalog_meta")
    if not isinstance(meta, dict):
        failures.append("Missing builders/_catalog_meta document")
        raise PostconditionFailureError("; ".join(failures))

    chunk_ids = list(meta.get("chunk_ids") or [])
    if not chunk_ids or meta.get("total_chunks") != len(chunk_ids):
        failures.append(f"Invalid _catalog_meta chunk count: {meta.get('total_chunks')} vs {len(chunk_ids)}")

    seen_chunk_builders: List[str] = []
    chunk_projects_total = 0
    for cid in chunk_ids:
        cdoc = live_builders_docs.get(cid)
        if not isinstance(cdoc, dict):
            failures.append(f"Missing chunk document builders/{cid}")
            continue
        size_kb = len(json.dumps({k: v for k, v in cdoc.items() if k != "_doc_id"}, ensure_ascii=False).encode("utf-8")) / 1024
        if size_kb > max_chunk_kb:
            failures.append(f"Chunk {cid} exceeds size cap ({size_kb:.1f} KB > {max_chunk_kb} KB)")
        for b in cdoc.get("builders") or []:
            bid = str(b.get("builder_id") or "")
            seen_chunk_builders.append(bid)
            chunk_projects_total += int(b.get("project_count") or len(b.get("project_ids") or []))
            if expected_project_ids_by_builder is not None and bid in expected_project_ids_by_builder:
                actual_pids = set(b.get("project_ids") or [])
                if actual_pids != expected_project_ids_by_builder[bid]:
                    failures.append(f"Exact project_ids membership mismatch in chunk {cid} for {bid}")

    if len(seen_chunk_builders) != len(set(seen_chunk_builders)):
        failures.append("Duplicate canonical builder IDs across catalogue chunks")
    missing_builders = expected_builder_ids - set(seen_chunk_builders)
    extra_builders = set(seen_chunk_builders) - expected_builder_ids
    if missing_builders or extra_builders:
        failures.append(
            f"Canonical builder set mismatch: missing={sorted(missing_builders)[:5]}, extra={sorted(extra_builders)[:5]}"
        )
    if chunk_projects_total != expected_total_projects:
        failures.append(
            f"Chunk total project count mismatch: expected={expected_total_projects}, actual={chunk_projects_total}"
        )

    for rbid in sorted(retained_active_individual_ids):
        if rbid not in live_builders_docs:
            failures.append(f"Retained active canonical individual doc missing: builders/{rbid}")
        elif expected_project_ids_by_builder is not None and rbid in expected_project_ids_by_builder:
            actual_rb = set((live_builders_docs[rbid] or {}).get("project_ids") or [])
            if actual_rb != expected_project_ids_by_builder[rbid]:
                failures.append(f"Exact project_ids mismatch in retained individual doc builders/{rbid}")

    if failures:
        raise PostconditionFailureError("Builder catalog postcondition failure: " + " | ".join(failures))
    return {
        "status": "PASS",
        "builders_verified": len(seen_chunk_builders),
        "chunks_verified": len(chunk_ids),
        "projects_verified": chunk_projects_total,
    }


def write_verified_checkpoint(checkpoint_path: Path, checkpoint_data: Dict[str, Any]) -> None:
    """Persist integrity-signed migration checkpoint JSON."""
    payload = copy.deepcopy(checkpoint_data)
    payload["checkpoint_sha256"] = compute_checkpoint_sha256(payload)
    checkpoint_path.parent.mkdir(parents=True, exist_ok=True)
    checkpoint_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")


def validate_and_load_checkpoint(
    checkpoint_path: Path,
    manifest: Dict[str, Any],
) -> Dict[str, Any]:
    """Validate checkpoint tamper hash and verify it belongs to the exact manifest and baseline."""
    ckpt = json.loads(checkpoint_path.read_text(encoding="utf-8"))
    if ckpt.get("checkpoint_sha256") != compute_checkpoint_sha256(ckpt):
        raise CheckpointValidationError("Checkpoint integrity hash mismatch")
    if ckpt.get("manifest_sha256") != manifest.get("manifest_sha256"):
        raise CheckpointValidationError(
            f"Checkpoint belongs to a different manifest hash: {ckpt.get('manifest_sha256')!r} != {manifest.get('manifest_sha256')!r}"
        )
    if ckpt.get("baseline_fingerprint") != manifest.get("baseline_fingerprint"):
        raise CheckpointValidationError("Checkpoint baseline_fingerprint does not match manifest")
    if ckpt.get("firebase_project_id") != manifest.get("firebase_project_id"):
        raise CheckpointValidationError("Checkpoint firebase_project_id mismatch")
    if ckpt.get("firestore_database") != manifest.get("firestore_database"):
        raise CheckpointValidationError("Checkpoint firestore_database mismatch")
    return ckpt


def compute_resumable_stage_ops(
    stage_name: str,
    stage_ops: List[Dict[str, Any]],
    checkpoint: Dict[str, Any],
    manifest: Dict[str, Any],
    live_projects: List[Dict[str, Any]],
    live_builders_docs: Dict[str, Dict[str, Any]],
) -> Tuple[List[Dict[str, Any]], List[str]]:
    """
    On resume after partial failure, inspect each operation in `stage_ops` against live state
    and expected old/target values. Returns `(ops_to_apply, already_applied_doc_paths)`.
    Raises CheckpointValidationError if live state matches NEITHER old nor target (concurrent drift).
    """
    completed_ops = set((checkpoint.get("completed_ops") or {}).get(stage_name) or [])
    exp_old = manifest.get("expected_old_values") or {}
    exp_proj_old = exp_old.get("projects") or {}
    exp_bldr_old = exp_old.get("builders") or {}
    live_proj_map = {str(p.get("_doc_id") or p.get("project_id") or ""): p for p in live_projects}

    ops_to_apply: List[Dict[str, Any]] = []
    already_applied: List[str] = []

    for op in stage_ops:
        upd = op.get("update")
        if not upd:
            raise CheckpointValidationError(f"Unsupported op during resume in {stage_name}")
        col, doc_id = _parse_doc_path(
            upd["name"], manifest["firebase_project_id"], manifest["firestore_database"]
        )
        rel_path = f"{col}/{doc_id}"
        target_decoded = firestore_value_to_python({"mapValue": {"fields": upd.get("fields", {})}})

        if col == "projects":
            cur_doc = live_proj_map.get(doc_id)
            if cur_doc is None:
                raise CheckpointValidationError(f"Live project missing during resume: {rel_path}")
            mask_paths = (op.get("updateMask") or {}).get("fieldPaths") or []
            old_snapshot = exp_proj_old.get(doc_id) or {}
            matches_target = all(
                extract_managed_field(cur_doc, fp) == extract_managed_field(target_decoded, fp)
                for fp in mask_paths
            )
            matches_old = all(
                extract_managed_field(cur_doc, fp) == old_snapshot.get(fp, MISSING_FIELD_SENTINEL)
                for fp in mask_paths
            )
        else:
            cur_b = live_builders_docs.get(doc_id)
            cur_clean = {k: v for k, v in cur_b.items() if k != "_doc_id"} if cur_b is not None else None
            if doc_id == "_catalog_meta" and cur_clean is not None:
                matches_target = {k: v for k, v in cur_clean.items() if k != "updated_at"} == {
                    k: v for k, v in target_decoded.items() if k != "updated_at"
                }
            else:
                matches_target = cur_clean == target_decoded
            old_b_meta = exp_bldr_old.get(doc_id) or {}
            if not old_b_meta.get("exists"):
                matches_old = cur_clean is None
            else:
                matches_old = (
                    cur_clean is not None
                    and compute_canonical_sha256(cur_clean) == old_b_meta.get("doc_sha256")
                )

        if matches_target:
            already_applied.append(rel_path)
        elif matches_old and rel_path not in completed_ops:
            ops_to_apply.append(op)
        else:
            raise CheckpointValidationError(
                f"Ambiguous/conflicting live state on {rel_path} during resume "
                f"(recorded_completed={rel_path in completed_ops}, matches_target={matches_target}, matches_old={matches_old})"
            )

    return ops_to_apply, already_applied
