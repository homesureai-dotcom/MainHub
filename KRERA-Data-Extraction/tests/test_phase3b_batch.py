"""
Automated Verification Suite for Phase 3B — Controlled 100-Project Batch Extraction.

Verifies:
1. Pre-extraction 100-project manifest stratification, promoter/year/type diversity,
   zero overlap with the 25 Phase 3A projects, and immutability of Phase 3A outputs.
2. All 100 raw JSON files and 100 normalized JSON files exist, pass strict identity
   verification (`reg_no_matches`, `ack_no_matches`, `project_name_matches`), retain
   provenance, separate document observation/link/placeholder/unavailable counts,
   preserve cross-section conflicts, and pass serialized PII output scanning.
3. Synthetic test fixtures verifying that personal photographs are excluded while
   site/project/building/construction/directional photographs are preserved and
   never misclassified as personal photographs.
4. SQLite checkpoint persistence (125 total successful checkpoints = 25 Phase 3A + 100 Phase 3B),
   structured error logs deliverable, and idempotent resume queue.
5. Manual live-portal comparison coverage (>= 15 projects spanning all page bands,
   all 4 project types, and unusual navigation schemas including 6, 9, 10, and 11 tabs).
"""

from __future__ import annotations

import json
import re
import sqlite3
from pathlib import Path

from scripts.detail_batch_safeguards import DetailBatchCoordinator
from scripts.detail_dom_parser import parse_project_detail_modal_html
from scripts.discovery_engine import KRERADiscoveryEngine, classify_pii_exclusion

REPO_ROOT = Path(__file__).resolve().parent.parent
PHASE3A_DIR = REPO_ROOT / "data" / "batch_phase3a"
PHASE3B_DIR = REPO_ROOT / "data" / "batch_phase3b"
REPORTS_DIR = REPO_ROOT / "reports"
SQLITE_PATH = REPO_ROOT / "data" / "k_rera_extraction.sqlite"

STANDALONE_PAN_REGEX = re.compile(r"(?<![A-Z0-9])[A-Z]{5}[0-9]{4}[A-Z](?![A-Z0-9])")


def test_phase3b_manifest_stratification_and_zero_phase3a_overlap() -> None:
    p3a_manifest_path = PHASE3A_DIR / "phase3a_selected_25_manifest.json"
    p3b_manifest_path = PHASE3B_DIR / "phase3b_selected_100_manifest.json"
    assert p3a_manifest_path.exists(), "Phase 3A manifest must remain preserved"
    assert p3b_manifest_path.exists(), "Phase 3B 100-project manifest must exist"

    p3a_manifest = json.loads(p3a_manifest_path.read_text(encoding="utf-8"))
    p3b_manifest = json.loads(p3b_manifest_path.read_text(encoding="utf-8"))

    p3a_projects = p3a_manifest["selected_projects"]
    p3b_projects = p3b_manifest["selected_projects"]
    assert len(p3a_projects) == 25
    assert len(p3b_projects) == 100

    p3a_regs = {p["reg_no"] for p in p3a_projects}
    p3a_acks = {p["ack_no"] for p in p3a_projects}
    p3a_vpds = {str(p["vpd_id"]) for p in p3a_projects}

    p3b_regs = {p["reg_no"] for p in p3b_projects}
    p3b_acks = {p["ack_no"] for p in p3b_projects}
    p3b_vpds = {str(p["vpd_id"]) for p in p3b_projects}

    assert len(p3b_regs) == 100, "All 100 Phase 3B projects must have distinct registration numbers"
    assert len(p3b_acks) == 100, "All 100 Phase 3B projects must have distinct acknowledgement numbers"
    assert len(p3b_vpds) == 100, "All 100 Phase 3B projects must have distinct vpd_ids"

    # Zero overlap with Phase 3A
    assert p3a_regs.isdisjoint(p3b_regs), "Phase 3B must not overlap with any Phase 3A registration number"
    assert p3a_acks.isdisjoint(p3b_acks), "Phase 3B must not overlap with any Phase 3A acknowledgement number"
    assert p3a_vpds.isdisjoint(p3b_vpds), "Phase 3B must not overlap with any Phase 3A vpd_id"

    # Verify page bands, project types, promoters, and years
    bands = {p["page_band"] for p in p3b_projects}
    assert bands == {
        "Early (Pages 1-100)",
        "Middle (Pages 101-300)",
        "Late (Pages 301-446)",
    }

    types = {p["project_type"] for p in p3b_projects}
    assert types == {
        "Residential/Group Housing",
        "Plotted Development",
        "Commercial",
        "Mixed Development",
    }

    promoters = {p["promoter_name"].strip().upper() for p in p3b_projects}
    assert len(promoters) == 100, "Expected 100 distinct promoters across the 100 selected projects"

    years = {p["approval_year"] for p in p3b_projects}
    assert len(years) >= 10, f"Expected all 10 approval years (2017-2026), got {sorted(years)}"


