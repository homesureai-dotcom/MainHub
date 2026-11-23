"""
HomeSure Phase 4.2E — Final Manifest v2 Verification & Freeze Tests (Strictly Read-Only).
"""

from __future__ import annotations

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
FREEZE_DIR = EXTRACTION_ROOT / "reports" / "phase4_2e_final_freeze"

for _p in (str(SCRIPTS_ROOT), str(FIRESTORE_IMPORT_ROOT)):
    if _p not in sys.path:
        sys.path.insert(0, _p)

from phase4_2e_final_freeze import (
    FINAL_STATUS_TAXONOMY,
    main as freeze_cli_main,
    verify_all_upstream_artifacts,
)


class TestPhase42EFinalFreeze:
    """Verify all 8 freeze deliverables, exact 18+9=27 UPDATE reconciliation, and immutable upstream locks."""

    def test_01_all_8_freeze_deliverables_exist_and_hashes_match(self):
        expected = [
            "phase4_2e_final_freeze_report.md",
            "phase4_2e_builder_operation_count_reconciliation.csv",
            "phase4_2e_final_operation_summary.json",
            "phase4_2e_final_integrity_verification.json",
            "phase4_2e_final_rollback_verification.json",
            "phase4_2e_final_test_report.md",
            "phase4_2e_final_artifact_hashes.json",
            "phase4_2e_manifest_v2_freeze_record.json",
        ]
        for fn in expected:
            fp = FREEZE_DIR / fn
            assert fp.exists() and fp.stat().st_size > 0, f"Missing/empty freeze file: {fp}"

        hashes_doc = json.loads((FREEZE_DIR / "phase4_2e_final_artifact_hashes.json").read_text(encoding="utf-8"))
        assert hashes_doc["approval_record_approved"] is False
        assert hashes_doc["freeze_status"] == "READY_FOR_PRODUCTION_APPROVAL"
        for fn, meta in hashes_doc["deliverable_hashes"].items():
            actual = hashlib.sha256((FREEZE_DIR / fn).read_bytes()).hexdigest()
            assert actual == meta["sha256"], f"Final freeze hash mismatch for {fn}"

        # Verify ALL 47 upstream immutable artifacts (4.2A-4.2D, v1, audit, v2) remain untouched
        up = verify_all_upstream_artifacts()
        assert up["phase4_2a_to_4_2d_verified_count"] == 17
        assert up["phase4_2e_v1_verified_count"] == 12
        assert up["discrepancy_audit_verified_count"] == 5
        assert up["manifest_v2_verified_count"] == 13
        assert up["approval_record_approved"] is False

    def test_02_update_count_reconciles_18_plus_9_equals_27(self):
        with (FREEZE_DIR / "phase4_2e_builder_operation_count_reconciliation.csv").open("r", encoding="utf-8", newline="") as fh:
            rows = list(csv.DictReader(fh))
        assert len(rows) == 168

        pairs = Counter((r["standalone_tier"], r["operation_category"]) for r in rows)
        assert pairs == {
            ("TOP_100", "CREATE"): 41,
            ("TOP_100", "UPDATE"): 18,
            ("TOP_100", "UNCHANGED"): 41,
            ("BELOW_TOP_100_RETAINED_ACTIVE", "UPDATE"): 9,
            ("DEFERRED_LEGACY_UNTOUCHED", "DEFERRED_UNTOUCHED"): 59,
        }

        summary = json.loads((FREEZE_DIR / "phase4_2e_final_operation_summary.json").read_text(encoding="utf-8"))
        truth = summary["discrepancy_resolution"]["verified_truth_from_staged_ops"]
        assert truth["top_100_update"] == 18
        assert truth["below_top100_update"] == 9
        assert truth["total_genuine_updates"] == 27

        ops = summary["complete_migration_operation_summary"]
        assert ops["create_builder_docs"] == 41
        assert ops["update_builder_docs"] == 27
        assert ops["patch_projects"] == 2059
        assert ops["write_catalog_chunks"] == 13
        assert ops["write_catalog_meta"] == 1
        assert ops["delete_ops"] == 0
        assert ops["total_simulated_operations"] == 2141
        assert ops["matches_v2_dry_run_total"] is True

    def test_03_integrity_rollback_freeze_and_status_tokens(self):
        integ = json.loads((FREEZE_DIR / "phase4_2e_final_integrity_verification.json").read_text(encoding="utf-8"))
        assert integ["status"] == "PASS"
        assert all(integ["checks"].values())

        rb = json.loads((FREEZE_DIR / "phase4_2e_final_rollback_verification.json").read_text(encoding="utf-8"))
        assert rb["status"] == "PASS" and rb["executed"] is False
        assert rb["operation_counts"]["total_rollback_operations"] == 2141

        fr = json.loads((FREEZE_DIR / "phase4_2e_manifest_v2_freeze_record.json").read_text(encoding="utf-8"))
        assert fr["freeze_status"] == "READY_FOR_PRODUCTION_APPROVAL"
        assert fr["approved"] is False
        assert fr["production_writes_executed"] == 0
        assert fr["production_deletes_executed"] == 0
        assert fr["frozen_manifest_internal_sha256"] == "bc661ac73d1222715e645a83951de6034a5a3a8b207f9141e0a2625cb4c0e40b"
        assert fr["frozen_manifest_file_sha256"] == "ec48a1d5e56f6de1c1ef55a0e43cb20daf578af67426ea5773af53545bad332f"
        assert fr["status_taxonomy"] == FINAL_STATUS_TAXONOMY

        rep_txt = (FREEZE_DIR / "phase4_2e_final_freeze_report.md").read_text(encoding="utf-8")
        for token in (
            "RECONCILIATION_STATUS: PASS",
            "IDENTITY_REVIEW_STATUS: PROVISIONAL",
            "CORPORATE_VERIFICATION_STATUS: NOT_PERFORMED",
            "PRODUCTION_APPROVAL_STATUS: NOT_APPROVED",
            "PRODUCTION_EXECUTION_STATUS: NOT_EXECUTED",
            "READY_FOR_PRODUCTION_APPROVAL",
        ):
            assert token in rep_txt

        with pytest.raises(SystemExit):
            freeze_cli_main(["--apply"])
