"""
K-RERA Project Detail Modal DOM Parser

Parses the HTML injected into `#result` inside `#project_details_popup` by K-RERA's
native `showFileApplicationPreview` handler into a discovery-driven payload for
`KRERADiscoveryEngine`.

Key capabilities:
- Extracts modal header identity (Project Name, Acknowledgement No, Registration No).
- Discovers visible navigation tabs (`ul.nav-tabs`), nested sub-tabs (e.g. Complaints),
  and hidden/unlinked `.tab-pane` containers present in the DOM (`#modPlan`, `#extPlan`,
  `#postReg`, `#menu3`, `#menu5`, `#completion`).
- Dynamically discovers sections, key-value `.row` pairs, 5 distinct table archetypes,
  and document metadata with category-first classification.
- Scrubs excluded PII at the DOM parsing boundary so raw extraction JSON never persists PII.
"""

from __future__ import annotations

import re
from typing import Any, Dict, List, Optional, Set, Tuple
from urllib.parse import parse_qs, urlparse
from lxml import html as lxml_html

from .discovery_engine import classify_pii_exclusion, is_individual_section
from .models import ObservationState

# Standard navigation tab probes to report absent tabs accurately
KNOWN_KRERA_NAV_TAB_PROBES = [
    "Promoter Details",
    "Land Details",
    "Project Details",
    "Bank Details",
    "Uploaded Documents",
    "Enquired Documents",
    "Complaints",
    "Quarterly Updates",
    "Completion Details",
]

# Deprecated: Do not assign semantic meaning to an unlinked pane based only on its DOM ID.
# Semantic labels for unlinked panes are resolved strictly via:
# 1. Explicit DOM comment label (e.g., <!-- <li><a href="#menu3">Cost Details</a></li> -->)
# 2. Actual heading inside the pane (.//h1 | .//h2 | .//h3 | .//h4)
# 3. Generic label: f"Unlinked Pane (#{pane_id})"
UNLINKED_PANE_LABELS: Dict[str, str] = {}


def resolve_unlinked_pane_label(
    pane_el: Any,
    pane_id: str,
    commented_nav_labels: Dict[str, str],
) -> str:
    """Resolves the display label for an unlinked DOM `.tab-pane` without assuming global meaning from DOM ID alone.

    Priority:
    1. Explicit DOM comment label (`<!-- <li><a href="#paneId">Label</a></li> -->`).
    2. First non-empty heading (`h1`, `h2`, `h3`, `h4`) inside the pane.
    3. Generic label: `Unlinked Pane (#<pane_id>)`.
    """
    clean_id = pane_id.lstrip("#").strip()
    comment_label = norm_ws(commented_nav_labels.get(clean_id) or commented_nav_labels.get(f"#{clean_id}"))
    if comment_label:
        return comment_label

    headings = pane_el.xpath(".//h1 | .//h2 | .//h3 | .//h4")
    for h_el in headings:
        h_text = re.sub(r"\s*:\s*$", "", norm_ws(h_el.text_content())).strip()
        if h_text:
            return h_text

    return f"Unlinked Pane (#{clean_id})"


def norm_ws(text: Optional[str]) -> str:
    """Collapses whitespace and strips leading/trailing spaces."""
    if not text:
        return ""
    return re.sub(r"\s+", " ", text).strip()


def extract_doc_id_from_url(url: Optional[str]) -> Optional[str]:
    """Extracts the DOC_ID or CER_NO query parameter from a K-RERA download URL."""
    if not url:
        return None
    try:
        parsed = urlparse(url)
        qs = parse_qs(parsed.query)
        if "DOC_ID" in qs and qs["DOC_ID"]:
            val = qs["DOC_ID"][0].strip()
            return val if val else None
        if "CER_NO" in qs and qs["CER_NO"]:
            val = qs["CER_NO"][0].strip()
            return val if val else None
    except Exception:
        pass
    return None


def clean_label_and_annex(el) -> Tuple[str, Optional[str]]:
    """Extracts clean field/document label and optional <annex> reference from a label element."""
    annex_els = el.xpath(".//annex")
    annex_text = norm_ws(annex_els[0].text_content()) if annex_els else None

    full_text = norm_ws(el.text_content())
    if annex_text and annex_text in full_text:
        full_text = full_text.replace(annex_text, " ")
    # Strip trailing colon and extra spaces
    label = re.sub(r"\s*:\s*$", "", norm_ws(full_text)).strip()
    return label, annex_text


def extract_modal_identity(root) -> Dict[str, Optional[str]]:
    """Extracts Project Name, Acknowledgement Number, and Registration Number from modal header."""
    full_text = norm_ws(root.text_content())
    proj_name = None
    ack_no = None
    reg_no = None

    m_proj = re.search(
        r"Project\s+Name\s*:\s*(.*?)(?=Acknowledgement\s+Number|Registration\s+Number|THE\s+BUYERS|$)",
        full_text,
        re.IGNORECASE,
    )
    if m_proj:
        proj_name = norm_ws(m_proj.group(1))

    m_ack = re.search(
        r"Acknowledgement\s+Number\s*:\s*([A-Za-z0-9/_-]+)",
        full_text,
        re.IGNORECASE,
    )
    if m_ack:
        ack_no = norm_ws(m_ack.group(1))

    m_reg = re.search(
        r"Registration\s+Number\s*:\s*([A-Za-z0-9/_-]+)",
        full_text,
        re.IGNORECASE,
    )
    if m_reg:
        reg_no = norm_ws(m_reg.group(1))

    return {
        "project_name": proj_name,
        "acknowledgement_number": ack_no,
        "registration_number": reg_no,
    }


