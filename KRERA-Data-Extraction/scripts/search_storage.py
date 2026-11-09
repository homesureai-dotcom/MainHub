"""
K-RERA Search Extraction Storage & Checkpointing (SQLite + JSONL + CSV)

Provides transactional page-by-page persistence, duplicate page/row detection,
safe resumption after interruption, and deterministic exports to JSONL and CSV.
"""

from __future__ import annotations

import csv
import json
import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple

from .search_parser import ExtractedSearchRow, PageExtractionResult


class DuplicatePageError(RuntimeError):
    """Raised when a newly extracted page has the exact same signature as an already-extracted page."""


class SearchExtractionStorage:
    """Manages SQLite persistence, resumption checkpoints, and JSONL/CSV exports."""

    def __init__(
        self,
        sqlite_path: str | Path = "KRERA-Data-Extraction/data/k_rera_extraction.sqlite",
        jsonl_path: str | Path = "KRERA-Data-Extraction/data/raw/k_rera_bengaluru_urban.jsonl",
        csv_path: str | Path = "KRERA-Data-Extraction/data/exports/k_rera_bengaluru_urban.csv",
    ):
        self.sqlite_path = Path(sqlite_path)
        self.jsonl_path = Path(jsonl_path)
        self.csv_path = Path(csv_path)

        self.sqlite_path.parent.mkdir(parents=True, exist_ok=True)
        self.jsonl_path.parent.mkdir(parents=True, exist_ok=True)
        self.csv_path.parent.mkdir(parents=True, exist_ok=True)

        self.conn = sqlite3.connect(str(self.sqlite_path))
        self.conn.row_factory = sqlite3.Row
        self._init_schema()

    def _init_schema(self) -> None:
        with self.conn:
            self.conn.executescript(
                """
                CREATE TABLE IF NOT EXISTS extraction_runs (
                    run_id INTEGER PRIMARY KEY AUTOINCREMENT,
                    started_at TEXT NOT NULL,
                    completed_at TEXT,
                    filter_config_json TEXT NOT NULL,
                    source_url TEXT,
                    portal_reported_total INTEGER,
                    discovered_headers_json TEXT,
                    reached_last_page INTEGER DEFAULT 0,
                    status TEXT NOT NULL DEFAULT 'IN_PROGRESS',
                    stop_reason TEXT
                );

                CREATE TABLE IF NOT EXISTS extracted_pages (
                    page_number INTEGER PRIMARY KEY,
                    run_id INTEGER NOT NULL,
                    row_count INTEGER NOT NULL,
                    first_record_key TEXT,
                    last_record_key TEXT,
                    page_signature_hash TEXT NOT NULL,
                    extracted_at TEXT NOT NULL,
                    status TEXT NOT NULL DEFAULT 'COMPLETED',
                    error_message TEXT,
                    FOREIGN KEY (run_id) REFERENCES extraction_runs(run_id)
                );

                CREATE TABLE IF NOT EXISTS raw_search_rows (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    run_id INTEGER NOT NULL,
                    page_number INTEGER NOT NULL,
                    row_order INTEGER NOT NULL,
                    record_unique_key TEXT NOT NULL,
                    row_hash TEXT NOT NULL,
                    column_headers_json TEXT NOT NULL,
                    cells_json TEXT NOT NULL,
                    row_dict_json TEXT NOT NULL,
                    links_json TEXT NOT NULL,
                    filter_config_json TEXT NOT NULL,
                    source_url TEXT NOT NULL,
                    extracted_at TEXT NOT NULL,
                    is_duplicate INTEGER NOT NULL DEFAULT 0,
                    UNIQUE(page_number, row_order),
                    FOREIGN KEY (run_id) REFERENCES extraction_runs(run_id)
                );

                CREATE INDEX IF NOT EXISTS idx_rows_unique_key ON raw_search_rows(record_unique_key);
                CREATE INDEX IF NOT EXISTS idx_rows_page ON raw_search_rows(page_number);
                """
            )

    def start_or_resume_run(
        self,
        filter_config: Dict[str, Any],
        source_url: str,
        reset: bool = False,
    ) -> int:
        """Creates a new extraction run record; if reset=True, clears previous pages/rows."""
        now_iso = datetime.now(timezone.utc).isoformat()
        filter_json = json.dumps(filter_config, sort_keys=True)

        with self.conn:
            if reset:
                self.conn.execute("DELETE FROM raw_search_rows")
                self.conn.execute("DELETE FROM extracted_pages")
                self.conn.execute("DELETE FROM extraction_runs")
                if self.jsonl_path.exists():
                    self.jsonl_path.unlink()
                if self.csv_path.exists():
                    self.csv_path.unlink()

            cur = self.conn.execute(
                """
                INSERT INTO extraction_runs (started_at, filter_config_json, source_url, status)
                VALUES (?, ?, ?, 'IN_PROGRESS')
                """,
                (now_iso, filter_json, source_url),
            )
            return int(cur.lastrowid)

    def get_completed_pages(self) -> Set[int]:
        """Returns the set of page numbers already marked COMPLETED in SQLite."""
        rows = self.conn.execute(
            "SELECT page_number FROM extracted_pages WHERE status = 'COMPLETED'"
        ).fetchall()
        return {int(r["page_number"]) for r in rows}

    def get_page_signatures(self) -> Dict[str, int]:
        """Returns mapping of page_signature_hash -> page_number for completed non-empty pages."""
        rows = self.conn.execute(
            """
            SELECT page_number, page_signature_hash, row_count
            FROM extracted_pages
            WHERE status = 'COMPLETED' AND row_count > 0
            """
        ).fetchall()
        return {str(r["page_signature_hash"]): int(r["page_number"]) for r in rows}

    def get_existing_unique_keys(self, exclude_page: Optional[int] = None) -> Set[str]:
        """Returns all record_unique_key values already persisted across other pages."""
        if exclude_page is not None:
            rows = self.conn.execute(
                "SELECT record_unique_key FROM raw_search_rows WHERE page_number != ?",
                (exclude_page,),
            ).fetchall()
        else:
            rows = self.conn.execute("SELECT record_unique_key FROM raw_search_rows").fetchall()
        return {str(r["record_unique_key"]) for r in rows}

    def record_page_error(self, run_id: int, page_number: int, error_message: str) -> None:
        """Records a page extraction failure transactionally."""
        now_iso = datetime.now(timezone.utc).isoformat()
        with self.conn:
            self.conn.execute(
                """
                INSERT INTO extracted_pages (
                    page_number, run_id, row_count, first_record_key, last_record_key,
                    page_signature_hash, extracted_at, status, error_message
                )
                VALUES (?, ?, 0, NULL, NULL, '', ?, 'ERROR', ?)
                ON CONFLICT(page_number) DO UPDATE SET
                    run_id = excluded.run_id,
                    extracted_at = excluded.extracted_at,
                    status = 'ERROR',
                    error_message = excluded.error_message
                """,
                (page_number, run_id, now_iso, error_message),
            )

    def save_page_result(
        self,
        run_id: int,
        page_result: PageExtractionResult,
        overwrite_page: bool = False,
    ) -> Tuple[int, int]:
        """Transactionally persists a single extracted page and its rows.

        Raises DuplicatePageError if a different page already has the identical non-empty row signature.
        Returns (inserted_rows_count, duplicate_rows_count).
        """
        page_no = page_result.page_number

        # 1. Check for duplicate page content across different page numbers
        existing_sigs = self.get_page_signatures()
        if (
            not page_result.is_empty_result
            and page_result.page_signature_hash in existing_sigs
            and existing_sigs[page_result.page_signature_hash] != page_no
        ):
            prev_page = existing_sigs[page_result.page_signature_hash]
            raise DuplicatePageError(
                f"Page {page_no} has identical content signature to already-extracted Page {prev_page}. "
                "Pagination likely failed to advance."
            )

        completed_pages = self.get_completed_pages()
        if page_no in completed_pages and not overwrite_page:
            return (0, 0)

        seen_keys = self.get_existing_unique_keys(exclude_page=page_no)
        duplicates_on_page = 0

        with self.conn:
            # Update run metadata with portal_reported_total and headers if present
            if page_result.pagination.portal_reported_total is not None:
                self.conn.execute(
                    """
                    UPDATE extraction_runs
                    SET portal_reported_total = ?,
                        discovered_headers_json = ?
                    WHERE run_id = ?
                    """,
                    (
                        page_result.pagination.portal_reported_total,
                        json.dumps(page_result.column_headers),
                        run_id,
                    ),
                )
            else:
                self.conn.execute(
                    """
                    UPDATE extraction_runs
                    SET discovered_headers_json = COALESCE(discovered_headers_json, ?)
                    WHERE run_id = ?
                    """,
                    (json.dumps(page_result.column_headers), run_id),
                )

            if overwrite_page:
                self.conn.execute("DELETE FROM raw_search_rows WHERE page_number = ?", (page_no,))

            for row in page_result.rows:
                is_dup = 1 if row.record_unique_key in seen_keys else 0
                if is_dup:
                    duplicates_on_page += 1
                seen_keys.add(row.record_unique_key)

                cells_serialized = [
                    {
                        "column_index": c.column_index,
                        "column_header": c.column_header,
                        "raw_text": c.raw_text,
                        "links": c.links,
                    }
                    for c in row.cells
                ]

                self.conn.execute(
                    """
                    INSERT OR REPLACE INTO raw_search_rows (
                        run_id, page_number, row_order, record_unique_key, row_hash,
                        column_headers_json, cells_json, row_dict_json, links_json,
                        filter_config_json, source_url, extracted_at, is_duplicate
                    )
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        run_id,
                        row.page_number,
                        row.row_order,
                        row.record_unique_key,
                        row.row_hash,
                        json.dumps(row.column_headers, ensure_ascii=False),
                        json.dumps(cells_serialized, ensure_ascii=False),
                        json.dumps(row.row_dict, ensure_ascii=False),
                        json.dumps(row.project_detail_links, ensure_ascii=False),
                        json.dumps(row.filter_config, ensure_ascii=False),
                        row.source_url,
                        row.extraction_timestamp,
                        is_dup,
                    ),
                )

            self.conn.execute(
                """
                INSERT INTO extracted_pages (
                    page_number, run_id, row_count, first_record_key, last_record_key,
                    page_signature_hash, extracted_at, status, error_message
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, 'COMPLETED', NULL)
                ON CONFLICT(page_number) DO UPDATE SET
                    run_id = excluded.run_id,
                    row_count = excluded.row_count,
                    first_record_key = excluded.first_record_key,
                    last_record_key = excluded.last_record_key,
                    page_signature_hash = excluded.page_signature_hash,
                    extracted_at = excluded.extracted_at,
                    status = 'COMPLETED',
                    error_message = NULL
                """,
                (
                    page_no,
                    run_id,
                    len(page_result.rows),
                    page_result.first_record_key,
                    page_result.last_record_key,
                    page_result.page_signature_hash,
                    page_result.extracted_at,
                ),
            )

        return (len(page_result.rows), duplicates_on_page)

    def finalize_run(
        self,
        run_id: int,
        status: str,
        reached_last_page: bool,
        stop_reason: Optional[str] = None,
    ) -> None:
        now_iso = datetime.now(timezone.utc).isoformat()
        with self.conn:
            self.conn.execute(
                """
                UPDATE extraction_runs
                SET completed_at = ?,
                    status = ?,
                    reached_last_page = ?,
                    stop_reason = ?
                WHERE run_id = ?
                """,
                (now_iso, status, 1 if reached_last_page else 0, stop_reason, run_id),
            )

    def export_jsonl_and_csv(self) -> Tuple[int, Path, Path]:
        """Exports all persisted rows ordered by (page_number, row_order) to JSONL and CSV."""
        rows = self.conn.execute(
            """
            SELECT
                page_number, row_order, record_unique_key, row_hash,
                column_headers_json, cells_json, row_dict_json, links_json,
                filter_config_json, source_url, extracted_at, is_duplicate
            FROM raw_search_rows
            ORDER BY page_number ASC, row_order ASC
            """
        ).fetchall()

        # Discover union of all column headers in order of appearance
        ordered_headers: List[str] = []
        seen_headers: Set[str] = set()
        parsed_records: List[Dict[str, Any]] = []

        for r in rows:
            col_headers = json.loads(r["column_headers_json"])
            for h in col_headers:
                if h not in seen_headers:
                    seen_headers.add(h)
                    ordered_headers.append(h)

            row_dict = json.loads(r["row_dict_json"])
            cells = json.loads(r["cells_json"])
            links = json.loads(r["links_json"])
            filter_cfg = json.loads(r["filter_config_json"])

            record_obj = {
                "page_number": r["page_number"],
                "row_order": r["row_order"],
                "extraction_timestamp": r["extracted_at"],
                "source_url": r["source_url"],
                "filter_config": filter_cfg,
                "record_unique_key": r["record_unique_key"],
                "row_hash": r["row_hash"],
                "is_duplicate": bool(r["is_duplicate"]),
                "project_detail_links": links,
                "row_data": row_dict,
                "cells": cells,
            }
            parsed_records.append(record_obj)

        # Write JSONL
        with self.jsonl_path.open("w", encoding="utf-8") as jf:
            for rec in parsed_records:
                jf.write(json.dumps(rec, ensure_ascii=False) + "\n")

        # Write CSV
        metadata_cols = [
            "page_number",
            "row_order",
            "extraction_timestamp",
            "source_url",
            "filter_status",
            "filter_district",
            "record_unique_key",
            "is_duplicate",
            "project_detail_link",
        ]
        csv_columns = metadata_cols + ordered_headers

        with self.csv_path.open("w", encoding="utf-8", newline="") as cf:
            writer = csv.DictWriter(cf, fieldnames=csv_columns)
            writer.writeheader()
            for rec in parsed_records:
                f_cfg = rec["filter_config"] or {}
                links = rec["project_detail_links"] or []
                primary_link = ""
                if links:
                    first_lnk = links[0]
                    primary_link = (
                        first_lnk.get("onclick")
                        or first_lnk.get("href")
                        or first_lnk.get("id")
                        or json.dumps(first_lnk, ensure_ascii=False)
                    )
                flat_row: Dict[str, Any] = {
                    "page_number": rec["page_number"],
                    "row_order": rec["row_order"],
                    "extraction_timestamp": rec["extraction_timestamp"],
                    "source_url": rec["source_url"],
                    "filter_status": f_cfg.get("application_status", ""),
                    "filter_district": f_cfg.get("district", ""),
                    "record_unique_key": rec["record_unique_key"],
                    "is_duplicate": rec["is_duplicate"],
                    "project_detail_link": primary_link,
                }
                for h in ordered_headers:
                    flat_row[h] = rec["row_data"].get(h, "")
                writer.writerow(flat_row)

        return (len(parsed_records), self.jsonl_path, self.csv_path)

    def close(self) -> None:
        if self.conn:
            self.conn.close()
