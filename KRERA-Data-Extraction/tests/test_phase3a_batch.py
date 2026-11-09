"""
Automated Verification Suite for Phase 3A Controlled 25-Project Batch Extraction

Verifies all Phase 3A acceptance criteria against:
- Pre-extraction manifest (`data/batch_phase3a/phase3a_selected_25_manifest.json`)
- 25 raw JSON files (`data/batch_phase3a/raw/*.json`)
- 25 normalized JSON files (`data/batch_phase3a/normalized/*.json`)
- SQLite checkpoints (`data/k_rera_extraction.sqlite` -> `detail_extraction_checkpoints`)
- Machine-readable batch summary (`reports/phase3a_batch_summary.json`)
"""

from __future__ import annotations

import json
import re
from pathlib import Path

from scripts.detail_batch_safeguards import DetailBatchCoordinator
from scripts.discovery_engine import PAN_VALUE_REGEX
from scripts.models import DetailExtractionStatus

REPO_ROOT = Path(__file__).resolve().parent.parent
BATCH_DIR = REPO_ROOT / "data" / "batch_phase3a"
RAW_DIR = BATCH_DIR / "raw"
NORM_DIR = BATCH_DIR / "normalized"
MANIFEST_PATH = BATCH_DIR / "phase3a_selected_25_manifest.json"
SUMMARY_PATH = REPO_ROOT / "reports" / "phase3a_batch_summary.json"
SQLITE_PATH = REPO_ROOT / "data" / "k_rera_extraction.sqlite"


def test_phase3a_manifest_stratification_and_diversity():
    """Verifies that the 25-project pre-extraction manifest covers Early, Middle, Late pages, 4 types, 25 promoters, and 10 years."""
    assert MANIFEST_PATH.exists()
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    assert manifest["selected_projects_count"] == 25
    projects = manifest["selected_projects"]
    assert len(projects) == 25

    meth = manifest["selection_methodology"]
    assert meth["page_band_distribution"]["Early (Pages 1-100)"] == 9
    assert meth["page_band_distribution"]["Middle (Pages 101-300)"] == 8
    assert meth["page_band_distribution"]["Late (Pages 301-446)"] == 8
    assert meth["distinct_promoters_count"] == 25
    assert set(meth["project_type_distribution"].keys()) == {
        "Residential/Group Housing",
        "Plotted Development",
        "Commercial",
        "Mixed Development",
    }
    assert len(meth["approval_year_distribution"]) == 10


def test_phase3a_25_outputs_identities_pii_and_checkpoints():
    """Verifies all 25 raw & normalized JSON files, strict identity verification, zero PII leakage, and SQLite checkpoints."""
    assert SUMMARY_PATH.exists()
    summary = json.loads(SUMMARY_PATH.read_text(encoding="utf-8"))

    assert summary["interrupted"] is False
    assert summary["outcome_counts"]["total_selected"] == 25
    assert summary["outcome_counts"]["total_processed"] == 25
    assert summary["outcome_counts"]["successful"] == 25
    assert summary["outcome_counts"]["identity_unverified"] == 0

    raw_files = sorted(RAW_DIR.glob("*_raw.json"))
    norm_files = sorted(NORM_DIR.glob("*_normalized.json"))
    assert len(raw_files) == 25
    assert len(norm_files) == 25

    # Check zero PII retention across all 50 files
    for fpath in raw_files + norm_files:
        text = fpath.read_text(encoding="utf-8")
        pan_matches = PAN_VALUE_REGEX.findall(text)
        assert pan_matches == [], f"Found unredacted PAN pattern {pan_matches} in {fpath.name}"
        assert "SYNTHETIC_PAN" not in text, f"Found synthetic PAN marker in {fpath.name}"
        assert "SYNTHETIC_INDIVIDUAL" not in text, f"Found synthetic PII marker in {fpath.name}"
        assert "SYNTHETIC_PERSONAL_PHOTO" not in text, f"Found synthetic photo marker in {fpath.name}"
        assert "[REDACTED_PII" not in text, f"Found [REDACTED_PII placeholder in {fpath.name}"
        assert "REDACTED_PAN_DOC" not in text, f"Found REDACTED_PAN_DOC URL in {fpath.name}"
        assert "REDACTED_PHOTO_DOC" not in text, f"Found REDACTED_PHOTO_DOC URL in {fpath.name}"

    # Check normalized project structures
    for npath in norm_files:
        pdata = json.loads(npath.read_text(encoding="utf-8"))
        assert pdata["extraction_status"] == "successful"
        iv = pdata["identity_verification"]
        assert iv is not None and iv["is_verified"] is True
        assert iv["verification_status"] == "verified"
        assert iv["reg_no_matches"] is True
        assert iv["ack_no_matches"] is True
        assert iv["project_name_matches"] is True

        for t_obs in list(pdata["tabs"].values()) + list(pdata["unlinked_dom_panes"].values()):
            for s_obs in t_obs.get("sections", []):
                for f_obs in s_obs.get("fields", []):
                    assert not re.search(r"\b(pan|aadhaar|aadhar)\b", f_obs["field_label"], re.I)
                    assert not re.search(
                        r"\b(present\s+address|permanent\s+address|residential\s+address)\b",
                        f_obs["field_label"],
                        re.I,
                    )
                for d_obs in s_obs.get("documents", []):
                    assert not re.search(r"\b(pan|aadhaar|aadhar)\b", d_obs["document_category"], re.I)

    # Check SQLite checkpoints & idempotent skip behavior
    coord = DetailBatchCoordinator(sqlite_path=SQLITE_PATH)
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    selected_records = manifest["selected_projects"]

    for rec in selected_records:
        cp = coord.get_checkpoint(rec["canonical_project_key"])
        assert cp is not None, f"Missing SQLite checkpoint for {rec['reg_no']}"
        assert cp.extraction_status == DetailExtractionStatus.SUCCESSFUL
        assert cp.is_retryable is False
        assert cp.payload_sha256 is not None

    queue, _, skip_reasons = coord.get_resumable_batch_queue(selected_records, force=False)
    assert queue == []
    assert skip_reasons["already_successful"] == 25

    # Check live portal manual comparisons (>= 5 projects across Early, Middle, Late pages)
    comparisons = summary.get("live_portal_manual_comparisons", [])
    assert len(comparisons) >= 5
    for cmp_item in comparisons:
        assert cmp_item["nav_tabs_exact_match"] is True
        assert cmp_item["comparison_passed"] is True
