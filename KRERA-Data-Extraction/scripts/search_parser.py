"""
K-RERA Search Results Table Parser & DOM Inspector

Strictly scoped to the search-results table (Phase 1).
Does NOT open individual project-detail pages or download documents.
Discovers column headers, row cells, link attributes, pagination state,
and portal-reported totals dynamically without hardcoding table schemas.
"""

from __future__ import annotations

import hashlib
import json
import re
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from lxml import html as lxml_html


class PortalSecurityBlockError(RuntimeError):
    """Raised when the portal displays a security modal, CAPTCHA block, or access restriction."""


@dataclass
class ExtractedCell:
    column_index: int
    column_header: str
    raw_text: str
    links: List[Dict[str, str]] = field(default_factory=list)


@dataclass
class ExtractedSearchRow:
    page_number: int
    row_order: int
    extraction_timestamp: str
    source_url: str
    filter_config: Dict[str, Any]
    column_headers: List[str]
    cells: List[ExtractedCell]
    row_dict: Dict[str, str]
    project_detail_links: List[Dict[str, str]]
    record_unique_key: str
    row_hash: str

    def to_jsonl_dict(self) -> Dict[str, Any]:
        return {
            "page_number": self.page_number,
            "row_order": self.row_order,
            "extraction_timestamp": self.extraction_timestamp,
            "source_url": self.source_url,
            "filter_config": self.filter_config,
            "record_unique_key": self.record_unique_key,
            "row_hash": self.row_hash,
            "project_detail_links": self.project_detail_links,
            "row_data": self.row_dict,
            "cells": [
                {
                    "column_index": c.column_index,
                    "column_header": c.column_header,
                    "raw_text": c.raw_text,
                    "links": c.links,
                }
                for c in self.cells
            ],
        }


@dataclass
class PaginationState:
    current_page: Optional[int] = None
    has_next: bool = False
    next_disabled: bool = True
    last_page_number: Optional[int] = None
    range_start: Optional[int] = None
    range_end: Optional[int] = None
    portal_reported_total: Optional[int] = None
    info_text_raw: Optional[str] = None
    visible_controls: List[str] = field(default_factory=list)


@dataclass
class PageExtractionResult:
    page_number: int
    source_url: str
    filter_config: Dict[str, Any]
    extracted_at: str
    column_headers: List[str]
    rows: List[ExtractedSearchRow]
    pagination: PaginationState
    page_signature_hash: str
    is_empty_result: bool = False

    @property
    def first_record_key(self) -> Optional[str]:
        return self.rows[0].record_unique_key if self.rows else None

    @property
    def last_record_key(self) -> Optional[str]:
        return self.rows[-1].record_unique_key if self.rows else None


SECURITY_BLOCK_PATTERNS = [
    r"Due to security reason,\s*This function has been disabled",
    r"Access Denied",
    r"403 Forbidden",
    r"Too Many Requests",
    r"automated queries.*blocked",
    r"unusual traffic from your computer network",
]


def _is_element_visible_in_static_html(el: Any) -> bool:
    """Checks if an HTML element and its ancestors are not explicitly hidden in static markup."""
    curr = el
    while curr is not None:
        if not isinstance(curr.tag, str):
            curr = curr.getparent()
            continue
        style = (curr.attrib.get("style") or "").lower().replace(" ", "")
        if "display:none" in style or "visibility:hidden" in style:
            return False
        if "hidden" in curr.attrib:
            return False
        classes = (curr.attrib.get("class") or "").split()
        # Bootstrap modal that is not open (`modal` without `in` or `show` and without display:block)
        if "modal" in classes and "in" not in classes and "show" not in classes:
            if "display:block" not in style:
                return False
        if "hide" in classes or "d-none" in classes or "hidden" in classes:
            return False
        curr = curr.getparent()
    return True


def check_for_security_block(tree: Any) -> None:
    """Inspects parsed DOM for visible security warnings, blocks, or CAPTCHA walls."""
    for pattern in SECURITY_BLOCK_PATTERNS:
        regex = re.compile(pattern, re.IGNORECASE)
        for el in tree.xpath("//*[text()]"):
            if not isinstance(el.tag, str) or el.tag.lower() in ("script", "style", "noscript"):
                continue
            direct_text = " ".join(el.xpath("./text()")).strip()
            if direct_text and regex.search(direct_text):
                if _is_element_visible_in_static_html(el):
                    raise PortalSecurityBlockError(
                        f"Portal security/block warning detected: '{direct_text}'"
                    )


