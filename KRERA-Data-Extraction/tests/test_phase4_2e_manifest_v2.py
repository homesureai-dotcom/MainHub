"""
HomeSure Phase 4.2E — Corrected Manifest v2 & Final Readiness Tests (Strictly Read-Only).
"""

from __future__ import annotations

import copy
import csv
import hashlib
import json
import sys
from collections import Counter
from pathlib import Path

import pytest

EXTRACTION_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_ROOT = EXTRACTION_ROOT / "scripts"
FIRESTORE_IMPORT_ROOT = SCRIPTS_ROOT / "firestore_import"
BACKUP_DIR = EXTRACTION_ROOT / "data" / "phase4_2_backup_20261122"
V1_DIR = EXTRACTION_ROOT / "reports" / "phase4_2e_final_reconciliation"
V2_DIR = EXTRACTION_ROOT / "reports" / "phase4_2e_manifest_v2_correction"

for _p in (str(SCRIPTS_ROOT), str(FIRESTORE_IMPORT_ROOT)):
    if _p not in sys.path:
        sys.path.insert(0, _p)

from phase4_2a_hardening import (
    MIGRATION_VERSION_V2_2_V2,
    ManifestValidationError,
    RollbackConflictError,
    build_safe_rollback_operations,
    detect_live_drift,
    load_source_evidence_index,
    validate_migration_manifest,
)
from phase4_2b_verification import ApprovalValidationError, _simulate_project_patches
from phase4_2_builder_sync import apply_migration_manifest
from phase4_2e_discrepancy_audit import verify_all_prior_artifacts_untouched
from phase4_2e_manifest_v2 import (
    AFFINITY_006539_FORM_A_FILE,
    AFFINITY_007631_FORM_A_FILE,
    AFFINITY_007631_PID,
    AFFINITY_007631_REG,
    PHASE4_2E_V2_MANIFEST_FILENAME,
    RGHCL_004171_FORM_A_FILE,
    RGHCL_004171_FORM_C_SHA256,
    RGHCL_004171_PID,
    RGHCL_004171_REG,
    V2_STATUS_SUMMARY,
    main as v2_cli_main,
    resolve_phase4_2e_v2_identities,
)
from phase4_2e_reconciliation import (
    IMMUTABLE_SOURCE_ARTIFACTS,
    VAISHNAVI_HARMONY_CERT_SHA256,
    _load_56_source_evidence_map,
    _load_p42c_flag_sets,
    _simulate_post_builders_map,
    plan_phase4_2e_migration_manifest,
)


