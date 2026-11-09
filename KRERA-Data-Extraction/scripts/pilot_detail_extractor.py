"""
HomeSure K-RERA Phase 2 — Five-Project Detail Extraction Pilot

Controlled discovery-driven project-detail extraction engine using the Phase 1
SQLite catalogue (`data/k_rera_extraction.sqlite`) and K-RERA's native visible
Playwright browser interaction (`showFileApplicationPreview`).

Scope:
- Strictly limited to the 5-project pilot sample (no bulk extraction, no document file downloads).
- Dynamically resolves each project's catalogue row, page number, and `view_project_details`
  element ID (`vpd_id`) from `data/k_rera_extraction.sqlite`.
- Verifies opened modal identity (`Project Name`, `Acknowledgement Number`, `Registration Number`)
  against the source catalogue record.
- Separates raw DOM extraction outputs (`data/pilot/raw/*.json`) from normalized discovery
  outputs (`data/pilot/normalized/*.json`).
- Enforces PII exclusion at the ingestion boundary (PAN numbers/documents, personal photographs,
  and individual residential addresses/contacts are redacted and logged as `PIIExclusionRecord`).
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional

from playwright.sync_api import Page, sync_playwright

# Ensure project root is importable when executed directly
REPO_ROOT = Path(__file__).resolve().parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from scripts.detail_dom_parser import parse_project_detail_modal_html
from scripts.discovery_engine import KRERADiscoveryEngine

PILOT_SAMPLE_SPECS = [
    {
        "pilot_index": 1,
        "slug": "godrej_united",
        "file_prefix": "01_godrej_united",
        "registration_no": "PRM/KA/RERA/1251/446/PR/171010/000003",
        "expected_name": "Godrej United",
        "selection_rationale": (
            "Known pilot project #1 (Legacy 2017 schema, 7 visible nav tabs, "
            "full post-19/12/2020 Completion Details structure with Project Cost Details, "
            "Development Details, Uploaded Documents, and Photos Uploaded)."
        ),
    },
    {
        "pilot_index": 2,
        "slug": "godrej_air",
        "file_prefix": "02_godrej_air",
        "registration_no": "PRM/KA/RERA/1251/446/PR/170819/000006",
        "expected_name": "Godrej Air",
        "selection_rationale": (
            "Known pilot project #2 (Legacy 2017 schema, 7 visible nav tabs, "
            "full post-19/12/2020 Completion Details with tabular Inventory Details "
            "and 22 completion/site photo links)."
        ),
    },
    {
        "pilot_index": 3,
        "slug": "prestige_boulevard",
        "file_prefix": "03_prestige_boulevard",
        "registration_no": "PRM/KA/RERA/1251/446/PR/170824/000057",
        "expected_name": "PRESTIGE BOULEVARD",
        "selection_rationale": (
            "Known pilot project #3 (Legacy 2017 schema, 7 visible nav tabs, "
            "short pre-19/12/2020 Completion Details structure with only 4 document "
            "entries and malformed 01-01-0001 approval date anomaly, plus 77 Promoter "
            "complaints vs 0 Project complaints)."
        ),
    },
    {
        "pilot_index": 4,
        "slug": "ecopolis_block_2",
        "file_prefix": "04_ecopolis_block_2",
        "registration_no": "PRM/KA/RERA/1251/309/PR/171014/000662",
        "expected_name": "ecopolis Block-2",
        "selection_rationale": (
            "Additional APPROVED project #4 where Completion Details navigation tab is "
            "absent (only 6 visible nav tabs; unlinked #completion DOM template is empty; "
            "Enquired Documents, Complaints, and Quarterly Updates are present_empty)."
        ),
    },
    {
        "pilot_index": 5,
        "slug": "hasiru_visthara",
        "file_prefix": "05_hasiru_visthara",
        "registration_no": "PRM/KA/RERA/1251/310/PR/311026/009069",
        "expected_name": "HASIRU VISTHARA",
        "selection_rationale": (
            "Additional APPROVED project #5 with a materially different modern 8-tab "
            "schema (Promoter Details with tabular Partner/Land Owner sections, Land Details, "
            "14-table Project Details with TDR/Sub-Structure/Super-Structure, commented-out "
            "populated Cost Details DOM pane, Bank Details, 4-column Uploaded Documents, "
            "populated Enquired Documents table with 4 documents, and absent Completion Details)."
        ),
    },
]

# JavaScript helper to scrub PII inside a live DOM clone before saving HTML test fixtures
JS_EXTRACT_SCRUBBED_MODAL_HTML = """
() => {
    const res = document.querySelector('#result');
    if (!res) return '';
    const clone = res.cloneNode(true);
    const panRegex = /(?<![A-Za-z0-9])[A-Z]{5}[0-9]{4}[A-Z](?![A-Za-z0-9])/g;
    const panLabelRegex = /\\bpan\\b|\\bpan\\s+number\\b|\\bpan\\s+card\\b|\\baadhaar\\b|\\baadhar\\b/i;

    // 1. Replace any text node matching Indian PAN format (10-char alphanumeric)
    const walker = document.createTreeWalker(clone, NodeFilter.SHOW_TEXT);
    const textNodes = [];
    while (walker.nextNode()) textNodes.push(walker.currentNode);
    for (const tn of textNodes) {
        if (panRegex.test(tn.nodeValue)) {
            tn.nodeValue = tn.nodeValue.replace(panRegex, 'SYNTHETIC_PAN_REDACTED');
        }
    }

    // 2. Redact PAN document links and personal photographs in #home (Promoter Details)
    clone.querySelectorAll('.row').forEach(row => {
        const cols = Array.from(row.children).filter(c => c.tagName === 'DIV');
        for (let i = 0; i + 1 < cols.length; i += 2) {
            const lbl = (cols[i].innerText || '').trim();
            const lblLow = lbl.toLowerCase();
            if (panLabelRegex.test(lblLow)) {
                const a = cols[i+1].querySelector('a');
                if (a) {
                    a.setAttribute('href', 'https://rera.karnataka.gov.in/download_jc?DOC_ID=REDACTED_PAN_DOC');
                    a.textContent = 'SYNTHETIC_PAN_DOC.pdf';
                } else {
                    cols[i+1].textContent = 'SYNTHETIC_PAN_REDACTED';
                }
            }
            const inPromoterPane = Boolean(row.closest('#home'));
            if (inPromoterPane && /\\bphotograph\\b|\\bphoto\\s+id\\b|\\bphoto\\b/i.test(lblLow) && !lblLow.includes('project photo')) {
                const a = cols[i+1].querySelector('a');
                if (a) {
                    a.setAttribute('href', 'https://rera.karnataka.gov.in/download_jc?DOC_ID=REDACTED_PHOTO_DOC');
                    a.textContent = 'SYNTHETIC_PERSONAL_PHOTO.jpg';
                }
            }
            // Redact individual residential address values inside Authorized Signatory / Individual sections
            if (/\\bpresent\\s+address\\b|\\bpermanent\\s+address\\b|\\bresidential\\s+address\\b/i.test(lblLow)) {
                cols[i+1].textContent = 'SYNTHETIC_INDIVIDUAL_ADDRESS_REDACTED';
            }
        }
    });

    // Redact Signatory / Individual address in #home .row following 'Authorized Signatory' heading
    const homePane = clone.querySelector('#home');
    if (homePane) {
        let inIndividualSection = false;
        Array.from(homePane.querySelectorAll('h1, h2, h3, h4, .row, table')).forEach(el => {
            if (/^H[1-4]$/.test(el.tagName)) {
                const hTxt = (el.innerText || '').toLowerCase();
                inIndividualSection = /signatory|member|partner|director|land owner|individual/.test(hTxt);
            } else if (inIndividualSection && el.classList.contains('row')) {
                const cols = Array.from(el.children).filter(c => c.tagName === 'DIV');
                for (let i = 0; i + 1 < cols.length; i += 2) {
                    const lblLow = (cols[i].innerText || '').toLowerCase();
                    if (/\\b(address|mobile|phone|mail|email)\\b/i.test(lblLow) && !lblLow.includes('official address')) {
                        cols[i+1].textContent = 'SYNTHETIC_INDIVIDUAL_PII_REDACTED';
                    }
                }
            } else if (inIndividualSection && el.tagName === 'TABLE') {
                // Check headerless 2-col address table or multi-column partner/signatory table
                const ths = Array.from(el.querySelectorAll('th')).map(th => (th.innerText || '').toLowerCase());
                if (ths.length === 0) {
                    el.querySelectorAll('tr').forEach(tr => {
                        const tds = tr.querySelectorAll('td');
                        if (tds.length === 2) {
                            const kLow = (tds[0].innerText || '').toLowerCase();
                            if (/present\\s+address|permanent\\s+address|residential\\s+address/.test(kLow)) {
                                tds[1].textContent = 'SYNTHETIC_INDIVIDUAL_ADDRESS_REDACTED';
                            }
                        }
                    });
                } else {
                    el.querySelectorAll('tbody tr').forEach(tr => {
                        const tds = Array.from(tr.children).filter(c => c.tagName === 'TD');
                        tds.forEach((td, idx) => {
                            const colHdr = ths[idx] || '';
                            if (/\\b(address|mobile|phone|mail|email|pan|aadhaar|aadhar|photo|photograph)\\b/i.test(colHdr) && !colHdr.includes('official address')) {
                                td.textContent = 'SYNTHETIC_INDIVIDUAL_PII_REDACTED';
                            }
                        });
                    });
                }
            }
        });

        // Redact personal <img> tags inside #home
        homePane.querySelectorAll('img').forEach(img => {
            img.setAttribute('src', 'redacted_personal_photo.jpg');
        });
    }

    return clone.innerHTML;
}
"""


def lookup_pilot_catalogue_records(sqlite_path: Path) -> List[Dict[str, Any]]:
    """Queries `raw_search_rows` in `data/k_rera_extraction.sqlite` for the 5 pilot projects."""
    if not sqlite_path.exists():
        raise FileNotFoundError(f"SQLite catalogue not found at {sqlite_path}")

    conn = sqlite3.connect(str(sqlite_path))
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    resolved_records: List[Dict[str, Any]] = []
    for spec in PILOT_SAMPLE_SPECS:
        reg_no = spec["registration_no"]
        cur.execute(
            """
            SELECT record_unique_key, page_number, row_order, row_dict_json, links_json
            FROM raw_search_rows
            WHERE row_dict_json LIKE ?
            ORDER BY id DESC
            LIMIT 1
            """,
            (f'%"{reg_no}"%',),
        )
        row = cur.fetchone()
        if not row:
            raise ValueError(f"Pilot project not found in SQLite catalogue: {spec}")

        row_dict = json.loads(row["row_dict_json"])
        links_data = json.loads(row["links_json"])
        vpd_info: Dict[str, Any] = {}
        if isinstance(links_data, dict):
            vpd_info = links_data.get("view_project_details", {})
        elif isinstance(links_data, list):
            for lnk in links_data:
                if (
                    "showFileApplicationPreview" in (lnk.get("onclick") or "")
                    or "VIEW PROJECT DETAILS" in (lnk.get("column") or "").upper()
                ):
                    vpd_info = lnk
                    break
        vpd_id = vpd_info.get("element_id") or vpd_info.get("id")
        if not vpd_id:
            raise ValueError(f"Missing view_project_details element_id for {reg_no}: {links_data}")

        resolved_records.append(
            {
                **spec,
                "record_key": row["record_unique_key"],
                "page_number": int(row["page_number"]),
                "row_order": int(row["row_order"]),
                "ack_no": row_dict.get("ACKNOWLEDGEMENT NO"),
                "reg_no": row_dict.get("REGISTRATION NO"),
                "project_name": row_dict.get("PROJECT NAME"),
                "promoter_name": row_dict.get("PROMOTER NAME"),
                "status": row_dict.get("STATUS"),
                "vpd_id": str(vpd_id),
                "vpd_onclick": vpd_info.get("onclick"),
                "catalogue_row_dict": row_dict,
            }
        )

    conn.close()
    return resolved_records


def navigate_to_datatable_page(page: Page, target_page: int, current_page: int) -> int:
    """Navigates K-RERA's `#approvedTable` DataTables pagination to `target_page`."""
    if target_page == current_page:
        return current_page

    def get_first_row_s_no() -> str:
        loc = page.locator("#approvedTable tbody tr").first.locator("td").first
        return (loc.inner_text() or "").strip()

    before_sno = get_first_row_s_no()

    # Check if target_page is the Last page (446)
    last_btn = page.locator("#approvedTable_paginate a", has_text=re.compile(r"^Last$", re.I))
    page_btn = page.locator(
        "#approvedTable_paginate a",
        has_text=re.compile(rf"^{target_page}$"),
    )

    if page_btn.count() > 0 and page_btn.first.is_visible():
        page_btn.first.click()
    elif target_page >= 440 and last_btn.count() > 0 and last_btn.first.is_visible():
        last_btn.first.click()
    else:
        # Use DataTables API if intermediate page link is not directly visible in paginate bar
        page.evaluate(f"$('#approvedTable').DataTable().page({target_page - 1}).draw('page');")

    # Wait until first row S.No changes
    for _ in range(30):
        time.sleep(0.3)
        now_sno = get_first_row_s_no()
        if now_sno and now_sno != before_sno:
            break

    return target_page


