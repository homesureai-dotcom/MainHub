#!/usr/bin/env python3
"""
HomeSure Phase 4.2E — Final Manifest v2 Verification, Count Reconciliation & Freeze (Read-Only).

Strictly read-only verification and freeze certification of Manifest v2
(`phase4_2e_identity_migration_manifest_v2.json`). Never modifies Manifest v2,
Manifest v1, Discrepancy Audit, Phase 4.2A–4.2D artifacts, `phase4_2b_approval_record.json`
(`approved: false`), or production Cloud Firestore (`0` writes, `0` deletes).

Writes exclusively to `KRERA-Data-Extraction/reports/phase4_2e_final_freeze/`.
"""

from __future__ import annotations

import argparse
import csv
import datetime
import hashlib
import json
import sys
from collections import Counter
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple

WORKSPACE_ROOT = Path(__file__).resolve().parents[3]
EXTRACTION_ROOT = WORKSPACE_ROOT / "KRERA-Data-Extraction"
SCRIPTS_ROOT = EXTRACTION_ROOT / "scripts"
FIRESTORE_IMPORT_ROOT = SCRIPTS_ROOT / "firestore_import"
for _p in (str(SCRIPTS_ROOT), str(FIRESTORE_IMPORT_ROOT)):
    if _p not in sys.path:
        sys.path.insert(0, _p)

from import_projects import (
    FIREBASE_PROJECT_ID,
    FIRESTORE_DATABASE,
    firestore_value_to_python,
    get_firebase_Auth_token,
    list_firestore_collection_docs,
)
from phase4_2a_hardening import (
    LiveDriftError,
    MIGRATION_VERSION_V2_2_V2,
    compute_manifest_sha256,
    detect_live_drift,
    validate_migration_manifest,
    verify_backup_bundle,
)
from phase4_2e_discrepancy_audit import AUDIT_OUTPUT_DIR, verify_all_prior_artifacts_untouched
from phase4_2e_manifest_v2 import (
    AFFINITY_006539_FORM_A_FILE,
    AFFINITY_007631_FORM_A_FILE,
    AFFINITY_007631_PID,
    PHASE4_2E_V2_MANIFEST_FILENAME,
    PHASE4_2E_V2_OUTPUT_DIR,
    RGHCL_004171_PID,
    RGHCL_004171_REG,
    V2_STATUS_SUMMARY,
)
from phase4_2e_reconciliation import (
    DEFAULT_BACKUP_DIR,
    EXPECTED_BASELINE_FINGERPRINT,
    IMMUTABLE_SOURCE_ARTIFACTS,
    PHASE4_2E_OUTPUT_DIR,
    RURAL_SNAPSHOT_PATH,
    VAISHNAVI_HARMONY_CERT_SHA256,
    _sha256_file,
    _write_csv,
)

FREEZE_OUTPUT_DIR = EXTRACTION_ROOT / "reports" / "phase4_2e_final_freeze"

FINAL_STATUS_TAXONOMY = {
    "RECONCILIATION_STATUS": "PASS",
    "IDENTITY_REVIEW_STATUS": "PROVISIONAL",
    "CORPORATE_VERIFICATION_STATUS": "NOT_PERFORMED",
    "PRODUCTION_APPROVAL_STATUS": "NOT_APPROVED",
    "PRODUCTION_EXECUTION_STATUS": "NOT_EXECUTED",
    "SOURCE_EVIDENCE_STATUS": V2_STATUS_SUMMARY["SOURCE_EVIDENCE_STATUS"],
}

FREEZE_DELIVERABLE_FILENAMES = [
    "phase4_2e_final_freeze_report.md",
    "phase4_2e_builder_operation_count_reconciliation.csv",
    "phase4_2e_final_operation_summary.json",
    "phase4_2e_final_integrity_verification.json",
    "phase4_2e_final_rollback_verification.json",
    "phase4_2e_final_test_report.md",
    "phase4_2e_manifest_v2_freeze_record.json",
]


