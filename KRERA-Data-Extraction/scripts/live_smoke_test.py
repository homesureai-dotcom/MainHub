"""
HomeSure K-RERA Phase 2.1 — Controlled Live Extraction Smoke Test

Executes an explicitly controlled live Playwright browser smoke test (separate from
saved HTML fixture tests) that:
1. Opens one known project (`Godrej United`, `vpd_id="6"`, Page 1, Row 1) using the
   visible Playwright browser workflow (`headless=False`).
2. Waits for modal content (`#project_details_popup #result ul.nav-tabs li a` and
   `.tab-content .tab-pane`) to finish loading.
3. Verifies modal identity (`Registration Number`, `Acknowledgement Number`, `Project Name`)
   BEFORE running the full parser.
4. Records whether live HTML was captured successfully.
5. Runs `parse_project_detail_modal_html` and `KRERADiscoveryEngine.process_project_details`
   against the live captured HTML.
6. Records extraction errors separately from empty portal sections.
7. Verifies that browser/modal cleanup (`close_project_modal_in_dom`) leaves the page clean
   and does not corrupt opening/verifying the next project (`Godrej Air`, `vpd_id="25"`).
"""

from __future__ import annotations

import json
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict

from lxml import html as lxml_html
from playwright.sync_api import sync_playwright

REPO_ROOT = Path(__file__).resolve().parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from scripts.detail_dom_parser import extract_modal_identity, parse_project_detail_modal_html
from scripts.discovery_engine import KRERADiscoveryEngine
from scripts.pilot_detail_extractor import (
    JS_EXTRACT_SCRUBBED_MODAL_HTML,
    close_project_modal_in_dom,
    lookup_pilot_catalogue_records,
)