def _clean_preserve_text(raw: str) -> str:
    """Normalizes internal whitespace/newlines from HTML layout while preserving exact textual content."""
    if not raw:
        return ""
    # Replace non-breaking spaces and collapse purely layout-induced multi-line indentation
    # while keeping single spaces intact.
    cleaned = raw.replace("\xa0", " ")
    cleaned = re.sub(r"[ \t\r\n]+", " ", cleaned)
    return cleaned.strip()


def _extract_links_from_element(cell_el: Any) -> List[Dict[str, str]]:
    """Captures visible link/button destinations or identifiers inside a cell without navigating."""
    links: List[Dict[str, str]] = []
    for node in cell_el.xpath(".//a | .//button | .//input[@type='button' or @type='submit']"):
        info: Dict[str, str] = {"tag": node.tag.lower()}
        text = _clean_preserve_text("".join(node.itertext()))
        if text:
            info["text"] = text
        for attr in ("href", "onclick", "id", "name", "value", "title", "target"):
            val = node.attrib.get(attr)
            if val is not None and val.strip() != "":
                info[attr] = val.strip()
        for k, v in node.attrib.items():
            if k.startswith("data-") and v.strip():
                info[k] = v.strip()
        # Only record if it has an actionable attribute or link
        if any(k in info for k in ("href", "onclick", "id", "value")) or any(
            k.startswith("data-") for k in info
        ):
            links.append(info)
    return links


def _select_results_table(tree: Any, table_selector_id: Optional[str] = None) -> Any:
    """Selects the active search-results table from the DOM."""
    if table_selector_id:
        tables = tree.xpath(f"//table[@id='{table_selector_id}']")
        if tables:
            return tables[0]

    # Prefer visible tables inside active tab-pane if Bootstrap tabs are used
    active_pane_tables = [
        t
        for t in tree.xpath(
            "//div[contains(@class, 'tab-pane') and contains(@class, 'active')]//table"
        )
        if _is_element_visible_in_static_html(t) and t.xpath(".//thead//th")
    ]
    if active_pane_tables:
        # If DataTables splits header/body into two tables, prefer the one with tbody or most columns
        with_tbody = [t for t in active_pane_tables if t.xpath(".//tbody")]
        if with_tbody:
            return max(with_tbody, key=lambda t: len(t.xpath(".//thead//th")))
        return max(active_pane_tables, key=lambda t: len(t.xpath(".//thead//th")))

    # Fallback: any visible table with a thead
    all_tables = [
        t
        for t in tree.xpath("//table")
        if _is_element_visible_in_static_html(t) and t.xpath(".//thead//th | .//tr[1]/th")
    ]
    if all_tables:
        with_tbody = [t for t in all_tables if t.xpath(".//tbody")]
        if with_tbody:
            return max(with_tbody, key=lambda t: len(t.xpath(".//thead//th | .//tr[1]/th")))
        return max(all_tables, key=lambda t: len(t.xpath(".//thead//th | .//tr[1]/th")))

    raise ValueError("No search results table with column headers found in DOM.")


def discover_column_headers(table_el: Any) -> List[str]:
    """Dynamically discovers column headers from a table element."""
    header_rows = table_el.xpath("./thead/tr")
    if header_rows:
        # Use the last row in thead (in case of top-level grouping headers)
        th_cells = header_rows[-1].xpath("./th | ./td")
    else:
        first_row = table_el.xpath(".//tr[1]")
        th_cells = first_row[0].xpath("./th | ./td") if first_row else []

    raw_headers: List[str] = []
    seen_counts: Dict[str, int] = {}

    for idx, th in enumerate(th_cells, start=1):
        label = _clean_preserve_text("".join(th.itertext()))
        if not label:
            label = f"Column_{idx}"
        if label in seen_counts:
            seen_counts[label] += 1
            unique_label = f"{label}__{seen_counts[label]}"
        else:
            seen_counts[label] = 1
            unique_label = label
        raw_headers.append(unique_label)

    if not raw_headers:
        raise ValueError("Table header row exists but contains 0 discoverable columns.")

    return raw_headers


