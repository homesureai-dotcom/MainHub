"""
K-RERA Search Results Extractor — Phase 1 (Visible Playwright Browser)

Scope is strictly limited to the public search-results table for:
- Application status/category: Applications Approved
- District: Bengaluru Urban

Does NOT open individual project-detail pages or download project documents.
Does NOT implement CAPTCHA bypass, stealth, proxy rotation, or DevTools bypass.
"""

from __future__ import annotations

import argparse
import json
import logging
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional

from playwright.sync_api import Page, sync_playwright

from .search_parser import (
    PageExtractionResult,
    PortalSecurityBlockError,
    parse_search_page_html,
)
from .search_storage import DuplicatePageError, SearchExtractionStorage
from .search_validator import generate_validation_report


PORTAL_SEARCH_URL = "https://rera.karnataka.gov.in/viewAllProjects"
PORTAL_FALLBACK_URL = "https://rera.karnataka.gov.in/projectViewDetails"


def setup_logger(log_path: str | Path = "KRERA-Data-Extraction/logs/extraction.log") -> logging.Logger:
    log_file = Path(log_path)
    log_file.parent.mkdir(parents=True, exist_ok=True)

    logger = logging.getLogger("krera_search_extractor")
    logger.setLevel(logging.INFO)
    logger.handlers.clear()

    fmt = logging.Formatter("%(asctime)s [%(levelname)s] %(message)s")

    fh = logging.FileHandler(log_file, encoding="utf-8")
    fh.setFormatter(fmt)
    logger.addHandler(fh)

    sh = logging.StreamHandler(sys.stdout)
    sh.setFormatter(fmt)
    logger.addHandler(sh)

    return logger


def check_live_page_for_security_block(page: Page, logger: logging.Logger) -> None:
    """Checks the live Playwright page for any visible security warning modal or block."""
    block_phrases = [
        "Due to security reason, This function has been disabled",
        "Access Denied",
        "403 Forbidden",
        "Too Many Requests",
    ]
    for phrase in block_phrases:
        loc = page.get_by_text(phrase, exact=False)
        if loc.count() > 0:
            for i in range(loc.count()):
                if loc.nth(i).is_visible():
                    msg = f"Portal security warning/block visible on page: '{phrase}'"
                    logger.error(msg)
                    raise PortalSecurityBlockError(msg)


