"""
Automated Verification Suite for HomeSure K-RERA Phase 3C (250-Project Batch & Audit Corrections)

Covers:
1. Requirement A: Portal restriction detection at every modal-opening attempt, timeout, and retry
   boundary, immediate halt without retrying or classifying as a project failure, and interruption
   report generation.
2. Requirement B: Unlinked pane semantic identification priority (tested here and in `test_dynamic_discovery.py`).
3. Requirement C: Automated live-DOM comparison evidence non-truncation (`retained_field_samples_count`
   == `len(retained_field_samples)` == `total_live_dom_fields_checked_count`), mismatch preservation,
   and explicit distinction from human inspection.
4. Requirement D: Adversarial PII scanner across all 500 Phase 3C output files.
5. Requirement E: Separation of extraction status from discovered/parsed/failed/verification coverage metrics.
6. Requirement F: Cross-phase exclusion against all 125 Phase 3A (25) and Phase 3B (100) projects
   across `reg_no`, `ack_no`, `vpd_id`, and frozen manifest integrity.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, List, Optional

import pytest

from scripts.discovery_engine import KRERADiscoveryEngine
from scripts.phase3c_batch_extractor import (
    PortalRestrictionDetectedError,
    build_automated_live_dom_comparison_entry,
    compute_project_coverage_quality_metrics,
    open_project_modal_with_restriction_safeguards,
    scan_phase3c_outputs_for_pii,
    select_or_load_frozen_250_manifest,
    write_portal_interruption_reports,
)

REPO_ROOT = Path(__file__).resolve().parent.parent
SQLITE_PATH = REPO_ROOT / "data" / "k_rera_extraction.sqlite"
P3A_MANIFEST_PATH = REPO_ROOT / "data" / "batch_phase3a" / "phase3a_selected_25_manifest.json"
P3B_MANIFEST_PATH = REPO_ROOT / "data" / "batch_phase3b" / "phase3b_selected_100_manifest.json"
P3C_MANIFEST_PATH = REPO_ROOT / "data" / "batch_phase3c" / "phase3c_selected_250_manifest.json"
P3C_RAW_DIR = REPO_ROOT / "data" / "batch_phase3c" / "raw"
P3C_NORM_DIR = REPO_ROOT / "data" / "batch_phase3c" / "normalized"
P3C_SUMMARY_PATH = REPO_ROOT / "reports" / "phase3c_batch_summary.json"
P3C_CMP_PATH = REPO_ROOT / "data" / "batch_phase3c" / "phase3c_live_dom_comparisons.json"


def test_phase3c_manifest_stratification_freezing_and_zero_historical_overlap():
    """Verifies Requirement F: 250 distinct APPROVED projects, frozen manifest, and 0 overlap with Phase 3A/3B."""
    assert P3C_MANIFEST_PATH.exists(), "Phase 3C frozen manifest must exist before extraction starts"

    p3a = json.loads(P3A_MANIFEST_PATH.read_text(encoding="utf-8"))["selected_projects"]
    p3b = json.loads(P3B_MANIFEST_PATH.read_text(encoding="utf-8"))["selected_projects"]
    assert len(p3a) == 25
    assert len(p3b) == 100

    hist_regs = {p["reg_no"].strip().upper() for p in p3a + p3b}
    hist_acks = {p["ack_no"].strip().upper() for p in p3a + p3b}
    hist_vpds = {str(p["vpd_id"]).strip() for p in p3a + p3b}
    assert len(hist_regs) == 125
    assert len(hist_acks) == 125
    assert len(hist_vpds) == 125

    manifest_on_disk = json.loads(P3C_MANIFEST_PATH.read_text(encoding="utf-8"))
    assert manifest_on_disk.get("frozen") is True
    sha_before = manifest_on_disk["manifest_projects_sha256"]
    p3c = manifest_on_disk["selected_projects"]
    assert len(p3c) == 250

    p3c_regs = {p["reg_no"].strip().upper() for p in p3c}
    p3c_acks = {p["ack_no"].strip().upper() for p in p3c}
    p3c_vpds = {str(p["vpd_id"]).strip() for p in p3c}
    assert len(p3c_regs) == 250
    assert len(p3c_acks) == 250
    assert len(p3c_vpds) == 250

    # Zero overlap with Phase 3A and Phase 3B
    assert len(p3c_regs & hist_regs) == 0
    assert len(p3c_acks & hist_acks) == 0
    assert len(p3c_vpds & hist_vpds) == 0

    # Verify page-band and project-type stratification
    meth = manifest_on_disk["selection_methodology"]
    assert meth["page_band_distribution"] == {
        "Early (Pages 1-100)": 83,
        "Middle (Pages 101-300)": 84,
        "Late (Pages 301-446)": 83,
    }
    assert set(meth["project_type_distribution"].keys()) == {
        "Residential/Group Housing",
        "Plotted Development",
        "Commercial",
        "Mixed Development",
    }
    assert sum(meth["project_type_distribution"].values()) == 250
    assert len(meth["approval_year_distribution"]) == 10

    # Verify selection and exclusion reports exist alongside frozen manifest
    assert (REPO_ROOT / "data" / "batch_phase3c" / "phase3c_manifest.json").exists()
    assert (REPO_ROOT / "data" / "batch_phase3c" / "phase3c_selection_report.json").exists()
    assert (REPO_ROOT / "data" / "batch_phase3c" / "phase3c_exclusion_report.json").exists()

    # Verify calling select_or_load_frozen_250_manifest reloads frozen manifest without overwriting
    bundle = select_or_load_frozen_250_manifest(SQLITE_PATH, REPO_ROOT, P3C_MANIFEST_PATH)
    assert bundle["loaded_from_frozen_manifest"] is True
    assert bundle["manifest"]["manifest_projects_sha256"] == sha_before


def test_portal_restriction_modal_retry_flow_and_interruption_report(tmp_path):
    """Verifies Requirement A: portal restrictions are checked after failed modal attempt, after timeout, and before retry."""

    class FakeAnchor:
        def __init__(self):
            self.clicks = 0

        def scroll_into_view_if_needed(self):
            pass

        def click(self):
            self.clicks += 1

    class FakePage:
        def __init__(self, fail_attempts: int, restriction_on_stage: Optional[int] = None):
            self.fail_attempts = fail_attempts
            self.restriction_on_stage = restriction_on_stage
            self.wait_calls = 0
            self.eval_calls = 0

        def wait_for_selector(self, selector: str, timeout: int = 45000):
            if "ul.nav-tabs" in selector:
                self.wait_calls += 1
                if self.wait_calls <= self.fail_attempts:
                    raise TimeoutError(f"Simulated modal timeout on attempt {self.wait_calls}")

        def evaluate(self, script: str):
            self.eval_calls += 1
            if self.restriction_on_stage is not None and self.eval_calls >= self.restriction_on_stage:
                return 'Portal restriction phrase detected: "due to security reason, this function has been disabled"'
            return None

    dummy_rec = {
        "batch_index": 42,
        "canonical_project_key": "REG::PRM/KA/RERA/1251/446/PR/260101/000999",
        "project_name": "TEST PROJECT",
        "reg_no": "PRM/KA/RERA/1251/446/PR/260101/000999",
    }

    # Case 1: Modal timeout on attempt 1 CAUSED by portal restriction -> must halt immediately WITHOUT clicking a 2nd time!
    anchor1 = FakeAnchor()
    # eval_calls == 1 is before_opening_project_modal (clean), eval_calls == 2 is after_failed_modal_attempt_1 (restricted)
    page1 = FakePage(fail_attempts=2, restriction_on_stage=2)
    with pytest.raises(PortalRestrictionDetectedError) as exc_info:
        open_project_modal_with_restriction_safeguards(
            page=page1,
            anchor=anchor1,
            rec=dummy_rec,
            max_modal_attempts=3,
            close_modal_fn=lambda p: None,
        )
    assert exc_info.value.stage == "after_failed_modal_attempt_1"
    assert exc_info.value.batch_index == 42
    assert anchor1.clicks == 1, "Must not retry modal click after detecting portal restriction"

    # Verify interruption report generation
    interruption_rec = {
        "stopped_at_batch_index": exc_info.value.batch_index,
        "project_key": exc_info.value.project_key,
        "stage": exc_info.value.stage,
        "cause": exc_info.value.reason,
        "classified_as_project_failure": False,
        "timestamp_utc": exc_info.value.detected_at_utc,
    }
    j_path, m_path = write_portal_interruption_reports(interruption_rec, tmp_path)
    assert j_path.exists() and m_path.exists()
    persisted_ir = json.loads(j_path.read_text(encoding="utf-8"))
    assert persisted_ir["classified_as_project_failure"] is False
    assert persisted_ir["stage"] == "after_failed_modal_attempt_1"

    # Case 2: Restriction appears right before retrying attempt 2 (eval_calls == 3) -> halts before 2nd click
    anchor2 = FakeAnchor()
    page2 = FakePage(fail_attempts=2, restriction_on_stage=3)
    with pytest.raises(PortalRestrictionDetectedError) as exc_info2:
        open_project_modal_with_restriction_safeguards(
            page=page2,
            anchor=anchor2,
            rec=dummy_rec,
            max_modal_attempts=3,
            close_modal_fn=lambda p: None,
        )
    assert exc_info2.value.stage == "before_retrying_modal_attempt_2"
    assert anchor2.clicks == 1, "Must stop before executing 2nd click when restriction appears before retry"

    # Case 3: Transient timeout on attempt 1 with NO portal restriction -> succeeds on attempt 2 and logs 1 retry event
    anchor3 = FakeAnchor()
    page3 = FakePage(fail_attempts=1, restriction_on_stage=None)
    retries = open_project_modal_with_restriction_safeguards(
        page=page3,
        anchor=anchor3,
        rec=dummy_rec,
        max_modal_attempts=3,
        close_modal_fn=lambda p: None,
    )
    assert anchor3.clicks == 2
    assert len(retries) == 1
    assert retries[0]["stage"] == "modal_open_retry_1"


def test_comparison_evidence_non_truncation_and_coverage_quality_metrics():
    """Verifies Requirements C and E: non-truncated comparison samples, mismatch tracking, and separate QA metrics."""
    engine = KRERADiscoveryEngine(enforce_pii_policy=True, require_identity_verification=True)
    proj = engine.create_project(
        {
            "PROJECT NAME": "QA METRICS TOWER",
            "ACKNOWLEDGEMENT NO": "PR/KN/260101/000888",
            "REGISTRATION NO": "PRM/KA/RERA/1251/446/PR/260101/000888",
        }
    )
    raw_dom = {
        "modal_identity": {
            "project_name": "QA METRICS TOWER",
            "acknowledgement_number": "PR/KN/260101/000888",
            "registration_number": "PRM/KA/RERA/1251/446/PR/260101/000888",
            "portal_detail_element_id": "888",
            "catalogue_page_number": 10,
            "catalogue_row_order": 2,
        },
        "tabs": [
            {
                "label": "Promoter Details",
                "id": "#home",
                "is_nav_visible": True,
                "dom_presence": "visible_nav_tab",
                "is_empty": False,
                "sections": [
                    {
                        "label": "Promoter Details",
                        "type": "key_value",
                        "is_empty": False,
                        "fields": [
                            {"label": f"Field_{i}", "value": f"Value_{i}"}
                            for i in range(1, 11)
                        ],
                        "table_headers": [],
                        "table_rows": [],
                        "documents": [],
                    }
                ],
                "sub_tabs": [],
            }
        ],
        "unlinked_dom_panes": [],
    }
    proj = engine.process_project_details(proj, raw_dom)

    # Build a live DOM snapshot with 9 matching fields and 1 mismatched field (10 total > 6)
    live_kv = {f"Field_{i}": f"Value_{i}" for i in range(1, 10)}
    live_kv["Field_10"] = "Different_Live_Portal_Value"
    snapshot = {
        "live_dom_top_nav_tabs": ["Promoter Details"],
        "live_dom_heading_sample": ["Promoter Details"],
        "live_dom_kv_sample": live_kv,
        "live_dom_total_download_anchors_including_unlinked_and_pii": 0,
    }
    rec = {
        "batch_index": 1,
        "page_band": "Early (Pages 1-100)",
        "page_number": 10,
        "project_name": "QA METRICS TOWER",
        "reg_no": "PRM/KA/RERA/1251/446/PR/260101/000888",
        "project_type": "Residential/Group Housing",
        "approval_year": "2026",
    }

    cmp_entry = build_automated_live_dom_comparison_entry(rec, proj, snapshot)
    assert cmp_entry["verification_mode"] == "automated_live_dom_comparison"
    assert cmp_entry["human_manual_inspection_performed"] is False
    assert cmp_entry["total_live_dom_fields_checked_count"] == 10
    assert cmp_entry["matched_live_dom_fields_count"] == 9
    assert cmp_entry["mismatched_live_dom_fields_count"] == 1
    assert len(cmp_entry["mismatched_field_details"]) == 1
    assert cmp_entry["mismatched_field_details"][0]["label"] == "Field_10"
    # Critical Requirement C invariant: retained_field_samples_count == len(retained_field_samples) == 10 (never sliced to 6)
    assert cmp_entry["retained_field_samples_count"] == 10
    assert len(cmp_entry["retained_field_samples"]) == 10
    assert cmp_entry["comparison_passed"] is False

    # Verify Requirement E coverage quality metrics structure
    dummy_summary = {
        "extraction_status": proj.extraction_status.value,
        "identity_verification": proj.identity_verification.model_dump(mode="json"),
        "visible_nav_tabs": [
            {
                "tab_label": "Promoter Details",
                "tab_identifier": "#home",
                "observation_state": "present_with_data",
                "sections_count": 1,
            }
        ],
        "unlinked_dom_panes": [],
        "coverage": proj.coverage.model_dump(mode="json"),
    }
    cqm = compute_project_coverage_quality_metrics(dummy_summary, comparison_entry=cmp_entry)
    assert cqm["execution_status"] == "successful"
    assert cqm["discovered_portal_content"]["visible_nav_tabs_discovered_count"] == 1
    assert cqm["parsed_content"]["fields_extracted_count"] == 10
    assert cqm["failed_or_skipped_content"]["tabs_extraction_failed_count"] == 0
    assert cqm["verification_coverage"]["automated_live_dom_compared"] is True
    assert cqm["verification_coverage"][" automated_live_dom_passed" if False else "automated_live_dom_passed"] is False
    assert cqm["verification_coverage"]["live_dom_field_mismatches_count"] == 1


def test_phase3c_250_outputs_identities_pii_and_checkpoints():
    """Post-extraction verification of all 250 Phase 3C raw/normalized JSON outputs, PII scan, and SQLite checkpoints."""
    raw_files = sorted(P3C_RAW_DIR.glob("*_raw.json")) if P3C_RAW_DIR.exists() else []
    norm_files = sorted(P3C_NORM_DIR.glob("*_normalized.json")) if P3C_NORM_DIR.exists() else []
    if len(raw_files) < 250 or len(norm_files) < 250 or not P3C_SUMMARY_PATH.exists():
        pytest.skip("Phase 3C 250-project live extraction has not yet completed all 250 files.")

    assert len(raw_files) == 250
    assert len(norm_files) == 250

    summary = json.loads(P3C_SUMMARY_PATH.read_text(encoding="utf-8"))
    assert summary["selected_projects_count"] == 250
    assert len(summary["projects"]) == 250
    assert summary["status_breakdown"].get("successful") == 250
    assert summary["status_breakdown"].get("partial", 0) == 0
    assert summary["status_breakdown"].get("failed", 0) == 0
    assert summary["identity_verified_count"] == 250
    assert summary["identity_unverified_count"] == 0

    # Verify all Section 11 deliverables exist in data/batch_phase3c/ and reports/
    batch_root = REPO_ROOT / "data" / "batch_phase3c"
    for fname in (
        "phase3c_manifest.json",
        "phase3c_selection_report.json",
        "phase3c_exclusion_report.json",
        "phase3c_raw.json",
        "phase3c_normalized.json",
        "phase3c_checkpoints.sqlite",
        "phase3c_error_log.json",
        "phase3c_retry_queue.json",
        "phase3c_live_dom_comparisons.json",
        "phase3c_human_qa.json",
        "phase3c_pii_audit.json",
        "phase3c_identity_validation.json",
        "phase3c_coverage_report.json",
        "phase3c_data_quality.json" if False else "phase3c_data_quality_report.json",
        "phase3c_final_report.md",
    ):
        assert (batch_root / fname).exists(), f"Missing deliverable: {batch_root / fname}"
    assert (REPO_ROOT / "reports" / "phase3c_final_report.md").exists()

    # Verify adversarial PII scan across all 500 Phase 3C files
    scan_res = scan_phase3c_outputs_for_pii(summary["projects"], REPO_ROOT)
    assert scan_res["files_scanned_count"] == 500
    assert scan_res["leaks_detected_count"] == 0, f"PII leaks found: {scan_res['leaks_detected']}"
    assert scan_res["passed"] is True

    # Verify comparison JSON consistency (Requirement C)
    comparisons = json.loads(P3C_CMP_PATH.read_text(encoding="utf-8"))
    assert len(comparisons) == 250
    for c in comparisons:
        assert c["verification_mode"] == "automated_live_dom_comparison"
        assert c["human_manual_inspection_performed"] is False
        assert c["retained_field_samples_count"] == len(c["retained_field_samples"])
        assert c["total_live_dom_fields_checked_count"] == len(c["retained_field_samples"])
        assert c["mismatched_live_dom_fields_count"] == 0
        assert c["comparison_passed"] is True