def extract_commented_out_nav_tabs(raw_html: str) -> Dict[str, str]:
    """Finds commented-out <li><a href='#paneId'>Label</a></li> inside raw HTML before stripping comments."""
    commented_map: Dict[str, str] = {}
    for m in re.finditer(r"<!--(.*?)-->", raw_html, flags=re.S):
        comment_body = m.group(1)
        for a_match in re.finditer(
            r'<a[^>]*href=["\']#([^"\']+)["\'][^>]*>(.*?)</a>',
            comment_body,
            flags=re.S | re.I,
        ):
            pane_id = a_match.group(1).strip()
            lbl = norm_ws(re.sub(r"<[^>]+>", " ", a_match.group(2)))
            if pane_id and lbl:
                commented_map[pane_id] = lbl
    return commented_map


def parse_project_detail_modal_html(
    raw_html: str,
    portal_detail_element_id: Optional[str] = None,
    catalogue_page_number: Optional[int] = None,
    catalogue_row_order: Optional[int] = None,
    scrub_raw_pii: bool = True,
) -> Dict[str, Any]:
    """Parses `#result` modal HTML into a discovery-driven dictionary payload."""
    commented_nav_labels = extract_commented_out_nav_tabs(raw_html)
    clean_html = re.sub(r"<!--.*?-->", "", raw_html, flags=re.S)
    root = lxml_html.fragment_fromstring(clean_html, create_parent="div")

    modal_identity = extract_modal_identity(root)
    modal_identity["portal_detail_element_id"] = portal_detail_element_id
    modal_identity["catalogue_page_number"] = catalogue_page_number
    modal_identity["catalogue_row_order"] = catalogue_row_order

    # 1. Discover top-level visible navigation tabs (ul.nav-tabs not inside a .tab-pane)
    top_nav_links = root.xpath(
        ".//ul[contains(concat(' ', normalize-space(@class), ' '), ' nav-tabs ')]"
        "[not(ancestor::*[contains(concat(' ', normalize-space(@class), ' '), ' tab-pane ')])]"
        "//li/a"
    )

    visible_pane_ids: Set[str] = set()
    subtab_pane_ids: Set[str] = set()
    tabs_payload: List[Dict[str, Any]] = []

    for a_el in top_nav_links:
        tab_label = norm_ws(a_el.text_content())
        href = (a_el.get("href") or "").strip()
        pane_id = href[1:] if href.startswith("#") else href
        if not pane_id:
            continue
        visible_pane_ids.add(pane_id)

        pane_els = root.xpath(f".//*[@id='{pane_id}']")
        if not pane_els:
            tabs_payload.append(
                {
                    "label": tab_label,
                    "id": f"#{pane_id}",
                    "is_nav_visible": True,
                    "dom_presence": "not_present_in_dom",
                    "is_empty": True,
                    "sections": [],
                }
            )
            continue

        pane_el = pane_els[0]
        try:
            tab_dict = _parse_tab_pane_element(
                pane_el=pane_el,
                tab_label=tab_label,
                pane_id=pane_id,
                is_nav_visible=True,
                dom_presence="visible_nav_tab",
                subtab_pane_ids=subtab_pane_ids,
                scrub_raw_pii=scrub_raw_pii,
            )
        except Exception as exc:
            tab_dict = {
                "label": tab_label,
                "id": f"#{pane_id}",
                "is_nav_visible": True,
                "dom_presence": "visible_nav_tab",
                "is_empty": True,
                "simulate_failure": True,
                "error_message": f"Tab parser failure in '{tab_label}' (#{pane_id}): {exc}",
                "sections": [],
                "sub_tabs": [],
            }
        tabs_payload.append(tab_dict)

    # 2. Discover unlinked / hidden .tab-pane elements present in the DOM
    unlinked_panes_payload: List[Dict[str, Any]] = []
    all_pane_els = root.xpath(
        ".//*[contains(concat(' ', normalize-space(@class), ' '), ' tab-pane ')]"
    )
    for pane_el in all_pane_els:
        pane_id = (pane_el.get("id") or "").strip()
        if not pane_id or pane_id in visible_pane_ids or pane_id in subtab_pane_ids:
            continue

        # Determine label for this unlinked DOM pane strictly via comment -> heading -> generic ID label
        pane_label = resolve_unlinked_pane_label(pane_el, pane_id, commented_nav_labels)

        try:
            pane_dict = _parse_tab_pane_element(
                pane_el=pane_el,
                tab_label=pane_label,
                pane_id=pane_id,
                is_nav_visible=False,
                dom_presence="hidden_or_unlinked_dom_pane",
                subtab_pane_ids=subtab_pane_ids,
                scrub_raw_pii=scrub_raw_pii,
            )
        except Exception as exc:
            pane_dict = {
                "label": pane_label,
                "id": f"#{pane_id}",
                "is_nav_visible": False,
                "dom_presence": "hidden_or_unlinked_dom_pane",
                "is_empty": True,
                "simulate_failure": True,
                "error_message": f"Unlinked pane parser failure in '{pane_label}' (#{pane_id}): {exc}",
                "sections": [],
                "sub_tabs": [],
            }
        unlinked_panes_payload.append(pane_dict)

    return {
        "modal_identity": modal_identity,
        "tabs": tabs_payload,
        "unlinked_dom_panes": unlinked_panes_payload,
        "commented_out_nav_tabs": commented_nav_labels,
        "checked_absent_tabs": KNOWN_KRERA_NAV_TAB_PROBES,
    }