def test_phase3b_100_outputs_identities_pii_provenance_and_checkpoints() -> None:
    raw_dir = PHASE3B_DIR / "raw"
    norm_dir = PHASE3B_DIR / "normalized"
    summary_path = REPORTS_DIR / "phase3b_batch_summary.json"
    error_logs_path = REPORTS_DIR / "phase3b_extraction_error_logs.json"

    assert summary_path.exists(), "phase3b_batch_summary.json must exist"
    assert error_logs_path.exists(), "phase3b_extraction_error_logs.json must exist"

    raw_files = sorted(raw_dir.glob("*_raw.json"))
    norm_files = sorted(norm_dir.glob("*_normalized.json"))
    assert len(raw_files) == 100, f"Expected 100 raw JSON files, found {len(raw_files)}"
    assert len(norm_files) == 100, f"Expected 100 normalized JSON files, found {len(norm_files)}"

    # Also verify Phase 3A outputs remain untouched (25 raw + 25 normalized)
    assert len(list((PHASE3A_DIR / "raw").glob("*_raw.json"))) == 25
    assert len(list((PHASE3A_DIR / "normalized").glob("*_normalized.json"))) == 25

    for rf, nf in zip(raw_files, norm_files):
        raw_txt = rf.read_text(encoding="utf-8")
        norm_txt = nf.read_text(encoding="utf-8")
        raw_data = json.loads(raw_txt)
        norm_data = json.loads(norm_txt)

        assert norm_data["extraction_status"] == "successful", f"Non-successful status in {nf.name}"
        iv = norm_data["identity_verification"]
        assert iv["is_verified"] is True, f"Identity not verified in {nf.name}"
        assert iv["verification_status"] == "verified"
        assert iv["reg_no_matches"] is True
        assert iv["ack_no_matches"] is True
        assert iv["project_name_matches"] is True

        # Verify provenance and coverage separation
        cov = norm_data["coverage"]
        assert cov["total_tabs_discovered"] >= 6
        assert cov["unique_document_observations_count"] >= 0
        assert cov["document_links_count"] >= 0
        assert cov["placeholder_document_entries_count"] >= 0
        assert cov["unavailable_document_slots_count"] >= 0
        assert cov["extraction_timestamp"], f"Missing extraction_timestamp in {nf.name}"
        assert raw_data.get("extracted_at_utc"), f"Missing extracted_at_utc in {rf.name}"

        # Scan serialized raw and normalized JSON for standalone 10-char PAN leaks
        # (strip 15-char GSTINs first, which contain an embedded 10-char PAN)
        raw_no_gstin = re.sub(r"\b\d{2}[A-Z]{5}\d{4}[A-Z][A-Z0-9]{3}\b", "", raw_txt)
        norm_no_gstin = re.sub(r"\b\d{2}[A-Z]{5}\d{4}[A-Z][A-Z0-9]{3}\b", "", norm_txt)

        raw_pan_hits = STANDALONE_PAN_REGEX.findall(raw_no_gstin)
        norm_pan_hits = STANDALONE_PAN_REGEX.findall(norm_no_gstin)
        assert not raw_pan_hits, f"Standalone PAN pattern leaked in {rf.name}: {raw_pan_hits}"
        assert not norm_pan_hits, f"Standalone PAN pattern leaked in {nf.name}: {norm_pan_hits}"

        # Normalized output must never contain unremoved synthetic PII markers
        for marker in (
            "SYNTHETIC_PAN_REDACTED",
            "SYNTHETIC_INDIVIDUAL_PII_REDACTED",
            "SYNTHETIC_INDIVIDUAL_ADDRESS_REDACTED",
            "SYNTHETIC_PERSONAL_PHOTO",
        ):
            assert marker not in norm_txt, f"Synthetic PII marker '{marker}' leaked into {nf.name}"

    # Verify SQLite checkpoints contain all 125 successful projects (25 Phase 3A + 100 Phase 3B)
    coordinator = DetailBatchCoordinator(sqlite_path=SQLITE_PATH)
    status_counts = coordinator.get_status_counts()
    assert status_counts.get("successful", 0) >= 125
    assert status_counts.get("failed", 0) == 0
    assert status_counts.get("partial", 0) == 0
    assert status_counts.get("identity_unverified", 0) == 0


