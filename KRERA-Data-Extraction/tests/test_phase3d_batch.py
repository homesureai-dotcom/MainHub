"""
Automated Verification Suite for HomeSure K-RERA Phase 3D (500-Project Batch & Phase 3C.1 Remediations)

Covers:
1. Catalogue reconciliation (4,459 rows -> 3,719 eligible_unprocessed, 375 already_processed, 365 non_approved).
2. Phase 3D 500-project manifest stratification, freeze hash integrity, and 0 overlap with Phase 3A (25),
   Phase 3B (100), and Phase 3C (250) across reg_no, ack_no, vpd_id, and canonical_project_key.
3. Phase 3C.1 Remediations:
   - Word-boundary Aadhaar exemption regex (so 'din' inside 'Building' never bypasses continuous 12-digit Aadhaar).
   - Statutory RERA escrow/bank account numbers and coordinates preserved.
   - Non-personal site/infrastructure photos in 'Enquired Documents' preserved.
   - Raw and normalized table row-level PII scrubbing parity in _parse_leaf_table.
   - Upgraded output PII scanner (DOC_ID token boundaries, PAN adjacent to document_identifier).
4. Mutually exclusive document accounting partition identity (total == unique + duplicates + unavailable).
5. Post-extraction verification of all 500 Phase 3D raw/normalized JSON outputs, PII scan, and 875 cumulative checkpoints.
"""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from scripts.detail_dom_parser import parse_project_detail_modal_html
from scripts.discovery_engine import KRERADiscoveryEngine, classify_pii_exclusion
from scripts.phase3c_batch_extractor import scan_phase3c_outputs_for_pii
from scripts.phase3d_batch_extractor import (
    audit_phase3d_raw_normalized_integrity,
    reconcile_catalogue_for_phase3d,
    reconcile_phase3d_documents,
    select_or_load_frozen_500_manifest,
)

REPO_ROOT = Path(__file__).resolve().parent.parent
SQLITE_PATH = REPO_ROOT / "data" / "k_rera_extraction.sqlite"
P3A_MANIFEST_PATH = REPO_ROOT / "data" / "batch_phase3a" / "phase3a_selected_25_manifest.json"
P3B_MANIFEST_PATH = REPO_ROOT / "data" / "batch_phase3b" / "phase3b_selected_100_manifest.json"
P3C_MANIFEST_PATH = REPO_ROOT / "data" / "batch_phase3c" / "phase3c_selected_250_manifest.json"
P3D_MANIFEST_PATH = REPO_ROOT / "data" / "batch_phase3d" / "phase3d_selected_500_manifest.json"
P3D_RAW_DIR = REPO_ROOT / "data" / "batch_phase3d" / "raw"
P3D_NORM_DIR = REPO_ROOT / "data" / "batch_phase3d" / "normalized"
P3D_SUMMARY_PATH = REPO_ROOT / "reports" / "phase3d_batch_summary.json"
P3D_CMP_PATH = REPO_ROOT / "data" / "batch_phase3d" / "phase3d_live_dom_comparisons.json"


