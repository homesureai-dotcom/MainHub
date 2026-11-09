"""
Automated Unit & Integration Tests for K-RERA Search Results Extractor (Phase 1)

Uses local mock HTML fixtures (zero live portal hits) to test:
1. Dynamic column discovery.
2. Different page sizes.
3. Pagination advancing correctly.
4. Duplicate page detection.
5. Resume after interruption.
6. Empty results.
7. Missing cell values.
8. Table structure changes.
9. Portal block/security warning.
10. Count mismatch.
"""

from __future__ import annotations

import json
from pathlib import Path
import pytest

from scripts.search_parser import (
    PortalSecurityBlockError,
    parse_search_page_html,
)
from scripts.search_storage import (
    DuplicatePageError,
    SearchExtractionStorage,
)
from scripts.search_validator import generate_validation_report


DEFAULT_FILTERS = {
    "application_status": "Applications Approved",
    "district": "Bengaluru Urban",
}
SOURCE_URL = "https://rera.karnataka.gov.in/projectViewDetails"


def _build_mock_html(
    headers: list[str],
    rows: list[list[str]],
    current_page: int = 1,
    total_pages: int = 3,
    range_start: int = 1,
    range_end: int = 2,
    reported_total: int = 5,
    next_disabled: bool = False,
    security_modal_visible: bool = False,
) -> str:
    modal_style = "display: block;" if security_modal_visible else "display: none;"
    modal_class = "modal fade in show" if security_modal_visible else "modal fade"

    th_html = "".join(f"<th>{h}</th>" for h in headers)
    if rows:
        tr_list = []
        for r in rows:
            tds = "".join(f"<td>{cell}</td>" for cell in r)
            tr_list.append(f"<tr>{tds}</tr>")
        tbody_html = "".join(tr_list)
    else:
        tbody_html = (
            f'<tr><td colspan="{len(headers)}" class="dataTables_empty">'
            "No data available in table</td></tr>"
        )

    next_cls = "paginate_button next disabled" if next_disabled else "paginate_button next"
    page_btns = []
    for p in range(1, total_pages + 1):
        cls = "paginate_button current" if p == current_page else "paginate_button"
        page_btns.append(f'<a class="{cls}">{p}</a>')

    return f"""
    <!DOCTYPE html>
    <html>
    <body>
      <div class="{modal_class}" style="{modal_style}">
        <div class="modal-body">Due to security reason, This function has been disabled!!</div>
      </div>
      <div class="tab-pane active" id="approvedTab">
        <div class="dataTables_wrapper">
          <table id="approvedTable" class="table dataTable">
            <thead>
              <tr>{th_html}</tr>
            </thead>
            <tbody>
              {tbody_html}
            </tbody>
          </table>
          <div class="dataTables_info">
            Showing {range_start:,} to {range_end:,} of {reported_total:,} entries
          </div>
          <div class="dataTables_paginate">
            <a class="paginate_button first">First</a>
            <a class="paginate_button previous">Previous</a>
            {''.join(page_btns)}
            <a class="{next_cls}">Next</a>
            <a class="paginate_button last">Last</a>
          </div>
        </div>
      </div>
    </body>
    </html>
    """


def test_1_dynamic_column_discovery():
    """1. Dynamic column discovery from arbitrary rendered table headers."""
    headers = [
        "S.No",
        "Acknowledgement No",
        "Registration No",
        "View Project Details",
        "Promoter Name",
        "Project Name",
        "Status",
        "District",
        "Taluk",
        "Project Type",
        "Approved On",
        "Proposed Completion Date",
    ]
    rows = [
        [
            "1",
            "PR/KN/170729/000101",
            "PRM/KA/RERA/1251/446/PR/171010/000001",
            '<a href="javascript:void(0);" id="101" onclick="showFileApplicationPreview(this)">View</a>',
            "GODREJ PROPERTIES LIMITED",
            "GODREJ UNITED",
            "APPROVED",
            "BENGALURU URBAN",
            "Bangalore East",
            "Residential",
            "10-10-2017",
            "31-05-2021",
        ]
    ]
    html = _build_mock_html(headers, rows, current_page=1, total_pages=1, range_start=1, range_end=1, reported_total=1, next_disabled=True)
    res = parse_search_page_html(html, SOURCE_URL, DEFAULT_FILTERS)

    assert res.column_headers == headers
    assert len(res.rows) == 1
    assert res.rows[0].row_dict["Project Name"] == "GODREJ UNITED"
    assert res.rows[0].project_detail_links[0]["id"] == "101"
    assert res.rows[0].project_detail_links[0]["onclick"] == "showFileApplicationPreview(this)"