def navigate_and_search_bengaluru_urban_approved(
    page: Page,
    logger: logging.Logger,
    district_target: str = "BENGALURU URBAN",
    tab_target: str = "Applications Approved",
) -> Dict[str, Any]:
    """Navigates to the K-RERA project search page, selects Bengaluru Urban,
    executes the search, and selects the Applications Approved tab if present.
    Returns a summary of discovered DOM elements and active table ID.
    """
    for attempt in range(1, 4):
        try:
            logger.info(
                "Opening K-RERA search portal (attempt %d/3): %s",
                attempt,
                PORTAL_SEARCH_URL,
            )
            page.goto(PORTAL_SEARCH_URL, wait_until="domcontentloaded", timeout=90000)
            page.wait_for_selector("select", timeout=60000)
            break
        except Exception as nav_exc:
            logger.warning("Attempt %d to load %s failed: %s", attempt, PORTAL_SEARCH_URL, nav_exc)
            if attempt == 3:
                raise
            time.sleep(3.0 * attempt)

    check_live_page_for_security_block(page, logger)

    current_url = page.url
    logger.info("Landed on URL: %s | Title: %s", current_url, page.title())

    # Discover all <select> dropdowns and find the District selector dynamically
    selects_info: List[Dict[str, Any]] = []
    district_select_selector: Optional[str] = None
    matched_option_value: Optional[str] = None
    matched_option_label: Optional[str] = None

    select_elements = page.locator("select")
    for i in range(select_elements.count()):
        sel = select_elements.nth(i)
        if not sel.is_visible():
            continue
        sel_id = sel.get_attribute("id") or ""
        sel_name = sel.get_attribute("name") or ""
        options = sel.locator("option")
        opt_list: List[Dict[str, str]] = []
        for j in range(options.count()):
            opt = options.nth(j)
            opt_val = (opt.get_attribute("value") or "").strip()
            opt_txt = (opt.inner_text() or "").strip()
            opt_list.append({"value": opt_val, "label": opt_txt})
            if district_target.lower() in opt_txt.lower() or district_target.lower() in opt_val.lower():
                if sel_id:
                    district_select_selector = f"select#{sel_id}"
                elif sel_name:
                    district_select_selector = f"select[name='{sel_name}']"
                matched_option_value = opt_val
                matched_option_label = opt_txt

        selects_info.append(
            {
                "id": sel_id,
                "name": sel_name,
                "option_count": len(opt_list),
                "sample_options": opt_list[:5],
            }
        )

    if not district_select_selector or matched_option_value is None:
        raise RuntimeError(
            f"Could not locate a visible District dropdown containing '{district_target}'. "
            f"Discovered selects: {json.dumps(selects_info)}"
        )

    logger.info(
        "Selecting district '%s' (value='%s') in '%s'",
        matched_option_label,
        matched_option_value,
        district_select_selector,
    )
    page.locator(district_select_selector).select_option(value=matched_option_value)
    time.sleep(0.5)

    # Locate and click the Search button
    search_btn = page.locator(
        "input[type='submit'][value*='Search' i], "
        "input[type='button'][value*='Search' i], "
        "button:has-text('Search')"
    )
    if search_btn.count() == 0:
        raise RuntimeError("Could not find a visible Search button on the K-RERA search form.")

    logger.info("Clicking Search button and waiting for results table...")
    search_btn.first.click()
    page.wait_for_selector("table thead th", timeout=120000)
    time.sleep(1.0)
    check_live_page_for_security_block(page, logger)

    post_search_url = page.url
    logger.info("Post-search URL: %s", post_search_url)

    # Discover all status tabs on the results page
    tabs_discovered: List[Dict[str, str]] = []
    tab_links = page.locator("ul.nav-tabs a, .nav-tabs a, a[data-toggle='tab']")
    target_tab_locator = None

    for i in range(tab_links.count()):
        t = tab_links.nth(i)
        if not t.is_visible():
            continue
        t_text = " ".join((t.inner_text() or "").split())
        t_href = t.get_attribute("href") or ""
        t_onclick = t.get_attribute("onclick") or ""
        t_id = t.get_attribute("id") or ""
        tabs_discovered.append(
            {"text": t_text, "href": t_href, "onclick": t_onclick, "id": t_id}
        )
        if tab_target.lower() in t_text.lower():
            target_tab_locator = t

    logger.info("Discovered status tabs: %s", json.dumps(tabs_discovered))

    active_table_id: Optional[str] = None
    if target_tab_locator is not None:
        t_href = target_tab_locator.get_attribute("href") or ""
        t_onclick = target_tab_locator.get_attribute("onclick") or ""
        logger.info(
            "Clicking target tab '%s' (href='%s', onclick='%s')...",
            tab_target,
            t_href,
            t_onclick,
        )
        target_tab_locator.click()
        time.sleep(1.5)
        page.wait_for_load_state("networkidle", timeout=60000)
        check_live_page_for_security_block(page, logger)

        if t_href.startswith("#") and len(t_href) > 1:
            pane_id = t_href[1:]
            pane_tables = page.locator(f'[id="{pane_id}"] table')
            for idx in range(pane_tables.count()):
                tbl = pane_tables.nth(idx)
                if tbl.is_visible() and tbl.locator("tbody").count() > 0:
                    active_table_id = tbl.get_attribute("id")
                    break

    if not active_table_id:
        all_tables = page.locator("table")
        for idx in range(all_tables.count()):
            tbl = all_tables.nth(idx)
            if tbl.is_visible() and tbl.locator("tbody").count() > 0 and tbl.locator("thead th").count() > 0:
                active_table_id = tbl.get_attribute("id")
                break

    # Wait for visible table rows
    page.wait_for_selector("table thead th", timeout=30000)

    return {
        "initial_url": PORTAL_SEARCH_URL,
        "post_search_url": post_search_url,
        "district_select_selector": district_select_selector,
        "selected_district_value": matched_option_value,
        "selected_district_label": matched_option_label,
        "discovered_tabs": tabs_discovered,
        "selected_tab_target": tab_target,
        "active_table_id": active_table_id,
    }


def get_active_table_container_selector(active_table_id: Optional[str]) -> str:
    """Returns the CSS selector for the DataTables wrapper of the active table."""
    if active_table_id:
        return f'[id="{active_table_id}_wrapper"]'
    return ".tab-pane.active .dataTables_wrapper, .dataTables_wrapper"