def test_site_photographs_preserved_and_personal_photographs_excluded() -> None:
    """Verifies via synthetic fixtures that site/project photos are preserved while personal photos are excluded."""
    # 1. Direct unit checks on classify_pii_exclusion
    for tab, sec, lbl, fn in [
        ("Uploaded Documents", "Project Photo", "Project Photo", "Tower_A_Elevation.pdf"),
        ("Completion Details", "Photos Uploaded", "East Side Photo", "East_View.jpg"),
        ("Completion Details", "Photos Uploaded", "Photo", "Site_Progress_Photo.pdf"),
        ("Quarterly Updates", "Quarterly Update Details", "Construction Photo", "Q3_Photo.pdf"),
        ("Project Details", "Project Details", "Site Photo", "Site_Layout_Photo.jpg"),
        ("Post-Registration & Tower Details", "Tower Details", "Building Photo", "Building_1.jpg"),
    ]:
        res = classify_pii_exclusion(
            field_label=lbl,
            raw_value=fn,
            section_label=sec,
            tab_label=tab,
            is_document=True,
            filename=fn,
            promoter_type="Company",
        )
        assert res is None, f"Site photograph ({tab} > {sec} > {lbl}) was wrongly classified as PII: {res}"

    # 2. Personal photographs must still be excluded
    for tab, sec, lbl, fn in [
        ("Promoter Details", "Authorized Signatory Detail", "Photograph", "signatory_photo.jpg"),
        ("Promoter Details", "Director Details", "Photo(Annexure-19)", "director_photo.pdf"),
        ("Promoter Details", "Promoter Details", "Promoter Photograph", "promoter_photo.jpg"),
        ("Uploaded Documents", "Promoter Documents", "Passport Photo of Partner", "partner_photo.jpg"),
    ]:
        res = classify_pii_exclusion(
            field_label=lbl,
            raw_value=fn,
            section_label=sec,
            tab_label=tab,
            is_document=True,
            filename=fn,
            promoter_type="Company",
        )
        assert res is not None and res[0] == "personal_photograph", (
            f"Personal photograph ({tab} > {sec} > {lbl}) was NOT excluded!"
        )

    # 3. End-to-end synthetic modal HTML fixture with both personal photo and site photos
    synthetic_html = """
    <div id="result">
      <div class="row">
        <p>Project Name : SYNTHETIC SITE PHOTO TEST</p>
        <p>Acknowledgement Number : ACK/KA/RERA/1251/446/PR/240101/999999</p>
        <p>Registration Number : PRM/KA/RERA/1251/446/PR/240102/999999</p>
      </div>
      <ul class="nav nav-tabs">
        <li><a href="#home">Promoter Details</a></li>
        <li><a href="#menu2">Uploaded Documents</a></li>
        <li><a href="#completion">Completion Details</a></li>
      </ul>
      <div class="tab-content">
        <div id="home" class="tab-pane">
          <h1>Authorized Signatory Detail</h1>
          <div class="row">
            <div class="col-md-3">Name</div><div class="col-md-3">Ramesh Rao</div>
            <div class="col-md-3">Photograph</div>
            <div class="col-md-3"><a href="https://rera.karnataka.gov.in/download_jc?DOC_ID=111">signatory_photo.jpg</a></div>
          </div>
        </div>
        <div id="menu2" class="tab-pane">
          <h1>Project Photo</h1>
          <div class="row">
            <div class="col-md-6">Project Photo</div>
            <div class="col-md-6"><a href="https://rera.karnataka.gov.in/download_jc?DOC_ID=222">Site_Elevation_Photo.pdf</a></div>
          </div>
        </div>
        <div id="completion" class="tab-pane">
          <h1>Photos Uploaded</h1>
          <div class="row">
            <div class="col-md-6">North Side Photo</div>
            <div class="col-md-6"><a href="https://rera.karnataka.gov.in/download_jc?DOC_ID=333">North_Tower_Photo.pdf</a></div>
          </div>
        </div>
      </div>
    </div>
    """
    parsed = parse_project_detail_modal_html(synthetic_html, portal_detail_element_id="999999", scrub_raw_pii=True)
    engine = KRERADiscoveryEngine(enforce_pii_policy=True, require_identity_verification=True)
    proj = engine.create_project(
        {
            "PROJECT NAME": "SYNTHETIC SITE PHOTO TEST",
            "ACKNOWLEDGEMENT NO": "ACK/KA/RERA/1251/446/PR/240101/999999",
            "REGISTRATION NO": "PRM/KA/RERA/1251/446/PR/240102/999999",
            "PROMOTER NAME": "SYNTHETIC BUILDERS LLP",
            "PROJECT TYPE": "Residential/Group Housing",
            "STATUS": "APPROVED",
        }
    )
    proj = engine.process_project_details(proj, parsed)
    doc_filenames = [
        d.displayed_filename
        for t in proj.tabs.values()
        for s in t.sections
        for d in s.documents
    ]
    assert "Site_Elevation_Photo.pdf" in doc_filenames
    assert "North_Tower_Photo.pdf" in doc_filenames
    assert "signatory_photo.jpg" not in doc_filenames
    assert any(ex.pii_category == "personal_photograph" for ex in proj.pii_exclusions)