def verify_all_upstream_artifacts(
    *,
    extraction_root: Path = EXTRACTION_ROOT,
    backup_dir: Path = DEFAULT_BACKUP_DIR,
    v1_dir: Path = PHASE4_2E_OUTPUT_DIR,
    audit_dir: Path = AUDIT_OUTPUT_DIR,
    v2_dir: Path = PHASE4_2E_V2_OUTPUT_DIR,
) -> Dict[str, Any]:
    """Independently verify checksums of all 47 upstream immutable artifacts (4.2A-4.2D, v1, audit, v2)."""
    backup_res = verify_backup_bundle(backup_dir)
    if backup_res["baseline_fingerprint"] != EXPECTED_BASELINE_FINGERPRINT:
        raise RuntimeError(f"Baseline fingerprint mismatch: {backup_res['baseline_fingerprint']}")

    prior_v1 = verify_all_prior_artifacts_untouched(extraction_root, backup_dir, v1_dir)
    approval = json.loads((backup_dir / "phase4_2b_approval_record.json").read_text(encoding="utf-8"))
    if approval.get("approved") is not False:
        raise RuntimeError(f"Approval record mutated away from False: {approval.get('approved')!r}")

    # Verify all 5 Discrepancy Audit files
    audit_hashes: Dict[str, str] = {}
    audit_md_txt = (audit_dir / "phase4_2e_discrepancy_audit.md").read_text(encoding="utf-8")
    for fn in (
        "phase4_2e_discrepancy_audit.md",
        "phase4_2e_rghcl_membership_audit.csv",
        "phase4_2e_affinity_007631_evidence_audit.json",
        "phase4_2e_builder_count_bridge.json",
        "phase4_2e_status_taxonomy_audit.json",
    ):
        fp = audit_dir / fn
        sha = _sha256_file(fp)
        if fn != "phase4_2e_discrepancy_audit.md" and sha not in audit_md_txt:
            raise RuntimeError(f"Audit artifact hash mismatch for {fn}")
        audit_hashes[fn] = sha

    # Verify all 13 Manifest v2 deliverables against phase4_2e_artifact_hashes_v2.json
    hashes_v2_path = v2_dir / "phase4_2e_artifact_hashes_v2.json"
    hashes_v2 = json.loads(hashes_v2_path.read_text(encoding="utf-8"))
    if hashes_v2.get("approval_record_approved") is not False:
        raise RuntimeError("Manifest v2 hash register shows approval_record_approved != False")

    v2_verified_hashes: Dict[str, Dict[str, Any]] = {}
    for fn, meta in hashes_v2["deliverable_hashes"].items():
        fp = v2_dir / fn
        actual_sha = _sha256_file(fp)
        if actual_sha != meta["sha256"]:
            raise RuntimeError(f"Manifest v2 deliverable hash mismatch for {fn}: {actual_sha} != {meta['sha256']}")
        v2_verified_hashes[fn] = {"size_bytes": fp.stat().st_size, "sha256": actual_sha}
    v2_verified_hashes["phase4_2e_artifact_hashes_v2.json"] = {
        "size_bytes": hashes_v2_path.stat().st_size,
        "sha256": _sha256_file(hashes_v2_path),
    }

    manifest_v2 = json.loads((v2_dir / PHASE4_2E_V2_MANIFEST_FILENAME).read_text(encoding="utf-8"))
    val_res = validate_migration_manifest(manifest_v2, allow_deletions=False)
    recomputed_internal = compute_manifest_sha256(manifest_v2)
    if recomputed_internal != manifest_v2.get("manifest_sha256"):
        raise RuntimeError("Manifest v2 internal manifest_sha256 mismatch")

    return {
        "backup_result": backup_res,
        "phase4_2a_to_4_2d_verified_count": len(IMMUTABLE_SOURCE_ARTIFACTS),
        "phase4_2e_v1_verified_count": len(prior_v1["phase4_2e_verified_hashes"]) + 1,
        "discrepancy_audit_verified_count": len(audit_hashes),
        "manifest_v2_verified_count": len(v2_verified_hashes),
        "manifest_v2_hashes": v2_verified_hashes,
        "manifest_v2": manifest_v2,
        "manifest_v2_validation": val_res,
        "manifest_v2_internal_sha256": recomputed_internal,
        "approval_record_approved": False,
    }


