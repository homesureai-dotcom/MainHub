"""
HomeSure Phase 4.2F — Human Adjudication Preparation Verification Tests (Strictly Read-Only).
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
PHASE4_2F_DIR = EXTRACTION_ROOT / "reports" / "phase4_2f_human_adjudication"

for _p in (str(SCRIPTS_ROOT), str(FIRESTORE_IMPORT_ROOT)):
    if _p not in sys.path:
        sys.path.insert(0, _p)

from phase4_2f_human_adjudication import (
    _verify_59_prior_artifacts,
    main as phase4_2f_cli_main,
)


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _read_csv(path: Path):
    with path.open("r", encoding="utf-8", newline="") as fh:
        return list(csv.DictReader(fh))


class TestPhase42FHumanAdjudication:
    """Verify all 6 Phase 4.2F deliverables, population reconciliation, zero pre-filled decisions, and immutability."""

    def test_01_all_6_deliverables_exist_and_hashes_match(self):
        expected = (
            "human_adjudication_register.csv",
            "human_adjudication_summary.json",
            "business_signoff_queue.csv",
            "unresolved_evidence_queue.csv",
            "phase4_2f_review_and_approval_report.md",
            "phase4_2f_artifact_hashes.json",
        )
        for fn in expected:
            fp = PHASE4_2F_DIR / fn
            assert fp.exists() and fp.stat().st_size > 0, f"Missing/empty deliverable: {fp}"

        hashes = json.loads((PHASE4_2F_DIR / "phase4_2f_artifact_hashes.json").read_text(encoding="utf-8"))
        assert hashes["HUMAN_ADJUDICATION_PREPARATION_STATUS"] == "PASS"
        assert hashes["PRODUCTION_APPROVAL_STATUS"] == "NOT_APPROVED"
        assert hashes["PRODUCTION_EXECUTION_STATUS"] == "NOT_EXECUTED"
        assert hashes["approval_record_approved"] is False
        assert hashes["firestore_writes_executed"] == 0

        for fn, meta in hashes["deliverable_hashes"].items():
            fp = PHASE4_2F_DIR / fn
            assert _sha256(fp) == meta["sha256"], f"Hash mismatch for {fn}"
            assert fp.stat().st_size == meta["size_bytes"], f"Size mismatch for {fn}"

    def test_02_population_reconciliation_and_no_fabricated_approvals(self):
        reg = _read_csv(PHASE4_2F_DIR / "human_adjudication_register.csv")
        bsq = _read_csv(PHASE4_2F_DIR / "business_signoff_queue.csv")
        unq = _read_csv(PHASE4_2F_DIR / "unresolved_evidence_queue.csv")

        assert len(reg) == 163
        assert len({r["project_id"] for r in reg}) == 163
        assert len({r["adjudication_id"] for r in reg}) == 163
        assert len(bsq) == 55
        assert len({r["project_id"] for r in bsq}) == 55
        assert len(unq) == 17
        assert len({r["project_id"] for r in unq}) == 17

        bs_54_rows = [r for r in reg if r["in_4_2d_business_signoff_54"] == "True"]
        un_17_rows = [r for r in reg if r["in_4_2e_unresolved_17"] == "True"]
        overlap_rows = [
            r for r in reg if r["in_4_2d_business_signoff_54"] == "True" and r["in_4_2e_unresolved_17"] == "True"
        ]
        assert len(bs_54_rows) == 54
        assert len(un_17_rows) == 17
        assert len(overlap_rows) == 15

        changed_cnt = Counter(r["changed_in_firestore"] for r in reg)
        assert dict(changed_cnt) == {"True": 140, "False": 23}

        # Confirm zero fabricated human approvals across all 3 CSVs and full evidence traceability
        for dataset in (reg, bsq, unq):
            for r in dataset:
                assert r["human_decision"] == ""
                assert r["reviewer"] == ""
                assert r["approval_date"] == ""
                assert r["comments"] == ""
                assert r["corporate_verification_status"] == "NOT_PERFORMED"
                assert r["supporting_source_evidence"].strip() != ""
                assert r["source_file_references"].strip() != ""
                assert r["official_krera_promoter_name"].strip() != ""
                assert r["canonical_display_name"].strip() != ""
                assert r["human_decision_allowed_values"] == "APPROVE | REJECT | RETAIN_PROVISIONAL"

        # All 17 UN_17 records can remain provisionally separate without blocking migration
        assert all(r["can_remain_provisional_without_blocking"] == "True" for r in unq)

    def test_03_summary_and_report_consistency(self):
        summary = json.loads((PHASE4_2F_DIR / "human_adjudication_summary.json").read_text(encoding="utf-8"))
        assert summary["HUMAN_ADJUDICATION_PREPARATION_STATUS"] == "PASS"
        assert summary["PRODUCTION_APPROVAL_STATUS"] == "NOT_APPROVED"
        assert summary["PRODUCTION_EXECUTION_STATUS"] == "NOT_EXECUTED"
        assert summary["CORPORATE_VERIFICATION_STATUS"] == "NOT_PERFORMED"
        assert all(summary["acceptance_criteria"].values()) is True

        pop = summary["population_reconciliation"]
        assert pop["bs_54_count"] == 54
        assert pop["un_17_count"] == 17
        assert pop["bs_un_overlap_count"] == 15
        assert pop["bs_only_count"] == 39
        assert pop["un_only_count"] == 2
        assert pop["bs_union_un_count"] == 56
        assert pop["v2_added_ownership_count"] == 1
        assert pop["business_signoff_queue_count"] == 55
        assert pop["total_cases_reviewed"] == 163
        assert pop["unflagged_projects_count"] == 3947
        assert pop["total_projects"] == 4110
        assert pop["total_patched_in_manifest_v2"] == 2059

        app = summary["approval_summary"]
        assert app["total_cases_reviewed"] == 163
        assert app["approved_decisions"] == 0
        assert app["rejected_decisions"] == 0
        assert app["provisional_decisions"] == 0
        assert app["pending_human_decisions"] == 163
        assert app["cases_awaiting_business_signoff"] == 55
        assert app["cases_awaiting_additional_evidence"] == 17
        assert app["cases_safe_to_remain_provisional_non_blocking"] == 99
        assert app["cases_with_no_impact_on_proposed_migration"] == 23
        assert len(app["remaining_blockers_to_production_approval"]) >= 4

        md = (PHASE4_2F_DIR / "phase4_2f_review_and_approval_report.md").read_text(encoding="utf-8")
        for token in (
            "HUMAN_ADJUDICATION_PREPARATION_STATUS: PASS",
            "PRODUCTION_APPROVAL_STATUS: NOT_APPROVED",
            "PRODUCTION_EXECUTION_STATUS: NOT_EXECUTED",
            "approved: false",
            "163",
            "55",
            "17",
            "15",
            "99",
            "23",
            "4,110",
        ):
            assert token in md

    def test_04_59_frozen_prior_artifacts_untouched_and_cli_no_write(self):
        prior = _verify_59_prior_artifacts()
        assert prior["total_verified"] == 59
        assert prior["upstream"]["approval_record_approved"] is False
        assert prior["rollback_audit"]["summary"]["rollback_mapping_status"] == "PASS"

        for flag in ("--apply", "--execute", "--approve", "--auto-approve"):
            assert phase4_2f_cli_main([flag]) == 2