def click_next_page_and_wait(
    page: Page,
    active_table_id: Optional[str],
    previous_first_row_text: str,
    expected_next_page: int,
    logger: logging.Logger,
    timeout_ms: int = 30000,
) -> bool:
    """Clicks the visible Next pagination control for the active table and waits for the table to update."""
    if active_table_id:
        next_selector = (
            f'[id="{active_table_id}_wrapper"] .dataTables_paginate a.next, '
            f'[id="{active_table_id}_wrapper"] .pagination li.next a, '
            f'[id="{active_table_id}_next"] a, '
            f'[id="{active_table_id}_next"]'
        )
        table_first_row_selector = f'[id="{active_table_id}"] tbody tr:first-child'
    else:
        next_selector = ".tab-pane.active .dataTables_paginate a.next, .dataTables_paginate a.next"
        table_first_row_selector = ".tab-pane.active table tbody tr:first-child, table.dataTable tbody tr:first-child"

    next_btn = page.locator(next_selector).first
    if next_btn.count() == 0 or not next_btn.is_visible():
        logger.info("No visible Next button found for selector: %s", next_selector)
        return False

    classes = (next_btn.get_attribute("class") or "").lower()
    if "disabled" in classes or next_btn.get_attribute("aria-disabled") == "true":
        logger.info("Next button is disabled; reached last page.")
        return False

    next_btn.scroll_into_view_if_needed()
    next_btn.click()

    # Poll until first row text changes or active page number advances
    deadline = time.time() + (timeout_ms / 1000.0)
    while time.time() < deadline:
        check_live_page_for_security_block(page, logger)
        first_row_loc = page.locator(table_first_row_selector).first
        if first_row_loc.count() > 0:
            current_first_text = " ".join((first_row_loc.inner_text() or "").split())
            if current_first_text and current_first_text != previous_first_row_text:
                return True
        time.sleep(0.15)

    logger.warning(
        "Timed out waiting for first row text to change after clicking Next for page %d.",
        expected_next_page,
    )
    return True


def run_extraction(
    mode: str = "inspect",
    max_pages: Optional[int] = 1,
    delay_seconds: float = 1.0,
    reset_storage: bool = False,
    overwrite_completed: bool = False,
) -> Dict[str, Any]:
    """Main entry point for live DOM inspection, POC extraction, and full extraction."""
    logger = setup_logger()
    filter_config = {
        "application_status": "Applications Approved",
        "district": "Bengaluru Urban",
    }

    storage = SearchExtractionStorage()
    run_id = storage.start_or_resume_run(
        filter_config=filter_config,
        source_url=PORTAL_SEARCH_URL,
        reset=reset_storage,
    )
    completed_pages = storage.get_completed_pages()
    logger.info(
        "Started extraction run_id=%d (mode=%s, max_pages=%s, previously_completed_pages=%d)",
        run_id,
        mode,
        max_pages,
        len(completed_pages),
    )

    reached_last_page = False
    pages_extracted_this_session = 0
    stop_reason = None
    run_status = "IN_PROGRESS"

    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=False)
            context = browser.new_context(viewport={"width": 1440, "height": 900})
            page = context.new_page()

            nav_info = navigate_and_search_bengaluru_urban_approved(
                page=page,
                logger=logger,
                district_target="BENGALURU URBAN",
                tab_target="Applications Approved",
            )
            active_table_id = nav_info.get("active_table_id")

            # Parse Page 1
            screenshot_path = Path("KRERA-Data-Extraction/research/screenshots/page_1_live_poc.png")
            screenshot_path.parent.mkdir(parents=True, exist_ok=True)
            page.screenshot(path=str(screenshot_path), full_page=False)
            logger.info("Saved live browser verification screenshot to %s", screenshot_path)

            html_p1 = page.content()
            p1_result = parse_search_page_html(
                html_content=html_p1,
                source_url=page.url,
                filter_config=filter_config,
                expected_page_number=1,
                table_selector_id=active_table_id,
            )

            logger.info(
                "DOM Inspection Summary: table_id=%s | headers=%s | rows_on_page_1=%d | "
                "portal_reported_total=%s | info_text='%s' | visible_pagination=%s",
                active_table_id,
                p1_result.column_headers,
                len(p1_result.rows),
                p1_result.pagination.portal_reported_total,
                p1_result.pagination.info_text_raw,
                p1_result.pagination.visible_controls,
            )

            if mode == "inspect":
                run_status = "INSPECT_ONLY"
                stop_reason = "DOM inspection completed"
                browser.close()
                return {
                    "navigation": nav_info,
                    "column_headers": p1_result.column_headers,
                    "page_1_row_count": len(p1_result.rows),
                    "portal_reported_total": p1_result.pagination.portal_reported_total,
                    "pagination_info": p1_result.pagination.info_text_raw,
                    "last_page_number": p1_result.pagination.last_page_number,
                    "sample_first_row": p1_result.rows[0].to_jsonl_dict() if p1_result.rows else None,
                    "sample_last_row": p1_result.rows[-1].to_jsonl_dict() if p1_result.rows else None,
                }

            current_page_num = 1
            current_result: PageExtractionResult = p1_result

            while True:
                if current_page_num not in completed_pages or overwrite_completed:
                    inserted, dupes = storage.save_page_result(
                        run_id=run_id,
                        page_result=current_result,
                        overwrite_page=overwrite_completed,
                    )
                    completed_pages.add(current_page_num)
                    pages_extracted_this_session += 1
                    logger.info(
                        "Saved Page %d (%d rows, %d duplicates) | First=%s | Last=%s",
                        current_page_num,
                        inserted,
                        dupes,
                        current_result.first_record_key,
                        current_result.last_record_key,
                    )
                else:
                    logger.info(
                        "Skipping already-completed Page %d during resume.",
                        current_page_num,
                    )

                if current_result.pagination.next_disabled or not current_result.pagination.has_next:
                    reached_last_page = True
                    stop_reason = f"Reached final page ({current_page_num})"
                    logger.info(stop_reason)
                    break

                if max_pages is not None and current_page_num >= max_pages:
                    stop_reason = f"Reached configured --max-pages={max_pages}"
                    logger.info(stop_reason)
                    break

                if delay_seconds > 0:
                    time.sleep(delay_seconds)

                # Capture first row text before clicking Next
                if active_table_id:
                    first_row_loc = page.locator(f'[id="{active_table_id}"] tbody tr:first-child').first
                else:
                    first_row_loc = page.locator("table.dataTable tbody tr:first-child").first
                prev_first_text = (
                    " ".join((first_row_loc.inner_text() or "").split())
                    if first_row_loc.count() > 0
                    else ""
                )

                next_page_num = current_page_num + 1
                advanced = click_next_page_and_wait(
                    page=page,
                    active_table_id=active_table_id,
                    previous_first_row_text=prev_first_text,
                    expected_next_page=next_page_num,
                    logger=logger,
                )
                if not advanced:
                    reached_last_page = True
                    stop_reason = f"Next pagination control no longer available after page {current_page_num}"
                    logger.info(stop_reason)
                    break

                if active_table_id and page.locator(f'[id="{active_table_id}_wrapper"]').count() > 0:
                    html_next = page.locator(f'[id="{active_table_id}_wrapper"]').first.evaluate(
                        "el => el.outerHTML"
                    )
                else:
                    html_next = page.content()

                current_result = parse_search_page_html(
                    html_content=html_next,
                    source_url=page.url,
                    filter_config=filter_config,
                    expected_page_number=next_page_num,
                    table_selector_id=active_table_id,
                )
                current_page_num = current_result.page_number

            run_status = "COMPLETED"
            browser.close()

    except PortalSecurityBlockError as sec_err:
        run_status = "BLOCKED_BY_SECURITY_WARNING"
        stop_reason = str(sec_err)
        logger.error("Stopping immediately due to portal security restriction: %s", sec_err)
    except DuplicatePageError as dup_err:
        run_status = "STOPPED_DUPLICATE_PAGE"
        stop_reason = str(dup_err)
        logger.error("Stopping due to duplicate page detection: %s", dup_err)
    except Exception as exc:
        run_status = "FAILED"
        stop_reason = f"{type(exc).__name__}: {exc}"
        logger.exception("Unhandled error during extraction: %s", exc)
    finally:
        storage.finalize_run(
            run_id=run_id,
            status=run_status,
            reached_last_page=reached_last_page,
            stop_reason=stop_reason,
        )
        exported_count, jsonl_file, csv_file = storage.export_jsonl_and_csv()
        logger.info(
            "Exported %d total rows to %s and %s",
            exported_count,
            jsonl_file,
            csv_file,
        )
        expected_full = max_pages is None
        report = generate_validation_report(
            storage=storage,
            expected_full_run=expected_full,
        )
        logger.info(
            "Validation report written: status=%s | extracted=%d | portal_total=%s | pages=%d",
            report["validation_status"],
            report["total_rows_extracted"],
            report["portal_reported_total"],
            report["pages_processed"],
        )
        storage.close()

    return report


