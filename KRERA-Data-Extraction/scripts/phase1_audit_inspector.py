"""
Phase 1 Data Audit & Live Portal Verification Script (Read-Only)

Investigates:
1. Finding 1: Status mismatch & how K-RERA associates tabs, search forms, and tables
   on `/viewAllProjects` (before search) and `/projectViewDetails` (after search).
2. Finding 3: Project-detail navigation feasibility for Godrej United (`id="6"`,
   `onclick="return showFileApplicationPreview(this);"`).

Strictly read-only with respect to existing extracted datasets.
"""

from __future__ import annotations

import json
import time
from pathlib import Path
from playwright.sync_api import sync_playwright

from .search_extractor import PORTAL_SEARCH_URL, check_live_page_for_security_block, setup_logger


def inspect_page_structure(page) -> dict:
    """Extracts form, tab, tab-pane, table, and inline function definitions from current page DOM."""
    return page.evaluate(
        """() => {
        const forms = Array.from(document.querySelectorAll('form')).map(f => ({
            id: f.id,
            name: f.name,
            action: f.getAttribute('action'),
            method: f.getAttribute('method'),
            inputs: Array.from(f.querySelectorAll('input, select, button')).map(el => ({
                tag: el.tagName.toLowerCase(),
                type: el.getAttribute('type'),
                id: el.id,
                name: el.name,
                value: el.value
            }))
        }));

        const navTabs = Array.from(document.querySelectorAll('ul.nav-tabs li, .nav-tabs li')).map(li => {
            const a = li.querySelector('a');
            return {
                li_class: li.className,
                li_id: li.id,
                a_text: a ? a.innerText.replace(/\\s+/g, ' ').trim() : '',
                a_href: a ? a.getAttribute('href') : '',
                a_onclick: a ? a.getAttribute('onclick') : '',
                a_id: a ? a.id : '',
                a_data_toggle: a ? a.getAttribute('data-toggle') : ''
            };
        });

        const tabPanes = Array.from(document.querySelectorAll('.tab-pane')).map(pane => ({
            id: pane.id,
            className: pane.className,
            tables: Array.from(pane.querySelectorAll('table')).map(t => {
                const infoEl = pane.querySelector('.dataTables_info');
                const bodyRows = Array.from(t.querySelectorAll('tbody tr')).slice(0, 3).map(tr =>
                    Array.from(tr.querySelectorAll('td')).slice(0, 8).map(td => td.innerText.replace(/\\s+/g, ' ').trim())
                );
                return {
                    id: t.id,
                    className: t.className,
                    thead_cols: Array.from(t.querySelectorAll('thead th')).map(th => th.innerText.replace(/\\s+/g, ' ').trim()),
                    tbody_tr_count: t.querySelectorAll('tbody tr').length,
                    info_text: infoEl ? infoEl.innerText.replace(/\\s+/g, ' ').trim() : null,
                    sample_rows: bodyRows
                };
            })
        }));

        const allTables = Array.from(document.querySelectorAll('table')).map(t => {
            const wrapper = t.closest('.dataTables_wrapper');
            const infoEl = wrapper ? wrapper.querySelector('.dataTables_info') : null;
            return {
                id: t.id,
                parent_pane_id: t.closest('.tab-pane') ? t.closest('.tab-pane').id : null,
                thead_cols_count: t.querySelectorAll('thead th').length,
                tbody_tr_count: t.querySelectorAll('tbody tr').length,
                info_text: infoEl ? infoEl.innerText.replace(/\\s+/g, ' ').trim() : null
            };
        });

        // Find showFileApplicationPreview script definition if present
        let previewFnSource = null;
        if (typeof window.showFileApplicationPreview === 'function') {
            previewFnSource = window.showFileApplicationPreview.toString();
        } else {
            const scripts = Array.from(document.querySelectorAll('script')).map(s => s.innerText);
            for (const s of scripts) {
                if (s.includes('showFileApplicationPreview')) {
                    const idx = s.indexOf('showFileApplicationPreview');
                    previewFnSource = s.substring(Math.max(0, idx - 100), Math.min(s.length, idx + 1200));
                    break;
                }
            }
        }

        return {
            url: window.location.href,
            title: document.title,
            forms,
            navTabs,
            tabPanes,
            allTables,
            previewFnSource
        };
    }"""
    )


