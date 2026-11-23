"""
HomeSure Phase 4.2A — Comprehensive Hardening, Preflight, Rollback, Recovery & Consumer Safety Tests
Implements all 36 mandatory test requirements (Section 10).
"""

import copy
import hashlib
import json
import sys
from pathlib import Path
from typing import Any, Dict, List

import pytest

EXTRACTION_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = EXTRACTION_ROOT.parent
SCRIPTS_ROOT = EXTRACTION_ROOT / "scripts"
FIRESTORE_IMPORT_ROOT = SCRIPTS_ROOT / "firestore_import"
for p in (str(SCRIPTS_ROOT), str(FIRESTORE_IMPORT_ROOT)):
    if p not in sys.path:
        sys.path.insert(0, p)

from build_and_upload_builders import build_builders_catalog_from_projects, chunk_builders_by_size
from import_projects import FIREBASE_PROJECT_ID, FIRESTORE_DATABASE, firestore_value_to_python, make_firestore_delete_op, python_to_firestore_value
from phase4_2_builder_sync import (
    apply_migration_manifest,
    export_live_backup,
    make_firestore_patch_op,
    plan_migration_operations,
    reconcile_identities_and_ownership,
)
from phase4_2a_hardening import (
    BackupVerificationError,
    CheckpointValidationError,
    CommitCountMismatchError,
    LiveDriftError,
    MISSING_FIELD_SENTINEL,
    ManifestValidationError,
    PostconditionFailureError,
    RollbackConflictError,
    build_deletion_impact_analysis,
    build_evidence_audit,
    build_safe_rollback_operations,
    commit_firestore_writes_verified,
    compute_manifest_sha256,
    detect_live_drift,
    load_source_evidence_index,
    validate_and_load_checkpoint,
    validate_evidence_gate,
    validate_migration_manifest,
    verify_backup_bundle,
)


def _doc_rel(full_name: str) -> str:
    prefix = f"projects/{FIREBASE_PROJECT_ID}/databases/{FIRESTORE_DATABASE}/documents/"
    return full_name[len(prefix) :]


def _apply_firestore_ops(
    store_projects: Dict[str, Dict[str, Any]],
    store_builders: Dict[str, Dict[str, Any]],
    writes: List[Dict[str, Any]],
) -> int:
    """In-memory Firestore REST `documents:commit` simulator supporting `updateMask` field deletion."""
    for w in writes:
        if "delete" in w:
            col, doc_id = _doc_rel(w["delete"]).split("/", 1)
            (store_builders if col == "builders" else store_projects).pop(doc_id, None)
            continue
        upd = w["update"]
        col, doc_id = _doc_rel(upd["name"]).split("/", 1)
        decoded = firestore_value_to_python({"mapValue": {"fields": upd.get("fields", {})}})
        mask_paths = (w.get("updateMask") or {}).get("fieldPaths")
        target = store_builders if col == "builders" else store_projects
        if mask_paths:
            cur = target[doc_id]
            for fp in mask_paths:
                if "." not in fp:
                    if fp in decoded:
                        cur[fp] = copy.deepcopy(decoded[fp])
                    else:
                        cur.pop(fp, None)
                else:
                    top, sub = fp.split(".", 1)
                    if isinstance(decoded.get(top), dict) and sub in decoded[top]:
                        cur.setdefault(top, {})[sub] = copy.deepcopy(decoded[top][sub])
                    elif isinstance(cur.get(top), dict):
                        cur[top].pop(sub, None)
        else:
            doc = copy.deepcopy(decoded)
            doc["_doc_id"] = doc_id
            target[doc_id] = doc
    return len(writes)