def _parse_tab_pane_element(
    pane_el,
    tab_label: str,
    pane_id: str,
    is_nav_visible: bool,
    dom_presence: str,
    subtab_pane_ids: Set[str],
    scrub_raw_pii: bool,
) -> Dict[str, Any]:
    """Parses a single `.tab-pane` element into sections, fields, tables, documents, and sub-tabs."""
    sim_fail = pane_el.get("data-simulate-parser-failure")
    if sim_fail:
        raise RuntimeError(sim_fail)

    sub_tabs_payload: List[Dict[str, Any]] = []

    # Check if this pane contains nested ul.nav-tabs (e.g., Complaints -> Promoter vs Project)
    inner_nav_links = pane_el.xpath(
        ".//ul[contains(concat(' ', normalize-space(@class), ' '), ' nav-tabs ')]//li/a"
    )
    for sub_a in inner_nav_links:
        sub_label = norm_ws(sub_a.text_content())
        sub_href = (sub_a.get("href") or "").strip()
        sub_id = sub_href[1:] if sub_href.startswith("#") else sub_href
        if not sub_id:
            continue
        subtab_pane_ids.add(sub_id)
        sub_pane_els = pane_el.xpath(f".//*[@id='{sub_id}']")
        if sub_pane_els:
            sub_dict = _parse_tab_pane_element(
                pane_el=sub_pane_els[0],
                tab_label=sub_label,
                pane_id=sub_id,
                is_nav_visible=True,
                dom_presence="nested_sub_tab",
                subtab_pane_ids=subtab_pane_ids,
                scrub_raw_pii=scrub_raw_pii,
            )
            sub_tabs_payload.append(sub_dict)

    sections_payload: List[Dict[str, Any]] = []
    if sub_tabs_payload:
        # Promote sub-tab sections with clear sub-tab prefix
        for st in sub_tabs_payload:
            for sec in st.get("sections", []):
                sec_copy = dict(sec)
                sec_copy["label"] = f"{st['label']} — {sec['label']}"
                sections_payload.append(sec_copy)
    else:
        sections_payload = _extract_sections_from_pane(
            pane_el=pane_el,
            tab_label=tab_label,
            scrub_raw_pii=scrub_raw_pii,
        )

    has_data = any(
        not s.get("is_empty", False)
        and (len(s.get("fields", [])) > 0 or len(s.get("table_rows", [])) > 0 or len(s.get("documents", [])) > 0)
        for s in sections_payload
    )

    # Special handling for #modPlan (Modification of Plan Details):
    # K-RERA renders a side-by-side comparison template ('As Per Registered Plan' vs 'As Per Modified Plan')
    # even when no modification was ever applied ('Modification Applied On' is blank and all modified links are empty).
    if pane_id == "modPlan":
        mod_applied_dates = [
            f.get("value")
            for s in sections_payload
            for f in s.get("fields", [])
            if "modification applied on" in (f.get("label") or "").lower()
        ]
        has_modified_docs = any(
            d.get("doc_id") or d.get("filename")
            for s in sections_payload
            for d in s.get("documents", [])
        )
        if (not mod_applied_dates or all(not d for d in mod_applied_dates)) and not has_modified_docs:
            has_data = False
            for s in sections_payload:
                s["is_empty"] = True
                if not s.get("empty_message"):
                    s["empty_message"] = "No Plan Modification Applied (Modification Applied On is blank)"

    return {
        "label": tab_label,
        "id": f"#{pane_id}",
        "is_nav_visible": is_nav_visible,
        "dom_presence": dom_presence,
        "is_empty": not has_data,
        "sections": sections_payload,
        "sub_tabs": sub_tabs_payload,
    }


def _new_section_dict(label: str) -> Dict[str, Any]:
    return {
        "label": label,
        "type": "generic",
        "is_empty": False,
        "empty_message": None,
        "fields": [],
        "table_headers": [],
        "table_rows": [],
        "documents": [],
        "excluded_images": [],
        "excluded_pii": [],
    }


def _record_excluded_pii(
    current_sec: Dict[str, Any],
    field_or_column_label: str,
    pii_hit: Tuple[str, str],
    redaction_action: str = "excluded_field",
) -> None:
    """Records safe PII exclusion metadata without retaining the excluded value, URL, doc_id, or filename."""
    pii_cat, reason = pii_hit
    current_sec["excluded_pii"].append(
        {
            "field_or_column_label": field_or_column_label,
            "pii_category": pii_cat,
            "redaction_action": redaction_action,
            "reason": reason,
        }
    )


def _is_downloadable_or_doc_href(href: Optional[str], link_text: str) -> bool:
    """Determines whether an anchor href or link text represents a portal document link."""
    if href is None:
        return False
    return bool(
        "/download_jc" in href
        or "/certificate" in href
        or "/covidcertificate" in href
        or link_text.lower().endswith(
            (".pdf", ".jpg", ".jpeg", ".png", ".xlsx", ".xls", ".doc", ".docx")
        )
    )


def _section_has_content(sec: Dict[str, Any]) -> bool:
    return bool(
        sec["fields"]
        or sec["table_rows"]
        or sec["documents"]
        or sec["empty_message"]
        or sec["excluded_images"]
        or sec["excluded_pii"]
    )


def _finalize_section_dict(sec: Dict[str, Any]) -> Dict[str, Any]:
    has_fields = any(
        f.get("value") not in (None, "")
        or f.get("observation_state") == ObservationState.NOT_APPLICABLE
        for f in sec["fields"]
    )
    has_rows = len(sec["table_rows"]) > 0
    has_docs = any(
        d.get("observation_state") != ObservationState.NOT_AVAILABLE
        and (d.get("filename") or d.get("doc_id"))
        for d in sec["documents"]
    )

    if has_fields and has_rows:
        sec["type"] = "mixed"
    elif has_rows:
        sec["type"] = "table"
    elif has_docs and not has_fields:
        sec["type"] = "document_list"
    elif sec["fields"]:
        sec["type"] = "key_value"

    sec["is_empty"] = not (has_fields or has_rows or has_docs)
    return sec