def test_2_different_page_sizes():
    """2. Handles different page sizes (e.g., 25 rows on Page 1, 3 rows on Final Page)."""
    headers = ["S.No", "Acknowledgement No", "Registration No", "Project Name"]
    rows_25 = [[str(i), f"ACK-{i}", f"REG-{i}", f"Project {i}"] for i in range(1, 26)]
    html_p1 = _build_mock_html(headers, rows_25, current_page=1, total_pages=2, range_start=1, range_end=25, reported_total=28)
    res_p1 = parse_search_page_html(html_p1, SOURCE_URL, DEFAULT_FILTERS)
    assert len(res_p1.rows) == 25
    assert res_p1.pagination.portal_reported_total == 28

    rows_3 = [[str(i), f"ACK-{i}", f"REG-{i}", f"Project {i}"] for i in range(26, 29)]
    html_p2 = _build_mock_html(headers, rows_3, current_page=2, total_pages=2, range_start=26, range_end=28, reported_total=28, next_disabled=True)
    res_p2 = parse_search_page_html(html_p2, SOURCE_URL, DEFAULT_FILTERS)
    assert len(res_p2.rows) == 3
    assert res_p2.pagination.next_disabled is True


def test_3_pagination_advancing_correctly(tmp_path: Path):
    """3. Verifies pagination advances across pages and persists distinct boundaries."""
    storage = SearchExtractionStorage(
        sqlite_path=tmp_path / "test.sqlite",
        jsonl_path=tmp_path / "out.jsonl",
        csv_path=tmp_path / "out.csv",
    )
    run_id = storage.start_or_resume_run(DEFAULT_FILTERS, SOURCE_URL, reset=True)
    headers = ["S.No", "Acknowledgement No", "Registration No", "Project Name"]

    p1_html = _build_mock_html(
        headers,
        [["1", "ACK-1", "REG-1", "Alpha"], ["2", "ACK-2", "REG-2", "Beta"]],
        current_page=1,
        total_pages=2,
        range_start=1,
        range_end=2,
        reported_total=4,
    )
    p2_html = _build_mock_html(
        headers,
        [["3", "ACK-3", "REG-3", "Gamma"], ["4", "ACK-4", "REG-4", "Delta"]],
        current_page=2,
        total_pages=2,
        range_start=3,
        range_end=4,
        reported_total=4,
        next_disabled=True,
    )

    r1 = parse_search_page_html(p1_html, SOURCE_URL, DEFAULT_FILTERS)
    r2 = parse_search_page_html(p2_html, SOURCE_URL, DEFAULT_FILTERS)

    assert r1.page_number == 1
    assert r2.page_number == 2
    assert r1.page_signature_hash != r2.page_signature_hash

    storage.save_page_result(run_id, r1)
    storage.save_page_result(run_id, r2)
    storage.finalize_run(run_id, status="COMPLETED", reached_last_page=True)

    report = generate_validation_report(storage, report_path=tmp_path / "report.json")
    assert report["validation_status"] == "VALIDATED_SUCCESS"
    assert report["pages_processed"] == 2
    assert report["total_rows_extracted"] == 4
    assert report["unique_records"] == 4
    assert report["page_boundaries"][0]["first_record"] == "ACK:ACK-1|REG:REG-1"
    assert report["page_boundaries"][1]["last_record"] == "ACK:ACK-4|REG:REG-4"
    storage.close()


def test_4_duplicate_page_detection(tmp_path: Path):
    """4. Detects when pagination fails to advance and returns duplicate page content."""
    storage = SearchExtractionStorage(
        sqlite_path=tmp_path / "test.sqlite",
        jsonl_path=tmp_path / "out.jsonl",
        csv_path=tmp_path / "out.csv",
    )
    run_id = storage.start_or_resume_run(DEFAULT_FILTERS, SOURCE_URL, reset=True)
    headers = ["S.No", "Acknowledgement No", "Registration No", "Project Name"]
    rows = [["1", "ACK-1", "REG-1", "Alpha"], ["2", "ACK-2", "REG-2", "Beta"]]

    p1_html = _build_mock_html(headers, rows, current_page=1)
    p2_stale_html = _build_mock_html(headers, rows, current_page=2)

    r1 = parse_search_page_html(p1_html, SOURCE_URL, DEFAULT_FILTERS)
    r2_stale = parse_search_page_html(p2_stale_html, SOURCE_URL, DEFAULT_FILTERS)

    storage.save_page_result(run_id, r1)
    with pytest.raises(DuplicatePageError):
        storage.save_page_result(run_id, r2_stale)
    storage.close()