def run_live_audit() -> dict:
    logger = setup_logger("KRERA-Data-Extraction/logs/audit_inspection.log")
    audit_results: dict = {}

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False)
        context = browser.new_context(viewport={"width": 1440, "height": 900})
        page = context.new_page()

        # 1. Inspect /viewAllProjects BEFORE search
        logger.info("Navigating to %s (Pre-search inspection)...", PORTAL_SEARCH_URL)
        page.goto(PORTAL_SEARCH_URL, wait_until="domcontentloaded", timeout=90000)
        page.wait_for_selector("select", timeout=60000)
        time.sleep(2.0)
        check_live_page_for_security_block(page, logger)

        pre_search_dom = inspect_page_structure(page)
        audit_results["pre_search_viewAllProjects"] = pre_search_dom
        logger.info("Captured pre-search DOM structure on %s", page.url)

        # 2. Select Bengaluru Urban and click Search -> /projectViewDetails
        logger.info("Selecting Bengaluru Urban and submitting search...")
        page.locator("select#projectDist").select_option(value="Bengaluru Urban")
        time.sleep(0.5)
        page.locator("input[type='submit'][value*='Search' i], button:has-text('Search')").first.click()
        page.wait_for_selector("table thead th", timeout=120000)
        time.sleep(2.0)
        check_live_page_for_security_block(page, logger)

        post_search_initial_dom = inspect_page_structure(page)
        audit_results["post_search_initial_projectViewDetails"] = post_search_initial_dom
        logger.info("Captured initial post-search DOM structure on %s", page.url)

        # 3. Click 'Applications Approved' tab and inspect DOM
        approved_tab = page.locator("ul.nav-tabs a, .nav-tabs a").filter(has_text="Applications Approved").first
        if approved_tab.count() > 0:
            approved_tab.click()
            time.sleep(1.5)
            audit_results["after_clicking_approved_tab"] = inspect_page_structure(page)

        # 4. Also check what happens when clicking 'Applications Rejected (957)' (href='#3')
        rejected_tab = page.locator("ul.nav-tabs a, .nav-tabs a").filter(has_text="Applications Rejected").first
        if rejected_tab.count() > 0:
            rejected_tab.click()
            time.sleep(1.5)
            audit_results["after_clicking_rejected_tab"] = inspect_page_structure(page)
            # Switch back to Applications Approved
            approved_tab.click()
            time.sleep(1.5)

        # 5. Finding 3: Test opening Godrej United ('View Project Details', id='6')
        logger.info("Testing project-detail navigation for Godrej United (id='6')...")
        godrej_link = page.locator("table#approvedTable a[id='6'][onclick*='showFileApplicationPreview']").first
        if godrej_link.count() == 0:
            godrej_link = page.locator("table#approvedTable tbody tr:first-child a[onclick*='showFileApplicationPreview']").first

        link_attrs = godrej_link.evaluate(
            """el => ({
                tag: el.tagName.toLowerCase(),
                id: el.id,
                href: el.getAttribute('href'),
                onclick: el.getAttribute('onclick'),
                title: el.getAttribute('title'),
                outerHTML: el.outerHTML
            })"""
        )
        logger.info("Godrej United link attributes: %s", json.dumps(link_attrs))

        godrej_link.click()
        # Wait for either navigation or AJAX detail content load
        time.sleep(4.0)
        page.wait_for_load_state("domcontentloaded", timeout=60000)
        check_live_page_for_security_block(page, logger)

        screenshot_detail = Path("KRERA-Data-Extraction/research/screenshots/godrej_united_detail_live.png")
        screenshot_detail.parent.mkdir(parents=True, exist_ok=True)
        page.screenshot(path=str(screenshot_detail), full_page=False)

        detail_dom = page.evaluate(
            """() => {
                const navTabs = Array.from(document.querySelectorAll('ul.nav-tabs li a, .nav-tabs a')).map(a => ({
                    text: a.innerText.replace(/\\s+/g, ' ').trim(),
                    href: a.getAttribute('href'),
                    onclick: a.getAttribute('onclick')
                }));
                const headings = Array.from(document.querySelectorAll('h1, h2, h3, h4, .panel-heading, .breadcrumb')).map(h =>
                    h.innerText.replace(/\\s+/g, ' ').trim()
                ).filter(Boolean).slice(0, 20);
                const bodySnippet = document.body.innerText.replace(/\\s+/g, ' ').trim().substring(0, 1500);
                return {
                    url: window.location.href,
                    title: document.title,
                    navTabs,
                    headings,
                    bodySnippet
                };
            }"""
        )
        audit_results["godrej_united_detail_navigation"] = {
            "clicked_link_attributes": link_attrs,
            "resulting_page": detail_dom,
            "screenshot_path": str(screenshot_detail),
        }

        browser.close()

    out_file = Path("KRERA-Data-Extraction/reports/live_audit_dom_evidence.json")
    out_file.parent.mkdir(parents=True, exist_ok=True)
    with out_file.open("w", encoding="utf-8") as f:
        json.dump(audit_results, f, indent=2, ensure_ascii=False)

    return audit_results


if __name__ == "__main__":
    res = run_live_audit()
    print("Audit completed. Saved to KRERA-Data-Extraction/reports/live_audit_dom_evidence.json")