def _read_csv(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    assert path.exists() and path.stat().st_size > 0, f"Missing/empty v2 file: {path}"
    with path.open("r", encoding="utf-8", newline="") as fh:
        reader = csv.DictReader(fh)
        return list(reader.fieldnames or []), list(reader)


@pytest.fixture(scope="module")
def v2_offline_fixture():
    b_bak = json.loads((BACKUP_DIR / "builders_backup.json").read_text(encoding="utf-8"))
    builders_docs = {k: {**v, "_doc_id": k} for k, v in b_bak.items()}
    p_bak = json.loads((BACKUP_DIR / "projects_builder_fields_backup.json").read_text(encoding="utf-8"))
    projects = []
    for pid, p in sorted(p_bak.items()):
        pc = dict(p)
        pc["_doc_id"] = pid
        projects.append(pc)
    backup_manifest = json.loads((BACKUP_DIR / "backup_manifest.json").read_text(encoding="utf-8"))
    v1_manifest = json.loads((V1_DIR / "phase4_2e_identity_migration_manifest_v1.json").read_text(encoding="utf-8"))
    _, src_ev_by_pid = _load_56_source_evidence_map()
    sql_ev_idx = load_source_evidence_index(EXTRACTION_ROOT)
    merge_pids, jv_pids, short_pids = _load_p42c_flag_sets()
    resolved_v2 = resolve_phase4_2e_v2_identities(
        projects,
        source_evidence_by_pid=src_ev_by_pid,
        sql_evidence_index=sql_ev_idx,
        merge_pids=merge_pids,
        jv_pids=jv_pids,
        short_pids=short_pids,
    )
    manifest_v2 = plan_phase4_2e_migration_manifest(
        projects,
        builders_docs,
        resolved_v2,
        backup_manifest=backup_manifest,
        predecessor_manifest=v1_manifest,
        source_artifact_hashes=dict(IMMUTABLE_SOURCE_ARTIFACTS),
        generated_at_utc="2026-11-23T12:00:00+00:00",
        migration_version=MIGRATION_VERSION_V2_2_V2,
        manifest_version_label="v2",
        predecessor_path="reports/phase4_2e_final_reconciliation/phase4_2e_identity_migration_manifest_v1.json",
        status_summary=V2_STATUS_SUMMARY,
    )
    return projects, builders_docs, backup_manifest, v1_manifest, manifest_v2, resolved_v2


class TestPhase42EManifestV2Corrections:
    """Verify all 13 v2 deliverables, RGHCL 24-project fix, Affinity 007631 fix, status summary, and prior locks."""

    def test_01_all_13_deliverables_exist_and_hashes_match(self):
        expected_files = [
            PHASE4_2E_V2_MANIFEST_FILENAME,
            "phase4_2e_project_identity_reconciliation_v2.csv",
            "phase4_2e_builder_identity_register_v2.csv",
            "phase4_2e_evidence_decision_register_v2.csv",
            "phase4_2e_unresolved_identity_register_v2.csv",
            "phase4_2e_ownership_reassignment_register_v2.csv",
            "phase4_2e_operation_dry_run_v2.json",
            "phase4_2e_rollback_package_v2.json",
            "phase4_2e_integrity_verification_v2.json",
            "phase4_2e_test_report_v2.md",
            "phase4_2e_final_reconciliation_report_v2.md",
            "phase4_2e_artifact_hashes_v2.json",
            "phase4_2e_v1_to_v2_changelog.md",
        ]
        for fn in expected_files:
            fp = V2_DIR / fn
            assert fp.exists() and fp.stat().st_size > 0, f"Missing/empty v2 deliverable: {fp}"

        hashes_v2 = json.loads((V2_DIR / "phase4_2e_artifact_hashes_v2.json").read_text(encoding="utf-8"))
        assert hashes_v2["approval_record_approved"] is False
        for fn, meta in hashes_v2["deliverable_hashes"].items():
            actual = hashlib.sha256((V2_DIR / fn).read_bytes()).hexdigest()
            assert actual == meta["sha256"], f"v2 artifact hash mismatch for {fn}"

        # Confirm all prior Phase 4.2A-4.2D & Phase 4.2E v1 artifacts remain untouched
        prior = verify_all_prior_artifacts_untouched()
        assert prior["approval_record_approved"] is False

    def test_02_rghcl_exact_24_projects_and_affinity_007631_fixed(self):
        manifest_v2 = json.loads((V2_DIR / PHASE4_2E_V2_MANIFEST_FILENAME).read_text(encoding="utf-8"))
        res = validate_migration_manifest(manifest_v2, allow_deletions=False)
        assert res["status"] == "VALID"
        assert manifest_v2["builders_after"] == 2242
        assert manifest_v2["status_summary"] == V2_STATUS_SUMMARY
        assert manifest_v2["metadata"]["approved"] is False
        assert manifest_v2["deletions_enabled"] is False
        assert manifest_v2["op_counts"]["deferred_stale_individual_builder_docs"] == 59

        _, proj_rows = _read_csv(V2_DIR / "phase4_2e_project_identity_reconciliation_v2.csv")
        _, b_rows = _read_csv(V2_DIR / "phase4_2e_builder_identity_register_v2.csv")
        _, ev_rows = _read_csv(V2_DIR / "phase4_2e_evidence_decision_register_v2.csv")
        _, unres_rows = _read_csv(V2_DIR / "phase4_2e_unresolved_identity_register_v2.csv")
        _, own_rows = _read_csv(V2_DIR / "phase4_2e_ownership_reassignment_register_v2.csv")

        assert len(proj_rows) == 4110
        assert len(b_rows) == 2242
        assert len(ev_rows) == 58
        assert len(unres_rows) == 17
        assert all(r["human_approved"] == "False" for r in unres_rows)
        assert len(own_rows) == 6
        assert Counter(r["reassignment_category"] for r in own_rows) == {
            "SCOPE_A_OWNERSHIP_REASSIGNMENT": 5,
            "AFFINITY_VAISHNAVI_FORM_A_REASSIGNMENT": 1,
        }

        proj_by_id = {r["project_id"]: r for r in proj_rows}
        b_by_id = {r["builder_id"]: r for r in b_rows}
        ev_by_id = {r["project_id"]: r for r in ev_rows}

        # RGHCL exact 24 projects + 004171 preserved official name
        assert b_by_id["builder_rajiv_gandhi_housing"]["project_count"] == "24"
        assert "builder_rajiv_gandhi_housing_corporation_limlted" not in b_by_id
        r4171 = proj_by_id[RGHCL_004171_PID]
        assert r4171["proposed_builder_id"] == "builder_rajiv_gandhi_housing"
        assert r4171["official_promoter_name"] == "Rajiv Gandhi Housing Corporation Limlted"
        assert r4171["form_c_cert_sha256"] == RGHCL_004171_FORM_C_SHA256
        assert r4171["form_a_json_file"] == RGHCL_004171_FORM_A_FILE
        assert r4171["merge_candidate_status"] == "RESOLVED_BY_FORM_A_ACCOUNT_826951"
        assert RGHCL_004171_PID in ev_by_id

        # Affinity 007631 corrected references + 6th ownership row
        r7631 = proj_by_id[AFFINITY_007631_PID]
        assert r7631["proposed_builder_id"] == "builder_affinity_projects"
        assert r7631["form_a_json_file"] == AFFINITY_007631_FORM_A_FILE
        assert r7631["cross_linked_form_a_file"] == AFFINITY_006539_FORM_A_FILE
        assert r7631["form_c_cert_sha256"] == VAISHNAVI_HARMONY_CERT_SHA256
        assert r7631["corporate_verification_status"] == "NOT_PERFORMED"
        assert AFFINITY_007631_PID in ev_by_id

        # Storage layer & tier/taluk invariants
        dry = json.loads((V2_DIR / "phase4_2e_operation_dry_run_v2.json").read_text(encoding="utf-8"))
        sl = dry["builder_storage_layer_breakdown"]
        assert sl["unique_canonical_provisional_identities"] == 2242
        assert sl["standalone_active_individual_docs_total"] + sl["chunk_only_identities"] == 2242
        assert sl["deferred_legacy_individual_docs_untouched"] == 59
        assert dry["applied"] is False and dry["approved"] is False and dry["firestore_writes"] == 0

        report_txt = (V2_DIR / "phase4_2e_final_reconciliation_report_v2.md").read_text(encoding="utf-8")
        for k, v in V2_STATUS_SUMMARY.items():
            assert f"{k}: {v}" in report_txt

        assert Counter(r["data_tier"] for r in proj_rows) == {"deep_extracted": 1022, "catalogue_summary": 3088}
        assert Counter(r["taluk"] for r in proj_rows) == {
            "Anekal": 891,
            "Bengaluru North": 691,
            "Bengaluru East": 1279,
            "Bengaluru South": 1084,
            "Yelahanka": 165,
        }


class TestPhase42EManifestV2FailureAndSafety:
    """Offline failure-injection, rollback, idempotency & no-write tests against Manifest v2."""

    def test_v2_drift_and_schema_rejection(self, v2_offline_fixture):
        projects, builders_docs, _, _, manifest_v2, _ = v2_offline_fixture
        assert detect_live_drift(manifest_v2, projects, builders_docs)["status"] == "CLEAN"
        mut_b = copy.deepcopy(builders_docs)
        mut_b["builder_rajiv_gandhi_housing"]["project_count"] = 999
        assert detect_live_drift(manifest_v2, projects, mut_b)["status"] == "DRIFT_DETECTED"

        bad_m = copy.deepcopy(manifest_v2)
        del bad_m["status_summary"]
        with pytest.raises(ManifestValidationError, match="missing required status_summary"):
            validate_migration_manifest(bad_m)

    def test_v2_rollback_conflict_and_idempotency(self, v2_offline_fixture):
        projects, builders_docs, backup_manifest, v1_manifest, manifest_v2, resolved_v2 = v2_offline_fixture
        sim_post_p = _simulate_project_patches(projects, manifest_v2["staged_ops"]["patch_projects"])
        sim_post_b = _simulate_post_builders_map(builders_docs, manifest_v2)
        rb = build_safe_rollback_operations(BACKUP_DIR, manifest_v2, sim_post_b, sim_post_p)
        assert len(rb["operations"]) == manifest_v2["op_counts"]["total_writes"]

        # Conflict check
        mut_p = copy.deepcopy(sim_post_p)
        for p in mut_p:
            if p["_doc_id"] == RGHCL_004171_PID:
                p["builder_id"] = "concurrent_edit"
                break
        with pytest.raises(RollbackConflictError, match="Rollback aborted"):
            build_safe_rollback_operations(BACKUP_DIR, manifest_v2, sim_post_b, mut_p)

        # Idempotency check on simulated post-v2 state
        m_second = plan_phase4_2e_migration_manifest(
            sim_post_p,
            sim_post_b,
            resolved_v2,
            backup_manifest=backup_manifest,
            predecessor_manifest=v1_manifest,
            source_artifact_hashes=dict(IMMUTABLE_SOURCE_ARTIFACTS),
            generated_at_utc=manifest_v2["generated_at_utc"],
            migration_version=MIGRATION_VERSION_V2_2_V2,
            manifest_version_label="v2",
            predecessor_path="reports/phase4_2e_final_reconciliation/phase4_2e_identity_migration_manifest_v1.json",
            status_summary=V2_STATUS_SUMMARY,
        )
        assert m_second["op_counts"]["total_writes"] == 0

    def test_v2_prohibited_production_write_and_no_apply_cli(self, v2_offline_fixture):
        projects, builders_docs, _, _, manifest_v2, _ = v2_offline_fixture
        unapproved = json.loads((BACKUP_DIR / "phase4_2b_approval_record.json").read_text(encoding="utf-8"))
        assert unapproved["approved"] is False
        with pytest.raises(ApprovalValidationError):
            apply_migration_manifest(
                manifest_v2,
                "fake-token",
                backup_dir=BACKUP_DIR,
                read_state_fn=lambda: (projects, builders_docs),
                commit_fn=lambda ops, tok: None,
                require_human_approval=True,
                approval_record=unapproved,
            )
        with pytest.raises(SystemExit):
            v2_cli_main(["--apply"])
