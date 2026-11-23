#!/usr/bin/env python3
"""
HomeSure Phase 4 — Incremental K-RERA Catalogue Refresh & Targeted Modal Recovery

Provides two deterministic, resumable, non-destructive modes:
1. `--refresh-catalogue`:
   - Queries live K-RERA (`/viewAllProjects` -> `/projectViewDetails`) for `Bengaluru Urban`
     and `Bengaluru  Rural` via session-backed read-only POST.
   - Preserves all historical rows in `raw_search_rows` untouched and appends only
     newly discovered `Bengaluru Urban` registrations.
   - Saves `Bengaluru  Rural` separately (`data/phase4_recovery/bengaluru_rural_snapshot.json`)
     without mixing Rural rows into Bengaluru Urban.
   - Runs geographical exception auditing and writes `reports/phase4_geography_audit.json`.

2. `--extract-targeted`:
   - Extracts deep modal payloads for `--wave1-flagship` (11 priority missing projects:
     5 Sobha Neopolis + 5 Assetz 63 Degree East + 1 ASSETZ REN & REI), `--builder SOBHA`,
     `--builder ASSETZ`, `--reg-nos ...`, or `--all-missing-eligible --limit N`.
   - Uses visible Playwright browser (`headless=False`), conservative delays, immediate
     security/CAPTCHA halt, DataTables exact-registration filter (`dt.search(reg).draw()`),
     strict identity verification, PII scrubbing, and SQLite checkpointing (`detail_extraction_checkpoints`).
   - Tracks full run completeness in `phase4_extraction_runs`.
"""

from __future__ import annotations

import argparse
import hashlib
import http.cookiejar
import json
import re
import sqlite3
import ssl
import sys
import time
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

from lxml import html as lxml_html
from playwright.sync_api import Page, sync_playwright

REPO_ROOT = Path(__file__).resolve().parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))
if str(REPO_ROOT / "scripts") not in sys.path:
    sys.path.insert(0, str(REPO_ROOT / "scripts"))

from scripts.detail_batch_safeguards import (
    DetailBatchCoordinator,
    compute_canonical_project_key,
    deduplicate_catalogue_projects,
)
from scripts.detail_dom_parser import extract_modal_identity, parse_project_detail_modal_html
from scripts.discovery_engine import KRERADiscoveryEngine
from scripts.geography import audit_geography_exceptions
from scripts.models import DetailExtractionStatus
from scripts.name_normalization import resolve_builder_identity
from scripts.phase3a_batch_extractor import check_portal_access_restriction, slugify_project_name
from scripts.pilot_detail_extractor import JS_EXTRACT_SCRUBBED_MODAL_HTML, close_project_modal_in_dom

SQLITE_PATH = REPO_ROOT / "data" / "k_rera_extraction.sqlite"
RECOVERY_DIR = REPO_ROOT / "data" / "phase4_recovery"
PHASE4_SQLITE_PATH = RECOVERY_DIR / "phase4_recovery.sqlite"
BATCH_DIR = REPO_ROOT / "data" / "batch_phase4_recovery"
RAW_OUT_DIR = BATCH_DIR / "raw"
NORM_OUT_DIR = BATCH_DIR / "normalized"
REPORTS_DIR = REPO_ROOT / "reports"

FLAGSHIP_WAVE1_REGS = [
    # Sobha Neopolis (5 phases)
    "PRM/KA/RERA/1251/446/PR/200923/006269",
    "PRM/KA/RERA/1251/446/PR/200923/006270",
    "PRM/KA/RERA/1251/446/PR/220923/006282",
    "PRM/KA/RERA/1251/446/PR/220923/006283",
    "PRM/KA/RERA/1251/446/PR/200923/006271",
    # Assetz 63 Degree East (5 registrations under APG Intelli Homes Private Limited)
    "PRM/KA/RERA/1251/446/PR/171030/000980",
    "PRM/KA/RERA/1251/446/PR/190504/002547",
    "PRM/KA/RERA/1251/446/PR/240122/004656",
    "PRM/KA/RERA/1251/446/PR/201222/005546",
    "PRM/KA/RERA/1251/446/PR/240122/004655",
    # Assetz Ren & Rei (1 registration under APG PREMIUM RESIDENTIAL PRIVATE LIMITED)
    "PRM/KA/RERA/1251/446/PR/130225/007501",
]


def ensure_phase4_catalogue_table(conn: sqlite3.Connection) -> None:
    conn.executescript(
        """
        CREATE TABLE IF NOT EXISTS phase4_urban_catalogue (
            record_key TEXT PRIMARY KEY,
            registration_number TEXT,
            acknowledgement_number TEXT,
            record_unique_key TEXT,
            page_number INTEGER NOT NULL,
            row_order INTEGER NOT NULL,
            cells_json TEXT NOT NULL,
            row_dict_json TEXT NOT NULL,
            links_json TEXT NOT NULL,
            extracted_at TEXT NOT NULL,
            is_new_since_nov5 INTEGER NOT NULL DEFAULT 0
        );
        CREATE INDEX IF NOT EXISTS idx_phase4_urban_reg
            ON phase4_urban_catalogue(registration_number);
        """
    )
    conn.commit()