def _extract_sections_from_pane(
    pane_el,
    tab_label: str,
    scrub_raw_pii: bool,
) -> List[Dict[str, Any]]:
    """Walks a `.tab-pane` in document order to extract sections, rows, tables, and documents."""
    sections: List[Dict[str, Any]] = []
    current_sec = _new_section_dict(tab_label)
    pending_completion_doc_category: Optional[str] = None
    pane_ctx: Dict[str, Optional[str]] = {"promoter_type": None}

    # Walk descendants in document order, skipping nested .tab-pane subtrees
    for el in pane_el.iter():
        if el is pane_el:
            continue
        tag = el.tag if isinstance(el.tag, str) else ""
        if not tag:
            continue
        tag_low = tag.lower()
        cls_str = f" {norm_ws(el.get('class'))} "

        # 1. Section Headings (h1, h2, h3, h4)
        if tag_low in ("h1", "h2", "h3", "h4"):
            heading_text = norm_ws(el.text_content())
            if not heading_text:
                continue

            # Check for "Promoter has Applied for Completion on <date>" banner inside Completion Details
            m_comp_date = re.match(
                r"^Promoter\s+has\s+Applied\s+for\s+Completion\s+on\s*(.*)$",
                heading_text,
                re.IGNORECASE,
            )
            if m_comp_date:
                applied_date = norm_ws(m_comp_date.group(1))
                if applied_date:
                    current_sec["fields"].append(
                        {
                            "label": "Completion Application Date",
                            "value": applied_date,
                            "observation_state": ObservationState.PRESENT_WITH_DATA,
                        }
                    )
                continue

            # Start a new section or rename current empty placeholder section
            if _section_has_content(current_sec):
                sections.append(_finalize_section_dict(current_sec))
                current_sec = _new_section_dict(heading_text)
            else:
                current_sec["label"] = heading_text
            pending_completion_doc_category = None
            continue

        # 2. Empty-state banner (div.add-more)
        if tag_low == "div" and " add-more " in cls_str:
            banner_msg = norm_ws(el.text_content())
            if banner_msg:
                current_sec["empty_message"] = banner_msg
                if "no previous projects" in banner_msg.lower():
                    current_sec["fields"].append(
                        {
                            "label": current_sec["label"],
                            "value": banner_msg,
                            "observation_state": ObservationState.NOT_APPLICABLE,
                        }
                    )
            continue

        # 3. Personal photograph <img> tags inside Promoter Details (#home) or individual sections (outside tables)
        if tag_low == "img":
            if el.xpath("ancestor::table"):
                continue
            alt_txt = (el.get("alt") or "").lower()
            src_txt = el.get("src") or ""
            is_promoter_or_individual = (
                "promoter" in tab_label.lower()
                or is_individual_section(current_sec["label"], tab_label)
            )
            if is_promoter_or_individual and (
                "photo" in alt_txt or "/download_jc" in src_txt or "redacted_personal_photo" in src_txt
            ):
                current_sec["excluded_images"].append(
                    {
                        "label": "Photograph (img)",
                        "reason": f"Excluded personal photograph <img> tag in section '{current_sec['label']}'.",
                    }
                )
            continue

        # 4. Leaf <div class="row"> (a .row that does not wrap child .row or <table> elements)
        if tag_low == "div" and " row " in cls_str:
            has_child_rows_or_tables = bool(
                el.xpath(".//div[contains(concat(' ', normalize-space(@class), ' '), ' row ')] | .//table")
            )
            if has_child_rows_or_tables:
                continue

            pending_completion_doc_category = _parse_leaf_row(
                row_el=el,
                current_sec=current_sec,
                tab_label=tab_label,
                pending_completion_doc_category=pending_completion_doc_category,
                scrub_raw_pii=scrub_raw_pii,
                pane_ctx=pane_ctx,
            )
            continue

        # 5. Every <table> (both outer tables and nested tables are parsed via their own direct rows)
        if tag_low == "table":
            _parse_leaf_table(
                table_el=el,
                current_sec=current_sec,
                tab_label=tab_label,
                scrub_raw_pii=scrub_raw_pii,
                pane_ctx=pane_ctx,
            )
            continue

    if _section_has_content(current_sec) or not sections:
        sections.append(_finalize_section_dict(current_sec))

    return sections


