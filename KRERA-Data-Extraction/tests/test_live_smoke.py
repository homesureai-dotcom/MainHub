"""
Live Smoke Test Verification Suite (`tests/test_live_smoke.py`)

Separately labelled with `@pytest.mark.live_smoke` to distinguish live browser
portal verification from offline HTML fixture tests (`tests/test_pilot_detail_extraction.py`).
"""

from __future__ import annotations

import json
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
LIVE_SMOKE_REPORT_PATH = REPO_ROOT / "reports" / "phase2_1_live_smoke_test.json"


@pytest.mark.live_smoke
def test_live_smoke_test_report_artifacts_and_invariants():
    """Verifies that the controlled live browser smoke test executed against the live K-RERA portal and passed all P0 checks."""
    assert LIVE_SMOKE_REPORT_PATH.exists(), (
        f"Live smoke test report missing at {LIVE_SMOKE_REPORT_PATH}. "
        "Run `python -m scripts.live_smoke_test` first."
    )
    report = json.loads(LIVE_SMOKE_REPORT_PATH.read_text(encoding="utf-8"))

    # 1. Confirm live browser data source (not saved fixtures)
    assert report["data_source"] == "live_visible_playwright_browser"
    assert report["used_saved_fixtures"] is False
    assert report["live_html_captured"] is True
    assert report["live_html_byte_length"] > 50000

    # 2. Confirm modal identity was verified BEFORE parsing
    pre_iv = report["pre_parse_identity_verification"]
    assert pre_iv is not None
    assert pre_iv["is_verified"] is True
    assert pre_iv["verification_status"] == "verified"
    assert pre_iv["reg_no_matches"] is True
    assert pre_iv["ack_no_matches"] is True
    assert pre_iv["project_name_matches"] is True
    assert pre_iv["modal_reg_no"] == "PRM/KA/RERA/1251/446/PR/171010/000003"

    # 3. Confirm extraction errors are recorded separately from empty portal sections
    assert report["extraction_status"] == "successful"
    assert report["extraction_errors"] == []
    assert report["tabs_extraction_failed"] == []
    assert "Enquired Documents" in report["empty_portal_tabs"]
    assert "Quarterly Updates" in report["empty_portal_tabs"]
    assert len(report["populated_portal_tabs"]) == 5

    # 4. Confirm DOM modal cleanup left the page clean and next extraction ('Godrej Air') succeeded
    cleanup = report["cleanup_verification"]
    assert cleanup["modal_hidden_after_close"] is True
    assert cleanup["backdrop_count_after_close"] == 0
    assert cleanup["body_modal_open_class_removed"] is True
    assert cleanup["result_container_cleared"] is True
    assert cleanup["next_project_clickable_and_verified"] is True
    assert (
        cleanup["next_project_identity_verification"]["modal_reg_no"]
        == "PRM/KA/RERA/1251/446/PR/170819/000006"
    )
    assert report["smoke_test_passed"] is True