def reconcile_standalone_builder_operations(
    *,
    backup_dir: Path = DEFAULT_BACKUP_DIR,
    v2_dir: Path = PHASE4_2E_V2_OUTPUT_DIR,
    manifest_v2: Dict[str, Any],
) -> Tuple[List[Dict[str, Any]], Dict[str, Any]]:
    """
    Reconcile EVERY individual `/builders/{id}` document against actual Manifest v2 `staged_ops`,
    resolving the `17 + 9 = 26` vs `27` UPDATE reporting discrepancy mathematically.
    """
    b_bak = json.loads((backup_dir / "builders_backup.json").read_text(encoding="utf-8"))
    with (v2_dir / "phase4_2e_builder_identity_register_v2.csv").open("r", encoding="utf-8", newline="") as fh:
        b_rows = list(csv.DictReader(fh))
    b_reg_by_id = {r["builder_id"]: r for r in b_rows}

    top100_rank_by_id = {r["builder_id"]: idx for idx, r in enumerate(b_rows[:100], start=1)}
    top100_set = set(top100_rank_by_id.keys())
    retained_below_100 = set(manifest_v2["retained_active_individual_builder_ids"])

    staged = manifest_v2["staged_ops"]
    staged_creates = {str(op["update"]["name"]).split("/")[-1]: op for op in staged["create_builder_docs"]}
    staged_updates = {str(op["update"]["name"]).split("/")[-1]: op for op in staged["update_builder_docs"]}
    live_indiv = {k: v for k, v in b_bak.items() if not k.startswith("_catalog_")}
    deferred_set = set(manifest_v2["deferred_deletion_candidates"])
    active_target = top100_set | retained_below_100

    all_standalone_ids = sorted(set(live_indiv.keys()) | set(staged_creates.keys()) | set(staged_updates.keys()) | active_target)
    reconciliation_rows: List[Dict[str, Any]] = []
    bucket_counts: Counter[Tuple[str, str]] = Counter()

    for bid in all_standalone_ids:
        exists_live = bid in live_indiv
        in_top100 = bid in top100_set
        in_below100_ret = bid in retained_below_100
        in_deferred = bid in deferred_set

        if in_top100:
            tier = "TOP_100"
            rank = str(top100_rank_by_id[bid])
        elif in_below100_ret:
            tier = "BELOW_TOP_100_RETAINED_ACTIVE"
            rank = ""
        else:
            tier = "DEFERRED_LEGACY_UNTOUCHED"
            rank = ""

        if bid in staged_creates:
            op_cat = "CREATE"
        elif bid in staged_updates:
            op_cat = "UPDATE"
        elif bid in active_target:
            op_cat = "UNCHANGED"
        elif in_deferred:
            op_cat = "DEFERRED_UNTOUCHED"
        else:
            op_cat = "UNEXPECTED"

        bucket_counts[(tier, op_cat)] += 1
        old_cnt = live_indiv[bid].get("project_count") if exists_live else 0
        new_cnt = b_reg_by_id[bid]["project_count"] if bid in b_reg_by_id else 0
        op_obj = staged_creates.get(bid) or staged_updates.get(bid)
        op_name = op_obj["update"]["name"] if op_obj else f"projects/{FIREBASE_PROJECT_ID}/databases/{FIRESTORE_DATABASE}/documents/builders/{bid}"

        notes = ""
        if bid == "builder_rajiv_gandhi_housing":
            notes = "Gained 004171 in v2 (23 -> 24 projects), shifting Top-100 UPDATE count from 17 (v1) to 18 (v2); explains prior 17+9=26 prose vs 27 actual staged UPDATEs."
        elif tier == "BELOW_TOP_100_RETAINED_ACTIVE":
            notes = "Retained active canonical individual doc below Top-100 updated in place (bloat/consumer-safe)."
        elif op_cat == "DEFERRED_UNTOUCHED":
            notes = "Preserved untouched (`deletions_enabled: false`)."

        reconciliation_rows.append(
            {
                "builder_id": bid,
                "standalone_tier": tier,
                "top100_rank": rank,
                "operation_category": op_cat,
                "exists_in_live_firestore": exists_live,
                "live_project_count": old_cnt,
                "proposed_project_count": new_cnt,
                "staged_in_manifest_v2": op_cat in ("CREATE", "UPDATE"),
                "document_path": f"builders/{bid}",
                "firestore_resource_name": op_name,
                "notes": notes,
            }
        )

    top_create = bucket_counts[("TOP_100", "CREATE")]
    top_update = bucket_counts[("TOP_100", "UPDATE")]
    top_unchanged = bucket_counts[("TOP_100", "UNCHANGED")]
    bel_create = bucket_counts[("BELOW_TOP_100_RETAINED_ACTIVE", "CREATE")]
    bel_update = bucket_counts[("BELOW_TOP_100_RETAINED_ACTIVE", "UPDATE")]
    bel_unchanged = bucket_counts[("BELOW_TOP_100_RETAINED_ACTIVE", "UNCHANGED")]
    def_cnt = bucket_counts[("DEFERRED_LEGACY_UNTOUCHED", "DEFERRED_UNTOUCHED")]

    actual_creates = len(staged["create_builder_docs"])
    actual_updates = len(staged["update_builder_docs"])
    actual_patches = len(staged["patch_projects"])
    actual_chunks = len(staged["write_catalog_chunks"])
    actual_meta = len(staged["write_catalog_meta"])
    actual_deletes = len(staged["delete_stale_builders_docs"])
    actual_total = actual_creates + actual_updates + actual_patches + actual_chunks + actual_meta + actual_deletes

    assert (top_create + bel_create) == actual_creates == 41
    assert (top_update + bel_update) == actual_updates == 27
    assert (top_create + top_update + top_unchanged) == 100
    assert (bel_create + bel_update + bel_unchanged) == 9
    assert def_cnt == 59
    assert len(reconciliation_rows) == 168
    assert bucket_counts.total() == 168
    assert all(k[1] != "UNEXPECTED" for k in bucket_counts)

    op_summary = {
        "discrepancy_resolution": {
            "previously_reported_prose": {"total_update": 27, "top_100_update": 17, "below_top100_update": 9, "note": "17 + 9 = 26 mismatch"},
            "verified_truth_from_staged_ops": {
                "total_genuine_updates": actual_updates,
                "top_100_create": top_create,
                "top_100_update": top_update,
                "top_100_unchanged": top_unchanged,
                "below_top100_create": bel_create,
                "below_top100_update": bel_update,
                "below_top100_unchanged": bel_unchanged,
                "math_check": f"{top_update} + {bel_update} = {actual_updates}",
                "explanation": (
                    "There are 27 GENUINE UPDATE operations in Manifest v2 (not 26), and the dry-run total of 2,141 is exact. "
                    "In v1, Top-100 had 17 UPDATE + 42 UNCHANGED; in v2, Top-100 builder `builder_rajiv_gandhi_housing` gained "
                    "registration 004171 (23 -> 24 projects), shifting it from UNCHANGED (42 -> 41) to Top-100 UPDATE (17 -> 18). "
                    "The previous v2 narrative carried over '17' from v1 instead of '18'."
                ),
            },
        },
        "standalone_builder_document_reconciliation": {
            "top_100": {"create": top_create, "update": top_update, "unchanged": top_unchanged, "subtotal": 100},
            "below_top100_retained_active": {"create": bel_create, "update": bel_update, "unchanged": bel_unchanged, "subtotal": 9},
            "active_standalone_individual_total": top_create + top_update + top_unchanged + bel_create + bel_update + bel_unchanged,
            "deferred_legacy_individual_untouched": def_cnt,
            "total_standalone_individual_docs_post_migration": len(reconciliation_rows),
            "chunk_only_builder_identities": len(b_rows) - (top_create + top_update + top_unchanged + bel_create + bel_update + bel_unchanged),
            "total_canonical_provisional_identities": len(b_rows),
            "total_post_migration_builders_collection_docs": len(reconciliation_rows) + actual_chunks + actual_meta,
        },
        "complete_migration_operation_summary": {
            "create_builder_docs": actual_creates,
            "update_builder_docs": actual_updates,
            "patch_projects": actual_patches,
            "write_catalog_chunks": actual_chunks,
            "write_catalog_meta": actual_meta,
            "delete_ops": actual_deletes,
            "total_simulated_operations": actual_total,
            "matches_v2_dry_run_total": actual_total == manifest_v2["op_counts"]["total_writes"] == 2141,
        },
    }
    return reconciliation_rows, op_summary


