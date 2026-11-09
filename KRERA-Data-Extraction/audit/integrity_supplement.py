"""Audit section 6 (supplement): explain raw-only items, re-apply the PII classifier to persisted outputs,
and investigate outliers. Read-only."""
from __future__ import annotations

import re
from collections import Counter, defaultdict

from audit.common import *  # noqa
from audit.integrity_audit import cz, raw_tab_collect, norm_tab_collect, row_sig
from scripts.discovery_engine import classify_pii_exclusion


def mask(s, n=60):
    s = cz(s)
    s = re.sub(r"[A-Za-z]{5}\d{4}[A-Za-z]", "<PAN?>", s)
    return s[:n]


def main():
    projects = manifest_projects()
    lost_field_reason = Counter()
    lost_doc_reason = Counter()
    lost_row_reason = Counter()
    lost_examples = defaultdict(list)
    resid_raw = Counter()
    resid_norm = Counter()
    resid_examples = defaultdict(list)
    cat_column_docs = 0
    cat_column_docs_projects = set()
    inconsistent_fields = Counter()
    conflict_untraceable_after_table_rows = 0
    conflict_obs_total = 0
    dup_row_samples = []
    big_tables = []
    state_without_value = []

    for p in projects:
        rf, nf = project_files(p)
        raw, norm = jload(rf), jload(nf)
        payload = raw["raw_dom_payload"]
        bi = p["batch_index"]
        raw_tabs = {t["label"]: t for t in payload["tabs"]}
        for label, ntab in (norm.get("tabs") or {}).items():
            rt = raw_tabs[label]
            nf_, nr_, nd_ = norm_tab_collect(ntab)
            rf_, rr_, rd_ = raw_tab_collect(rt)
            for (lbl, val), cnt in (rf_ - nf_).items():
                sec_guess = label
                r = classify_pii_exclusion(lbl, val, label, label)
                if not val:
                    why = "empty_value_field_dropped"
                elif r:
                    why = f"policy_exclusion_applied_at_normalization:{r[0]}"
                else:
                    why = "unexplained"
                lost_field_reason[why] += cnt
                if len(lost_examples[f"field:{why}"]) < 4:
                    lost_examples[f"field:{why}"].append({"batch_index": bi, "tab": label, "label": mask(lbl), "value": mask(val, 40)})
            for (cat, fn, url), cnt in (rd_ - nd_).items():
                r = classify_pii_exclusion(cat, fn, label, label, is_document=True, filename=fn)
                if url.endswith("DOC_ID=") or (not url and not fn):
                    why = "empty_link_placeholder_document_dropped"
                elif r:
                    why = f"policy_exclusion_applied_at_normalization:{r[0]}"
                else:
                    why = "unexplained"
                lost_doc_reason[why] += cnt
                if len(lost_examples[f"doc:{why}"]) < 4:
                    lost_examples[f"doc:{why}"].append({"batch_index": bi, "tab": label, "category": mask(cat), "filename": mask(fn, 40), "url_tail": url[-24:]})
            for sig, cnt in (rr_ - nr_).items():
                row = json.loads(sig)
                hit = None
                for k, v in row.items():
                    r = classify_pii_exclusion(k, v, label, label, is_document=True, filename=v)
                    if r:
                        hit = r[0]
                        break
                why = f"identity_document_name_in_row_{hit}" if hit else "unexplained"
                lost_row_reason[why] += cnt
                if len(lost_examples[f"row:{why}"]) < 4:
                    lost_examples[f"row:{why}"].append({"batch_index": bi, "tab": label, "row": mask(sig, 120)})
            # residual: apply classifier to what is persisted in RAW (visible tabs) and NORMALIZED
            for source, tabobj_raw in (("raw", rt),):
                for s in tabobj_raw.get("sections", []):
                    sl = s.get("label", "")
                    for f in s.get("fields", []):
                        r = classify_pii_exclusion(f.get("label", ""), f.get("value", ""), sl, label)
                        if r:
                            resid_raw[("field", r[0])] += 1
                            if len(resid_examples["raw_field"]) < 6:
                                resid_examples["raw_field"].append({"batch_index": bi, "tab": label, "section": sl, "label": mask(f.get("label")), "cat": r[0]})
                    for d in s.get("documents", []):
                        r = classify_pii_exclusion(d.get("category", ""), d.get("filename", ""), sl, label, is_document=True, filename=d.get("filename"))
                        if r:
                            resid_raw[("document", r[0])] += 1
                            if len(resid_examples["raw_document"]) < 6:
                                resid_examples["raw_document"].append({"batch_index": bi, "tab": label, "section": sl, "category": mask(d.get("category")), "filename": mask(d.get("filename")), "cat": r[0]})
                    for row in s.get("table_rows", []):
                        for k, v in row.items():
                            r = classify_pii_exclusion(k, v, sl, label, is_document=True, filename=v)
                            if r:
                                resid_raw[("table_cell", r[0])] += 1
                                if len(resid_examples["raw_table_cell"]) < 8:
                                    resid_examples["raw_table_cell"].append({"batch_index": bi, "tab": label, "section": sl, "col": mask(k), "value": mask(v, 50), "cat": r[0]})
            for sec, _ in ((s, None) for s in []):
                pass
        for container, tab, sec, path in iter_norm_sections(norm):
            sl = sec.get("section_label", "")
            for f in sec.get("fields") or []:
                r = classify_pii_exclusion(f.get("field_label", ""), f.get("raw_value", ""), sl, tab.split("|")[-1])
                if r:
                    resid_norm[("field", r[0])] += 1
                    if len(resid_examples["norm_field"]) < 6:
                        resid_examples["norm_field"].append({"batch_index": bi, "tab": tab, "label": mask(f.get("field_label")), "cat": r[0]})
                if f.get("observation_state") == "present_with_data" and not cz(f.get("raw_value")):
                    inconsistent_fields[f.get("field_label")] += 1
            for d in sec.get("documents") or []:
                r = classify_pii_exclusion(d.get("document_category", ""), d.get("displayed_filename", ""), sl, tab, is_document=True, filename=d.get("displayed_filename"))
                if r:
                    resid_norm[("document", r[0])] += 1
                    if len(resid_examples["norm_document"]) < 6:
                        resid_examples["norm_document"].append({"batch_index": bi, "tab": tab, "category": mask(d.get("document_category")), "filename": mask(d.get("displayed_filename")), "cat": r[0]})
                if re.match(r"^Column_\d+", cz(d.get("document_category"))):
                    cat_column_docs += 1
                    cat_column_docs_projects.add(bi)
            for row in sec.get("table_rows") or []:
                for k, v in row.items():
                    r = classify_pii_exclusion(k, v, sl, tab, is_document=True, filename=v)
                    if r:
                        resid_norm[("table_cell", r[0])] += 1
                        if len(resid_examples["norm_table_cell"]) < 8:
                            resid_examples["norm_table_cell"].append({"batch_index": bi, "tab": tab, "section": sl, "col": mask(k), "value": mask(v, 50), "cat": r[0]})
        # conflict traceability including table rows
        idx = set()
        for container, tab, sec, path in iter_norm_sections(norm):
            for f in sec.get("fields") or []:
                idx.add((cz(f.get("field_label")), cz(f.get("raw_value"))))
            for row in sec.get("table_rows") or []:
                for k, v in row.items():
                    idx.add((cz(k), cz(v)))
        cat_vals = {cz(v) for v in (norm.get("catalogue_source_info") or {}).values()}
        for c in norm.get("cross_section_conflicts") or []:
            for o in c.get("observations") or []:
                conflict_obs_total += 1
                if o.get("tab_label") == "Search Results Catalogue":
                    ok = cz(o.get("raw_value")) in cat_vals
                else:
                    ok = (cz(o.get("field_label")), cz(o.get("raw_value"))) in idx
                if not ok:
                    conflict_untraceable_after_table_rows += 1
                    if len(lost_examples["conflict_untraceable"]) < 6:
                        lost_examples["conflict_untraceable"].append({"batch_index": bi, "obs": {k: o.get(k) for k in ("tab_label", "section_label", "field_label", "raw_value")}})
        # duplicate rows investigation + biggest tables
        for container, tab, sec, path in iter_norm_sections(norm, "tabs"):
            rows = [row_sig(r) for r in sec.get("table_rows") or []]
            if len(rows) > 400:
                big_tables.append({"batch_index": bi, "tab": tab, "section": sec.get("section_label"), "rows": len(rows),
                                   "distinct_rows": len(set(rows)), "headers_count": len(sec.get("table_headers") or [])})
            c = Counter(rows)
            dups = sum(v - 1 for v in c.values() if v > 1)
            if dups >= 90 and len(dup_row_samples) < 4:
                sig, cnt = c.most_common(1)[0]
                dup_row_samples.append({"batch_index": bi, "tab": tab, "section": sec.get("section_label"), "dup_rows": dups,
                                        "top_repeated_row_masked": mask(sig, 160), "times_repeated": cnt, "table_headers": (sec.get("table_headers") or [])[:8]})

    out = {
        "generated_at_utc": now_iso(),
        "raw_items_absent_from_normalized": {
            "fields": dict(lost_field_reason), "documents": dict(lost_doc_reason), "table_rows": dict(lost_row_reason),
            "examples_masked": dict(lost_examples),
        },
        "classifier_reapplied_to_persisted_outputs": {
            "meaning": "Items that the production PII classifier would still exclude if applied to what is stored in the file (should be 0 for a clean output).",
            "raw_files": {f"{k[0]}:{k[1]}": v for k, v in resid_raw.items()},
            "normalized_files": {f"{k[0]}:{k[1]}": v for k, v in resid_norm.items()},
            "examples_masked": {k: v for k, v in resid_examples.items()},
        },
        "document_category_quirks": {"documents_with_category_like_Column_N": cat_column_docs, "projects_affected": len(cat_column_docs_projects)},
        "fields_present_with_data_but_empty_raw_by_label": dict(inconsistent_fields.most_common(12)),
        "conflict_observation_traceability_including_table_cells": {"observations": conflict_obs_total, "untraceable": conflict_untraceable_after_table_rows},
        "very_large_tables_over_400_rows": big_tables, "duplicate_row_deep_dive_masked": dup_row_samples,
    }
    return out


if __name__ == "__main__":
    o = main()
    print(json.dumps(o, indent=1)[:12000])