def parse_pagination_state(tree: Any, table_el: Any) -> PaginationState:
    """Dynamically inspects pagination controls and DataTables summary info."""
    state = PaginationState()

    # Find container wrapper (e.g., DataTables wrapper or active tab pane)
    wrapper = None
    curr = table_el
    while curr is not None:
        classes = curr.attrib.get("class") or ""
        if "dataTables_wrapper" in classes or "tab-pane" in classes:
            wrapper = curr
            break
        curr = curr.getparent()
    search_root = wrapper if wrapper is not None else tree

    # 1. Inspect info text: "Showing 1 to 10 of 4,459 entries"
    info_nodes = search_root.xpath(
        ".//*[contains(@class, 'dataTables_info') or contains(text(), 'Showing ') or contains(text(), 'entries')]"
    )
    info_pattern = re.compile(
        r"Showing\s+([\d,]+)\s+to\s+([\d,]+)\s+of\s+([\d,]+)\s+entries",
        re.IGNORECASE,
    )
    for node in info_nodes:
        txt = _clean_preserve_text("".join(node.itertext()))
        m = info_pattern.search(txt)
        if m:
            state.info_text_raw = m.group(0)
            state.range_start = int(m.group(1).replace(",", ""))
            state.range_end = int(m.group(2).replace(",", ""))
            state.portal_reported_total = int(m.group(3).replace(",", ""))
            break

    # Check for "Showing 0 to 0 of 0 entries" if no match yet
    if state.portal_reported_total is None:
        full_text = _clean_preserve_text("".join(search_root.itertext()))
        m = info_pattern.search(full_text)
        if m:
            state.info_text_raw = m.group(0)
            state.range_start = int(m.group(1).replace(",", ""))
            state.range_end = int(m.group(2).replace(",", ""))
            state.portal_reported_total = int(m.group(3).replace(",", ""))

    # 2. Inspect pagination controls
    paginate_containers = search_root.xpath(
        ".//*[contains(@class, 'dataTables_paginate') or contains(@class, 'pagination')]"
    )
    if paginate_containers:
        p_root = paginate_containers[0]
        buttons = p_root.xpath(".//a | .//button | .//li[contains(@class, 'paginate_button')]")
        page_numbers: List[int] = []

        for btn in buttons:
            txt = _clean_preserve_text("".join(btn.itertext()))
            classes = (btn.attrib.get("class") or "").lower().split()
            parent_classes = (
                (btn.getparent().attrib.get("class") or "").lower().split()
                if btn.getparent() is not None
                else []
            )
            all_classes = set(classes + parent_classes)
            is_disabled = (
                "disabled" in all_classes
                or btn.attrib.get("disabled") is not None
                or btn.attrib.get("aria-disabled") == "true"
            )
            is_current = "current" in all_classes or "active" in all_classes

            if txt and txt not in state.visible_controls:
                state.visible_controls.append(txt)

            if txt.isdigit():
                num = int(txt)
                page_numbers.append(num)
                if is_current:
                    state.current_page = num

            if txt.lower() in ("next", "next ›", "›", ">", "»") or "next" in all_classes:
                state.has_next = not is_disabled
                state.next_disabled = is_disabled

        if page_numbers:
            state.last_page_number = max(page_numbers)

    return state


def _derive_record_unique_key(row_dict: Dict[str, str], links: List[Dict[str, str]], row_hash: str) -> str:
    """Derives a deterministic unique identifier for a project row without losing rows with missing Reg No."""
    reg_no = ""
    ack_no = ""

    for k, v in row_dict.items():
        k_lower = k.lower()
        if "registration no" in k_lower or "reg no" in k_lower or "reg. no" in k_lower:
            reg_no = v.strip()
        elif "acknowledgement no" in k_lower or "ack no" in k_lower or "ack. no" in k_lower:
            ack_no = v.strip()

    # Check if there is a stable project identifier in the detail link attributes
    link_id = ""
    for lnk in links:
        for attr in ("id", "onclick", "href", "data-id", "data-project-id"):
            if attr in lnk and lnk[attr] and lnk[attr] not in ("#", "javascript:void(0);", "javascript:void(0)"):
                link_id = lnk[attr]
                break
        if link_id:
            break

    if ack_no and reg_no:
        return f"ACK:{ack_no}|REG:{reg_no}"
    if ack_no:
        return f"ACK:{ack_no}"
    if reg_no:
        return f"REG:{reg_no}"
    if link_id:
        return f"LNK:{link_id}"
    return f"HASH:{row_hash[:24]}"