def _make_approved_fixture(tmp_path: Path):
    projects = [
        {
            "_doc_id": "proj_sri_sattva",
            "project_id": "proj_sri_sattva",
            "registration_number": "PRM/KA/RERA/1251/310/PR/300625/007883",
            "project_name": "Sri Sri Sattva",
            "officialProjectName": "Sri Sri Sattva",
            "promoter_name": "SRI SUMERU REALTY PRIVATE LIMITED",
            "officialBuilderName": "SRI SUMERU REALTY PRIVATE LIMITED",
            "builder_id": "builder_sattva_group",
            "canonical_builder_name": "Sattva Group (Salarpuria Sattva)",
            "normalizedBuilderName": "Sattva",
            "builderAliases": ["Sattva Group"],
            "is_featured_brand": True,
            "nameNormalizationConfidence": "exact_entity",
            "needsManualReview": False,
            "normalizedTaluk": "Bengaluru North",
            "taluk": "Bengaluru North",
            "district": "Bengaluru Urban",
            "projectAliases": ["Sri Sri Sattva"],
            "provenance": {"data_tier": "deep_extracted"},
            "summary_metrics": {"phi_score": 81.0},
            "search_metadata": {"search_tokens": ["sri", "sattva"], "preserved_sibling": "keep_me"},
        },
        {
            "_doc_id": "proj_missing_fields",
            "project_id": "proj_missing_fields",
            "registration_number": "PRM/KA/RERA/1251/308/PR/200104/000004",
            "project_name": "SOWPARNIKA PRANATHI",
            "officialProjectName": "SOWPARNIKA PRANATHI",
            "promoter_name": "SOWPARNIKA PROJECTS AND INFRASTRUCTURE PRIVATE LIMITED",
            "officialBuilderName": "SOWPARNIKA PROJECTS AND INFRASTRUCTURE PRIVATE LIMITED",
            "builder_id": "builder_sowparnika_projects_and",
            "canonical_builder_name": "Sowparnika Projects And",
            # Deliberately omit `normalizedBuilderName` and `search_metadata.normalized_builder_name_lower`
            # in backup to test missing-field deletion on rollback!
            "builderAliases": [],
            "is_featured_brand": False,
            "nameNormalizationConfidence": "exact_entity",
            "needsManualReview": False,
            "normalizedTaluk": "Anekal",
            "taluk": "Anekal",
            "district": "Bengaluru Urban",
            "projectAliases": ["SOWPARNIKA PRANATHI"],
            "provenance": {"data_tier": "catalogue_summary"},
            "unrelated_top_field": "untouched_value",
            "search_metadata": {"search_tokens": ["sowparnika"], "custom_nested": "keep_nested"},
        },
    ]
    builders_list = build_builders_catalog_from_projects(projects)
    chunks = chunk_builders_by_size(builders_list)
    builders_docs: Dict[str, Any] = {}
    for i, ch in enumerate(chunks, start=1):
        cid = f"_catalog_chunk_{i}"
        builders_docs[cid] = {"_doc_id": cid, "chunk_id": cid, "chunk_index": i, "total_chunks": len(chunks), "builders_count": len(ch), "builders": ch}
    builders_docs["_catalog_meta"] = {
        "_doc_id": "_catalog_meta",
        "meta_id": "_catalog_meta",
        "schema_version": "1.1.0",
        "total_chunks": len(chunks),
        "chunk_ids": [f"_catalog_chunk_{i}" for i in range(1, len(chunks) + 1)],
        "total_builders": len(builders_list),
        "total_projects": len(projects),
        "deep_extracted_projects": 1,
        "catalogue_summary_projects": 1,
        "updated_at": "2026-11-22T00:00:00Z",
    }
    for b in builders_list:
        builders_docs[b["builder_id"]] = {"_doc_id": b["builder_id"], **b}

    bm = export_live_backup(projects, builders_docs, tmp_path)
    plan = plan_migration_operations(
        projects,
        builders_docs,
        backup_manifest=bm,
        backup_dir=tmp_path,
        approved=True,
        approved_by="qa",
        approved_at_utc="2026-11-22T00:00:00Z",
    )
    return projects, builders_docs, bm, plan


# ===========================================================================
# 1–5: Identity and Evidence
# ===========================================================================