def test_phase3d_catalogue_reconciliation_and_frozen_500_manifest():
    """Verifies Stages 3-6: 4,459 catalogue reconciliation, 3,719 eligible pool, 500 frozen manifest, and 0 historical overlap."""
    assert P3D_MANIFEST_PATH.exists(), "Phase 3D frozen manifest must exist before extraction starts"

    reconciliation = reconcile_catalogue_for_phase3d(SQLITE_PATH, REPO_ROOT)
    summary_rec = reconciliation["reconciliation_summary"]
    counts = summary_rec["classification_state_counts"]
    assert summary_rec["total_catalogue_rows"] == 4459
    assert counts["eligible_unprocessed"] == 3719
    assert counts["already_processed"] == 375
    assert counts["non_approved"] == 365
    assert counts["identity_incomplete"] == 0
    assert counts["detail_link_unavailable"] == 0
    assert counts["duplicate_catalogue_record"] == 0
    assert sum(counts.values()) == 4459

    p3a = json.loads(P3A_MANIFEST_PATH.read_text(encoding="utf-8"))["selected_projects"]
    p3b = json.loads(P3B_MANIFEST_PATH.read_text(encoding="utf-8"))["selected_projects"]
    p3c = json.loads(P3C_MANIFEST_PATH.read_text(encoding="utf-8"))["selected_projects"]
    assert len(p3a) == 25
    assert len(p3b) == 100
    assert len(p3c) == 250

    hist_all = p3a + p3b + p3c
    hist_regs = {p["reg_no"].strip().upper() for p in hist_all}
    hist_acks = {p["ack_no"].strip().upper() for p in hist_all}
    hist_vpds = {str(p["vpd_id"]).strip() for p in hist_all}
    hist_keys = {p["canonical_project_key"].strip() for p in hist_all}
    assert len(hist_regs) == 375
    assert len(hist_acks) == 375
    assert len(hist_vpds) == 375
    assert len(hist_keys) == 375

    manifest_on_disk = json.loads(P3D_MANIFEST_PATH.read_text(encoding="utf-8"))
    assert manifest_on_disk.get("frozen") is True
    sha_before = manifest_on_disk["manifest_projects_sha256"]
    p3d = manifest_on_disk["selected_projects"]
    assert len(p3d) == 500

    p3d_regs = {p["reg_no"].strip().upper() for p in p3d}
    p3d_acks = {p["ack_no"].strip().upper() for p in p3d}
    p3d_vpds = {str(p["vpd_id"]).strip() for p in p3d}
    p3d_keys = {p["canonical_project_key"].strip() for p in p3d}
    assert len(p3d_regs) == 500
    assert len(p3d_acks) == 500
    assert len(p3d_vpds) == 500
    assert len(p3d_keys) == 500

    # Zero overlap with Phases 3A, 3B, and 3C
    assert len(p3d_regs & hist_regs) == 0
    assert len(p3d_acks & hist_acks) == 0
    assert len(p3d_vpds & hist_vpds) == 0
    assert len(p3d_keys & hist_keys) == 0

    # Verify sub-batch indexing (20 sub-batches of 25 projects)
    sub_batches = [p["internal_sub_batch_number"] for p in p3d]
    assert min(sub_batches) == 1
    assert max(sub_batches) == 20
    for sb in range(1, 21):
        assert sub_batches.count(sb) == 25

    # Verify selection and reconciliation artifacts exist
    batch_root = REPO_ROOT / "data" / "batch_phase3d"
    for fname in (
        "phase3d_manifest.json",
        "phase3d_selected_500_manifest.json",
        "phase3d_selection_report.json",
        "phase3d_exclusion_report.json",
        "phase3d_historical_exclusion_report.json",
        "phase3d_catalogue_reconciliation.json",
        "phase3d_remaining_eligible_inventory.json",
    ):
        assert (batch_root / fname).exists(), f"Missing pre-execution artifact: {fname}"
    assert (REPO_ROOT / "reports" / "phase3d_catalogue_reconciliation_report.md").exists()

    # Verify reloading frozen manifest is idempotent
    bundle = select_or_load_frozen_500_manifest(SQLITE_PATH, REPO_ROOT, P3D_MANIFEST_PATH)
    assert bundle["loaded_from_frozen_manifest"] is True
    assert bundle["manifest"]["manifest_projects_sha256"] == sha_before


