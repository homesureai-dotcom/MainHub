"""
HomeSure Phase 4.2E — Final Rollback Operation Mapping Audit Verification Tests (Strictly Read-Only).
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
AUDIT_DIR = EXTRACTION_ROOT / "reports" / "phase4_2e_final_rollback_mapping_audit"
FREEZE_DIR = EXTRACTION_ROOT / "reports" / "phase4_2e_final_freeze"
V2_DIR = EXTRACTION_ROOT / "reports" / "phase4_2e_manifest_v2_correction"
BACKUP_DIR = EXTRACTION_ROOT / "data" / "phase4_2_backup_20261122"

for _p in (str(SCRIPTS_ROOT), str(FIRESTORE_IMPORT_ROOT)):
    if _p not in sys.path:
        sys.path.insert(0, _p)

from phase4_2e_final_freeze import verify_all_upstream_artifacts
from phase4_2e_rollback_mapping_audit import (
    _verify_freeze_deliverables,
    main as audit_cli_main,
)


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class TestPhase42ERollbackMappingAudit:
    """Verify 2,141-row rollback bijection, category reconciliation, hashes, safety, and immutability."""

    def test_01_all_4_deliverables_exist_and_hashes_match(self):
        required = (
            "rollback_operation_mapping.csv",
            "rollback_operation_category_summary.json",
            "rollback_coverage_verification.md",
            "rollback_mapping_audit_hashes.json",
        )
        for fn in required:
            fp = AUDIT_DIR / fn
            assert fp.exists() and fp.stat().st_size > 0, f"Missing/empty deliverable: {fp}"

        hashes = json.loads((AUDIT_DIR / "rollback_mapping_audit_hashes.json").read_text(encoding="utf-8"))
        assert hashes["rollback_mapping_status"] == "PASS"
        assert hashes["declaration"] == "ROLLBACK_MAPPING_STATUS: PASS"
        assert hashes["approval_record_approved"] is False
        assert hashes["rollback_package_executed"] is False
        assert hashes["firestore_writes_executed"] == 0

        for fn, meta in hashes["deliverable_hashes"].items():
            fp = AUDIT_DIR / fn
            assert _sha256(fp) == meta["sha256"], f"Hash mismatch for {fn}"
            assert fp.stat().st_size == meta["size_bytes"], f"Size mismatch for {fn}"

    def test_02_exact_2141_row_bijection_and_payload_parity(self):
        with (AUDIT_DIR / "rollback_operation_mapping.csv").open("r", encoding="utf-8", newline="") as fh:
            rows = list(csv.DictReader(fh))

        assert len(rows) == 2141
        assert len({r["forward_op_id"] for r in rows}) == 2141
        assert len({r["rollback_op_id"] for r in rows}) == 2141
        assert len({r["rollback_op_index"] for r in rows}) == 2141
        assert len({r["target_firestore_path"] for r in rows}) == 2141

        assert all(r["verification_result"] == "PASS" for r in rows)

        fwd_counts = Counter(r["forward_stage"] for r in rows)
        assert dict(fwd_counts) == {
            "create_builder_docs": 41,
            "update_builder_docs": 27,
            "patch_projects": 2059,
            "write_catalog_chunks": 13,
            "write_catalog_meta": 1,
        }

        rb_counts = Counter(r["rollback_op_type"] for r in rows)
        assert dict(rb_counts) == {
            "created_builder_delete": 41,
            "updated_builder_full_restore": 27,
            "project_field_masked_restore": 2059,
            "catalog_chunk_full_restore": 13,
            "catalog_meta_full_restore": 1,
        }

        for r in rows:
            if r["forward_stage"] == "create_builder_docs":
                assert r["original_state_status"] == "ABSENT_PRE_MIGRATION"
                assert r["original_state_sha256"] == "ABSENT"
                assert r["rollback_wire_action"] == "delete"
                assert r["rollback_effect"] == "DELETE_CREATED_BUILDER"
                assert r["rollback_payload_sha256"] == "DELETE"
            else:
                assert r["original_state_status"] == "PRESENT_IN_BACKUP"
                assert len(r["original_state_sha256"]) == 64
                assert r["original_state_sha256"] == r["rollback_payload_sha256"]

    def test_03_category_reconciliation_and_markdown_consistency(self):
        summary = json.loads((AUDIT_DIR / "rollback_operation_category_summary.json").read_text(encoding="utf-8"))
        assert summary["rollback_mapping_status"] == "PASS"
        assert summary["declaration"] == "ROLLBACK_MAPPING_STATUS: PASS"
        assert all(summary["acceptance_criteria"].values()) is True

        rec = summary["builder_restore_reconciliation"]
        assert rec["coarse_report_builder_document_restores"] == 41
        assert rec["updated_individual_builders_total"] == 27
        assert rec["top_100_updated_builders"] == 18
        assert rec["below_top_100_retained_active_updated_builders"] == 9
        assert rec["catalog_chunks_restored"] == 13
        assert rec["catalog_meta_restored"] == 1
        assert rec["math_check"] == "27 + 13 + 1 = 41"
        assert rec["genuine_functional_mismatch"] is False

        mask_total = sum(entry["count"] for entry in summary["project_update_mask_distribution"])
        assert mask_total == 2059

        cp = summary["conflict_protection_validation"]
        assert cp["simulated_in_memory_only"] is True
        assert cp["firestore_writes_executed"] == 0
        assert cp["all_conflict_and_safety_checks_passed"] is True

        md_txt = (AUDIT_DIR / "rollback_coverage_verification.md").read_text(encoding="utf-8")
        for needle in (
            "ROLLBACK_MAPPING_STATUS: PASS",
            "2,141",
            "41",
            "27",
            "2,059",
            "13",
            "1",
            "approved: false",
            "4,282",
        ):
            if needle == "4,282":
                assert needle not in md_txt, "Markdown total bug must not appear"
            else:
                assert needle in md_txt

    def test_04_frozen_upstream_and_freeze_artifacts_untouched_and_cli_no_apply(self):
        upstream = verify_all_upstream_artifacts(backup_dir=BACKUP_DIR, v2_dir=V2_DIR)
        assert upstream["approval_record_approved"] is False
        freeze = _verify_freeze_deliverables(freeze_dir=FREEZE_DIR)
        assert freeze["verified_count"] == 8

        hashes = json.loads((AUDIT_DIR / "rollback_mapping_audit_hashes.json").read_text(encoding="utf-8"))
        refs = hashes["frozen_references"]
        assert refs["manifest_v2_internal_sha256"] == upstream["manifest_v2_internal_sha256"]
        assert refs["rollback_package_v2_sha256"] == _sha256(V2_DIR / "phase4_2e_rollback_package_v2.json")
        assert refs["freeze_record_sha256"] == _sha256(FREEZE_DIR / "phase4_2e_manifest_v2_freeze_record.json")

        for flag in ("--apply", "--execute", "--rollback"):
            assert audit_cli_main([flag]) == 2