class TestIdentityAndEvidenceHardening:
    def test_01_generated_evidence_strings_alone_rejected(self):
        rows = [
            {
                "project_id": "p1",
                "registration_number": "PRM/KA/RERA/1251/310/PR/001",
                "relationship_change": "OWNERSHIP_CHANGE",
                "original_portal_promoter_name": "",
                "normalized_promoter_name": "ABC DEVELOPERS",
                "source_promoter_matches_live": False,
                "source_file": "",
                "source_record_id": "",
                "source_record_hash": "",
                "extraction_timestamp": "",
                "identity_basis": "KRERA_PROMOTER_IDENTITY",
                "corporate_legal_verification_status": "UNVERIFIED_KRERA_PORTAL_ONLY",
                "reason": "Descriptive prose saying builder changed with high confidence.",
            }
        ]
        gate = validate_evidence_gate(rows)
        assert gate["status"] == "BLOCKED"
        assert gate["failure_count"] == 1

    def test_02_missing_source_evidence_forces_manual_review(self):
        recon = {
            "project_rows": [
                {
                    "project_id": "p_nosrc",
                    "registration_number": "PRM/KA/RERA/MISSING/001",
                    "project_name": "MISSING PROJECT",
                    "promoter_name": "MISSING PROMOTER PVT LTD",
                    "existing_builder_id": "builder_old",
                    "corrected_builder_id": "builder_missing_promoter",
                    "relationship_change": "SLUG_CHANGE_ONLY",
                    "confidence_level": "exact_entity",
                    "evidence": "Generated description without source row",
                }
            ],
            "merge_candidates": [],
            "jv_brand_overlaps": [],
            "new_groups": {},
        }
        projs = [{"_doc_id": "p_nosrc", "officialBuilderName": "MISSING PROMOTER PVT LTD"}]
        audit = build_evidence_audit(recon, projs, source_index={})
        assert audit["rows"][0]["assignment_mechanism"] == "MANUAL_REVIEW_REQUIRED"
        assert audit["summary"]["manual_review_required_changes"] == 1
        assert audit["gate"]["status"] == "BLOCKED"

    def test_03_krera_promoter_identity_not_corporate_verification(self):
        rows = [
            {
                "project_id": "p_fake_mca",
                "registration_number": "PRM/KA/RERA/1251/310/PR/002",
                "relationship_change": "SPLIT_ENTITY_SEPARATION",
                "original_portal_promoter_name": "ACME BUILDERS",
                "normalized_promoter_name": "ACME BUILDERS",
                "source_promoter_matches_live": True,
                "source_file": "data/phase4_recovery/phase4_recovery.sqlite",
                "source_record_id": "rec_1",
                "source_record_hash": "a" * 64,
                "extraction_timestamp": "2026-11-22T00:00:00Z",
                "identity_basis": "KRERA_PROMOTER_IDENTITY",
                "corporate_legal_verification_status": "VERIFIED_MCA_CORPORATE",
            }
        ]
        gate = validate_evidence_gate(rows)
        assert gate["status"] == "BLOCKED"
        assert "MCA/GSTIN" in gate["failures"][0]["reason"]

    def test_04_merge_candidates_remain_separate(self):
        p1 = {
            "_doc_id": "p1",
            "project_id": "p1",
            "registration_number": "PRM/KA/RERA/1251/308/PR/01",
            "project_name": "ABHEE ONE",
            "officialProjectName": "ABHEE ONE",
            "promoter_name": "ABHEE VENTURES PRIVATE LIMITED",
            "officialBuilderName": "ABHEE VENTURES PRIVATE LIMITED",
            "builder_id": "builder_abhee_ventures",
            "canonical_builder_name": "Abhee Ventures",
            "normalizedTaluk": "Bengaluru East",
            "provenance": {"data_tier": "deep_extracted"},
        }
        p2 = {
            "_doc_id": "p2",
            "project_id": "p2",
            "registration_number": "PRM/KA/RERA/1251/308/PR/02",
            "project_name": "ABHEE TWO",
            "officialProjectName": "ABHEE TWO",
            "promoter_name": "ABHEEVENTURES LLP",
            "officialBuilderName": "ABHEEVENTURES LLP",
            "builder_id": "builder_abheeventures",
            "canonical_builder_name": "Abheeventures",
            "normalizedTaluk": "Bengaluru East",
            "provenance": {"data_tier": "catalogue_summary"},
        }
        recon = reconcile_identities_and_ownership([p1, p2], {})
        assert len(recon["merge_candidates"]) == 1
        by_pid = {r["project_id"]: r for r in recon["project_rows"]}
        assert by_pid["p1"]["corrected_builder_id"] != by_pid["p2"]["corrected_builder_id"]

    def test_05_jv_overlaps_remain_separate(self):
        p_branded = {
            "_doc_id": "pjv1",
            "project_id": "pjv1",
            "registration_number": "PRM/KA/RERA/1251/309/PR/03",
            "project_name": "VAISHNAVI SERENE",
            "officialProjectName": "VAISHNAVI SERENE",
            "promoter_name": "AFFINITY PROJECTS LLP",
            "officialBuilderName": "AFFINITY PROJECTS LLP",
            "builder_id": "builder_vaishnavi_group",
            "canonical_builder_name": "Vaishnavi Group",
            "normalizedTaluk": "Yelahanka",
            "provenance": {"data_tier": "deep_extracted"},
        }
        p_indep = {
            "_doc_id": "pjv2",
            "project_id": "pjv2",
            "registration_number": "PRM/KA/RERA/1251/309/PR/04",
            "project_name": "AFFINITY MEADOWS",
            "officialProjectName": "AFFINITY MEADOWS",
            "promoter_name": "AFFINITY PROJECTS",
            "officialBuilderName": "AFFINITY PROJECTS",
            "builder_id": "builder_affinity_projects",
            "canonical_builder_name": "Affinity Projects",
            "normalizedTaluk": "Yelahanka",
            "provenance": {"data_tier": "catalogue_summary"},
        }
        recon = reconcile_identities_and_ownership([p_branded, p_indep], {})
        assert len(recon["jv_brand_overlaps"]) == 1
        by_pid = {r["project_id"]: r for r in recon["project_rows"]}
        assert by_pid["pjv1"]["corrected_builder_id"] == "builder_vaishnavi_group"
        assert by_pid["pjv2"]["corrected_builder_id"] == "builder_affinity_projects"


# ===========================================================================
# 6–14: Manifest and Live Drift Protection
# ===========================================================================