def test_5_resume_after_interruption(tmp_path: Path):
    """5. Supports safe resumption after interruption without re-extracting completed pages."""
    sqlite_file = tmp_path / "resume.sqlite"
    jsonl_file = tmp_path / "resume.jsonl"
    csv_file = tmp_path / "resume.csv"

    headers = ["S.No", "Acknowledgement No", "Registration No", "Project Name"]
    p1_html = _build_mock_html(headers, [["1", "ACK-1", "REG-1", "P1"]], current_page=1, total_pages=2, reported_total=2)
    p2_html = _build_mock_html(headers, [["2", "ACK-2", "REG-2", "P2"]], current_page=2, total_pages=2, reported_total=2, next_disabled=True)

    # First run extracts Page 1 and is interrupted
    storage1 = SearchExtractionStorage(sqlite_file, jsonl_file, csv_file)
    run1 = storage1.start_or_resume_run(DEFAULT_FILTERS, SOURCE_URL, reset=True)
    r1 = parse_search_page_html(p1_html, SOURCE_URL, DEFAULT_FILTERS)
    storage1.save_page_result(run1, r1)
    storage1.finalize_run(run1, status="INTERRUPTED", reached_last_page=False, stop_reason="Simulated interrupt")
    storage1.close()

    # Second run resumes, sees Page 1 completed, skips Page 1, and extracts Page 2
    storage2 = SearchExtractionStorage(sqlite_file, jsonl_file, csv_file)
    completed = storage2.get_completed_pages()
    assert completed == {1}

    run2 = storage2.start_or_resume_run(DEFAULT_FILTERS, SOURCE_URL, reset=False)
    # Attempting to save Page 1 without overwrite is a no-op
    inserted, _ = storage2.save_page_result(run2, r1, overwrite_page=False)
    assert inserted == 0

    r2 = parse_search_page_html(p2_html, SOURCE_URL, DEFAULT_FILTERS)
    inserted2, _ = storage2.save_page_result(run2, r2, overwrite_page=False)
    assert inserted2 == 1
    storage2.finalize_run(run2, status="COMPLETED", reached_last_page=True)

    count, _, _ = storage2.export_jsonl_and_csv()
    assert count == 2
    report = generate_validation_report(storage2, report_path=tmp_path / "report.json")
    assert report["validation_status"] == "VALIDATED_SUCCESS"
    assert report["total_rows_extracted"] == 2
    storage2.close()


def test_6_empty_results():
    """6. Handles empty search results gracefully."""
    headers = ["S.No", "Acknowledgement No", "Registration No", "Project Name"]
    html = _build_mock_html(headers, [], current_page=1, total_pages=0, range_start=0, range_end=0, reported_total=0, next_disabled=True)
    res = parse_search_page_html(html, SOURCE_URL, DEFAULT_FILTERS)

    assert res.is_empty_result is True
    assert len(res.rows) == 0
    assert res.pagination.portal_reported_total == 0


def test_7_missing_cell_values(tmp_path: Path):
    """7. Tracks missing or blank cell values by column in the validation report."""
    storage = SearchExtractionStorage(
        sqlite_path=tmp_path / "missing.sqlite",
        jsonl_path=tmp_path / "missing.jsonl",
        csv_path=tmp_path / "missing.csv",
    )
    run_id = storage.start_or_resume_run(DEFAULT_FILTERS, SOURCE_URL, reset=True)
    headers = ["S.No", "Acknowledgement No", "Registration No", "Project Name", "Taluk"]
    rows = [
        ["1", "ACK-10", "", "Project Without RegNo", ""],
        ["2", "ACK-11", "REG-11", "Project With RegNo", "Bangalore South"],
    ]
    html = _build_mock_html(headers, rows, current_page=1, total_pages=1, range_start=1, range_end=2, reported_total=2, next_disabled=True)
    res = parse_search_page_html(html, SOURCE_URL, DEFAULT_FILTERS)
    storage.save_page_result(run_id, res)
    storage.finalize_run(run_id, status="COMPLETED", reached_last_page=True)

    report = generate_validation_report(storage, report_path=tmp_path / "report.json")
    assert report["missing_or_blank_by_column"]["Registration No"] == 1
    assert report["missing_or_blank_by_column"]["Taluk"] == 1
    assert report["missing_or_blank_by_column"]["Project Name"] == 0
    storage.close()