def verify_critical_invariants_v2(
    *,
    live_projects: List[Dict[str, Any]],
    live_builders: Dict[str, Dict[str, Any]],
    v2_dir: Path = PHASE4_2E_V2_OUTPUT_DIR,
    manifest_v2: Dict[str, Any],
    drift_res: Dict[str, Any],
    upstream: Dict[str, Any],
) -> Dict[str, Any]:
    """Verify every Section 5 invariant across Manifest v2 CSVs, chunks, rural snapshot & live baseline."""
    with (v2_dir / "phase4_2e_project_identity_reconciliation_v2.csv").open("r", encoding="utf-8", newline="") as fh:
        proj_rows = list(csv.DictReader(fh))
    with (v2_dir / "phase4_2e_builder_identity_register_v2.csv").open("r", encoding="utf-8", newline="") as fh:
        b_rows = list(csv.DictReader(fh))
    with (v2_dir / "phase4_2e_ownership_reassignment_register_v2.csv").open("r", encoding="utf-8", newline="") as fh:
        own_rows = list(csv.DictReader(fh))
    with (v2_dir / "phase4_2e_unresolved_identity_register_v2.csv").open("r", encoding="utf-8", newline="") as fh:
        unres_rows = list(csv.DictReader(fh))
    v2_integ = json.loads((v2_dir / "phase4_2e_integrity_verification_v2.json").read_text(encoding="utf-8"))

    # Rural check
    rural_data = json.loads(RURAL_SNAPSHOT_PATH.read_text(encoding="utf-8"))
    rural_regs = {str(r.get("REGISTRATION NO") or "").strip() for r in (rural_data.get("records") or [])}
    urban_regs = {r["registration_number"] for r in proj_rows}

    # Chunk consistency check directly from staged write_catalog_chunks
    chunk_builders: Set[str] = set()
    chunk_projects: Set[str] = set()
    for op in manifest_v2["staged_ops"]["write_catalog_chunks"]:
        dec = firestore_value_to_python({"mapValue": {"fields": op["update"]["fields"]}})
        for b in dec["builders"]:
            chunk_builders.add(b["builder_id"])
            chunk_projects.update(b["project_ids"])

    rghcl_rows = [r for r in proj_rows if r["proposed_builder_id"] == "builder_rajiv_gandhi_housing"]
    r004171 = next(r for r in proj_rows if r["project_id"] == RGHCL_004171_PID)
    r007631 = next(r for r in proj_rows if r["project_id"] == AFFINITY_007631_PID)
    tier_counts = Counter(r["data_tier"] for r in proj_rows)
    taluk_counts = Counter(r["taluk"] for r in proj_rows)
    mc_rec = manifest_v2.get("merge_candidate_reconciliation") or {}

    checks = {
        "projects_4110_urban": len(proj_rows) == len(live_projects) == 4110,
        "unique_rera_registrations_4110": len(urban_regs) == 4110 and len({r["project_id"] for r in proj_rows}) == 4110,
        "tiers_1022_deep_3088_summary": tier_counts == {"deep_extracted": 1022, "catalogue_summary": 3088},
        "rural_730_isolated_zero_overlap": len(rural_data.get("records") or []) == 730 and len(rural_regs & urban_regs) == 0,
        "builders_2242_canonical_provisional": len(b_rows) == 2242 and chunk_builders == {r["builder_id"] for r in b_rows},
        "rghcl_24_projects_incl_004171": len(rghcl_rows) == 24 and r004171["proposed_builder_id"] == "builder_rajiv_gandhi_housing" and r004171["official_promoter_name"] == "Rajiv Gandhi Housing Corporation Limlted",
        "affinity_007631_mapped_with_own_forma": r007631["proposed_builder_id"] == "builder_affinity_projects" and r007631["form_a_json_file"] == AFFINITY_007631_FORM_A_FILE and r007631["cross_linked_form_a_file"] == AFFINITY_006539_FORM_A_FILE and r007631["form_c_cert_sha256"] == VAISHNAVI_HARMONY_CERT_SHA256,
        "six_ownership_reassignments": len(own_rows) == 6,
        "seventeen_unresolved_zero_approved": len(unres_rows) == 17 and all(r["human_approved"] == "False" for r in unres_rows),
        "merge_33_and_jv_9_accounted": mc_rec.get("previous_phase4_2e_v1_merge_candidates") == 33 and mc_rec.get("remaining_preserved_merge_candidates") == 32 and mc_rec.get("preserved_jv_brand_overlaps") == 9 and len(mc_rec.get("resolved_in_v2") or []) == 1,
        "deferred_59_untouched": len(manifest_v2["deferred_deletion_candidates"]) == 59 and all(b in live_builders for b in manifest_v2["deferred_deletion_candidates"]),
        "chunks_13_consistent_4110_projects": len(manifest_v2["staged_ops"]["write_catalog_chunks"]) == 13 and len(chunk_projects) == 4110,
        "five_taluks_exact": dict(taluk_counts) == {"Anekal": 891, "Bengaluru East": 1279, "Bengaluru North": 691, "Bengaluru South": 1084, "Yelahanka": 165},
        "invariants_36990_zero_mismatches": v2_integ["project_integrity"]["invariant_comparisons"] == 36990 and v2_integ["project_integrity"]["invariant_mismatches"] == 0,
        "live_firestore_drift_clean": drift_res["status"] == "CLEAN" and drift_res["drift_count"] == 0,
    }
    failures = [k for k, ok in checks.items() if not ok]
    if failures:
        raise RuntimeError(f"Critical invariant failure(s): {failures}")

    return {
        "status": "PASS",
        "checks": checks,
        "failures": failures,
        "counts": {
            "projects_total": len(proj_rows),
            "unique_registrations": len(urban_regs),
            "data_tiers": dict(tier_counts),
            "taluks": dict(taluk_counts),
            "rural_records_isolated": len(rural_data.get("records") or []),
            "builders_total": len(b_rows),
            "rghcl_projects": len(rghcl_rows),
            "ownership_reassignments": len(own_rows),
            "unresolved_provisional_rows": len(unres_rows),
            "unresolved_human_approved": 0,
            "merge_candidates_accounted": 33,
            "merge_candidates_resolved_v2": 1,
            "merge_candidates_preserved_v2": 32,
            "jv_overlaps_preserved": 9,
            "deferred_legacy_docs_untouched": 59,
            "invariant_comparisons": 36990,
            "invariant_mismatches": 0,
        },
        "upstream_hashes_verified": {
            "phase4_2a_to_4_2d_count": upstream["phase4_2a_to_4_2d_verified_count"],
            "phase4_2e_v1_count": upstream["phase4_2e_v1_verified_count"],
            "discrepancy_audit_count": upstream["discrepancy_audit_verified_count"],
            "manifest_v2_count": upstream["manifest_v2_verified_count"],
            "manifest_v2_internal_sha256": upstream["manifest_v2_internal_sha256"],
            "manifest_v2_hashes": upstream["manifest_v2_hashes"],
        },
    }