def run_controlled_live_smoke_test(update_live_fixtures: bool = True) -> Dict[str, Any]:
    """Runs the controlled live browser smoke test on `Godrej United` and verifies cleanup on `Godrej Air`."""
    sqlite_path = REPO_ROOT / "data" / "k_rera_extraction.sqlite"
    fixtures_dir = REPO_ROOT / "tests" / "fixtures" / "pilot_modals"
    reports_dir = REPO_ROOT / "reports"
    reports_dir.mkdir(parents=True, exist_ok=True)

    pilot_records = lookup_pilot_catalogue_records(sqlite_path)
    primary_rec = pilot_records[0]  # Godrej United (Page 1, Row 1, vpd_id="6")
    next_rec = pilot_records[1]     # Godrej Air (Page 1, Row 2, vpd_id="25")

    engine = KRERADiscoveryEngine(
        enforce_pii_policy=True,
        require_identity_verification=True,
    )

    started_at = datetime.now(timezone.utc)
    result_report: Dict[str, Any] = {
        "test_name": "Phase 2.1 Controlled Live Browser Extraction Smoke Test",
        "data_source": "live_visible_playwright_browser",
        "used_saved_fixtures": False,
        "portal_url": "https://rera.karnataka.gov.in/viewAllProjects",
        "started_at_utc": started_at.isoformat(),
        "primary_project": {
            "project_name": primary_rec["project_name"],
            "registration_number": primary_rec["reg_no"],
            "acknowledgement_number": primary_rec["ack_no"],
            "catalogue_page_number": primary_rec["page_number"],
            "catalogue_row_order": primary_rec["row_order"],
            "portal_detail_element_id": primary_rec["vpd_id"],
        },
        "live_html_captured": False,
        "live_html_byte_length": 0,
        "pre_parse_identity_verification": None,
        "extraction_status": None,
        "extraction_errors": [],
        "tabs_extraction_failed": [],
        "empty_portal_tabs": [],
        "empty_portal_sections": [],
        "populated_portal_tabs": [],
        "populated_portal_sections_count": 0,
        "document_metrics": {},
        "pii_exclusions_count": 0,
        "cleanup_verification": {
            "modal_hidden_after_close": False,
            "backdrop_count_after_close": None,
            "body_modal_open_class_removed": False,
            "result_container_cleared": False,
            "next_project_clickable_and_verified": False,
            "next_project_identity_verification": None,
        },
        "smoke_test_passed": False,
    }

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False)
        context = browser.new_context(viewport={"width": 1440, "height": 900})
        page = context.new_page()

        print("[LiveSmoke] Opening https://rera.karnataka.gov.in/viewAllProjects in visible browser...")
        page.goto("https://rera.karnataka.gov.in/viewAllProjects", timeout=60000)
        page.wait_for_load_state("networkidle")

        # Select Bengaluru Urban and submit search
        page.locator("select#projectDist").select_option(label="Bengaluru Urban")
        time.sleep(0.5)
        page.locator("input[type='submit'][value='Search'], button:has-text('Search')").first.click()

        page.wait_for_selector("#approvedTable tbody tr", timeout=60000)
        time.sleep(1.5)

        # Step 1: Open Godrej United (vpd_id='6')
        vpd_id = primary_rec["vpd_id"]
        anchor = page.locator(
            f"#approvedTable a[id='{vpd_id}'][onclick*='showFileApplicationPreview']"
        ).first
        if anchor.count() == 0:
            browser.close()
            raise RuntimeError(f"Primary anchor a[id='{vpd_id}'] not found on Page 1")

        print(f"[LiveSmoke] Clicking View Project Details a[id='{vpd_id}'] for {primary_rec['project_name']}...")
        anchor.scroll_into_view_if_needed()
        anchor.click()

        # Step 2: Wait for modal content to finish loading
        page.wait_for_selector("#project_details_popup #result ul.nav-tabs li a", timeout=45000)
        page.wait_for_selector("#project_details_popup #result .tab-content .tab-pane", timeout=45000)
        time.sleep(1.2)

        # Step 3: Capture live PII-scrubbed modal HTML
        live_html = page.evaluate(JS_EXTRACT_SCRUBBED_MODAL_HTML)
        result_report["live_html_byte_length"] = len(live_html or "")
        result_report["live_html_captured"] = bool(live_html and len(live_html) >= 500)

        if not result_report["live_html_captured"]:
            browser.close()
            raise RuntimeError("Failed to capture non-empty live modal HTML from #result")

        if update_live_fixtures:
            fixtures_dir.mkdir(parents=True, exist_ok=True)
            (fixtures_dir / f"{primary_rec['slug']}.html").write_text(live_html, encoding="utf-8")

        # Step 4: Verify modal identity BEFORE full parsing
        root = lxml_html.fragment_fromstring(live_html, create_parent="div")
        pre_modal_identity = extract_modal_identity(root)
        pre_modal_identity["portal_detail_element_id"] = vpd_id
        pre_modal_identity["catalogue_page_number"] = primary_rec["page_number"]
        pre_modal_identity["catalogue_row_order"] = primary_rec["row_order"]

        project = engine.create_project(primary_rec["catalogue_row_dict"])
        pre_iv = engine.verify_project_identity(project, pre_modal_identity)
        result_report["pre_parse_identity_verification"] = pre_iv.model_dump(mode="json")

        if not pre_iv.is_verified:
            browser.close()
            raise RuntimeError(
                f"Pre-parse identity verification failed for {primary_rec['project_name']}: "
                f"{pre_iv.mismatch_reasons}"
            )

        # Step 5: Run full DOM parser + KRERADiscoveryEngine on the captured live HTML
        raw_dom_payload = parse_project_detail_modal_html(
            raw_html=live_html,
            portal_detail_element_id=vpd_id,
            catalogue_page_number=primary_rec["page_number"],
            catalogue_row_order=primary_rec["row_order"],
            scrub_raw_pii=True,
        )
        project = engine.process_project_details(project, raw_dom_payload)

        # Step 6: Record extraction errors separately from empty portal sections
        cov = project.coverage
        result_report["extraction_status"] = project.extraction_status.value
        result_report["extraction_errors"] = list(cov.errors)
        result_report["tabs_extraction_failed"] = list(cov.tabs_extraction_failed)
        result_report["empty_portal_tabs"] = list(cov.tabs_present_empty)
        result_report["empty_portal_sections"] = list(cov.sections_present_empty)
        result_report["populated_portal_tabs"] = list(cov.tabs_processed)
        result_report["populated_portal_sections_count"] = len(cov.sections_present_with_data)
        result_report["document_metrics"] = {
            "total_documents_discovered": cov.total_documents_discovered,
            "unique_document_observations_count": cov.unique_document_observations_count,
            "document_links_count": cov.document_links_count,
            "placeholder_document_entries_count": cov.placeholder_document_entries_count,
            "unavailable_document_slots_count": cov.unavailable_document_slots_count,
            "total_table_rows_discovered": cov.total_table_rows_discovered,
        }
        result_report["pii_exclusions_count"] = len(project.pii_exclusions)

        # Step 7: Perform DOM modal cleanup and verify it does not corrupt the next extraction
        close_project_modal_in_dom(page)

        cleanup_state = page.evaluate(
            """
            () => {
                const popup = document.querySelector('#project_details_popup');
                const backdrops = document.querySelectorAll('.modal-backdrop');
                const res = document.querySelector('#result');
                const popupHidden = !popup || (!popup.classList.contains('in') && popup.style.display === 'none');
                const bodyClean = !document.body.classList.contains('modal-open');
                const resClean = !res || res.innerHTML.trim() === '';
                return {
                    popupHidden,
                    backdropCount: backdrops.length,
                    bodyClean,
                    resClean
                };
            }
            """
        )
        result_report["cleanup_verification"]["modal_hidden_after_close"] = bool(
            cleanup_state["popupHidden"]
        )
        result_report["cleanup_verification"]["backdrop_count_after_close"] = int(
            cleanup_state["backdropCount"]
        )
        result_report["cleanup_verification"]["body_modal_open_class_removed"] = bool(
            cleanup_state["bodyClean"]
        )
        result_report["cleanup_verification"]["result_container_cleared"] = bool(
            cleanup_state["resClean"]
        )

        # Verify next extraction (`Godrej Air`, vpd_id='25') works cleanly after cleanup
        next_vpd_id = next_rec["vpd_id"]
        next_anchor = page.locator(
            f"#approvedTable a[id='{next_vpd_id}'][onclick*='showFileApplicationPreview']"
        ).first
        print(
            f"[LiveSmoke] Verifying post-cleanup extraction on next project "
            f"'{next_rec['project_name']}' (a[id='{next_vpd_id}'])..."
        )
        next_anchor.scroll_into_view_if_needed()
        next_anchor.click()

        page.wait_for_selector("#project_details_popup #result ul.nav-tabs li a", timeout=45000)
        time.sleep(1.2)

        next_html = page.evaluate(JS_EXTRACT_SCRUBBED_MODAL_HTML)
        if update_live_fixtures and next_html and len(next_html) >= 500:
            (fixtures_dir / f"{next_rec['slug']}.html").write_text(next_html, encoding="utf-8")

        next_root = lxml_html.fragment_fromstring(next_html, create_parent="div")
        next_modal_id = extract_modal_identity(next_root)
        next_modal_id["portal_detail_element_id"] = next_vpd_id
        next_modal_id["catalogue_page_number"] = next_rec["page_number"]
        next_modal_id["catalogue_row_order"] = next_rec["row_order"]

        next_proj = engine.create_project(next_rec["catalogue_row_dict"])
        next_iv = engine.verify_project_identity(next_proj, next_modal_id)
        result_report["cleanup_verification"]["next_project_identity_verification"] = (
            next_iv.model_dump(mode="json")
        )
        result_report["cleanup_verification"]["next_project_clickable_and_verified"] = bool(
            next_iv.is_verified
        )

        close_project_modal_in_dom(page)
        browser.close()

    completed_at = datetime.now(timezone.utc)
    result_report["completed_at_utc"] = completed_at.isoformat()
    result_report["duration_seconds"] = round(
        (completed_at - started_at).total_seconds(), 2
    )
    result_report["smoke_test_passed"] = bool(
        result_report["live_html_captured"]
        and result_report["pre_parse_identity_verification"]["is_verified"]
        and result_report["extraction_status"] == "successful"
        and len(result_report["extraction_errors"]) == 0
        and result_report["cleanup_verification"]["modal_hidden_after_close"]
        and result_report["cleanup_verification"]["backdrop_count_after_close"] == 0
        and result_report["cleanup_verification"]["body_modal_open_class_removed"]
        and result_report["cleanup_verification"]["result_container_cleared"]
        and result_report["cleanup_verification"]["next_project_clickable_and_verified"]
    )

    out_path = reports_dir / "phase2_1_live_smoke_test.json"
    out_path.write_text(
        json.dumps(result_report, indent=2, ensure_ascii=False, default=str),
        encoding="utf-8",
    )
    print(f"[LiveSmoke] Smoke test passed={result_report['smoke_test_passed']}. Wrote {out_path}")
    return result_report


if __name__ == "__main__":
    run_controlled_live_smoke_test(update_live_fixtures=True)