class TestManifestAndDriftHardening:
    def test_06_invalid_manifest_schema_rejected(self, tmp_path: Path):
        _, _, _, plan = _make_approved_fixture(tmp_path)
        bad = copy.deepcopy(plan)
        bad["manifest_schema_version"] = "1.0.0"
        with pytest.raises(ManifestValidationError, match="manifest_schema_version"):
            validate_migration_manifest(bad, FIREBASE_PROJECT_ID, FIRESTORE_DATABASE)

        bad2 = copy.deepcopy(plan)
        del bad2["baseline_fingerprint"]
        with pytest.raises(ManifestValidationError, match="Missing required"):
            validate_migration_manifest(bad2, FIREBASE_PROJECT_ID, FIRESTORE_DATABASE)

    def test_07_wrong_firebase_project_id_rejected(self, tmp_path: Path):
        _, _, _, plan = _make_approved_fixture(tmp_path)
        with pytest.raises(ManifestValidationError, match="firebase_project_id"):
            validate_migration_manifest(plan, "wrong-firebase-project", FIRESTORE_DATABASE)

    def test_08_tampered_manifest_hash_rejected(self, tmp_path: Path):
        _, _, _, plan = _make_approved_fixture(tmp_path)
        tampered = copy.deepcopy(plan)
        tampered["op_counts"]["total_writes"] += 1
        with pytest.raises(ManifestValidationError, match="SHA-256 mismatch"):
            validate_migration_manifest(tampered, FIREBASE_PROJECT_ID, FIRESTORE_DATABASE)

    def test_09_unexpected_collection_path_rejected(self, tmp_path: Path):
        _, _, _, plan = _make_approved_fixture(tmp_path)
        bad = copy.deepcopy(plan)
        bad["staged_ops"]["patch_projects"][0]["update"]["name"] = (
            f"projects/{FIREBASE_PROJECT_ID}/databases/{FIRESTORE_DATABASE}/documents/"
            "projects/proj_1/regulatory_tabs/bundle_all"
        )
        bad["manifest_sha256"] = compute_manifest_sha256(bad)
        with pytest.raises(ManifestValidationError, match="Unexpected collection/subcollection"):
            validate_migration_manifest(bad, FIREBASE_PROJECT_ID, FIRESTORE_DATABASE)

    def test_10_forbidden_field_and_conditional_metadata_rejected(self, tmp_path: Path):
        _, _, _, plan = _make_approved_fixture(tmp_path)
        # 10a: regulatory/data_tier field in mask
        bad1 = copy.deepcopy(plan)
        bad1["staged_ops"]["patch_projects"][0]["updateMask"]["fieldPaths"].append("provenance.data_tier")
        bad1["manifest_sha256"] = compute_manifest_sha256(bad1)
        with pytest.raises(ManifestValidationError, match="Forbidden field"):
            validate_migration_manifest(bad1, FIREBASE_PROJECT_ID, FIRESTORE_DATABASE)

        # 10b: search_metadata updated without builder text/alias change
        bad2 = copy.deepcopy(plan)
        bad2["staged_ops"]["patch_projects"][0] = make_firestore_patch_op(
            "projects/proj_sri_sattva",
            {"builder_id": "builder_x", "search_metadata": {"search_tokens": ["x"]}},
            ["builder_id", "search_metadata.search_tokens"],
        )
        bad2["manifest_sha256"] = compute_manifest_sha256(bad2)
        with pytest.raises(ManifestValidationError, match="Conditional search_metadata"):
            validate_migration_manifest(bad2, FIREBASE_PROJECT_ID, FIRESTORE_DATABASE)

    def test_11_unexpected_operation_count_rejected(self, tmp_path: Path):
        _, _, _, plan = _make_approved_fixture(tmp_path)
        bad = copy.deepcopy(plan)
        bad["op_counts"]["patch_projects"] = 999
        bad["manifest_sha256"] = compute_manifest_sha256(bad)
        with pytest.raises(ManifestValidationError, match="Operation count mismatch"):
            validate_migration_manifest(bad, FIREBASE_PROJECT_ID, FIRESTORE_DATABASE)

    def test_12_duplicate_conflicting_operations_rejected(self, tmp_path: Path):
        _, _, _, plan = _make_approved_fixture(tmp_path)
        bad = copy.deepcopy(plan)
        dup = copy.deepcopy(bad["staged_ops"]["patch_projects"][0])
        bad["staged_ops"]["patch_projects"].append(dup)
        bad["op_counts"]["patch_projects"] = len(bad["staged_ops"]["patch_projects"])
        bad["op_counts"]["total_writes"] += 1
        bad["manifest_sha256"] = compute_manifest_sha256(bad)
        with pytest.raises(ManifestValidationError, match="Duplicate/conflicting"):
            validate_migration_manifest(bad, FIREBASE_PROJECT_ID, FIRESTORE_DATABASE)

    def test_13_stale_baseline_fingerprint_rejected(self, tmp_path: Path):
        projects, builders_docs, _, plan = _make_approved_fixture(tmp_path)
        drift = detect_live_drift(plan, projects, builders_docs, live_backup_fingerprint="f" * 64)
        assert drift["status"] == "DRIFT_DETECTED"
        assert drift["drift_items"][0]["severity"] == "CRITICAL"

    def test_14_per_document_old_value_mismatch_drift_detected(self, tmp_path: Path):
        projects, builders_docs, _, plan = _make_approved_fixture(tmp_path)
        drifted_projects = copy.deepcopy(projects)
        drifted_projects[0]["builder_id"] = "builder_someone_changed_live"

        drift = detect_live_drift(plan, drifted_projects, builders_docs)
        assert drift["status"] == "DRIFT_DETECTED"
        assert drift["drift_items"][0]["document_path"] == "projects/proj_sri_sattva"
        assert drift["drift_items"][0]["field_path"] == "builder_id"

        with pytest.raises(LiveDriftError, match="Live Firestore drift detected"):
            apply_migration_manifest(
                plan,
                token="t",
                backup_dir=tmp_path,
                read_state_fn=lambda: (drifted_projects, builders_docs),
                commit_fn=lambda b, _t: len(b),
            )