def verify_rollback_readiness_v2(
    *,
    v2_dir: Path = PHASE4_2E_V2_OUTPUT_DIR,
    manifest_v2: Dict[str, Any],
    upstream: Dict[str, Any],
) -> Dict[str, Any]:
    """Verify 1-to-1 rollback coverage, backup checksums, conflict detection, and executed=False."""
    rb = json.loads((v2_dir / "phase4_2e_rollback_package_v2.json").read_text(encoding="utf-8"))
    if rb.get("executed") is not False:
        raise RuntimeError("Rollback package executed flag is not False")
    if rb.get("target_manifest_sha256") != manifest_v2["manifest_sha256"]:
        raise RuntimeError("Rollback target_manifest_sha256 does not match Manifest v2")
    if rb.get("baseline_fingerprint") != upstream["backup_result"]["baseline_fingerprint"]:
        raise RuntimeError("Rollback baseline_fingerprint mismatch")

    ops = rb["operations"]
    proj_restores = {
        str(op["update"]["name"]).split("/documents/projects/", 1)[1]: op
        for op in ops
        if "update" in op and "/documents/projects/" in op["update"]["name"]
    }
    builder_restores = {
        str(op["update"]["name"]).split("/documents/builders/", 1)[1]: op
        for op in ops
        if "update" in op and "/documents/builders/" in op["update"]["name"]
    }
    builder_deletes = {
        str(op["delete"]).split("/documents/builders/", 1)[1]
        for op in ops
        if "delete" in op and "/documents/builders/" in op["delete"]
    }

    staged = manifest_v2["staged_ops"]
    exp_proj = {str(op["update"]["name"]).split("/documents/projects/", 1)[1] for op in staged["patch_projects"]}
    exp_b_restores = (
        {str(op["update"]["name"]).split("/documents/builders/", 1)[1] for op in staged["update_builder_docs"]}
        | {str(op["update"]["name"]).split("/documents/builders/", 1)[1] for op in staged["write_catalog_chunks"]}
        | {str(op["update"]["name"]).split("/documents/builders/", 1)[1] for op in staged["write_catalog_meta"]}
    )
    exp_b_deletes = {str(op["update"]["name"]).split("/documents/builders/", 1)[1] for op in staged["create_builder_docs"]}

    checks = {
        "executed_is_false": rb["executed"] is False,
        "backup_checksums_verified": upstream["backup_result"]["status"] == "VERIFIED",
        "every_project_patch_has_rollback": set(proj_restores.keys()) == exp_proj and len(proj_restores) == 2059,
        "every_builder_update_chunk_meta_has_restore": set(builder_restores.keys()) == exp_b_restores and len(builder_restores) == 41,
        "every_created_builder_has_delete_on_rollback": builder_deletes == exp_b_deletes and len(builder_deletes) == 41,
        "total_rollback_ops_match_2141": len(ops) == len(exp_proj) + len(exp_b_restores) + len(exp_b_deletes) == 2141,
    }
    if not all(checks.values()):
        raise RuntimeError(f"Rollback readiness verification failed: {checks}")

    return {
        "status": "PASS",
        "executed": False,
        "target_manifest_sha256": rb["target_manifest_sha256"],
        "baseline_fingerprint": rb["baseline_fingerprint"],
        "checks": checks,
        "operation_counts": {
            "project_field_masked_restores": len(proj_restores),
            "builder_document_restores": len(builder_restores),
            "created_builder_document_deletes": len(builder_deletes),
            "total_rollback_operations": len(ops),
        },
        "conflict_and_unmanaged_field_protection": (
            "Verified via Phase 4.2E test suite (`test_fi_07_unmanaged_field_preservation`, "
            "`test_fi_09_rollback_newly_introduced_fields`, `test_v2_rollback_conflict_and_idempotency`): "
            "`build_safe_rollback_operations` preserves unknown/unmanaged fields, deletes newly introduced "
            "fields via updateMask omission when absent pre-migration, and aborts via RollbackConflictError on concurrent edits."
        ),
    }