def ensure_phase4_runs_table(conn: sqlite3.Connection) -> None:
    conn.executescript(
        """
        CREATE TABLE IF NOT EXISTS phase4_extraction_runs (
            run_id INTEGER PRIMARY KEY AUTOINCREMENT,
            started_at TEXT NOT NULL,
            completed_at TEXT,
            geographic_scope TEXT NOT NULL,
            status_filter TEXT NOT NULL,
            pages_discovered INTEGER NOT NULL DEFAULT 0,
            pages_processed INTEGER NOT NULL DEFAULT 0,
            records_discovered INTEGER NOT NULL DEFAULT 0,
            records_extracted INTEGER NOT NULL DEFAULT 0,
            records_failed INTEGER NOT NULL DEFAULT 0,
            records_skipped INTEGER NOT NULL DEFAULT 0,
            unique_registrations INTEGER NOT NULL DEFAULT 0,
            completion_status TEXT NOT NULL DEFAULT 'RUNNING',
            notes TEXT
        );
        """
    )
    conn.commit()


def start_phase4_run(
    conn: sqlite3.Connection,
    scope: str,
    status_filter: str,
    notes: str = "",
) -> int:
    ensure_phase4_runs_table(conn)
    cur = conn.cursor()
    cur.execute(
        """
        INSERT INTO phase4_extraction_runs
        (started_at, geographic_scope, status_filter, completion_status, notes)
        VALUES (?, ?, ?, 'RUNNING', ?)
        """,
        (datetime.now(timezone.utc).isoformat(), scope, status_filter, notes),
    )
    conn.commit()
    return int(cur.lastrowid)


def finish_phase4_run(
    conn: sqlite3.Connection,
    run_id: int,
    *,
    pages_discovered: int,
    pages_processed: int,
    records_discovered: int,
    records_extracted: int,
    records_failed: int,
    records_skipped: int,
    unique_registrations: int,
    completion_status: str,
    notes: str = "",
) -> None:
    conn.execute(
        """
        UPDATE phase4_extraction_runs
        SET completed_at = ?,
            pages_discovered = ?,
            pages_processed = ?,
            records_discovered = ?,
            records_extracted = ?,
            records_failed = ?,
            records_skipped = ?,
            unique_registrations = ?,
            completion_status = ?,
            notes = ?
        WHERE run_id = ?
        """,
        (
            datetime.now(timezone.utc).isoformat(),
            pages_discovered,
            pages_processed,
            records_discovered,
            records_extracted,
            records_failed,
            records_skipped,
            unique_registrations,
            completion_status,
            notes,
            run_id,
        ),
    )
    conn.commit()