# ===========================================================================
# 15–22: Backup Integrity and Missing-Field Rollback
# ===========================================================================

class TestBackupAndRollbackHardening:
    def test_15_backup_hash_mismatch_rejected(self, tmp_path: Path):
        _make_approved_fixture(tmp_path)
        (tmp_path / "builders_backup.json").write_text('{"tampered": true}', encoding="utf-8")
        with pytest.raises(BackupVerificationError, match="SHA-256 mismatch"):
            verify_backup_bundle(tmp_path, FIREBASE_PROJECT_ID, FIRESTORE_DATABASE)

    def test_16_missing_backup_file_fails_gate(self, tmp_path: Path):
        _make_approved_fixture(tmp_path)
        (tmp_path / "projects_builder_fields_backup.json").unlink()
        with pytest.raises(BackupVerificationError, match="Missing required backup"):
            verify_backup_bundle(tmp_path, FIREBASE_PROJECT_ID, FIRESTORE_DATABASE)

    def _migrate_and_rollback(self, tmp_path: Path):
        projects, builders_docs, _, plan = _make_approved_fixture(tmp_path)
        store_projects = {p["_doc_id"]: copy.deepcopy(p) for p in projects}
        store_builders = copy.deepcopy(builders_docs)
        apply_migration_manifest(
            plan,
            token="t",
            backup_dir=tmp_path,
            read_state_fn=lambda: (list(store_projects.values()), store_builders),
            commit_fn=lambda b, _t: _apply_firestore_ops(store_projects, store_builders, b),
        )
        rb = build_safe_rollback_operations(
            tmp_path, plan, store_builders, list(store_projects.values())
        )
        _apply_firestore_ops(store_projects, store_builders, rb["operations"])
        return store_projects, rb

    def test_17_rollback_removes_newly_introduced_top_level_field(self, tmp_path: Path):
        store_projects, rb = self._migrate_and_rollback(tmp_path)
        assert "normalizedBuilderName" in rb["deleted_fields_by_project"]["proj_missing_fields"]
        assert "normalizedBuilderName" not in store_projects["proj_missing_fields"]

    def test_18_rollback_removes_newly_introduced_nested_field(self, tmp_path: Path):
        store_projects, rb = self._migrate_and_rollback(tmp_path)
        assert "search_metadata.normalized_builder_name_lower" in rb["deleted_fields_by_project"]["proj_missing_fields"]
        sm = store_projects["proj_missing_fields"]["search_metadata"]
        assert "normalized_builder_name_lower" not in sm
        assert sm["custom_nested"] == "keep_nested"

    def test_19_rollback_restores_existing_fields(self, tmp_path: Path):
        store_projects, _ = self._migrate_and_rollback(tmp_path)
        assert store_projects["proj_missing_fields"]["builder_id"] == "builder_sowparnika_projects_and"
        assert store_projects["proj_sri_sattva"]["builder_id"] == "builder_sattva_group"

    def test_20_rollback_preserves_unrelated_fields(self, tmp_path: Path):
        store_projects, _ = self._migrate_and_rollback(tmp_path)
        assert store_projects["proj_missing_fields"]["unrelated_top_field"] == "untouched_value"
        assert store_projects["proj_sri_sattva"]["summary_metrics"]["phi_score"] == 81.0
        assert store_projects["proj_sri_sattva"]["search_metadata"]["preserved_sibling"] == "keep_me"

    def test_21_rollback_refuses_concurrent_unrelated_changes(self, tmp_path: Path):
        projects, builders_docs, _, plan = _make_approved_fixture(tmp_path)
        store_projects = {p["_doc_id"]: copy.deepcopy(p) for p in projects}
        store_builders = copy.deepcopy(builders_docs)
        apply_migration_manifest(
            plan,
            token="t",
            backup_dir=tmp_path,
            read_state_fn=lambda: (list(store_projects.values()), store_builders),
            commit_fn=lambda b, _t: _apply_firestore_ops(store_projects, store_builders, b),
        )
        # Concurrent edit happens AFTER migration
        store_projects["proj_sri_sattva"]["canonical_builder_name"] = "CONCURRENT ADMIN EDIT"
        with pytest.raises(RollbackConflictError, match="concurrent conflict"):
            build_safe_rollback_operations(tmp_path, plan, store_builders, list(store_projects.values()))

    def test_22_rollback_cannot_delete_unrelated_post_snapshot_docs(self, tmp_path: Path):
        projects, builders_docs, _, plan = _make_approved_fixture(tmp_path)
        store_projects = {p["_doc_id"]: copy.deepcopy(p) for p in projects}
        store_builders = copy.deepcopy(builders_docs)
        apply_migration_manifest(
            plan,
            token="t",
            backup_dir=tmp_path,
            read_state_fn=lambda: (list(store_projects.values()), store_builders),
            commit_fn=lambda b, _t: _apply_firestore_ops(store_projects, store_builders, b),
        )
        # Inject an unrelated builder doc created AFTER the snapshot outside migration
        store_builders["builder_new_post_snapshot_unrelated"] = {
            "_doc_id": "builder_new_post_snapshot_unrelated",
            "builder_id": "builder_new_post_snapshot_unrelated",
            "project_count": 1,
        }
        rb = build_safe_rollback_operations(tmp_path, plan, store_builders, list(store_projects.values()))
        assert "builder_new_post_snapshot_unrelated" in rb["preserved_unrelated_post_snapshot_docs"]
        _apply_firestore_ops(store_projects, store_builders, rb["operations"])
        assert "builder_new_post_snapshot_unrelated" in store_builders