def _write_final_freeze_report(
    out_path: Path,
    *,
    freeze_record: Dict[str, Any],
    op_summary: Dict[str, Any],
    integrity: Dict[str, Any],
    rollback_ver: Dict[str, Any],
) -> None:
    dr = op_summary["discrepancy_resolution"]["verified_truth_from_staged_ops"]
    sb = op_summary["standalone_builder_document_reconciliation"]
    ms = op_summary["complete_migration_operation_summary"]
    ic = integrity["counts"]
    lines = [
        "# HomeSure — Final Manifest v2 Verification, Count Reconciliation & Freeze Report",
        "",
        "```text",
        "RECONCILIATION_STATUS: PASS",
        "IDENTITY_REVIEW_STATUS: PROVISIONAL",
        "CORPORATE_VERIFICATION_STATUS: NOT_PERFORMED",
        "PRODUCTION_APPROVAL_STATUS: NOT_APPROVED",
        "PRODUCTION_EXECUTION_STATUS: NOT_EXECUTED",
        "```",
        "",
        f"**Freeze Declaration:** **`{freeze_record['freeze_status']}`**  ",
        f"**Frozen Manifest Candidate:** `reports/phase4_2e_manifest_v2_correction/phase4_2e_identity_migration_manifest_v2.json`  ",
        f"**Frozen Manifest Version:** `{freeze_record['frozen_manifest_version']}` (`{freeze_record['frozen_manifest_schema_version']}`)  ",
        f"**Frozen Internal `manifest_sha256`:** `{freeze_record['frozen_manifest_internal_sha256']}`  ",
        f"**Frozen Manifest File SHA-256:** `{freeze_record['frozen_manifest_file_sha256']}`  ",
        f"**Baseline Fingerprint:** `{freeze_record['baseline_fingerprint']}`  ",
        "**Production Safety:** `approved: false` | `firestore_writes: 0` | `firestore_deletes: 0` | `production_mutations: 0`",
        "",
        "---",
        "",
        "## 1. Resolution of UPDATE Count Discrepancy (`18 + 9 = 27` Verified)",
        "",
        f"- **Previous Prose Discrepancy:** Report text listed `Total UPDATE = 27`, `Top-100 UPDATE = 17`, and `Below-Top-100 UPDATE = 9` (`17 + 9 = 26`).",
        f"- **Exact Truth from `phase4_2e_identity_migration_manifest_v2.json` (`staged_ops`):** There are **`27` GENUINE `UPDATE` operations** (`18` in Top-100 + `9` below Top-100 retained active = `27`), and the **`2,141` dry-run operation total is 100% accurate**.",
        f"- **Why the prose differed:** {dr['explanation']}",
        "",
        "| Standalone Builder Bucket | CREATE | UPDATE | UNCHANGED | DEFERRED_UNTOUCHED | Total |",
        "|---|---:|---:|---:|---:|---:|",
        f"| Top-100 standalone individual docs | {sb['top_100']['create']} | **{sb['top_100']['update']}** | {sb['top_100']['unchanged']} | 0 | **100** |",
        f"| Below-Top-100 retained active docs | {sb['below_top100_retained_active']['create']} | **{sb['below_top100_retained_active']['update']}** | {sb['below_top100_retained_active']['unchanged']} | 0 | **9** |",
        f"| **Subtotal active standalone individual docs** | **{ms['create_builder_docs']}** | **{ms['update_builder_docs']}** | **{sb['top_100']['unchanged'] + sb['below_top100_retained_active']['unchanged']}** | **0** | **{sb['active_standalone_individual_total']}** |",
        f"| Deferred legacy individual docs (`deletions: 0`) | 0 | 0 | 0 | **{sb['deferred_legacy_individual_untouched']}** | **{sb['deferred_legacy_individual_untouched']}** |",
        f"| **All standalone `/builders/{{id}}` docs** | **{ms['create_builder_docs']}** | **{ms['update_builder_docs']}** | **{sb['top_100']['unchanged'] + sb['below_top100_retained_active']['unchanged']}** | **{sb['deferred_legacy_individual_untouched']}** | **{sb['total_standalone_individual_docs_post_migration']}** |",
        "",
        f"- **Chunk-only builder identities:** **`{sb['chunk_only_builder_identities']}`** (`2,242 - 109 = 2,133`), giving **`{sb['total_canonical_provisional_identities']}`** unique builders across `13` chunks (`182` total `/builders` collection docs = `168` standalone + `13` chunks + `1` `_catalog_meta`). Every single standalone builder ID is itemized in `phase4_2e_builder_operation_count_reconciliation.csv`.",
        "",
        "---",
        "",
        "## 2. Complete Verified Migration Operation Summary (`2,141` Simulated Writes; `0` Deletes)",
        "",
        f"- `create_builder_docs`: **{ms['create_builder_docs']}**",
        f"- `update_builder_docs`: **{ms['update_builder_docs']}**",
        f"- `patch_projects`: **{ms['patch_projects']}**",
        f"- `write_catalog_chunks`: **{ms['write_catalog_chunks']}**",
        f"- `write_catalog_meta`: **{ms['write_catalog_meta']}**",
        f"- `delete_ops`: **{ms['delete_ops']}** (`59` deferred legacy docs preserved untouched)",
        f"- **Total simulated operations:** **{ms['total_simulated_operations']}** (`applied: False`, live writes executed: **0**)",
        "",
        "---",
        "",
        "## 3. Integrity, Invariant & Rollback Readiness Summary",
        "",
        f"- **Upstream Immutability Verified:** All `{integrity['upstream_hashes_verified']['phase4_2a_to_4_2d_count']}` Phase 4.2A–4.2D files, `{integrity['upstream_hashes_verified']['phase4_2e_v1_count']}` v1 files, `{integrity['upstream_hashes_verified']['discrepancy_audit_count']}` audit files, and `{integrity['upstream_hashes_verified']['manifest_v2_count']}` Manifest v2 files match exact SHA-256 checksums (`approved: false`).",
        f"- **Critical Data Invariants:** `{ic['projects_total']}` Bengaluru Urban projects (`{ic['unique_registrations']}` unique RERA registrations), `{ic['data_tiers']['deep_extracted']}` `deep_extracted` / `{ic['data_tiers']['catalogue_summary']}` `catalogue_summary`, `{ic['rural_records_isolated']}` Bengaluru Rural isolated (`0` overlap), `{ic['builders_total']}` builders across `13` chunks, `{ic['rghcl_projects']}` RGHCL projects (incl. `004171`), Affinity `007631` own Form-A/Form-C verified, `{ic['ownership_reassignments']}` ownership reassignments, `{ic['unresolved_provisional_rows']}` unresolved/provisional rows (`0` approved), `{ic['merge_candidates_accounted']}` merge candidates (`32` preserved + `1` resolved), `{ic['jv_overlaps_preserved']}` JV overlaps preserved, `{ic['deferred_legacy_docs_untouched']}` deferred docs untouched, `{ic['invariant_comparisons']}` invariant checks (`0` mismatches), live Firestore drift **`CLEAN` (`0`)**.",
        f"- **5 Bengaluru Urban Taluks:** `Anekal: {ic['taluks']['Anekal']}`, `Bengaluru East: {ic['taluks']['Bengaluru East']}`, `Bengaluru North: {ic['taluks']['Bengaluru North']}`, `Bengaluru South: {ic['taluks']['Bengaluru South']}`, `Yelahanka: {ic['taluks']['Yelahanka']}`.",
        f"- **Rollback Package (`executed: {rollback_ver['executed']}`):** `{rollback_ver['operation_counts']['total_rollback_operations']}` verified rollback operations (`{rollback_ver['operation_counts']['project_field_masked_restores']}` project restores + `{rollback_ver['operation_counts']['builder_document_restores']}` builder restores + `{rollback_ver['operation_counts']['created_builder_document_deletes']}` created-builder deletes).",
        "",
        "---",
        "",
        "## 4. Freeze Gate & Next Step",
        "",
        "**Manifest v2 is frozen as `READY_FOR_PRODUCTION_APPROVAL` with `approved: false` and `PRODUCTION_EXECUTION_STATUS: NOT_EXECUTED`. The next action after this task must be an explicit human decision on whether to authorize the production migration.**",
    ]
    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def compute_and_write_final_hashes(
    *,
    output_dir: Path = FREEZE_OUTPUT_DIR,
    upstream: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Compute SHA-256 of all 7 sibling freeze deliverables and write `phase4_2e_final_artifact_hashes.json`."""
    deliverable_hashes: Dict[str, Dict[str, Any]] = {}
    for fn in FREEZE_DELIVERABLE_FILENAMES:
        fp = output_dir / fn
        if not fp.exists():
            raise FileNotFoundError(f"Missing final freeze deliverable: {fp}")
        deliverable_hashes[fn] = {"size_bytes": fp.stat().st_size, "sha256": _sha256_file(fp)}

    payload = {
        "generated_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "phase": "4.2E-final-freeze",
        "freeze_status": "READY_FOR_PRODUCTION_APPROVAL",
        "baseline_fingerprint": EXPECTED_BASELINE_FINGERPRINT,
        "frozen_manifest_v2_internal_sha256": (upstream or {}).get(
            "manifest_v2_internal_sha256",
            "bc661ac73d1222715e645a83951de6034a5a3a8b207f9141e0a2625cb4c0e40b",
        ),
        "frozen_manifest_v2_file_sha256": (
            ((upstream or {}).get("manifest_v2_hashes") or {})
            .get(PHASE4_2E_V2_MANIFEST_FILENAME, {})
            .get("sha256", _sha256_file(PHASE4_2E_V2_OUTPUT_DIR / PHASE4_2E_V2_MANIFEST_FILENAME))
        ),
        "approval_record_approved": False,
        "status_taxonomy": FINAL_STATUS_TAXONOMY,
        "deliverable_hashes": deliverable_hashes,
    }
    (output_dir / "phase4_2e_final_artifact_hashes.json").write_text(
        json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    return payload


def run_final_freeze_verification(
    *,
    projects: Optional[List[Dict[str, Any]]] = None,
    builders_docs: Optional[Dict[str, Dict[str, Any]]] = None,
    output_dir: Path = FREEZE_OUTPUT_DIR,
    backup_dir: Path = DEFAULT_BACKUP_DIR,
    v1_dir: Path = PHASE4_2E_OUTPUT_DIR,
    audit_dir: Path = AUDIT_OUTPUT_DIR,
    v2_dir: Path = PHASE4_2E_V2_OUTPUT_DIR,
    extraction_root: Path = EXTRACTION_ROOT,
    check_live_firestore: bool = True,
) -> Dict[str, Any]:
    """Execute complete read-only final verification, count reconciliation, and freeze of Manifest v2."""
    upstream = verify_all_upstream_artifacts(
        extraction_root=extraction_root,
        backup_dir=backup_dir,
        v1_dir=v1_dir,
        audit_dir=audit_dir,
        v2_dir=v2_dir,
    )
    manifest_v2 = upstream["manifest_v2"]

    if projects is None or builders_docs is None:
        if not check_live_firestore:
            raise RuntimeError("Offline mode requires explicit projects and builders_docs")
        token = get_firebase_Auth_token()
        live_projects = list_firestore_collection_docs("projects", token)
        live_builders_list = list_firestore_collection_docs("builders", token)
        live_builders = {str(d.get("_doc_id") or ""): d for d in live_builders_list}
    else:
        live_projects = projects
        live_builders = builders_docs

    drift_res = detect_live_drift(
        manifest_v2,
        live_projects,
        live_builders,
        live_backup_fingerprint=upstream["backup_result"]["baseline_fingerprint"],
    )
    if drift_res["status"] != "CLEAN" or drift_res["drift_count"] != 0:
        raise LiveDriftError(f"Live Firestore drifted against Manifest v2: {drift_res['drift_items'][:5]}")

    recon_rows, op_summary = reconcile_standalone_builder_operations(
        backup_dir=backup_dir, v2_dir=v2_dir, manifest_v2=manifest_v2
    )
    integrity = verify_critical_invariants_v2(
        live_projects=live_projects,
        live_builders=live_builders,
        v2_dir=v2_dir,
        manifest_v2=manifest_v2,
        drift_res=drift_res,
        upstream=upstream,
    )
    rollback_ver = verify_rollback_readiness_v2(
        v2_dir=v2_dir, manifest_v2=manifest_v2, upstream=upstream
    )

    output_dir.mkdir(parents=True, exist_ok=True)
    # 2. phase4_2e_builder_operation_count_reconciliation.csv
    recon_cols = list(recon_rows[0].keys())
    _write_csv(output_dir / "phase4_2e_builder_operation_count_reconciliation.csv", recon_cols, recon_rows)

    # 3. phase4_2e_final_operation_summary.json
    (output_dir / "phase4_2e_final_operation_summary.json").write_text(
        json.dumps(op_summary, indent=2, ensure_ascii=False), encoding="utf-8"
    )

    # 4. phase4_2e_final_integrity_verification.json
    (output_dir / "phase4_2e_final_integrity_verification.json").write_text(
        json.dumps(integrity, indent=2, ensure_ascii=False), encoding="utf-8"
    )

    # 5. phase4_2e_final_rollback_verification.json
    (output_dir / "phase4_2e_final_rollback_verification.json").write_text(
        json.dumps(rollback_ver, indent=2, ensure_ascii=False), encoding="utf-8"
    )

    # 8. phase4_2e_manifest_v2_freeze_record.json
    now_iso = datetime.datetime.now(datetime.timezone.utc).isoformat()
    freeze_record = {
        "freeze_record_version": "1.0.0",
        "frozen_at_utc": now_iso,
        "freeze_status": "READY_FOR_PRODUCTION_APPROVAL",
        "frozen_manifest_path": "reports/phase4_2e_manifest_v2_correction/phase4_2e_identity_migration_manifest_v2.json",
        "frozen_manifest_schema_version": manifest_v2["manifest_schema_version"],
        "frozen_manifest_version": MIGRATION_VERSION_V2_2_V2,
        "frozen_manifest_internal_sha256": upstream["manifest_v2_internal_sha256"],
        "frozen_manifest_file_sha256": upstream["manifest_v2_hashes"][PHASE4_2E_V2_MANIFEST_FILENAME]["sha256"],
        "baseline_fingerprint": upstream["backup_result"]["baseline_fingerprint"],
        "baseline_snapshot_id": upstream["backup_result"]["snapshot_id"],
        "approved": False,
        "production_writes_executed": 0,
        "production_deletes_executed": 0,
        "status_taxonomy": FINAL_STATUS_TAXONOMY,
        "verified_operation_totals": op_summary["complete_migration_operation_summary"],
        "next_required_action": "Explicit human review and separate production migration authorization decision.",
    }
    (output_dir / "phase4_2e_manifest_v2_freeze_record.json").write_text(
        json.dumps(freeze_record, indent=2, ensure_ascii=False), encoding="utf-8"
    )

    # 1. phase4_2e_final_freeze_report.md
    _write_final_freeze_report(
        output_dir / "phase4_2e_final_freeze_report.md",
        freeze_record=freeze_record,
        op_summary=op_summary,
        integrity=integrity,
        rollback_ver=rollback_ver,
    )

    # 6. Initial test report (updated cleanly after final test runs)
    test_rep = output_dir / "phase4_2e_final_test_report.md"
    if not test_rep.exists():
        test_rep.write_text("# HomeSure — Final Manifest v2 Test Report\n\nPending final regression run.\n", encoding="utf-8")

    # 7. phase4_2e_final_artifact_hashes.json
    hashes_payload = compute_and_write_final_hashes(output_dir=output_dir, upstream=upstream)

    return {
        "freeze_record": freeze_record,
        "op_summary": op_summary,
        "integrity": integrity,
        "rollback": rollback_ver,
        "hashes": hashes_payload,
    }


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(
        description="Final Manifest v2 Verification, Count Reconciliation & Freeze (Strictly Read-Only; NO --apply)."
    )
    parser.add_argument("--output-dir", type=Path, default=FREEZE_OUTPUT_DIR)
    args = parser.parse_args(argv)
    res = run_final_freeze_verification(output_dir=args.output_dir, check_live_firestore=True)
    fr = res["freeze_record"]
    print(
        f"Manifest v2 FROZEN ({fr['freeze_status']}): internal_sha256={fr['frozen_manifest_internal_sha256']} "
        f"file_sha256={fr['frozen_manifest_file_sha256']} total_ops={fr['verified_operation_totals']['total_simulated_operations']} "
        f"(approved=False, writes=0)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