def close_project_modal_in_dom(page: Page) -> None:
    """Closes `#project_details_popup` cleanly via DOM manipulation and restores original jQuery/DataTable bindings."""
    page.evaluate(
        """
        () => {
            const popup = document.querySelector('#project_details_popup');
            if (popup) {
                popup.classList.remove('in');
                popup.style.display = 'none';
                popup.setAttribute('aria-hidden', 'true');
            }
            document.querySelectorAll('.modal-backdrop').forEach(el => el.remove());
            document.body.classList.remove('modal-open');
            document.body.style.paddingRight = '';
            const res = document.querySelector('#result');
            if (res) res.innerHTML = '';
            if (window.__kreraOrigJQuery) {
                window.jQuery = window.__kreraOrigJQuery;
                window.$ = window.__kreraOrigDollar || window.__kreraOrigJQuery;
            }
        }
        """
    )
    time.sleep(0.4)


def capture_live_pilot_modals(
    pilot_records: List[Dict[str, Any]],
    fixtures_dir: Path,
) -> Dict[str, str]:
    """Opens K-RERA in a visible Playwright browser, navigates to each pilot project, and extracts scrubbed modal HTML."""
    fixtures_dir.mkdir(parents=True, exist_ok=True)
    html_by_slug: Dict[str, str] = {}

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False)
        context = browser.new_context(viewport={"width": 1440, "height": 900})
        page = context.new_page()

        print("[Pilot] Opening https://rera.karnataka.gov.in/viewAllProjects in visible browser...")
        page.goto("https://rera.karnataka.gov.in/viewAllProjects", timeout=60000)
        page.wait_for_load_state("networkidle")

        # Select Bengaluru Urban and execute search
        district_select = page.locator("select#projectDist")
        district_select.select_option(label="Bengaluru Urban")
        time.sleep(0.5)

        search_btn = page.locator("input[type='submit'][value='Search'], button:has-text('Search')").first
        search_btn.click()

        page.wait_for_selector("#approvedTable tbody tr", timeout=60000)
        time.sleep(1.5)
        current_dt_page = 1

        for rec in pilot_records:
            slug = rec["slug"]
            target_page = rec["page_number"]
            vpd_id = rec["vpd_id"]
            expected_name = rec["project_name"]
            expected_reg = rec["reg_no"]

            print(
                f"[Pilot] Navigating to Page {target_page} for #{rec['pilot_index']} "
                f"'{expected_name}' (vpd_id='{vpd_id}', reg='{expected_reg}')..."
            )
            current_dt_page = navigate_to_datatable_page(page, target_page, current_dt_page)

            # Locate the native View Project Details anchor by ID and onclick handler
            anchor = page.locator(f"#approvedTable a[id='{vpd_id}'][onclick*='showFileApplicationPreview']").first
            if anchor.count() == 0:
                raise RuntimeError(
                    f"Could not find anchor a[id='{vpd_id}'] on DataTables page {target_page} for {expected_name}"
                )

            anchor.scroll_into_view_if_needed()
            anchor.click()

            # Wait for #result to populate with ul.nav-tabs
            page.wait_for_selector("#project_details_popup #result ul.nav-tabs li a", timeout=45000)
            time.sleep(1.2)

            # Extract PII-scrubbed HTML directly from the live DOM
            scrubbed_html = page.evaluate(JS_EXTRACT_SCRUBBED_MODAL_HTML)
            if not scrubbed_html or len(scrubbed_html) < 500:
                raise RuntimeError(f"Empty or truncated #result HTML for {expected_name}")

            fixture_file = fixtures_dir / f"{slug}.html"
            fixture_file.write_text(scrubbed_html, encoding="utf-8")
            html_by_slug[slug] = scrubbed_html
            print(
                f"[Pilot] Captured modal HTML for '{expected_name}' "
                f"({len(scrubbed_html):,} bytes -> {fixture_file.name})"
            )

            close_project_modal_in_dom(page)

        browser.close()

    return html_by_slug