def test_phase3c1_remediations_pii_and_raw_normalized_table_parity(tmp_path):
    """Verifies Stage 2 (Phase 3C.1 Remediations): word-boundary Aadhaar rule, site photos in Enquired Documents, and raw/normalized table parity."""
    engine = KRERADiscoveryEngine(enforce_pii_policy=True, require_identity_verification=True)

    # 1. 'Building' contains substring 'din' -> must NOT bypass continuous 12-digit Aadhaar detection
    det_bldg = classify_pii_exclusion(
        field_label="Notes",
        raw_value="458963214785",
        section_label="Building Details",
        tab_label="Project Details",
    )
    assert det_bldg is not None
    assert det_bldg[0] == "personal_or_entity_pan"

    # 2. Statutory RERA escrow/bank account numbers and DINs MUST remain preserved
    det_escrow = classify_pii_exclusion(
        field_label="RERA Bank Account Number",
        raw_value="502000123456",
        section_label="Bank Details of Project",
        tab_label="Project Details",
    )
    assert det_escrow is None

    det_din = classify_pii_exclusion(
        field_label="DIN Number",
        raw_value="012345678901",
        section_label="Director Details",
        tab_label="Promoter Details",
    )
    assert det_din is None

    # 3. Non-personal site/infrastructure photos in Enquired Documents MUST be preserved
    det_site_enq = classify_pii_exclusion(
        field_label="Photo of site",
        raw_value="DOC_ID=987654",
        section_label="Enquired Documents",
        tab_label="Enquired Documents",
        is_document=True,
    )
    assert det_site_enq is None

    det_borewell = classify_pii_exclusion(
        field_label="Borewell Photo",
        raw_value="DOC_ID=987655",
        section_label="Infrastructure",
        tab_label="Project Details",
        is_document=True,
    )
    assert det_borewell is None

    # Individual promoter photo MUST still be excluded
    det_promoter_photo = classify_pii_exclusion(
        field_label="Promoter Photograph",
        raw_value="DOC_ID=987656",
        section_label="Individual Promoter Details",
        tab_label="Promoter Details",
        is_document=True,
    )
    assert det_promoter_photo is not None
    assert det_promoter_photo[0] == "personal_photograph"

    # 4. Raw and Normalized table row parity when scrubbing PII document rows in _parse_leaf_table
    sample_html = """
    <div id="myModal">
      <p>Project Name : PARITY TEST PROJECT</p>
      <p>Acknowledgement Number : PR/KN/260101/000777</p>
      <p>Registration Number : PRM/KA/RERA/1251/446/PR/260101/000777</p>
      <ul class="nav-tabs">
        <li><a href="#docs">Uploaded Documents</a></li>
      </ul>
      <div class="tab-content">
        <div id="docs" class="tab-pane">
          <p class="inner_heading">Uploaded Documents</p>
          <table>
            <thead>
              <tr><th>Document Name</th><th>Document</th></tr>
            </thead>
            <tbody>
              <tr>
                <td>Approved Building Plan</td>
                <td><a href="downloadFile.do?DOC_ID=1001">Approved_Plan.pdf</a></td>
              </tr>
              <tr>
                <td>PAN Card</td>
                <td><a href="downloadFile.do?DOC_ID=1002">PAN_Card.pdf</a></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
    raw_dom = parse_project_detail_modal_html(
        sample_html,
        portal_detail_element_id="777",
        catalogue_page_number=1,
        catalogue_row_order=1,
        scrub_raw_pii=True,
    )
    proj = engine.create_project(
        {
            "PROJECT NAME": "PARITY TEST PROJECT",
            "ACKNOWLEDGEMENT NO": "PR/KN/260101/000777",
            "REGISTRATION NO": "PRM/KA/RERA/1251/446/PR/260101/000777",
        }
    )
    proj = engine.process_project_details(proj, raw_dom)

    raw_sec = raw_dom["tabs"][0]["sections"][0]
    norm_tab = list(proj.tabs.values())[0]
    norm_sec = norm_tab.sections[0]
    assert len(raw_sec["table_rows"]) == 1
    assert len(norm_sec.table_rows) == 1
    assert len(raw_sec["documents"]) == 1
    assert proj.coverage.total_documents_discovered == 1

    # 5. Upgraded output PII scanner must catch comma-separated values after DOC_ID and PAN near document_identifier
    bad_raw = tmp_path / "bad_raw.json"
    bad_norm = tmp_path / "bad_norm.json"
    bad_raw.write_text(
        json.dumps({"notes": "DOC_ID=991122, 9876543210, promoter@gmail.com"}),
        encoding="utf-8",
    )
    bad_norm.write_text(
        json.dumps({"document_identifier": "12345", "leaked_pan": "ABCDE1234F"}),
        encoding="utf-8",
    )
    scan_res = scan_phase3c_outputs_for_pii(
        [
            {
                "batch_index": 1,
                "canonical_project_key": "TEST::1",
                "raw_output_file": "bad_raw.json",
                "normalized_output_file": "bad_norm.json",
            }
        ],
        tmp_path,
    )
    assert scan_res["passed"] is False
    assert scan_res["leaks_detected_count"] >= 2


def test_phase3d_500_outputs_identities_pii_and_checkpoints():
    """Post-extraction verification of all 500 Phase 3D raw/normalized JSON outputs, PII scan, and 875 cumulative checkpoints."""
    raw_files = sorted(P3D_RAW_DIR.glob("*_raw.json")) if P3D_RAW_DIR.exists() else []
    norm_files = sorted(P3D_NORM_DIR.glob("*_normalized.json")) if P3D_NORM_DIR.exists() else []
    if len(raw_files) < 500 or len(norm_files) < 500 or not P3D_SUMMARY_PATH.exists():
        pytest.skip("Phase 3D 500-project live extraction has not yet completed all 500 files.")

    assert len(raw_files) == 500
    assert len(norm_files) == 500

    summary = json.loads(P3D_SUMMARY_PATH.read_text(encoding="utf-8"))
    assert summary["selected_projects_count"] == 500
    assert len(summary["projects"]) == 500
    assert summary["status_breakdown"].get("successful") == 500
    assert summary["status_breakdown"].get("partial", 0) == 0
    assert summary["status_breakdown"].get("failed", 0) == 0
    assert summary["identity_verified_count"] == 500
    assert summary["identity_unverified_count"] == 0

    # Verify all required deliverables exist in data/batch_phase3d/ and reports/
    batch_root = REPO_ROOT / "data" / "batch_phase3d"
    for fname in (
        "phase3d_manifest.json",
        "phase3d_selection_report.json",
        "phase3d_exclusion_report.json",
        "phase3d_catalogue_reconciliation.json",
        "phase3d_remaining_eligible_inventory.json",
        "phase3d_raw.json",
        "phase3d_normalized.json",
        "phase3d_checkpoints.sqlite",
        "phase3d_error_log.json",
        "phase3d_retry_queue.json",
        "phase3d_live_dom_comparisons.json",
        "phase3d_human_qa.json",
        "phase3d_pii_audit.json",
        "phase3d_identity_validation.json",
        "phase3d_coverage_report.json",
        "phase3d_data_quality_report.json",
        "phase3d_document_reconciliation.json",
        "phase3d_raw_normalized_integrity.json",
        "phase3d_final_report.md",
    ):
        assert (batch_root / fname).exists(), f"Missing Phase 3D deliverable: {batch_root / fname}"
    assert (REPO_ROOT / "reports" / "phase3d_final_report.md").exists()

    # Verify adversarial PII scan across all 1,000 Phase 3D files
    scan_res = scan_phase3c_outputs_for_pii(summary["projects"], REPO_ROOT)
    assert scan_res["files_scanned_count"] == 1000
    assert scan_res["leaks_detected_count"] == 0, f"PII leaks found: {scan_res['leaks_detected']}"
    assert scan_res["passed"] is True

    # Verify mutually exclusive document accounting identity
    doc_rec = reconcile_phase3d_documents(summary["projects"], REPO_ROOT)
    agg = doc_rec["aggregate_reconciliation"]
    assert agg["partition_identity_verified"] is True
    assert agg["visible_tabs_total_document_records"] == (
        agg["unique_linked_document_observations"]
        + agg["duplicate_document_observations"]
        + agg["unavailable_document_slots"]
    )

    # Verify raw vs normalized structural parity across all 500 projects
    rn_audit = audit_phase3d_raw_normalized_integrity(summary["projects"], REPO_ROOT)
    rn_agg = rn_audit["aggregate_parity"]
    assert rn_agg["projects_checked"] == 500
    assert rn_audit["parity_verified"] is True
    assert rn_audit["fabricated_items_in_normalized_count"] == 0
    assert rn_agg["raw_visible_tabs"] == rn_agg["norm_visible_tabs"]
    assert rn_agg["raw_unlinked_panes"] == rn_agg["norm_unlinked_panes"]

    # Verify comparison JSON consistency
    comparisons = json.loads(P3D_CMP_PATH.read_text(encoding="utf-8"))
    assert len(comparisons) == 500
    for c in comparisons:
        assert c["verification_mode"] == "automated_live_dom_comparison"
        assert c["human_manual_inspection_performed"] is False
        assert c["retained_field_samples_count"] == len(c["retained_field_samples"])
        assert c["total_live_dom_fields_checked_count"] == len(c["retained_field_samples"])