# ===========================================================================
# 23–28: Execution, Commit Verification, Postconditions & Resume Recovery
# ===========================================================================

class TestExecutionAndRecoveryHardening:
    def _simulate_mid_stage_failure(self, tmp_path: Path):
        projects, builders_docs, _, plan = _make_approved_fixture(tmp_path)
        store_projects = {p["_doc_id"]: copy.deepcopy(p) for p in projects}
        store_builders = copy.deepcopy(builders_docs)
        ckpt = tmp_path / "resume_ckpt.json"

        def fail_on_second_project(batch, _t):
            for op in batch:
                name = (op.get("update") or {}).get("name", "")
                if name.endswith("projects/proj_sri_sattva"):
                    raise RuntimeError("Simulated mid-stage partial commit error")
            return _apply_firestore_ops(store_projects, store_builders, batch)

        with pytest.raises(RuntimeError, match="Simulated mid-stage partial commit error"):
            apply_migration_manifest(
                plan,
                token="t",
                backup_dir=tmp_path,
                read_state_fn=lambda: (list(store_projects.values()), store_builders),
                commit_fn=fail_on_second_project,
                batch_size=1,
                checkpoint_path=ckpt,
            )
        return plan, store_projects, store_builders, ckpt

    def test_23_partial_commit_failure_detected(self, tmp_path: Path):
        _, _, _, ckpt = self._simulate_mid_stage_failure(tmp_path)
        assert ckpt.exists()
        saved = json.loads(ckpt.read_text(encoding="utf-8"))
        assert saved["status"] == "IN_PROGRESS"
        assert saved["current_stage"] == "patch_projects"
        assert "projects/proj_missing_fields" in saved["completed_ops"]["patch_projects"]
        assert "projects/proj_sri_sattva" not in saved["completed_ops"]["patch_projects"]

    def test_24_checkpoint_resumes_only_verified_unapplied_ops(self, tmp_path: Path):
        plan, store_projects, store_builders, ckpt = self._simulate_mid_stage_failure(tmp_path)
        applied_on_resume: List[str] = []

        def tracking_resume_commit(batch, _t):
            for op in batch:
                applied_on_resume.append(_doc_rel(op["update"]["name"]))
            return _apply_firestore_ops(store_projects, store_builders, batch)

        res = apply_migration_manifest(
            plan,
            token="t",
            backup_dir=tmp_path,
            read_state_fn=lambda: (list(store_projects.values()), store_builders),
            commit_fn=tracking_resume_commit,
            batch_size=1,
            checkpoint_path=ckpt,
        )
        assert res["status"] == "COMPLETED"
        assert "projects/proj_missing_fields" not in applied_on_resume
        assert "projects/proj_sri_sattva" in applied_on_resume

    def test_25_checkpoint_from_different_manifest_rejected(self, tmp_path: Path):
        projects, builders_docs, bm, plan = _make_approved_fixture(tmp_path)
        ckpt = tmp_path / "wrong_ckpt.json"
        from phase4_2a_hardening import write_verified_checkpoint
        write_verified_checkpoint(
            ckpt,
            {
                "status": "IN_PROGRESS",
                "firebase_project_id": FIREBASE_PROJECT_ID,
                "firestore_database": FIRESTORE_DATABASE,
                "baseline_fingerprint": plan["baseline_fingerprint"],
                "manifest_sha256": "0" * 64,
                "completed_stages": {},
                "completed_ops": {},
            },
        )
        with pytest.raises(CheckpointValidationError, match="different manifest hash"):
            validate_and_load_checkpoint(ckpt, plan)

    def test_26_commit_response_count_mismatch_detected(self):
        fake_writes = [make_firestore_delete_op("builders/a"), make_firestore_delete_op("builders/b")]
        # Server returns only 1 writeResult for 2 submitted writes!
        with pytest.raises(CommitCountMismatchError, match="writeResults count mismatch"):
            commit_firestore_writes_verified(
                fake_writes,
                token="t",
                http_post_fn=lambda _u, _b, _h: (200, json.dumps({"writeResults": [{"updateTime": "now"}]}).encode("utf-8")),
            )

    def test_27_stage_postcondition_failure_halts_subsequent_stages(self, tmp_path: Path):
        projects, builders_docs, _, plan = _make_approved_fixture(tmp_path)
        store_projects = {p["_doc_id"]: copy.deepcopy(p) for p in projects}
        store_builders = copy.deepcopy(builders_docs)

        # Simulate server silently corrupting `provenance.data_tier` during `patch_projects`
        def corrupting_commit(batch, _t):
            n = _apply_firestore_ops(store_projects, store_builders, batch)
            for op in batch:
                if "projects/" in (op.get("update") or {}).get("name", ""):
                    store_projects["proj_sri_sattva"]["provenance"]["data_tier"] = "corrupted_tier"
            return n

        # Assert write_catalog_meta is NEVER reached because patch_projects postcondition fails
        with pytest.raises(PostconditionFailureError, match="Data tier mutation"):
            apply_migration_manifest(
                plan,
                token="t",
                backup_dir=tmp_path,
                read_state_fn=lambda: (list(store_projects.values()), store_builders),
                commit_fn=corrupting_commit,
                expected_invariants={
                    "projects_total": 2,
                    "tier_counts": {"deep_extracted": 1, "catalogue_summary": 1},
                    "taluk_counts": {"Bengaluru North": 1, "Anekal": 1},
                },
            )

    def test_28_deletion_blocked_in_hardening_mode(self, tmp_path: Path):
        _, _, _, plan = _make_approved_fixture(tmp_path)
        with pytest.raises(ManifestValidationError, match="Deletions are disabled"):
            bad = copy.deepcopy(plan)
            bad["staged_ops"]["delete_stale_builders_docs"] = [make_firestore_delete_op("builders/stale_x")]
            bad["op_counts"]["delete_stale_individual_builder_docs"] = 1
            bad["op_counts"]["total_writes"] += 1
            bad["manifest_sha256"] = compute_manifest_sha256(bad)
            validate_migration_manifest(bad, FIREBASE_PROJECT_ID, FIRESTORE_DATABASE, allow_deletions=False)