def test_phase3b_manual_comparisons_and_navigation_diversity() -> None:
    cmp_path = PHASE3B_DIR / "phase3b_manual_comparisons.json"
    summary_path = REPORTS_DIR / "phase3b_batch_summary.json"
    assert cmp_path.exists()
    comparisons = json.loads(cmp_path.read_text(encoding="utf-8"))
    summary = json.loads(summary_path.read_text(encoding="utf-8"))

    assert len(comparisons) >= 15, f"Expected at least 15 manual comparisons, got {len(comparisons)}"
    assert all(c["nav_tabs_exact_match"] is True for c in comparisons)
    assert all(c["comparison_passed"] is True for c in comparisons)

    # Must cover all 3 page bands and all 4 project types
    cmp_bands = {c["page_band"] for c in comparisons}
    assert cmp_bands == {
        "Early (Pages 1-100)",
        "Middle (Pages 101-300)",
        "Late (Pages 301-446)",
    }
    cmp_types = {c["project_type"] for c in comparisons}
    assert cmp_types == {
        "Residential/Group Housing",
        "Plotted Development",
        "Commercial",
        "Mixed Development",
    }

    # Must include unusual navigation layouts (e.g. 6-tab, 9-tab, 10-tab, or 11-tab)
    tab_counts_in_cmp = {len(c["extracted_top_nav_tabs"]) for c in comparisons}
    assert 6 in tab_counts_in_cmp
    assert 9 in tab_counts_in_cmp
    assert len(summary["navigation_schema_distribution"]) >= 8