def test_8_table_structure_changes(tmp_path: Path):
    """8. Adapts to table structure changes (new columns added or reordered)."""
    storage = SearchExtractionStorage(
        sqlite_path=tmp_path / "struct.sqlite",
        jsonl_path=tmp_path / "struct.jsonl",
        csv_path=tmp_path / "struct.csv",
    )
    run_id = storage.start_or_resume_run(DEFAULT_FILTERS, SOURCE_URL, reset=True)

    headers_v1 = ["S.No", "Acknowledgement No", "Project Name"]
    html_v1 = _build_mock_html(headers_v1, [["1", "ACK-1", "Alpha"]], current_page=1, total_pages=2, reported_total=2)

    headers_v2 = ["S.No", "Acknowledgement No", "Project Name", "New Regulatory Column"]
    html_v2 = _build_mock_html(headers_v2, [["2", "ACK-2", "Beta", "Compliant"]], current_page=2, total_pages=2, reported_total=2, next_disabled=True)

    storage.save_page_result(run_id, parse_search_page_html(html_v1, SOURCE_URL, DEFAULT_FILTERS))
    storage.save_page_result(run_id, parse_search_page_html(html_v2, SOURCE_URL, DEFAULT_FILTERS))
    storage.finalize_run(run_id, status="COMPLETED", reached_last_page=True)

    count, jsonl_p, csv_p = storage.export_jsonl_and_csv()
    assert count == 2
    report = generate_validation_report(storage, report_path=tmp_path / "report.json")
    assert "New Regulatory Column" in report["discovered_columns"]
    assert report["missing_or_blank_by_column"]["New Regulatory Column"] == 1
    storage.close()


def test_9_portal_block_security_warning():
    """9. Immediately raises PortalSecurityBlockError when security modal is visible."""
    headers = ["S.No", "Project Name"]
    html_blocked = _build_mock_html(
        headers,
        [["1", "Test"]],
        security_modal_visible=True,
    )
    with pytest.raises(PortalSecurityBlockError) as exc_info:
        parse_search_page_html(html_blocked, SOURCE_URL, DEFAULT_FILTERS)
    assert "Due to security reason" in str(exc_info.value)


def test_10_count_mismatch(tmp_path: Path):
    """10. Flags validation discrepancy when extracted row count does not match portal-reported total."""
    storage = SearchExtractionStorage(
        sqlite_path=tmp_path / "mismatch.sqlite",
        jsonl_path=tmp_path / "mismatch.jsonl",
        csv_path=tmp_path / "mismatch.csv",
    )
    run_id = storage.start_or_resume_run(DEFAULT_FILTERS, SOURCE_URL, reset=True)
    headers = ["S.No", "Acknowledgement No", "Registration No", "Project Name"]
    # Portal reports 10 entries, but only 2 are returned on the single page
    html = _build_mock_html(
        headers,
        [["1", "ACK-1", "REG-1", "P1"], ["2", "ACK-2", "REG-2", "P2"]],
        current_page=1,
        total_pages=1,
        range_start=1,
        range_end=2,
        reported_total=10,
        next_disabled=True,
    )
    res = parse_search_page_html(html, SOURCE_URL, DEFAULT_FILTERS)
    storage.save_page_result(run_id, res)
    storage.finalize_run(run_id, status="COMPLETED", reached_last_page=True)

    report = generate_validation_report(storage, report_path=tmp_path / "report.json", expected_full_run=True)
    assert report["counts_reconcile"] is False
    assert report["is_successful_full_extraction"] is False
    assert report["validation_status"] == "VALIDATION_FAILED_OR_DISCREPANCY"
    assert any("Count mismatch" in msg for msg in report["discrepancy_explanations"])
    storage.close()