# ===========================================================================
# 29–31: Builder Consumer Safety
# ===========================================================================

class TestBuilderConsumerSafety:
    def test_29_every_proposed_deletion_in_impact_analysis(self):
        # 2 active below top-100 + 1 replaced old slug + 1 pre-Phase4 orphan
        existing = {
            "builder_top1": {"builder_id": "builder_top1", "project_count": 10},
            "builder_mahesh_g": {"builder_id": "builder_mahesh_g", "builder_name": "Mahesh G", "project_count": 3},
            "builder_replaced_old": {"builder_id": "builder_replaced_old", "builder_name": "Old Slug", "project_count": 2},
            "builder_orphan_legacy": {"builder_id": "builder_orphan_legacy", "builder_name": "Legacy", "project_count": 1},
        }
        corrected = [
            {"builder_id": "builder_top1", "project_count": 10},
            {"builder_id": "builder_mahesh_g", "project_count": 3},
        ]
        impact = build_deletion_impact_analysis(
            existing,
            corrected,
            top100_ids={"builder_top1"},
            existing_chunk_builder_ids={"builder_top1", "builder_mahesh_g", "builder_replaced_old"},
        )
        by_id = {r["builder_id"]: r for r in impact["rows"]}
        assert set(by_id.keys()) == {"builder_mahesh_g", "builder_replaced_old", "builder_orphan_legacy"}
        assert by_id["builder_mahesh_g"]["phase4_2a_decision"] == "RETAIN_ACTIVE_CANONICAL_INDIVIDUAL_DOC"
        assert by_id["builder_replaced_old"]["phase4_2a_decision"] == "DEFER_TO_SEPARATE_APPROVED_CLEANUP"
        assert by_id["builder_orphan_legacy"]["phase4_2a_decision"] == "DEFER_TO_SEPARATE_APPROVED_CLEANUP"

    def test_30_repository_builder_consumer_lookup_paths_verified(self):
        repo_dart = (REPO_ROOT / "lib/features/property/services/property_repository.dart").read_text(encoding="utf-8")
        assert ".collection('builders').doc('_catalog_meta').get()" in repo_dart
        assert ".doc('_catalog_chunk_$chunkIdx')" in repo_dart
        rules = (REPO_ROOT / "firestore.rules").read_text(encoding="utf-8")
        assert "match /builders/{builderId}" in rules

    def test_31_eight_active_canonical_builders_retained_in_indiv_and_chunks(self):
        bdir = EXTRACTION_ROOT / "data/phase4_2_backup_20261122"
        if not (bdir / "projects_builder_fields_backup.json").exists():
            pytest.skip("Live backup directory not present")
        b_raw = json.loads((bdir / "builders_backup.json").read_text(encoding="utf-8"))
        builders_docs = {k: {**v, "_doc_id": k} for k, v in b_raw.items()}
        p_raw = json.loads((bdir / "projects_builder_fields_backup.json").read_text(encoding="utf-8"))
        projects = [{**v, "_doc_id": k} for k, v in p_raw.items()]
        plan = plan_migration_operations(projects, builders_docs, backup_dir=bdir)

        eight_active = {
            "builder_bricks_and_milestones",
            "builder_elite_estates",
            "builder_global_edifice_infra",
            "builder_mahesh_g",
            "builder_maitree_developers",
            "builder_modern_spaaces",
            "builder_monarch",
            "builder_pramodaya_enterprises",
        }
        assert eight_active.issubset(set(plan["retained_active_individual_builder_ids"]))
        assert eight_active.isdisjoint(set(plan["deferred_deletion_candidates"]))
        assert eight_active.issubset(set(plan["expected_canonical_builder_ids"]))
        # Must NEVER appear in delete ops
        assert plan["staged_ops"]["delete_stale_builders_docs"] == []