def run_pilot_pipeline(use_live_browser: bool = True) -> Dict[str, Any]:
    """Executes the 5-project pilot pipeline and writes raw, normalized, and summary outputs."""
    sqlite_path = REPO_ROOT / "data" / "k_rera_extraction.sqlite"
    fixtures_dir = REPO_ROOT / "tests" / "fixtures" / "pilot_modals"
    raw_out_dir = REPO_ROOT / "data" / "pilot" / "raw"
    norm_out_dir = REPO_ROOT / "data" / "pilot" / "normalized"
    reports_dir = REPO_ROOT / "reports"

    raw_out_dir.mkdir(parents=True, exist_ok=True)
    norm_out_dir.mkdir(parents=True, exist_ok=True)
    reports_dir.mkdir(parents=True, exist_ok=True)

    pilot_records = lookup_pilot_catalogue_records(sqlite_path)

    if use_live_browser:
        html_by_slug = capture_live_pilot_modals(pilot_records, fixtures_dir)
        extraction_mode = "live_visible_playwright_browser"
    else:
        html_by_slug = {}
        for rec in pilot_records:
            fixture_file = fixtures_dir / f"{rec['slug']}.html"
            if not fixture_file.exists():
                raise FileNotFoundError(f"Missing fixture file: {fixture_file}")
            html_by_slug[rec["slug"]] = fixture_file.read_text(encoding="utf-8")
        extraction_mode = "saved_modal_dom_fixtures"

    engine = KRERADiscoveryEngine(enforce_pii_policy=True)
    project_summaries: List[Dict[str, Any]] = []

    for rec in pilot_records:
        slug = rec["slug"]
        file_prefix = rec["file_prefix"]
        raw_html = html_by_slug[slug]

        # 1. Parse raw DOM payload (with PII scrubbed at raw boundary)
        raw_dom_payload = parse_project_detail_modal_html(
            raw_html=raw_html,
            portal_detail_element_id=rec["vpd_id"],
            catalogue_page_number=rec["page_number"],
            catalogue_row_order=rec["row_order"],
            scrub_raw_pii=True,
        )

        raw_envelope = {
            "pilot_index": rec["pilot_index"],
            "slug": slug,
            "extraction_mode": extraction_mode,
            "extracted_at_utc": datetime.now(timezone.utc).isoformat(),
            "selection_rationale": rec["selection_rationale"],
            "catalogue_record": {
                "record_key": rec["record_key"],
                "page_number": rec["page_number"],
                "row_order": rec["row_order"],
                "vpd_id": rec["vpd_id"],
                "vpd_onclick": rec["vpd_onclick"],
                "ack_no": rec["ack_no"],
                "reg_no": rec["reg_no"],
                "project_name": rec["project_name"],
                "promoter_name": rec["promoter_name"],
                "status": rec["status"],
                "catalogue_row_dict": rec["catalogue_row_dict"],
            },
            "raw_dom_payload": raw_dom_payload,
        }

        raw_file_path = raw_out_dir / f"{file_prefix}_raw.json"
        raw_file_path.write_text(
            json.dumps(raw_envelope, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )

        # 2. Run KRERADiscoveryEngine to produce normalized Project model
        project = engine.create_project(rec["catalogue_row_dict"])
        project = engine.process_project_details(project, raw_dom_payload)

        norm_file_path = norm_out_dir / f"{file_prefix}_normalized.json"
        norm_file_path.write_text(
            project.model_dump_json(indent=2),
            encoding="utf-8",
        )

        # Collect anomalies across fields and documents
        field_anomalies: List[Dict[str, Any]] = []
        doc_anomalies: List[Dict[str, Any]] = []
        all_tabs_and_panes = list(project.tabs.values()) + list(project.unlinked_dom_panes.values())
        for t_obs in all_tabs_and_panes:
            for s_obs in t_obs.sections:
                for f_obs in s_obs.fields:
                    if f_obs.anomaly_flags:
                        field_anomalies.append(
                            {
                                "tab": t_obs.tab_label,
                                "section": s_obs.section_label,
                                "field_label": f_obs.field_label,
                                "raw_value": f_obs.raw_value,
                                "flags": f_obs.anomaly_flags,
                            }
                        )
                for d_obs in s_obs.documents:
                    if d_obs.anomaly_flags:
                        doc_anomalies.append(
                            {
                                "tab": t_obs.tab_label,
                                "section": s_obs.section_label,
                                "category": d_obs.document_category,
                                "filename": d_obs.displayed_filename,
                                "approval_date": d_obs.approval_date_raw,
                                "flags": d_obs.anomaly_flags,
                            }
                        )

        project_summaries.append(
            {
                "pilot_index": rec["pilot_index"],
                "slug": slug,
                "project_id": project.internal_id,
                "project_name": project.project_name,
                "acknowledgement_number": project.acknowledgement_number,
                "registration_number": project.registration_number,
                "promoter_name": project.promoter_name,
                "project_type": project.project_type,
                "status": project.status,
                "extraction_status": project.extraction_status.value,
                "catalogue_page_number": rec["page_number"],
                "catalogue_row_order": rec["row_order"],
                "portal_detail_element_id": rec["vpd_id"],
                "selection_rationale": rec["selection_rationale"],
                "identity_verification": (
                    project.identity_verification.model_dump(mode="json")
                    if project.identity_verification
                    else None
                ),
                "visible_nav_tabs": [
                    {
                        "tab_label": t.tab_label,
                        "tab_identifier": t.tab_identifier,
                        "observation_state": t.observation_state.value,
                        "sections_count": len(t.sections),
                        "sub_tabs": [
                            {
                                "label": st.tab_label,
                                "id": st.tab_identifier,
                                "state": st.observation_state.value,
                            }
                            for st in t.sub_tabs.values()
                        ],
                    }
                    for t in project.tabs.values()
                ],
                "unlinked_dom_panes": [
                    {
                        "pane_id": p_key,
                        "tab_label": p.tab_label,
                        "observation_state": p.observation_state.value,
                        "sections_count": len(p.sections),
                    }
                    for p_key, p in project.unlinked_dom_panes.items()
                ],
                "tabs_not_present": project.coverage.tabs_not_present,
                "coverage": project.coverage.model_dump(mode="json"),
                "pii_exclusions_count": len(project.pii_exclusions),
                "pii_exclusions": [e.model_dump(mode="json") for e in project.pii_exclusions],
                "cross_section_conflicts_count": len(project.cross_section_conflicts),
                "cross_section_conflicts": [
                    c.model_dump(mode="json") for c in project.cross_section_conflicts
                ],
                "field_anomalies": field_anomalies,
                "document_anomalies": doc_anomalies,
                "raw_output_file": str(raw_file_path.relative_to(REPO_ROOT)),
                "normalized_output_file": str(norm_file_path.relative_to(REPO_ROOT)),
            }
        )

    summary_payload = {
        "phase": "Phase 2 — Five-Project Detail Extraction Pilot",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "extraction_mode": extraction_mode,
        "total_pilot_projects": len(project_summaries),
        "all_identities_verified": all(
            p["identity_verification"]["is_verified"] for p in project_summaries
        ),
        "projects": project_summaries,
    }

    summary_path = reports_dir / "phase2_pilot_summary.json"
    summary_path.write_text(
        json.dumps(summary_payload, indent=2, ensure_ascii=False, default=str),
        encoding="utf-8",
    )
    print(f"[Pilot] Wrote consolidated summary to {summary_path}")
    return summary_payload


def main() -> None:
    parser = argparse.ArgumentParser(description="HomeSure K-RERA Phase 2 Five-Project Detail Pilot")
    parser.add_argument(
        "--from-fixtures",
        action="store_true",
        help="Run extraction pipeline against saved modal HTML fixtures without opening a live browser.",
    )
    args = parser.parse_args()
    run_pilot_pipeline(use_live_browser=not args.from_fixtures)


if __name__ == "__main__":
    main()