def main() -> None:
    parser = argparse.ArgumentParser(description="K-RERA Search Results Extractor (Phase 1)")
    parser.add_argument(
        "--mode",
        choices=["inspect", "extract"],
        default="inspect",
        help="Mode: 'inspect' (DOM inspection only) or 'extract' (extract search rows).",
    )
    parser.add_argument(
        "--max-pages",
        type=int,
        default=1,
        help="Maximum number of pages to extract (use 0 or omit with --full for all pages).",
    )
    parser.add_argument(
        "--full",
        action="store_true",
        help="Extract all available pages until the final page.",
    )
    parser.add_argument(
        "--delay-seconds",
        type=float,
        default=1.0,
        help="Configurable delay in seconds between page navigations.",
    )
    parser.add_argument(
        "--reset",
        action="store_true",
        help="Clear previous SQLite state and start fresh.",
    )
    parser.add_argument(
        "--overwrite-completed",
        action="store_true",
        help="Re-extract pages even if already marked COMPLETED in SQLite.",
    )

    args = parser.parse_args()
    max_p = None if args.full or args.max_pages == 0 else args.max_pages
    result = run_extraction(
        mode=args.mode,
        max_pages=max_p,
        delay_seconds=args.delay_seconds,
        reset_storage=args.reset,
        overwrite_completed=args.overwrite_completed,
    )
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
