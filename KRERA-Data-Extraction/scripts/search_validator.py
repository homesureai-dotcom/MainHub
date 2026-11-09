"""
K-RERA Search Extraction Validator & Report Generator

Generates `reports/validation_report.json` from the SQLite extraction state
and enforces strict reconciliation and completeness checks.
"""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Set

from .search_storage import SearchExtractionStorage


def generate_validation_report(
    storage: SearchExtractionStorage,
    report_path: str | Path = "KRERA-Data-Extraction/reports/validation_report.json",
    expected_full_run: bool = True,
) -> Dict[str, Any]:
    """Computes validation metrics from SQLite and writes `validation_report.json`."""
    conn = storage.conn

    # 1. Latest run metadata
    latest_run = conn.execute(
        """
        SELECT *
        FROM extraction_runs
        ORDER BY run_id DESC
        LIMIT 1
        """
    ).fetchone()

    portal_reported_total: Optional[int] = (
        int(latest_run["portal_reported_total"])
        if latest_run and latest_run["portal_reported_total"] is not None
        else None
    )
    if portal_reported_total is None:
        prev_total_row = conn.execute(
            """
            SELECT portal_reported_total
            FROM extraction_runs
            WHERE portal_reported_total IS NOT NULL
            ORDER BY run_id DESC
            LIMIT 1
            """
        ).fetchone()
        if prev_total_row and prev_total_row["portal_reported_total"] is not None:
            portal_reported_total = int(prev_total_row["portal_reported_total"])
    reached_last_page: bool = (
        bool(latest_run["reached_last_page"]) if latest_run else False
    )
    run_status = latest_run["status"] if latest_run else "NO_RUN"
    stop_reason = latest_run["stop_reason"] if latest_run else None

    # 2. Pages summary & boundaries
    page_rows = conn.execute(
        """
        SELECT page_number, row_count, first_record_key, last_record_key,
               extracted_at, status, error_message
        FROM extracted_pages
        ORDER BY page_number ASC
        """
    ).fetchall()

    completed_pages_count = 0
    pages_with_errors: List[Dict[str, Any]] = []
    page_boundaries: List[Dict[str, Any]] = []

    for p in page_rows:
        p_num = int(p["page_number"])
        p_status = str(p["status"])
        if p_status == "COMPLETED":
            completed_pages_count += 1
            page_boundaries.append(
                {
                    "page_number": p_num,
                    "row_count": int(p["row_count"]),
                    "first_record": p["first_record_key"],
                    "last_record": p["last_record_key"],
                    "extracted_at": p["extracted_at"],
                }
            )
        else:
            pages_with_errors.append(
                {
                    "page_number": p_num,
                    "status": p_status,
                    "error_message": p["error_message"],
                }
            )

    # 3. Rows, uniqueness, duplicates, and missing/blank counts by column
    raw_rows = conn.execute(
        """
        SELECT page_number, row_order, record_unique_key, column_headers_json,
               cells_json, row_dict_json, is_duplicate
        FROM raw_search_rows
        ORDER BY page_number ASC, row_order ASC
        """
    ).fetchall()

    total_rows_extracted = len(raw_rows)
    unique_keys: Set[str] = set()
    duplicate_count = 0
    discovered_columns: List[str] = []
    seen_columns: Set[str] = set()

    for r in raw_rows:
        headers = json.loads(r["column_headers_json"])
        for h in headers:
            if h not in seen_columns:
                seen_columns.add(h)
                discovered_columns.append(h)

    missing_by_column: Dict[str, int] = {col: 0 for col in discovered_columns}

    for r in raw_rows:
        key = str(r["record_unique_key"])
        if key in unique_keys or int(r["is_duplicate"]) == 1:
            duplicate_count += 1
        unique_keys.add(key)

        row_dict = json.loads(r["row_dict_json"])
        cells_list = json.loads(r["cells_json"])
        cell_links_by_col = {
            c["column_header"]: c.get("links", []) for c in cells_list
        }
        for col in discovered_columns:
            val = row_dict.get(col)
            links = cell_links_by_col.get(col, [])
            if (val is None or str(val).strip() == "") and not links:
                missing_by_column[col] += 1

    unique_records_count = len(unique_keys)

    # 4. Count reconciliation & validation status
    counts_reconcile = (
        portal_reported_total is not None
        and total_rows_extracted == portal_reported_total
    )

    discrepancy_reasons: List[str] = []
    if pages_with_errors:
        discrepancy_reasons.append(
            f"{len(pages_with_errors)} page(s) encountered extraction errors."
        )
    if duplicate_count > 0:
        discrepancy_reasons.append(
            f"{duplicate_count} duplicate record(s) detected across extracted pages."
        )
    if portal_reported_total is None:
        discrepancy_reasons.append("Portal-reported total count was not found in DOM.")
    elif total_rows_extracted != portal_reported_total:
        delta = total_rows_extracted - portal_reported_total
        if not expected_full_run and not reached_last_page:
            discrepancy_reasons.append(
                f"Controlled partial run: extracted {total_rows_extracted} of {portal_reported_total} "
                f"portal-reported rows across {completed_pages_count} page(s)."
            )
        else:
            discrepancy_reasons.append(
                f"Count mismatch: extracted {total_rows_extracted} rows vs. portal-reported "
                f"{portal_reported_total} (delta: {delta:+d})."
            )
    if expected_full_run and not reached_last_page:
        discrepancy_reasons.append("Pagination did not reach the final page.")

    is_valid_full_extraction = (
        counts_reconcile
        and reached_last_page
        and len(pages_with_errors) == 0
        and duplicate_count == 0
        and run_status == "COMPLETED"
    )

    if is_valid_full_extraction:
        validation_status = "VALIDATED_SUCCESS"
    elif (
        not expected_full_run
        and run_status == "COMPLETED"
        and total_rows_extracted > 0
        and len(pages_with_errors) == 0
        and duplicate_count == 0
    ):
        validation_status = "VALIDATED_PARTIAL_RUN"
    else:
        validation_status = "VALIDATION_FAILED_OR_DISCREPANCY"

    report: Dict[str, Any] = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "run_status": run_status,
        "stop_reason": stop_reason,
        "validation_status": validation_status,
        "is_successful_full_extraction": is_valid_full_extraction,
        "portal_reported_total": portal_reported_total,
        "total_rows_extracted": total_rows_extracted,
        "pages_processed": completed_pages_count,
        "unique_records": unique_records_count,
        "duplicate_records": duplicate_count,
        "discovered_columns": discovered_columns,
        "missing_or_blank_by_column": missing_by_column,
        "reached_last_page": reached_last_page,
        "counts_reconcile": counts_reconcile,
        "discrepancy_explanations": discrepancy_reasons,
        "pages_with_errors": pages_with_errors,
        "page_boundaries": page_boundaries,
    }

    out_path = Path(report_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)

    return report