def _parse_leaf_row(
    row_el,
    current_sec: Dict[str, Any],
    tab_label: str,
    pending_completion_doc_category: Optional[str],
    scrub_raw_pii: bool,
    pane_ctx: Optional[Dict[str, Optional[str]]] = None,
) -> Optional[str]:
    """Extracts key-value pairs and document links from a leaf Bootstrap `.row`."""
    if pane_ctx is None:
        pane_ctx = {"promoter_type": None}

    cols = [
        c
        for c in row_el
        if isinstance(c.tag, str)
        and c.tag.lower() == "div"
        and any(k in (c.get("class") or "") for k in ("col-md-", "col-sm-", "col-xs-"))
    ]
    if len(cols) < 2:
        return pending_completion_doc_category

    # Walk column pairs: (0, 1), (2, 3), ...
    pairs: List[Tuple[Any, Any]] = []
    idx = 0
    while idx + 1 < len(cols):
        pairs.append((cols[idx], cols[idx + 1]))
        idx += 2

    # Check if this row is the Pre-19/12/2020 Completion Details 'Name : <Category>' row
    if len(pairs) == 1 and "completion" in tab_label.lower():
        lbl0, _ = clean_label_and_annex(pairs[0][0])
        val0 = norm_ws(pairs[0][1].text_content())
        if lbl0.lower() == "name" and val0:
            current_sec["fields"].append(
                {
                    "label": "Completion Document Category Name",
                    "value": val0,
                    "observation_state": ObservationState.PRESENT_WITH_DATA,
                }
            )
            return val0

    # Check if this row is the Pre-19/12/2020 Completion Details 'Approval Date : <date> | Document : <link>' row
    if (
        len(pairs) == 2
        and pending_completion_doc_category
        and "completion" in tab_label.lower()
    ):
        lbl0, _ = clean_label_and_annex(pairs[0][0])
        val0 = norm_ws(pairs[0][1].text_content())
        lbl1, annex1 = clean_label_and_annex(pairs[1][0])
        if "approval date" in lbl0.lower() and "document" in lbl1.lower():
            links = pairs[1][1].xpath(".//a")
            href = links[0].get("href") if links else None
            fn = norm_ws(links[0].text_content()) if links else norm_ws(pairs[1][1].text_content())
            doc_id = extract_doc_id_from_url(href)

            current_sec["fields"].append(
                {
                    "label": f"{pending_completion_doc_category} - Approval Date",
                    "value": val0,
                    "observation_state": ObservationState.PRESENT_WITH_DATA,
                }
            )
            current_sec["fields"].append(
                {
                    "label": f"{pending_completion_doc_category} - Document",
                    "value": fn,
                    "source_link": href,
                    "annexure_reference": annex1,
                    "observation_state": ObservationState.PRESENT_WITH_DATA if (fn or doc_id) else ObservationState.NOT_AVAILABLE,
                }
            )
            current_sec["documents"].append(
                {
                    "category": pending_completion_doc_category,
                    "filename": fn or None,
                    "approval_date": val0 or None,
                    "url": href,
                    "doc_id": doc_id,
                    "annexure_reference": annex1,
                }
            )
            return None

    # Standard processing of column pairs in a .row
    prev_pair_label: Optional[str] = None
    prev_pair_val: Optional[str] = None

    for lbl_col, val_col in pairs:
        f_label, annex_ref = clean_label_and_annex(lbl_col)
        if not f_label:
            continue

        f_val = norm_ws(val_col.text_content())
        if f_label.lower() in ("promoter type", "type of promoter") and f_val:
            pane_ctx["promoter_type"] = f_val

        links = val_col.xpath(".//a")
        href = links[0].get("href") if links else None
        link_text = norm_ws(links[0].text_content()) if links else ""
        doc_id = extract_doc_id_from_url(href)

        # Check PII exclusion at raw parsing boundary if scrub_raw_pii=True
        if scrub_raw_pii:
            pii_hit = classify_pii_exclusion(
                f_label,
                f_val,
                current_sec["label"],
                tab_label,
                is_document=bool(links),
                promoter_type=pane_ctx.get("promoter_type"),
            )
            if pii_hit:
                _record_excluded_pii(
                    current_sec,
                    f_label,
                    pii_hit,
                    redaction_action="excluded_document" if links else "excluded_field",
                )
                prev_pair_label, prev_pair_val = f_label, None
                continue

        # Determine if this pair contains document link(s)
        is_doc_link = bool(links and _is_downloadable_or_doc_href(href, link_text))

        # Check if this is an empty document link gated by the previous pair in the same row
        explicit_state: Optional[ObservationState] = None
        if is_doc_link and not doc_id and not link_text:
            if prev_pair_label and prev_pair_val:
                p_lbl_low = prev_pair_label.lower()
                p_val_up = prev_pair_val.upper()
                if (
                    ("loan" in p_lbl_low and p_val_up == "NO")
                    or ("change in inventory" in p_lbl_low and p_val_up == "NO")
                    or ("completed within the stipulated period" in p_lbl_low and p_val_up == "YES")
                ):
                    explicit_state = ObservationState.NOT_APPLICABLE
            if not explicit_state:
                explicit_state = ObservationState.NOT_AVAILABLE

        # Also check if a regular field has an explicit NO on an applicability question
        if not is_doc_link and f_val.upper() == "NO" and any(
            q in f_label.lower()
            for q in ("is tdr applicable", "is there any rera registrations", "is there any projects launched")
        ):
            explicit_state = ObservationState.NOT_APPLICABLE

        current_sec["fields"].append(
            {
                "label": f_label,
                "value": link_text if (is_doc_link and len(links) == 1) else f_val,
                "source_link": href if is_doc_link else (href if href else None),
                "annexure_reference": annex_ref,
                "observation_state": explicit_state,
            }
        )

        if is_doc_link:
            # If the preceding pair in the same row was a received/approval date, attach it
            inferred_date = None
            if prev_pair_label and "date" in prev_pair_label.lower() and prev_pair_val:
                inferred_date = prev_pair_val

            for a_el in links:
                a_href = a_el.get("href")
                a_fn = norm_ws(a_el.text_content())
                a_doc_id = extract_doc_id_from_url(a_href)
                if not _is_downloadable_or_doc_href(a_href, a_fn):
                    continue
                if scrub_raw_pii:
                    doc_pii = classify_pii_exclusion(
                        f_label,
                        a_fn,
                        current_sec["label"],
                        tab_label,
                        is_document=True,
                        promoter_type=pane_ctx.get("promoter_type"),
                    )
                    if doc_pii:
                        _record_excluded_pii(current_sec, f_label, doc_pii, redaction_action="excluded_document")
                        continue
                current_sec["documents"].append(
                    {
                        "category": f_label,
                        "filename": a_fn or None,
                        "approval_date": inferred_date,
                        "url": a_href,
                        "doc_id": a_doc_id,
                        "annexure_reference": annex_ref,
                        "observation_state": explicit_state,
                    }
                )

        prev_pair_label = f_label
        prev_pair_val = f_val

    return pending_completion_doc_category