def fetch_live_district_table(district_value: str) -> Tuple[List[str], List[Dict[str, Any]]]:
    """Perform a read-only session-backed POST to K-RERA `/projectViewDetails` for a district."""
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    cj = http.cookiejar.CookieJar()
    opener = urllib.request.build_opener(
        urllib.request.HTTPCookieProcessor(cj),
        urllib.request.HTTPSHandler(context=ctx),
    )
    opener.addheaders = [
        ("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
    ]

    opener.open("https://rera.karnataka.gov.in/viewAllProjects", timeout=60).read()
    payload = urllib.parse.urlencode(
        {
            "project": "",
            "firm": "",
            "appNo": "",
            "regNo": "",
            "district": district_value,
            "subdistrict": "",
            "btn1": "Search",
        }
    ).encode("utf-8")
    req = urllib.request.Request(
        "https://rera.karnataka.gov.in/projectViewDetails",
        data=payload,
        headers={
            "Content-Type": "application/x-www-form-urlencoded",
            "Referer": "https://rera.karnataka.gov.in/viewAllProjects",
        },
    )
    body = opener.open(req, timeout=90).read().decode("utf-8", errors="replace")
    doc = lxml_html.fromstring(body)
    tbl = doc.xpath("//table[@id='approvedTable']")
    if not tbl:
        raise RuntimeError(f"Table #approvedTable not found in K-RERA response for district='{district_value}'")
    tbl = tbl[0]

    headers = [" ".join(th.itertext()).strip() for th in tbl.xpath(".//thead//th")]
    parsed_rows: List[Dict[str, Any]] = []
    for tr in tbl.xpath(".//tbody/tr"):
        td_els = tr.xpath("./td")
        if len(td_els) < 5:
            continue
        cells_list = []
        links_list = []
        row_dict = {}
        for idx, td in enumerate(td_els, start=1):
            hdr = headers[idx - 1] if idx - 1 < len(headers) else f"Column_{idx}"
            raw_txt = " ".join(td.itertext()).strip()
            td_links = []
            for a in td.xpath(".//a"):
                link_info: Dict[str, Any] = {"tag": "a"}
                if a.get("onclick"):
                    link_info["onclick"] = a.get("onclick")
                if a.get("href"):
                    link_info["href"] = a.get("href")
                if a.get("id"):
                    link_info["id"] = a.get("id")
                if a.get("title"):
                    link_info["title"] = a.get("title")
                link_info["column_header"] = hdr
                td_links.append(link_info)
                links_list.append(link_info)
            cells_list.append(
                {"column_index": idx, "column_header": hdr, "raw_text": raw_txt, "links": td_links}
            )
            row_dict[hdr] = raw_txt
        parsed_rows.append(
            {
                "row_dict": row_dict,
                "cells_list": cells_list,
                "links_list": links_list,
            }
        )
    return headers, parsed_rows


def run_refresh_catalogue(
    legacy_sqlite_path: Path,
    phase4_sqlite_path: Path = PHASE4_SQLITE_PATH,
) -> Dict[str, Any]:
    """
    Refreshes Bengaluru Urban & Bengaluru Rural live snapshots cleanly without mutating
    the immutable Nov 5 `k_rera_extraction.sqlite` (`raw_search_rows == 4,459`).
    Stores refreshed rows in `phase4_recovery.sqlite` (`phase4_urban_catalogue`) + JSON snapshots.
    """
    RECOVERY_DIR.mkdir(parents=True, exist_ok=True)
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    phase4_sqlite_path.parent.mkdir(parents=True, exist_ok=True)

    conn = sqlite3.connect(str(phase4_sqlite_path))
    ensure_phase4_catalogue_table(conn)
    run_id = start_phase4_run(
        conn,
        scope="Bengaluru Urban + Bengaluru Rural",
        status_filter="ALL (Refresh Catalogue)",
        notes="Live K-RERA catalogue snapshot refresh + rural snapshot + geography audit",
    )

    try:
        print("[Refresh] Fetching live Bengaluru Urban table from K-RERA...")
        headers, urban_rows = fetch_live_district_table("Bengaluru Urban")
        print(f"[Refresh] Live Bengaluru Urban rows: {len(urban_rows)}")

        print("[Refresh] Fetching live Bengaluru Rural table from K-RERA...")
        _, rural_rows = fetch_live_district_table("Bengaluru  Rural")
        print(f"[Refresh] Live Bengaluru Rural rows: {len(rural_rows)}")

        # Save Bengaluru Rural separately (never mixed into Bengaluru Urban)
        rural_records = []
        for idx, item in enumerate(rural_rows, start=1):
            rd = item["row_dict"]
            rural_records.append(
                {
                    "row_index": idx,
                    "registration_number": rd.get("REGISTRATION NO", ""),
                    "acknowledgement_number": rd.get("ACKNOWLEDGEMENT NO", ""),
                    "promoter_name": rd.get("PROMOTER NAME", ""),
                    "project_name": rd.get("PROJECT NAME", ""),
                    "status": (rd.get("STATUS", "").split()[0].upper() if rd.get("STATUS") else ""),
                    "district": rd.get("DISTRICT", ""),
                    "taluk": rd.get("TALUK", ""),
                    "project_type": rd.get("PROJECT TYPE", ""),
                    "approved_on": rd.get("APPROVED ON", ""),
                    "proposed_completion_date": rd.get("PROPOSED COMPLETION DATE", ""),
                }
            )
        rural_out = RECOVERY_DIR / "bengaluru_rural_snapshot.json"
        rural_out.write_text(
            json.dumps(
                {
                    "observed_at_utc": datetime.now(timezone.utc).isoformat(),
                    "district_option_value": "Bengaluru  Rural",
                    "total_rows": len(rural_records),
                    "records": rural_records,
                },
                indent=2,
                ensure_ascii=False,
            ),
            encoding="utf-8",
        )

        # Read baseline Nov 5 registration_numbers & keys read-only from legacy SQLite
        existing_nov5_regs = set()
        existing_nov5_keys = set()
        legacy_conn = sqlite3.connect(f"file:{legacy_sqlite_path}?mode=ro", uri=True)
        try:
            for (rk, cj_str) in legacy_conn.execute(
                "SELECT record_unique_key, cells_json FROM raw_search_rows"
            ).fetchall():
                existing_nov5_keys.add(rk)
                for item in json.loads(cj_str):
                    if isinstance(item, dict) and item.get("column_header") == "REGISTRATION NO":
                        val = (item.get("raw_text") or "").strip().upper()
                        if val:
                            existing_nov5_regs.add(val)
        finally:
            legacy_conn.close()

        now_iso = datetime.now(timezone.utc).isoformat()
        new_rows_since_nov5: List[Dict[str, Any]] = []
        urban_audit_records: List[Dict[str, Any]] = []
        urban_snapshot_records: List[Dict[str, Any]] = []
        skipped_existing = 0

        cur = conn.cursor()
        cur.execute("DELETE FROM phase4_urban_catalogue")
        seen_record_keys = set()

        for idx, item in enumerate(urban_rows):
            rd = item["row_dict"]
            reg_no = rd.get("REGISTRATION NO", "").strip()
            ack_no = rd.get("ACKNOWLEDGEMENT NO", "").strip()
            st = rd.get("STATUS", "").split()[0].upper() if rd.get("STATUS") else ""
            urban_audit_records.append(
                {
                    "registration_number": reg_no,
                    "project_name": rd.get("PROJECT NAME", ""),
                    "district": rd.get("DISTRICT", ""),
                    "taluk": rd.get("TALUK", ""),
                    "status": st,
                }
            )

            rec_key = f"ACK:{ack_no}|REG:{reg_no}" if (ack_no and reg_no) else (f"REG:{reg_no}" if reg_no else f"ACK:{ack_no}")
            canon_pk = f"REG::{reg_no.upper()}" if reg_no else (rec_key or f"IDX::{idx}")
            is_new = 0 if ((reg_no and reg_no.upper() in existing_nov5_regs) or rec_key in existing_nov5_keys) else 1
            if not is_new:
                skipped_existing += 1
            elif reg_no:
                new_rows_since_nov5.append(
                    {
                        "registration_number": reg_no,
                        "acknowledgement_number": ack_no,
                        "promoter_name": rd.get("PROMOTER NAME", ""),
                        "project_name": rd.get("PROJECT NAME", ""),
                        "taluk": rd.get("TALUK", ""),
                        "status": st,
                        "approved_on": rd.get("APPROVED ON", ""),
                    }
                )

            page_num = (idx // 10) + 1
            row_ord = (idx % 10) + 1
            seen_record_keys.add(canon_pk)
            cur.execute(
                """
                INSERT OR REPLACE INTO phase4_urban_catalogue
                (record_key, registration_number, acknowledgement_number, record_unique_key,
                 page_number, row_order, cells_json, row_dict_json, links_json, extracted_at, is_new_since_nov5)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    canon_pk,
                    reg_no,
                    ack_no,
                    rec_key,
                    page_num,
                    row_ord,
                    json.dumps(item["cells_list"], ensure_ascii=False),
                    json.dumps(rd, ensure_ascii=False),
                    json.dumps(item["links_list"], ensure_ascii=False),
                    now_iso,
                    is_new,
                ),
            )
            urban_snapshot_records.append(
                {
                    "row_index": idx + 1,
                    "page_number": page_num,
                    "row_order": row_ord,
                    "registration_number": reg_no,
                    "acknowledgement_number": ack_no,
                    "promoter_name": rd.get("PROMOTER NAME", ""),
                    "project_name": rd.get("PROJECT NAME", ""),
                    "status": st,
                    "district": rd.get("DISTRICT", ""),
                    "taluk": rd.get("TALUK", ""),
                    "project_type": rd.get("PROJECT TYPE", ""),
                    "approved_on": rd.get("APPROVED ON", ""),
                    "proposed_completion_date": rd.get("PROPOSED COMPLETION DATE", ""),
                    "is_new_since_nov5": bool(is_new),
                }
            )

        conn.commit()

        urban_out = RECOVERY_DIR / "bengaluru_urban_live_snapshot.json"
        urban_out.write_text(
            json.dumps(
                {
                    "observed_at_utc": now_iso,
                    "district_option_value": "Bengaluru Urban",
                    "headers": headers,
                    "total_rows": len(urban_snapshot_records),
                    "new_since_nov5_count": len(new_rows_since_nov5),
                    "records": urban_snapshot_records,
                },
                indent=2,
                ensure_ascii=False,
            ),
            encoding="utf-8",
        )

        # Run comprehensive Geography Exception Audit across both Urban & Rural live records
        geo_audit = {
            "generated_at_utc": now_iso,
            "bengaluru_urban_live": audit_geography_exceptions(urban_audit_records),
            "bengaluru_rural_live": audit_geography_exceptions(rural_records),
            "new_urban_rows_since_nov5_count": len(new_rows_since_nov5),
            "new_urban_rows_since_nov5": new_rows_since_nov5,
        }
        geo_audit_path = REPORTS_DIR / "phase4_geography_audit.json"
        geo_audit_path.write_text(json.dumps(geo_audit, indent=2, ensure_ascii=False), encoding="utf-8")

        finish_phase4_run(
            conn,
            run_id,
            pages_discovered=(len(urban_rows) + 9) // 10,
            pages_processed=(len(urban_rows) + 9) // 10,
            records_discovered=len(urban_rows),
            records_extracted=len(new_rows_since_nov5),
            records_failed=0,
            records_skipped=skipped_existing,
            unique_registrations=len(seen_record_keys),
            completion_status="COMPLETED",
            notes=f"Refreshed {len(urban_rows)} Urban rows ({len(new_rows_since_nov5)} new vs Nov 5); saved {len(rural_records)} Rural rows separately.",
        )
        print(
            f"[Refresh] Complete! Refreshed {len(urban_rows)} Bengaluru Urban rows "
            f"({len(new_rows_since_nov5)} new since Nov 5; {skipped_existing} matching baseline). "
            f"Geo audit: {geo_audit_path}"
        )
        return geo_audit
    except Exception as exc:
        finish_phase4_run(
            conn,
            run_id,
            pages_discovered=0,
            pages_processed=0,
            records_discovered=0,
            records_extracted=0,
            records_failed=1,
            records_skipped=0,
            unique_registrations=0,
            completion_status="FAILED",
            notes=str(exc),
        )
        raise
    finally:
        conn.close()


def _parse_catalogue_row_to_candidate(
    row_dict: Dict[str, Any],
    links: List[Any],
    record_unique_key: str,
    page_number: int,
    row_order: int,
) -> Optional[Dict[str, Any]]:
    status_raw = (row_dict.get("STATUS") or "").strip().upper()
    status_canon = status_raw.split()[0] if status_raw else ""
    dist = (row_dict.get("DISTRICT") or "").strip()
    reg_no = (row_dict.get("REGISTRATION NO") or "").strip()
    if status_canon != "APPROVED" or not reg_no or "urban" not in dist.lower():
        return None

    vpd_id = ""
    vpd_onclick = ""
    for lk in links:
        if isinstance(lk, dict) and "showFileApplicationPreview" in str(lk.get("onclick") or ""):
            vpd_id = str(lk.get("id") or "")
            vpd_onclick = str(lk.get("onclick") or "")
            break

    return {
        "record_key": record_unique_key,
        "page_number": int(page_number),
        "row_order": int(row_order),
        "vpd_id": vpd_id,
        "vpd_onclick": vpd_onclick,
        "ack_no": (row_dict.get("ACKNOWLEDGEMENT NO") or "").strip(),
        "reg_no": reg_no,
        "project_name": (row_dict.get("PROJECT NAME") or "").strip(),
        "promoter_name": (row_dict.get("PROMOTER NAME") or "").strip(),
        "project_type": (row_dict.get("PROJECT TYPE") or "").strip(),
        "status": status_canon,
        "approved_on": (row_dict.get("APPROVED ON") or "").strip(),
        "proposed_completion_date": (row_dict.get("PROPOSED COMPLETION DATE") or "").strip(),
        "catalogue_row_dict": row_dict,
    }


def load_approved_catalogue_candidates(
    legacy_sqlite_path: Path,
    phase4_sqlite_path: Path = PHASE4_SQLITE_PATH,
) -> List[Dict[str, Any]]:
    """Load deduplicated APPROVED Bengaluru Urban candidates from baseline + Phase 4 snapshot."""
    by_reg: Dict[str, Dict[str, Any]] = {}

    legacy_conn = sqlite3.connect(f"file:{legacy_sqlite_path}?mode=ro", uri=True)
    legacy_conn.row_factory = sqlite3.Row
    try:
        rows = legacy_conn.execute(
            """
            SELECT page_number, row_order, record_unique_key, row_dict_json, links_json
            FROM raw_search_rows
            ORDER BY id ASC
            """
        ).fetchall()
        for r in rows:
            cand = _parse_catalogue_row_to_candidate(
                json.loads(r["row_dict_json"]),
                json.loads(r["links_json"]),
                r["record_unique_key"],
                r["page_number"],
                r["row_order"],
            )
            if cand:
                by_reg[cand["reg_no"].upper()] = cand
    finally:
        legacy_conn.close()

    if phase4_sqlite_path.exists():
        p4_conn = sqlite3.connect(f"file:{phase4_sqlite_path}?mode=ro", uri=True)
        p4_conn.row_factory = sqlite3.Row
        try:
            has_tbl = p4_conn.execute(
                "SELECT 1 FROM sqlite_master WHERE type='table' AND name='phase4_urban_catalogue'"
            ).fetchone()
            if has_tbl:
                p4_rows = p4_conn.execute(
                    """
                    SELECT page_number, row_order, record_unique_key, row_dict_json, links_json
                    FROM phase4_urban_catalogue
                    ORDER BY page_number ASC, row_order ASC
                    """
                ).fetchall()
                for r in p4_rows:
                    cand = _parse_catalogue_row_to_candidate(
                        json.loads(r["row_dict_json"]),
                        json.loads(r["links_json"]),
                        r["record_unique_key"],
                        r["page_number"],
                        r["row_order"],
                    )
                    if cand:
                        by_reg[cand["reg_no"].upper()] = cand
        finally:
            p4_conn.close()

    return sorted(by_reg.values(), key=lambda x: (x["page_number"], x["row_order"]))


def locate_and_open_modal_by_reg_no(page: Page, reg_no: str, expected_vpd_id: str) -> str:
    """
    Uses preserved DataTables search (`dt.search(reg_no).draw()`) to locate the exact
    project row in <200ms without iterating through 448 pages, then clicks its detail anchor.
    Returns the resolved `vpd_id` attribute.
    """
    resolved_id = page.evaluate(
        """
        ({regNo, expectedId}) => {
            if (window.__kreraOrigJQuery) {
                window.jQuery = window.__kreraOrigJQuery;
                window.$ = window.__kreraOrigDollar || window.__kreraOrigJQuery;
            }
            const dt = window.__kreraDT || window.jQuery('#approvedTable').DataTable();
            dt.search(regNo).draw();
            const rows = Array.from(document.querySelectorAll('#approvedTable tbody tr'));
            for (const tr of rows) {
                if ((tr.innerText || '').toUpperCase().includes(regNo.toUpperCase())) {
                    const a = tr.querySelector("a[onclick*='showFileApplicationPreview']");
                    if (a) return a.getAttribute('id') || expectedId;
                }
            }
            return '';
        }
        """,
        {"regNo": reg_no, "expectedId": expected_vpd_id},
    )
    if not resolved_id:
        raise RuntimeError(f"Could not locate row for registration '{reg_no}' in live #approvedTable")

    time.sleep(0.3)
    anchor = page.locator(
        f"#approvedTable tbody a[id='{resolved_id}'][onclick*='showFileApplicationPreview']"
    ).first
    if anchor.count() == 0:
        raise RuntimeError(f"Anchor a[id='{resolved_id}'] missing after DataTables search for '{reg_no}'")

    anchor.scroll_into_view_if_needed()
    anchor.click()

    page.wait_for_selector("#project_details_popup #result ul.nav-tabs li a", timeout=45000)
    page.wait_for_selector("#project_details_popup #result .tab-content .tab-pane", timeout=45000)
    time.sleep(0.9)
    return str(resolved_id)


def _load_historical_successful_checkpoints(
    legacy_sqlite_path: Path,
) -> Tuple[set[str], set[str]]:
    """Read-only lookup of already-successful checkpoints with valid JSON on disk."""
    done_keys: set[str] = set()
    done_regs: set[str] = set()
    if not legacy_sqlite_path.exists():
        return done_keys, done_regs
    conn = sqlite3.connect(f"file:{legacy_sqlite_path}?mode=ro", uri=True)
    try:
        has_tbl = conn.execute(
            "SELECT 1 FROM sqlite_master WHERE type='table' AND name='detail_extraction_checkpoints'"
        ).fetchone()
        if not has_tbl:
            return done_keys, done_regs
        rows = conn.execute(
            """
            SELECT project_key, registration_number, normalized_output_path
            FROM detail_extraction_checkpoints
            WHERE extraction_status = 'successful'
            """
        ).fetchall()
        for pk, reg, norm_rel in rows:
            if norm_rel and (REPO_ROOT / norm_rel).exists():
                if pk:
                    done_keys.add(str(pk))
                if reg:
                    done_regs.add(str(reg).strip().upper())
    finally:
        conn.close()
    return done_keys, done_regs


def run_targeted_extraction(
    legacy_sqlite_path: Path,
    targets: List[Dict[str, Any]],
    scope_label: str,
    force_reextract: bool = False,
    phase4_sqlite_path: Path = PHASE4_SQLITE_PATH,
) -> Dict[str, Any]:
    """Run controlled Playwright modal extraction for the specified target list."""
    RAW_OUT_DIR.mkdir(parents=True, exist_ok=True)
    NORM_OUT_DIR.mkdir(parents=True, exist_ok=True)
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    phase4_sqlite_path.parent.mkdir(parents=True, exist_ok=True)

    coordinator = DetailBatchCoordinator(sqlite_path=phase4_sqlite_path, max_attempts=3)
    engine = KRERADiscoveryEngine(enforce_pii_policy=True, require_identity_verification=True)
    hist_done_keys, hist_done_regs = _load_historical_successful_checkpoints(legacy_sqlite_path)

    dedup = deduplicate_catalogue_projects(targets)
    unique_targets = dedup.unique_records

    conn = sqlite3.connect(str(phase4_sqlite_path))
    run_id = start_phase4_run(
        conn,
        scope=scope_label,
        status_filter="APPROVED",
        notes=f"Targeted recovery for {len(unique_targets)} registrations",
    )

    # Filter out already-successful checkpoints up front (legacy Phases 1-3D or Phase 4)
    to_extract: List[Dict[str, Any]] = []
    skipped_count = 0
    for rec in unique_targets:
        rec["canonical_project_key"] = compute_canonical_project_key(rec)
        reg_upper = (rec.get("reg_no") or "").strip().upper()
        if not force_reextract and (
            rec["canonical_project_key"] in hist_done_keys or reg_upper in hist_done_regs
        ):
            skipped_count += 1
            continue
        should_run, reason = coordinator.should_extract_project(rec, force=force_reextract)
        cp = coordinator.get_checkpoint(rec["canonical_project_key"])
        if (
            not should_run
            and cp is not None
            and cp.extraction_status == DetailExtractionStatus.SUCCESSFUL
            and cp.normalized_output_path
            and (REPO_ROOT / cp.normalized_output_path).exists()
        ):
            skipped_count += 1
        else:
            to_extract.append(rec)

    print(
        f"[Phase4Recovery] Scope='{scope_label}' | Candidates={len(unique_targets)} | "
        f"Already Successful (skipped)={skipped_count} | Queued for live modal extraction={len(to_extract)}"
    )

    extracted_ok = 0
    failed_count = 0
    interrupted_reason: Optional[str] = None
    outcomes: List[Dict[str, Any]] = []

    if to_extract:
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=False)
            context = browser.new_context(viewport={"width": 1440, "height": 900})
            page = context.new_page()

            for nav_try in range(1, 4):
                try:
                    page.goto(
                        "https://rera.karnataka.gov.in/viewAllProjects",
                        wait_until="load",
                        timeout=120000,
                    )
                    page.wait_for_selector("select#projectDist", timeout=60000)
                    break
                except Exception as exc:
                    if nav_try == 3:
                        browser.close()
                        finish_phase4_run(
                            conn,
                            run_id,
                            pages_discovered=0,
                            pages_processed=0,
                            records_discovered=len(unique_targets),
                            records_extracted=extracted_ok,
                            records_failed=len(to_extract),
                            records_skipped=skipped_count,
                            unique_registrations=len(unique_targets),
                            completion_status="FAILED",
                            notes=f"Initial page load failed: {exc}",
                        )
                        conn.close()
                        raise
                    time.sleep(3.0 * nav_try)

            block = check_portal_access_restriction(page)
            if block:
                browser.close()
                finish_phase4_run(
                    conn,
                    run_id,
                    pages_discovered=0,
                    pages_processed=0,
                    records_discovered=len(unique_targets),
                    records_extracted=0,
                    records_failed=0,
                    records_skipped=skipped_count,
                    unique_registrations=len(unique_targets),
                    completion_status="INCOMPLETE",
                    notes=f"Portal security restriction: {block}",
                )
                conn.close()
                raise RuntimeError(f"Portal security restriction detected: {block}")

            page.locator("select#projectDist").select_option(label="Bengaluru Urban")
            time.sleep(0.5)
            page.locator("input[type='submit'][value='Search'], button:has-text('Search')").first.click()
            page.wait_for_selector("#approvedTable tbody tr", timeout=120000)
            page.wait_for_function(
                "() => typeof showFileApplicationPreview === 'function' && typeof $ !== 'undefined' && $.fn.DataTable && $.fn.DataTable.isDataTable('#approvedTable')",
                timeout=120000,
            )
            page.evaluate(
                """
                () => {
                    window.__kreraOrigJQuery = window.jQuery;
                    window.__kreraOrigDollar = window.$;
                    window.__kreraDT = window.jQuery('#approvedTable').DataTable();
                }
                """
            )
            time.sleep(1.0)

            for idx, rec in enumerate(to_extract, start=1):
                reg_no = rec["reg_no"]
                proj_name = rec["project_name"]
                proj_key = rec["canonical_project_key"]
                slug = slugify_project_name(proj_name, f"rec_{idx:03d}")
                reg_tail = re.sub(r"[^A-Za-z0-9]+", "_", reg_no.split("/")[-1])
                file_prefix = f"{slug}_{reg_tail}"
                raw_path = RAW_OUT_DIR / f"{file_prefix}_raw.json"
                norm_path = NORM_OUT_DIR / f"{file_prefix}_normalized.json"

                block = check_portal_access_restriction(page)
                if block:
                    interrupted_reason = block
                    print(f"[Phase4Recovery] HALTING IMMEDIATELY due to portal restriction: {block}")
                    break

                t0 = time.perf_counter()
                try:
                    resolved_vpd = locate_and_open_modal_by_reg_no(page, reg_no, rec.get("vpd_id", ""))
                    rec["vpd_id"] = resolved_vpd

                    block = check_portal_access_restriction(page)
                    if block:
                        interrupted_reason = block
                        close_project_modal_in_dom(page)
                        break

                    scrubbed_html = page.evaluate(JS_EXTRACT_SCRUBBED_MODAL_HTML)
                    if not scrubbed_html or len(scrubbed_html) < 400:
                        raise RuntimeError(f"Empty/truncated modal HTML for {reg_no}")

                    root_frag = lxml_html.fragment_fromstring(scrubbed_html, create_parent="div")
                    pre_modal_id = extract_modal_identity(root_frag)
                    pre_modal_id["portal_detail_element_id"] = resolved_vpd
                    pre_modal_id["catalogue_page_number"] = rec["page_number"]
                    pre_modal_id["catalogue_row_order"] = rec["row_order"]

                    project = engine.create_project(rec["catalogue_row_dict"])
                    iv = engine.verify_project_identity(project, pre_modal_id)
                    if not iv.is_verified:
                        raw_dom_payload = {
                            "modal_identity": pre_modal_id,
                            "identity_verification_aborted": True,
                            "tabs": [],
                            "unlinked_dom_panes": [],
                        }
                        project = engine.process_project_details(project, raw_dom_payload)
                    else:
                        raw_dom_payload = parse_project_detail_modal_html(
                            raw_html=scrubbed_html,
                            portal_detail_element_id=resolved_vpd,
                            catalogue_page_number=rec["page_number"],
                            catalogue_row_order=rec["row_order"],
                            scrub_raw_pii=True,
                        )
                        project = engine.process_project_details(project, raw_dom_payload)

                    duration_s = round(time.perf_counter() - t0, 2)

                    if project.extraction_status == DetailExtractionStatus.SUCCESSFUL:
                        raw_envelope = {
                            "batch_phase": "Phase 4 — Targeted Missing-Project Recovery",
                            "scope": scope_label,
                            "extracted_at_utc": datetime.now(timezone.utc).isoformat(),
                            "extraction_duration_seconds": duration_s,
                            "catalogue_record": {
                                k: v for k, v in rec.items() if k != "catalogue_row_dict"
                            },
                            "raw_dom_payload": raw_dom_payload,
                        }
                        raw_path.write_text(
                            json.dumps(raw_envelope, indent=2, ensure_ascii=False, default=str),
                            encoding="utf-8",
                        )
                        norm_path.write_text(project.model_dump_json(indent=2), encoding="utf-8")
                        extracted_ok += 1
                    else:
                        failed_count += 1

                    coordinator.record_project_outcome(
                        record=rec,
                        project=project,
                        raw_output_path=str(raw_path.relative_to(REPO_ROOT)),
                        normalized_output_path=str(norm_path.relative_to(REPO_ROOT)),
                    )
                    outcomes.append(
                        {
                            "reg_no": reg_no,
                            "project_name": proj_name,
                            "status": project.extraction_status.value,
                            "tabs": len(project.tabs),
                            "fields": project.coverage.total_fields_discovered,
                            "docs": project.coverage.document_links_count,
                            "duration_s": duration_s,
                        }
                    )
                    print(
                        f"  [{idx}/{len(to_extract)}] {proj_name} ({reg_no}) -> "
                        f"{project.extraction_status.value} | tabs={len(project.tabs)}, "
                        f"fields={project.coverage.total_fields_discovered}, docs={project.coverage.document_links_count} ({duration_s}s)"
                    )

                except Exception as exc:
                    failed_count += 1
                    coordinator.log_error(
                        project_key=proj_key,
                        registration_number=reg_no,
                        acknowledgement_number=rec.get("ack_no"),
                        attempt_number=1,
                        error_stage="phase4_modal_extraction",
                        error_type=type(exc).__name__,
                        error_message=str(exc),
                        is_retryable=True,
                    )
                    outcomes.append({"reg_no": reg_no, "project_name": proj_name, "status": "failed", "error": str(exc)})
                    print(f"  [{idx}/{len(to_extract)}] ERROR {proj_name} ({reg_no}): {exc}")
                finally:
                    try:
                        close_project_modal_in_dom(page)
                    except Exception:
                        pass
                    time.sleep(1.0)

            browser.close()

    status_out = "COMPLETED"
    if interrupted_reason or (failed_count > 0 and extracted_ok == 0):
        status_out = "INCOMPLETE" if interrupted_reason else "FAILED"
    elif failed_count > 0:
        status_out = "INCOMPLETE"

    finish_phase4_run(
        conn,
        run_id,
        pages_discovered=len(to_extract),
        pages_processed=extracted_ok + failed_count,
        records_discovered=len(unique_targets),
        records_extracted=extracted_ok,
        records_failed=failed_count,
        records_skipped=skipped_count,
        unique_registrations=len(unique_targets),
        completion_status=status_out,
        notes=interrupted_reason or f"Recovered {extracted_ok}/{len(to_extract)} queued projects.",
    )
    conn.close()

    summary = {
        "run_id": run_id,
        "scope": scope_label,
        "completion_status": status_out,
        "candidates": len(unique_targets),
        "skipped_already_successful": skipped_count,
        "queued": len(to_extract),
        "extracted_ok": extracted_ok,
        "failed": failed_count,
        "interrupted_reason": interrupted_reason,
        "outcomes": outcomes,
    }
    RECOVERY_DIR.mkdir(parents=True, exist_ok=True)
    safe_scope = re.sub(r"[^a-z0-9]+", "_", scope_label.lower()).strip("_")
    (RECOVERY_DIR / f"run_{run_id}_{safe_scope}.json").write_text(
        json.dumps(summary, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    print(f"[Phase4Recovery] Finished run #{run_id}: {status_out} | extracted={extracted_ok}, failed={failed_count}, skipped={skipped_count}")
    return summary


def main() -> int:
    parser = argparse.ArgumentParser(description="HomeSure Phase 4 Incremental K-RERA Extractor")
    parser.add_argument("--refresh-catalogue", action="store_true", help="Refresh live Bengaluru Urban & Rural catalogue snapshots")
    parser.add_argument("--extract-targeted", action="store_true", help="Run targeted deep modal recovery")
    parser.add_argument("--wave1-flagship", action="store_true", help="Target the 11 flagship missing Sobha Neopolis / 63 Degree East / Ren & Rei projects")
    parser.add_argument("--builder", type=str, help="Target missing APPROVED projects for a canonical builder ('SOBHA' or 'ASSETZ')")
    parser.add_argument("--reg-nos", type=str, help="Comma-separated list of exact RERA registration numbers")
    parser.add_argument("--all-missing-eligible", action="store_true", help="Target all remaining unextracted APPROVED Bengaluru Urban rows")
    parser.add_argument("--limit", type=int, default=None, help="Optional cap on queued projects")
    parser.add_argument("--force", action="store_true", help="Force re-extraction even if checkpointed as successful")
    args = parser.parse_args()

    if not args.refresh_catalogue and not args.extract_targeted:
        print("Specify --refresh-catalogue and/or --extract-targeted", file=sys.stderr)
        return 1

    if args.refresh_catalogue:
        run_refresh_catalogue(SQLITE_PATH, PHASE4_SQLITE_PATH)

    if args.extract_targeted:
        all_candidates = load_approved_catalogue_candidates(SQLITE_PATH, PHASE4_SQLITE_PATH)
        targets: List[Dict[str, Any]] = []
        scope_label = "targeted"

        if args.wave1_flagship:
            wanted = {r.upper() for r in FLAGSHIP_WAVE1_REGS}
            targets = [c for c in all_candidates if c["reg_no"].upper() in wanted]
            scope_label = "wave1_flagship_11"
        elif args.builder:
            b_upper = args.builder.strip().upper()
            target_bid = (
                "builder_sobha_limited"
                if "SOBHA" in b_upper
                else ("builder_assetz_group" if "ASSETZ" in b_upper else args.builder.strip())
            )
            for c in all_candidates:
                binfo = resolve_builder_identity(c["project_name"], c["promoter_name"], c["reg_no"])
                if binfo["builder_id"] == target_bid or b_upper in binfo["canonical_builder_name"].upper():
                    targets.append(c)
            scope_label = f"builder_{target_bid}"
        elif args.reg_nos:
            wanted = {r.strip().upper() for r in args.reg_nos.split(",") if r.strip()}
            targets = [c for c in all_candidates if c["reg_no"].upper() in wanted]
            scope_label = f"custom_{len(targets)}"
        elif args.all_missing_eligible:
            targets = all_candidates
            scope_label = "all_missing_eligible"
        else:
            print("Specify --wave1-flagship, --builder, --reg-nos, or --all-missing-eligible", file=sys.stderr)
            return 1

        if args.limit and args.limit > 0:
            # Keep only un-checkpointed across legacy + Phase 4 SQLite up to limit
            _, done_regs = _load_historical_successful_checkpoints(SQLITE_PATH)
            if PHASE4_SQLITE_PATH.exists():
                p4_done_keys, p4_done_regs = _load_historical_successful_checkpoints(PHASE4_SQLITE_PATH)
                del p4_done_keys
                done_regs |= p4_done_regs
            pending_only = [t for t in targets if t["reg_no"].upper() not in done_regs]
            targets = pending_only[: args.limit]

        res = run_targeted_extraction(
            SQLITE_PATH,
            targets,
            scope_label,
            force_reextract=args.force,
            phase4_sqlite_path=PHASE4_SQLITE_PATH,
        )
        if res["failed"] > 0 or res["interrupted_reason"]:
            return 2

    return 0


if __name__ == "__main__":
    sys.exit(main())
