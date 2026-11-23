"""
HomeSure Phase 4.2G — Production Execution & Live Post-Migration Verification Tests.
"""

from __future__ import annotations

import csv
import hashlib
import json
import sys
from collections import Counter
from pathlib import Path

EXTRACTION_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_ROOT = EXTRACTION_ROOT / "scripts"
FIRESTORE_IMPORT_ROOT = SCRIPTS_ROOT / "firestore_import"
PHASE4_2G_DIR = EXTRACTION_ROOT / "reports" / "phase4_2g_production_execution"

for _p in (str(SCRIPTS_ROOT), str(FIRESTORE_IMPORT_ROOT)):
    if _p not in sys.path:
        sys.path.insert(0, _p)

from phase4_2f_human_adjudication import _verify_59_prior_artifacts
from phase4_2g_production_execution import (
    EXPECTED_BATCH6_HASHES,
    EXPECTED_FROZEN_MANIFEST_V2_FILE_SHA256,
    EXPECTED_FROZEN_MANIFEST_V2_INTERNAL_SHA256,
    verify_phase4_2f_and_batch6_inputs,
)


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _read_csv(path: Path):
    with path.open("r", encoding="utf-8", newline="") as fh:
        return list(csv.DictReader(fh))


class TestPhase42GProductionExecution:
    """Verify all 13 Phase 4.2G deliverables, Batch 6 decision parity, live post-migration reconciliation, and immutability."""

    def test_01_all_13_deliverables_exist_and_hashes_match(self):
        required = (
            "phase4_2g_execution_authorization.json",
            "phase4_2g_final_execution_manifest.json",
            "phase4_2g_pre_execution_backup_hashes.json",
            "phase4_2g_execution_log.json",
            "phase4_2g_operation_results.csv",
            "phase4_2g_post_migration_reconciliation.json",
            "phase4_2g_builder_identity_verification.csv",
            "phase4_2g_project_membership_verification.csv",
            "phase4_2g_rollback_readiness_report.md",
            "phase4_2g_application_qa_report.md",
            "phase4_2g_test_results.md",
            "phase4_2g_artifact_hashes.json",
            "PHASE_4_2G_PRODUCTION_EXECUTION_FINAL_REPORT.md",
        )
        for fn in required:
            fp = PHASE4_2G_DIR / fn
            assert fp.exists() and fp.stat().st_size > 0, f"Missing/empty deliverable: {fp}"

        hashes = json.loads((PHASE4_2G_DIR / "phase4_2g_artifact_hashes.json").read_text(encoding="utf-8"))
        assert hashes["RECONCILIATION_STATUS"] == "PASS"
        assert hashes["IDENTITY_REVIEW_STATUS"] == "COMPLETE_WITH_PROVISIONAL_IDENTITIES"
        assert hashes["CORPORATE_VERIFICATION_STATUS"] == "NOT_PERFORMED"
        assert hashes["PRODUCTION_APPROVAL_STATUS"] == "APPROVED"
        assert hashes["PRODUCTION_EXECUTION_STATUS"] == "COMPLETED"
        assert len(hashes["deliverable_hashes"]) == 12

        for fn, meta in hashes["deliverable_hashes"].items():
            fp = PHASE4_2G_DIR / fn
            assert _sha256(fp) == meta["sha256"], f"Hash mismatch for {fn}"
            assert fp.stat().st_size == meta["size_bytes"], f"Size mismatch for {fn}"

    def test_02_authorization_and_batch6_decision_binding(self):
        auth = json.loads((PHASE4_2G_DIR / "phase4_2g_execution_authorization.json").read_text(encoding="utf-8"))
        assert auth["approved"] is True
        assert auth["firebase_project_id"] == "homesureai-51893"
        assert auth["PRODUCTION_APPROVAL_STATUS"] == "APPROVED"
        assert auth["PRODUCTION_EXECUTION_STATUS"] == "COMPLETED"
        assert auth["CORPORATE_VERIFICATION_STATUS"] == "NOT_PERFORMED"
        assert auth["frozen_manifest_v2_internal_sha256"] == EXPECTED_FROZEN_MANIFEST_V2_INTERNAL_SHA256
        assert auth["frozen_manifest_v2_file_sha256"] == EXPECTED_FROZEN_MANIFEST_V2_FILE_SHA256
        assert auth["batch6_decision_register_sha256"] == EXPECTED_BATCH6_HASHES[
            "human_adjudication_register_batch6_decisions_applied.csv"
        ]
        assert len(auth["adjudication_batch_references"]) == 6
        assert auth["adjudication_decision_counts"] == {
            "APPROVE": 40,
            "RETAIN_PROVISIONAL": 99,
            "ACKNOWLEDGE_EVIDENCE_RESOLVED": 1,
            "ACKNOWLEDGE_NO_MIGRATION_CHANGE": 23,
            "UNDECIDED": 0,
            "TOTAL": 163,
        }
        assert auth["exact_operation_counts"] == {
            "create_builder_docs": 41,
            "update_builder_docs": 27,
            "patch_projects": 2059,
            "write_catalog_chunks": 13,
            "write_catalog_meta": 1,
            "delete_stale_builders_docs": 0,
            "total_operations": 2141,
        }

    def test_03_operation_results_and_post_migration_live_reconciliation(self):
        op_rows = _read_csv(PHASE4_2G_DIR / "phase4_2g_operation_results.csv")
        assert len(op_rows) == 2164  # 2,141 committed + 23 skipped no-migration-change acknowledgments
        status_counts = Counter(r["status"] for r in op_rows)
        assert dict(status_counts) == {
            "COMMITTED": 2141,
            "SKIPPED_NO_MIGRATION_CHANGE": 23,
        }

        recon = json.loads((PHASE4_2G_DIR / "phase4_2g_post_migration_reconciliation.json").read_text(encoding="utf-8"))
        assert recon["RECONCILIATION_STATUS"] == "PASS"
        assert recon["IDENTITY_REVIEW_STATUS"] == "COMPLETE_WITH_PROVISIONAL_IDENTITIES"
        assert recon["CORPORATE_VERIFICATION_STATUS"] == "NOT_PERFORMED"
        assert recon["PRODUCTION_APPROVAL_STATUS"] == "APPROVED"
        assert recon["PRODUCTION_EXECUTION_STATUS"] == "COMPLETED"

        pc = recon["project_catalogue"]
        assert pc["total_projects"] == 4110
        assert pc["unique_registration_numbers"] == 4110
        assert pc["duplicate_registrations"] == 0
        assert pc["orphaned_project_to_builder_references"] == 0
        assert pc["project_builder_mismatches"] == 0
        assert pc["deep_extracted_projects"] == 1022
        assert pc["catalogue_summary_projects"] == 3088
        assert pc["bengaluru_rural_records_separate"] == 730
        assert pc["bengaluru_rural_urban_overlap"] == 0

        bc = recon["builder_catalogue"]
        assert bc["total_canonical_provisional_builders_in_chunks"] == 2242
        assert bc["catalog_chunks_count"] == 13
        assert bc["missing_builder_ids"] == 0
        assert bc["duplicate_builder_ids_in_chunks"] == 0
        assert bc["builder_membership_mismatches"] == 0
        assert bc["active_standalone_builder_docs"] == 109
        assert bc["deferred_legacy_builder_docs_untouched"] == 59
        assert bc["deferred_legacy_builder_docs_mutated"] == 0
        assert bc["total_builders_collection_docs"] == 182

        hd = recon["human_decisions_verification"]
        assert hd["total_adjudication_records_verified"] == 163
        assert hd["approved_applied"] == 40
        assert hd["retain_provisional_applied_and_separate"] == 99
        assert hd["acknowledge_evidence_resolved_verified"] == 1
        assert hd["acknowledge_no_migration_change_verified"] == 23
        assert hd["undecided_cases"] == 0
        assert hd["failures"] == []

        assert recon["project_geography_taluks"] == {
            "Anekal": 891,
            "Bengaluru East": 1279,
            "Bengaluru North": 691,
            "Bengaluru South": 1084,
            "Yelahanka": 165,
        }
        assert all(recon["specific_identity_preservation_checks"].values()) is True
        assert recon["live_rollback_readiness"]["conflict_free_against_live_post_migration_state"] is True
        assert recon["live_rollback_readiness"]["generated_rollback_operations_count"] == 2141

        b_rows = _read_csv(PHASE4_2G_DIR / "phase4_2g_builder_identity_verification.csv")
        p_rows = _read_csv(PHASE4_2G_DIR / "phase4_2g_project_membership_verification.csv")
        assert len(b_rows) == 2242
        assert all(r["verification_status"] == "PASS" for r in b_rows)
        assert len(p_rows) == 4110
        assert all(r["membership_verified"] == "True" for r in p_rows)

    def test_04_historical_artifacts_remain_untouched(self):
        prior_59 = _verify_59_prior_artifacts()
        assert prior_59["total_verified"] == 59
        assert prior_59["upstream"]["approval_record_approved"] is False
        b6 = verify_phase4_2f_and_batch6_inputs()
        assert b6["phase4_2f_prep_verified_count"] == 6