def parse_search_page_html(
    html_content: str,
    source_url: str,
    filter_config: Dict[str, Any],
    expected_page_number: int = 1,
    table_selector_id: Optional[str] = None,
    extraction_timestamp: Optional[str] = None,
) -> PageExtractionResult:
    """Parses a K-RERA search-results HTML snapshot into structured rows and pagination state."""
    if not html_content or not html_content.strip():
        raise ValueError("Empty HTML content provided to parser.")

    tree = lxml_html.fromstring(html_content)

    # 1. Check for security modal / portal block
    check_for_security_block(tree)

    # 2. Locate results table & discover headers dynamically
    table_el = _select_results_table(tree, table_selector_id=table_selector_id)
    headers = discover_column_headers(table_el)

    # 3. Inspect pagination & portal-reported total
    pagination = parse_pagination_state(tree, table_el)
    actual_page_number = pagination.current_page if pagination.current_page is not None else expected_page_number
    ts = extraction_timestamp or datetime.now(timezone.utc).isoformat()

    # 4. Extract tbody rows
    tbody_rows = table_el.xpath("./tbody/tr")
    if not tbody_rows:
        # Fallback if table has no explicit tbody tag
        all_tr = table_el.xpath("./tr")
        tbody_rows = all_tr[1:] if len(all_tr) > 1 else []

    extracted_rows: List[ExtractedSearchRow] = []
    is_empty = False

    for idx, tr in enumerate(tbody_rows, start=1):
        td_cells = tr.xpath("./td | ./th")
        if not td_cells:
            continue

        # Check for DataTables empty placeholder row
        first_td_classes = (td_cells[0].attrib.get("class") or "").lower()
        first_td_text = _clean_preserve_text("".join(td_cells[0].itertext()))
        if (
            "datatables_empty" in first_td_classes
            or (
                len(td_cells) == 1
                and any(
                    phrase in first_td_text.lower()
                    for phrase in (
                        "no data available",
                        "no matching records",
                        "no records found",
                    )
                )
            )
        ):
            is_empty = True
            break

        row_cells: List[ExtractedCell] = []
        row_dict: Dict[str, str] = {}
        row_links: List[Dict[str, str]] = []

        # Map each cell to its discovered header; if row has extra cells beyond thead, create dynamic overflow headers
        max_cols = max(len(headers), len(td_cells))
        for col_idx in range(max_cols):
            if col_idx < len(headers):
                col_header = headers[col_idx]
            else:
                col_header = f"Overflow_Column_{col_idx + 1}"
                headers.append(col_header)

            if col_idx < len(td_cells):
                td = td_cells[col_idx]
                raw_text = _clean_preserve_text("".join(td.itertext()))
                cell_links = _extract_links_from_element(td)
            else:
                raw_text = ""
                cell_links = []

            row_cells.append(
                ExtractedCell(
                    column_index=col_idx + 1,
                    column_header=col_header,
                    raw_text=raw_text,
                    links=cell_links,
                )
            )
            row_dict[col_header] = raw_text
            for lnk in cell_links:
                lnk_with_col = dict(lnk)
                lnk_with_col["column_header"] = col_header
                row_links.append(lnk_with_col)

        # Compute deterministic hash of the row content (excluding S.No so duplicate records across pages are caught)
        non_sno_items = [
            f"{c.column_header}={c.raw_text}"
            for c in row_cells
            if c.column_header.lower() not in ("s.no", "s.no.", "sl.no", "sr.no", "sno")
        ]
        hash_payload = "||".join(non_sno_items) + "||" + json.dumps(row_links, sort_keys=True)
        row_hash = hashlib.sha256(hash_payload.encode("utf-8")).hexdigest()
        unique_key = _derive_record_unique_key(row_dict, row_links, row_hash)

        extracted_rows.append(
            ExtractedSearchRow(
                page_number=actual_page_number,
                row_order=idx,
                extraction_timestamp=ts,
                source_url=source_url,
                filter_config=filter_config,
                column_headers=list(headers),
                cells=row_cells,
                row_dict=row_dict,
                project_detail_links=row_links,
                record_unique_key=unique_key,
                row_hash=row_hash,
            )
        )

    if not extracted_rows:
        is_empty = True

    page_sig_payload = "|".join(f"{r.row_order}:{r.record_unique_key}:{r.row_hash}" for r in extracted_rows)
    page_sig_hash = hashlib.sha256(page_sig_payload.encode("utf-8")).hexdigest()

    return PageExtractionResult(
        page_number=actual_page_number,
        source_url=source_url,
        filter_config=filter_config,
        extracted_at=ts,
        column_headers=headers,
        rows=extracted_rows,
        pagination=pagination,
        page_signature_hash=page_sig_hash,
        is_empty_result=is_empty,
    )