# ===========================================================================
# 32–36: Live 4,110-Project Dataset & Evidence Invariants
# ===========================================================================

@pytest.fixture(scope="module")
def real_backup_data():
    bdir = EXTRACTION_ROOT / "data/phase4_2_backup_20261122"
    p_file = bdir / "projects_builder_fields_backup.json"
    b_file = bdir / "builders_backup.json"
    if not p_file.exists() or not b_file.exists():
        pytest.skip("Real Phase 4.2 backup files not available")
    p_raw = json.loads(p_file.read_text(encoding="utf-8"))
    b_raw = json.loads(b_file.read_text(encoding="utf-8"))
    projects = [{**v, "_doc_id": k} for k, v in p_raw.items()]
    builders_docs = {k: {**v, "_doc_id": k} for k, v in b_raw.items()}
    recon = reconcile_identities_and_ownership(projects, builders_docs)
    src_idx = load_source_evidence_index(EXTRACTION_ROOT)
    ev = build_evidence_audit(recon, projects, src_idx)
    return projects, builders_docs, recon, ev


class TestRealDatasetInvariants:
    def test_32_dataset_4110_project_ids_unique(self, real_backup_data):
        projects, _, recon, ev = real_backup_data
        pids = [p["_doc_id"] for p in projects]
        assert len(pids) == 4110
        assert len(set(pids)) == 4110
        assert recon["duplicate_project_ids"] == []
        assert ev["gate"]["status"] == "PASS"

    def test_33_dataset_4110_registration_numbers_unique(self, real_backup_data):
        projects, _, recon, _ = real_backup_data
        regs = [p["registration_number"] for p in projects]
        assert len(regs) == 4110
        assert len(set(regs)) == 4110
        assert recon["duplicate_registration_numbers"] == []

    def test_34_dataset_data_tier_counts_preserved(self, real_backup_data):
        projects, _, _, _ = real_backup_data
        deep = sum(1 for p in projects if p["provenance"]["data_tier"] == "deep_extracted")
        cat = sum(1 for p in projects if p["provenance"]["data_tier"] == "catalogue_summary")
        assert deep == 1022
        assert cat == 3088

    def test_35_dataset_taluk_counts_preserved(self, real_backup_data):
        projects, _, _, _ = real_backup_data
        from collections import Counter
        tc = Counter(p["normalizedTaluk"] for p in projects)
        assert dict(tc) == {
            "Anekal": 891,
            "Bengaluru East": 1279,
            "Bengaluru North": 691,
            "Bengaluru South": 1084,
            "Yelahanka": 165,
        }

    def test_36_bengaluru_rural_remains_separate(self, real_backup_data):
        projects, _, _, _ = real_backup_data
        rural_path = EXTRACTION_ROOT / "data/phase4_recovery/bengaluru_rural_snapshot.json"
        if not rural_path.exists():
            pytest.skip("Bengaluru Rural snapshot missing")
        rural_raw = json.loads(rural_path.read_text(encoding="utf-8"))
        rural_list = rural_raw if isinstance(rural_raw, list) else rural_raw.get("records", [])
        rural_regs = {
            str((r or {}).get("registration_number") or (r or {}).get("REGISTRATION NO") or "").strip()
            for r in rural_list
        } - {""}
        urban_regs = {p["registration_number"] for p in projects}
        assert urban_regs.isdisjoint(rural_regs)
        assert all("urban" in (p.get("district") or "").lower() for p in projects)