def _parse_leaf_table(
    table_el,
    current_sec: Dict[str, Any],
    tab_label: str,
    scrub_raw_pii: bool,
    pane_ctx: Optional[Dict[str, Optional[str]]] = None,
) -> None:
    """Parses a leaf `<table>` element across all 5 K-RERA table archetypes."""
    if pane_ctx is None:
        pane_ctx = {"promoter_type": None}

    # Extract header cells belonging directly to this table (not nested child tables)
    header_els = table_el.xpath("./thead/tr[last()]/th | ./thead/tr[last()]/td")
    if not header_els:
        header_els = table_el.xpath("./tbody/tr[1]/th | ./tr[1]/th")

    # Collect body rows belonging directly to this table (excluding thead rows and any tr with th)
    body_trs = table_el.xpath("./tbody/tr")
    if not body_trs:
        body_trs = table_el.xpath("./tr")
    data_trs = [tr for tr in body_trs if not tr.xpath("./th")]

    # Fallback when a table has no <thead> and uses <td> in the first row for headers
    if not header_els and data_trs:
        first_tr_tds = data_trs[0].xpath("./td")
        if first_tr_tds:
            first_cell_txt = norm_ws(first_tr_tds[0].text_content())
            if re.match(
                r"^(sl\.?\s*no\.?|s\.?\s*no\.?|sr\.?\s*no\.?|registration\s*/\s*extensions|particulars)$",
                first_cell_txt,
                re.I,
            ):
                header_els = first_tr_tds
                data_trs = data_trs[1:]
            elif len(data_trs) >= 2 and len(first_tr_tds) >= 2 and all(
                not td.xpath(".//table | .//a | .//img")
                and not norm_ws(td.text_content()).endswith(":")
                for td in first_tr_tds
            ):
                # Check if first row cells are all recognized header labels (e.g. Name, Address, Mobile, Email, PAN)
                header_kw_matches = sum(
                    1
                    for td in first_tr_tds
                    if re.search(
                        r"^(name|member\s+name|director\s+name|partner\s+name|signatory\s+name|designation"
                        r"|address|residential\s+address|present\s+address|permanent\s+address|mobile|phone"
                        r"|contact|email|e-mail|pan|aadhaar|aadhar|photo|photograph|share|role|status)$",
                        norm_ws(td.text_content()),
                        re.I,
                    )
                )
                if header_kw_matches >= max(2, len(first_tr_tds) // 2):
                    header_els = first_tr_tds
                    data_trs = data_trs[1:]

    headers = [norm_ws(h.text_content()) for h in header_els]
    headers_low = [h.lower() for h in headers]

    if headers and not current_sec["table_headers"]:
        current_sec["table_headers"] = headers

    # Archetype 1: 4-Column Side-by-Side Document Table
    # e.g., ['Document Name', 'Document', 'Document Name', 'Document'] or ['Declaration', 'Document', 'Declaration', 'Document']
    if (
        len(headers_low) == 4
        and headers_low[1] == "document"
        and headers_low[3] == "document"
    ):
        for tr in data_trs:
            tds = tr.xpath("./td")
            for pair_start in (0, 2):
                if pair_start + 1 >= len(tds):
                    continue
                cat_td = tds[pair_start]
                doc_td = tds[pair_start + 1]
                cat_label, annex_ref = clean_label_and_annex(cat_td)
                if not cat_label:
                    continue
                links = doc_td.xpath(".//a")
                if not links:
                    fn = norm_ws(doc_td.text_content())
                    if scrub_raw_pii:
                        pii_hit = classify_pii_exclusion(
                            cat_label,
                            fn,
                            current_sec["label"],
                            tab_label,
                            is_document=True,
                            promoter_type=pane_ctx.get("promoter_type"),
                        )
                        if pii_hit:
                            _record_excluded_pii(current_sec, cat_label, pii_hit, redaction_action="excluded_document")
                            continue
                    current_sec["documents"].append(
                        {
                            "category": cat_label,
                            "filename": fn or None,
                            "url": None,
                            "doc_id": None,
                            "annexure_reference": annex_ref,
                        }
                    )
                    current_sec["table_rows"].append(
                        {
                            headers[pair_start]: cat_label,
                            "Annexure": annex_ref,
                            "Document": fn,
                            "Source URL": None,
                        }
                    )
                else:
                    for a_el in links:
                        href = a_el.get("href")
                        fn = norm_ws(a_el.text_content())
                        doc_id = extract_doc_id_from_url(href)
                        if scrub_raw_pii:
                            pii_hit = classify_pii_exclusion(
                                cat_label,
                                fn,
                                current_sec["label"],
                                tab_label,
                                is_document=True,
                                promoter_type=pane_ctx.get("promoter_type"),
                            )
                            if pii_hit:
                                _record_excluded_pii(current_sec, cat_label, pii_hit, redaction_action="excluded_document")
                                continue
                        current_sec["documents"].append(
                            {
                                "category": cat_label,
                                "filename": fn or None,
                                "url": href,
                                "doc_id": doc_id,
                                "annexure_reference": annex_ref,
                            }
                        )
                        current_sec["table_rows"].append(
                            {
                                headers[pair_start]: cat_label,
                                "Annexure": annex_ref,
                                "Document": fn,
                                "Source URL": href,
                            }
                        )
        return

    # Archetype 2: 3-Column Enquired Documents Table ['Document Name', 'Uploaded Date', 'Document']
    if (
        len(headers_low) == 3
        and "document name" in headers_low[0]
        and "date" in headers_low[1]
        and "document" in headers_low[2]
    ):
        for tr in data_trs:
            tds = tr.xpath("./td")
            if len(tds) < 3:
                continue
            cat_label, annex_ref = clean_label_and_annex(tds[0])
            up_date = norm_ws(tds[1].text_content())
            links = tds[2].xpath(".//a")
            if not links:
                fn = norm_ws(tds[2].text_content())
                if not cat_label and not fn:
                    continue
                if scrub_raw_pii:
                    pii_hit = classify_pii_exclusion(
                        cat_label or "Enquired Document",
                        fn,
                        current_sec["label"],
                        tab_label,
                        is_document=True,
                        promoter_type=pane_ctx.get("promoter_type"),
                    )
                    if pii_hit:
                        _record_excluded_pii(current_sec, cat_label or "Enquired Document", pii_hit, redaction_action="excluded_document")
                        continue
                current_sec["table_rows"].append(
                    {
                        "Document Name": cat_label,
                        "Uploaded Date": up_date,
                        "Document": fn,
                        "Source URL": None,
                    }
                )
                current_sec["documents"].append(
                    {
                        "category": cat_label or "Enquired Document",
                        "filename": fn or None,
                        "approval_date": up_date or None,
                        "url": None,
                        "doc_id": None,
                        "annexure_reference": annex_ref,
                    }
                )
            else:
                for a_el in links:
                    href = a_el.get("href")
                    fn = norm_ws(a_el.text_content())
                    doc_id = extract_doc_id_from_url(href)
                    if not cat_label and not fn and not doc_id:
                        continue
                    if scrub_raw_pii:
                        pii_hit = classify_pii_exclusion(
                            cat_label or "Enquired Document",
                            fn,
                            current_sec["label"],
                            tab_label,
                            is_document=True,
                            promoter_type=pane_ctx.get("promoter_type"),
                        )
                        if pii_hit:
                            _record_excluded_pii(current_sec, cat_label or "Enquired Document", pii_hit, redaction_action="excluded_document")
                            continue
                    current_sec["table_rows"].append(
                        {
                            "Document Name": cat_label,
                            "Uploaded Date": up_date,
                            "Document": fn,
                            "Source URL": href,
                        }
                    )
                    current_sec["documents"].append(
                        {
                            "category": cat_label or "Enquired Document",
                            "filename": fn or None,
                            "approval_date": up_date or None,
                            "url": href,
                            "doc_id": doc_id,
                            "annexure_reference": annex_ref,
                        }
                    )
        return

    # Archetype 3: Financial Year Matrix Table (headers[0] == 'Financial Year')
    if headers_low and headers_low[0] == "financial year" and len(headers) >= 2:
        for tr in data_trs:
            tds = tr.xpath("./td")
            if not tds:
                continue
            row_cat, annex_ref = clean_label_and_annex(tds[0])
            if not row_cat:
                continue
            row_dict: Dict[str, Any] = {"Financial Year": row_cat}
            if annex_ref:
                row_dict["Annexure"] = annex_ref
            for col_idx in range(1, min(len(tds), len(headers))):
                yr_header = headers[col_idx]
                cell_td = tds[col_idx]
                links = cell_td.xpath(".//a")
                cell_fn = norm_ws(cell_td.text_content())
                doc_cat_lbl = f"{row_cat} [{yr_header}]"
                if scrub_raw_pii:
                    pii_hit = classify_pii_exclusion(
                        doc_cat_lbl,
                        cell_fn,
                        current_sec["label"],
                        tab_label,
                        is_document=bool(links),
                        promoter_type=pane_ctx.get("promoter_type"),
                    )
                    if pii_hit:
                        _record_excluded_pii(
                            current_sec,
                            doc_cat_lbl,
                            pii_hit,
                            redaction_action="excluded_document" if links else "excluded_table_column",
                        )
                        continue
                row_dict[yr_header] = cell_fn
                if links:
                    for a_el in links:
                        href = a_el.get("href")
                        fn = norm_ws(a_el.text_content())
                        doc_id = extract_doc_id_from_url(href)
                        if href or fn:
                            current_sec["documents"].append(
                                {
                                    "category": doc_cat_lbl,
                                    "filename": fn or None,
                                    "url": href,
                                    "doc_id": doc_id,
                                    "annexure_reference": annex_ref,
                                }
                            )
                elif cell_fn:
                    current_sec["documents"].append(
                        {
                            "category": doc_cat_lbl,
                            "filename": cell_fn,
                            "url": None,
                            "doc_id": None,
                            "annexure_reference": annex_ref,
                        }
                    )
            current_sec["table_rows"].append(row_dict)
        return

    # Archetype 4: Headerless 2-Column or 2N-Column Key-Value Table (e.g. Present Address / Permanent Address / Official Address)
    non_nested_trs = [
        tr for tr in data_trs if not any(td.xpath(".//table") for td in tr.xpath("./td"))
    ]
    is_headerless_kv_table = False
    if not headers and non_nested_trs:
        if all(len(tr.xpath("./td")) == 2 for tr in non_nested_trs):
            is_headerless_kv_table = True
        elif all(
            len(tr.xpath("./td")) >= 4
            and len(tr.xpath("./td")) % 2 == 0
            and all(
                norm_ws(tr.xpath("./td")[i].text_content()).endswith(":")
                for i in range(0, len(tr.xpath("./td")), 2)
            )
            for tr in non_nested_trs
        ):
            is_headerless_kv_table = True

    if is_headerless_kv_table:
        for tr in non_nested_trs:
            tds = tr.xpath("./td")
            for pair_idx in range(0, len(tds) - 1, 2):
                lbl_td = tds[pair_idx]
                val_td = tds[pair_idx + 1]
                k_lbl, annex_ref = clean_label_and_annex(lbl_td)
                v_txt = norm_ws(val_td.text_content())
                if not k_lbl:
                    continue
                if k_lbl.lower() in ("promoter type", "type of promoter") and v_txt:
                    pane_ctx["promoter_type"] = v_txt
                if val_td.xpath(".//img"):
                    if scrub_raw_pii:
                        _record_excluded_pii(
                            current_sec,
                            k_lbl,
                            (
                                "personal_photograph",
                                f"Excluded personal photograph <img> in key-value table field '{k_lbl}' of section '{current_sec['label']}'.",
                            ),
                            redaction_action="excluded_image",
                        )
                        continue
                links = val_td.xpath(".//a")
                if scrub_raw_pii:
                    pii_hit = classify_pii_exclusion(
                        k_lbl,
                        v_txt,
                        current_sec["label"],
                        tab_label,
                        is_document=bool(links),
                        promoter_type=pane_ctx.get("promoter_type"),
                    )
                    if pii_hit:
                        _record_excluded_pii(
                            current_sec,
                            k_lbl,
                            pii_hit,
                            redaction_action="excluded_document" if links else "excluded_field",
                        )
                        continue

                current_sec["fields"].append(
                    {
                        "label": k_lbl,
                        "value": v_txt,
                        "annexure_reference": annex_ref,
                    }
                )
                for a_el in links:
                    a_href = a_el.get("href")
                    a_fn = norm_ws(a_el.text_content())
                    a_doc_id = extract_doc_id_from_url(a_href)
                    if _is_downloadable_or_doc_href(a_href, a_fn):
                        if scrub_raw_pii:
                            doc_pii = classify_pii_exclusion(
                                k_lbl,
                                a_fn or v_txt,
                                current_sec["label"],
                                tab_label,
                                is_document=True,
                                promoter_type=pane_ctx.get("promoter_type"),
                            )
                            if doc_pii:
                                _record_excluded_pii(
                                    current_sec,
                                    k_lbl,
                                    doc_pii,
                                    redaction_action="excluded_document",
                                )
                                continue
                        current_sec["documents"].append(
                            {
                                "category": k_lbl,
                                "filename": a_fn or None,
                                "url": a_href,
                                "doc_id": a_doc_id,
                                "annexure_reference": annex_ref,
                            }
                        )
        return

    # Archetype 5: Standard Tabular Data (e.g. Registration/Extensions, Inventory, Complaints, Land Survey, Partner/LandOwner)
    for tr in data_trs:
        tds = tr.xpath("./td")
        if not tds:
            continue
        # Ignore empty single-cell rows
        if len(tds) == 1 and not norm_ws(tds[0].text_content()):
            continue

        row_dict: Dict[str, Any] = {}
        first_col_val = norm_ws(tds[0].text_content()) if not tds[0].xpath(".//table") else ""
        for c_idx, td in enumerate(tds):
            # If this <td> wraps a nested child <table>, skip it here because the child <table> is parsed separately
            if td.xpath(".//table"):
                continue
            col_name = headers[c_idx] if c_idx < len(headers) and headers[c_idx] else f"Column_{c_idx + 1}"
            # Strip embedded <annex> from table header if needed
            col_name_clean = norm_ws(re.sub(r"\(\s*Annexure[^)]*\)", "", col_name, flags=re.I)) or col_name
            cell_txt = norm_ws(td.text_content())
            links = td.xpath(".//a")

            # Check for personal photo <img> in table cell
            if td.xpath(".//img"):
                if scrub_raw_pii:
                    _record_excluded_pii(
                        current_sec,
                        col_name_clean,
                        (
                            "personal_photograph",
                            f"Excluded personal photograph <img> in table column '{col_name_clean}' of section '{current_sec['label']}'.",
                        ),
                        redaction_action="excluded_image",
                    )
                    continue

            if scrub_raw_pii:
                pii_hit = classify_pii_exclusion(
                    col_name_clean,
                    cell_txt,
                    current_sec["label"],
                    tab_label,
                    is_document=bool(links),
                    promoter_type=pane_ctx.get("promoter_type"),
                )
                if pii_hit:
                    _record_excluded_pii(
                        current_sec,
                        col_name_clean,
                        pii_hit,
                        redaction_action="excluded_table_column",
                    )
                    continue

            row_dict[col_name_clean] = cell_txt
            for a_el in links:
                href = a_el.get("href")
                link_txt = norm_ws(a_el.text_content())
                doc_id = extract_doc_id_from_url(href)
                if _is_downloadable_or_doc_href(href, link_txt):
                    doc_cat = (
                        f"{col_name_clean} ({first_col_val})"
                        if first_col_val and c_idx > 0
                        else col_name_clean
                    )
                    if scrub_raw_pii:
                        doc_pii = classify_pii_exclusion(
                            doc_cat,
                            link_txt or cell_txt,
                            current_sec["label"],
                            tab_label,
                            is_document=True,
                            promoter_type=pane_ctx.get("promoter_type"),
                        )
                        if doc_pii:
                            _record_excluded_pii(
                                current_sec,
                                doc_cat,
                                doc_pii,
                                redaction_action="excluded_document",
                            )
                            continue
                    current_sec["documents"].append(
                        {
                            "category": doc_cat,
                            "filename": link_txt or cell_txt or None,
                            "url": href,
                            "doc_id": doc_id,
                        }
                    )

        if any(v not in ("", None) for v in row_dict.values()):
            if scrub_raw_pii:
                doc_row_cat = (
                    row_dict.get("Document Name")
                    or row_dict.get("Declaration")
                    or row_dict.get("Category")
                )
                doc_row_fn = row_dict.get("Document")
                if doc_row_cat:
                    row_pii_hit = classify_pii_exclusion(
                        str(doc_row_cat),
                        str(doc_row_fn or ""),
                        current_sec["label"],
                        tab_label,
                        is_document=True,
                        filename=str(doc_row_fn or ""),
                        promoter_type=pane_ctx.get("promoter_type"),
                    )
                    if row_pii_hit:
                        _record_excluded_pii(
                            current_sec,
                            str(doc_row_cat),
                            row_pii_hit,
                            redaction_action="excluded_table_column",
                        )
                        continue
            current_sec["table_rows"].append(row_dict)
