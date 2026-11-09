"""Audit section 6: raw-to-normalized parity and data-integrity checks (read-only)."""
from __future__ import annotations

import json
import re
import statistics
from collections import Counter, defaultdict
from datetime import date

from audit.common import *  # noqa

WS = re.compile(r"[\s\u00a0]+")


def cz(s):
    return WS.sub(" ", str(s if s is not None else "")).strip()


def indep_date(raw):
    s = cz(raw)
    if not s:
        return None, "empty"
    m = re.fullmatch(r"(\d{1,2})[-/.](\d{1,2})[-/.](\d{4})", s)
    if m:
        d, mo, y = map(int, m.groups())
    else:
        m = re.fullmatch(r"(\d{4})-(\d{2})-(\d{2})", s)
        if not m:
            return None, "unrecognised_format"
        y, mo, d = map(int, m.groups())
    try:
        dt = date(y, mo, d)
    except ValueError:
        return None, "invalid_calendar_date"
    if y < 1990 or y > 2100:
        return None, "implausible_year"
    return dt.isoformat(), "valid"


def norm_numeric(raw):
    s = cz(raw).replace(",", "").replace("₹", "").replace("INR", "").replace("Rs.", "").replace("Rs", "").strip()
    try:
        return float(s)
    except ValueError:
        return None


def raw_tab_has_content(rt):
    for s in rt.get("sections", []):
        if any(cz(f.get("value")) for f in s.get("fields", [])) or s.get("table_rows") or s.get("documents"):
            return True
    return False


def row_sig(row):
    return json.dumps({cz(k): cz(v) for k, v in row.items()}, sort_keys=True, ensure_ascii=False)


def norm_tab_collect(tab_obj):
    fields, rows, docs = Counter(), Counter(), Counter()
    containers = [tab_obj]
    subs = tab_obj.get("sub_tabs") or []
    containers += list(subs.values()) if isinstance(subs, dict) else [x for x in subs if isinstance(x, dict)]
    for c in containers:
        for sec, _ in iter_sections(c.get("sections") or []):
            for f in sec.get("fields") or []:
                fields[(cz(f.get("field_label")), cz(f.get("raw_value")))] += 1
            for r in sec.get("table_rows") or []:
                rows[row_sig(r)] += 1
            for d in sec.get("documents") or []:
                docs[(cz(d.get("document_category")), cz(d.get("displayed_filename")), cz(d.get("source_url")))] += 1
    return fields, rows, docs


def raw_tab_collect(rt):
    fields, rows, docs = Counter(), Counter(), Counter()
    containers = [rt] + [x for x in rt.get("sub_tabs", []) if isinstance(x, dict)]
    for c in containers:
        for s in c.get("sections", []):
            for f in s.get("fields", []):
                fields[(cz(f.get("label")), cz(f.get("value")))] += 1
            for r in s.get("table_rows", []):
                rows[row_sig(r)] += 1
            for d in s.get("documents", []):
                docs[(cz(d.get("category")), cz(d.get("filename")), cz(d.get("url")))] += 1
    return fields, rows, docs


def main():
    projects = manifest_projects()
    agg = Counter()
    examples = defaultdict(list)
    per = []
    conflict_concepts = Counter()
    conflict_kind = Counter()
    conflict_kind_by_concept = defaultdict(Counter)
    projects_with_true_conflict = set()
    projects_with_any_conflict = set()
    pane_label_variants = defaultdict(Counter)
    pane_provenance = Counter()
    pane_prov_by_id = defaultdict(Counter)
    metric_rows = []
    date_stats = Counter()
    numeric_stats = Counter()
    string_norm_diff = Counter()

    def ex(kind, item, cap=8):
        if len(examples[kind]) < cap:
            examples[kind].append(item)

    for p in projects:
        rf, nf = project_files(p)
        raw, norm = jload(rf), jload(nf)
        payload = raw["raw_dom_payload"]
        bi = p["batch_index"]
        row = {"batch_index": bi, "project_name": p["project_name"], "problems": []}

        # --- visible tab parity
        raw_vis = [t["label"] for t in payload["tabs"] if t.get("is_nav_visible")]
        norm_tabs = list((norm.get("tabs") or {}).keys())
        if raw_vis != norm_tabs:
            row["problems"].append("visible_tab_label_order_mismatch")
            agg["projects_visible_tab_mismatch"] += 1
            ex("visible_tab_mismatch", {"batch_index": bi, "raw": raw_vis, "norm": norm_tabs})
        raw_tabs_by_label = {t["label"]: t for t in payload["tabs"]}

        # --- multiset parity per tab
        for label, ntab in (norm.get("tabs") or {}).items():
            rt = raw_tabs_by_label.get(label)
            if rt is None:
                row["problems"].append(f"normalized_tab_without_raw:{label}")
                agg["normalized_tabs_without_raw_tab"] += 1
                continue
            nf_, nr_, nd_ = norm_tab_collect(ntab)
            rf_, rr_, rd_ = raw_tab_collect(rt)
            for kind, a, b in (("fields", rf_, nf_), ("table_rows", rr_, nr_), ("documents", rd_, nd_)):
                agg[f"raw_{kind}_total"] += sum(a.values())
                agg[f"normalized_{kind}_total"] += sum(b.values())
                lost = a - b
                added = b - a
                agg[f"raw_{kind}_not_in_normalized"] += sum(lost.values())
                agg[f"normalized_{kind}_not_in_raw"] += sum(added.values())
                if lost:
                    ex(f"raw_{kind}_not_in_normalized", {"batch_index": bi, "tab": label, "sample": str(list(lost.items())[0])[:240]})
                if added:
                    ex(f"normalized_{kind}_not_in_raw", {"batch_index": bi, "tab": label, "sample": str(list(added.items())[0])[:240]})
            # empty vs content
            has_content = raw_tab_has_content(rt)
            st = ntab.get("observation_state")
            if st == "present_empty" and has_content:
                agg["tabs_normalized_empty_but_raw_has_content"] += 1
                ex("empty_but_raw_content", {"batch_index": bi, "tab": label})
            if st == "present_with_data" and not has_content:
                agg["tabs_normalized_with_data_but_raw_has_no_content"] += 1
                ex("data_but_raw_empty", {"batch_index": bi, "tab": label})
            if ntab.get("error_message"):
                agg["tabs_with_error_message"] += 1
            agg["tabs_total"] += 1

        # --- field-level checks (normalized)
        for container, tab, sec, path in iter_norm_sections(norm):
            for f in sec.get("fields") or []:
                dtp = f.get("data_type")
                rv, nv = f.get("raw_value"), f.get("normalized_value")
                agg["fields_checked"] += 1
                if f.get("observation_state") == "present_with_data" and not cz(rv):
                    agg["fields_present_with_data_but_empty_raw"] += 1
                if f.get("observation_state") in ("present_empty",) and cz(rv):
                    agg["fields_present_empty_but_raw_nonempty"] += 1
                if dtp in ("date_string", "malformed_date") or (isinstance(nv, str) and re.fullmatch(r"\d{4}-\d{2}-\d{2}", nv or "")):
                    iso, why = indep_date(rv)
                    date_stats["date_like_fields"] += 1
                    if why == "valid":
                        if nv == iso:
                            date_stats["valid_and_normalized_correctly"] += 1
                        elif nv in (None, ""):
                            date_stats["valid_but_not_normalized_(under_parse)"] += 1
                        else:
                            date_stats["VALID_BUT_NORMALIZED_TO_DIFFERENT_VALUE"] += 1
                            ex("date_wrong", {"batch_index": bi, "label": f.get("field_label"), "raw": rv, "norm": nv, "indep": iso}, 12)
                    else:
                        if nv in (None, ""):
                            date_stats[f"invalid_not_normalized_correct:{why}"] += 1
                        else:
                            date_stats["INVALID_RAW_BUT_NORMALIZED_NON_NULL(silent_correction)"] += 1
                            ex("date_silent_correction", {"batch_index": bi, "label": f.get("field_label"), "raw": rv, "norm": nv, "why": why}, 12)
                        if why in ("invalid_calendar_date", "implausible_year") and "ANOMALY" not in " ".join(f.get("anomaly_flags") or []) and dtp != "malformed_date":
                            date_stats["invalid_date_without_anomaly_flag_or_malformed_type"] += 1
                            ex("date_invalid_unflagged", {"batch_index": bi, "label": f.get("field_label"), "raw": rv, "type": dtp, "flags": f.get("anomaly_flags")}, 12)
                elif dtp in ("integer", "float"):
                    numeric_stats["numeric_typed_fields"] += 1
                    x = norm_numeric(rv)
                    try:
                        y = float(nv) if nv not in (None, "") else None
                    except (TypeError, ValueError):
                        y = None
                    if x is None or y is None:
                        numeric_stats["numeric_typed_but_unparseable_by_independent_parse_or_null_norm"] += 1
                        ex("numeric_unparseable", {"batch_index": bi, "label": f.get("field_label"), "raw": rv, "norm": nv}, 10)
                    elif abs(x - y) > 1e-9 * max(1.0, abs(x)):
                        numeric_stats["NUMERIC_VALUE_ALTERED"] += 1
                        ex("numeric_altered", {"batch_index": bi, "label": f.get("field_label"), "raw": rv, "norm": nv}, 12)
                    else:
                        numeric_stats["numeric_equal_to_raw"] += 1
                    if str(rv).strip() != "" and cz(rv) != str(rv):
                        numeric_stats["raw_value_contains_unusual_whitespace"] += 1
                elif dtp == "string":
                    if cz(rv) != cz(nv) and not (rv in (None, "") and nv in (None, "")):
                        string_norm_diff["string_fields_normalized_value_differs_from_raw"] += 1
                        ex("string_diff", {"batch_index": bi, "label": f.get("field_label"), "raw": str(rv)[:80], "norm": str(nv)[:80]}, 8)
                # leading-zero or id-like numbers coerced to integer
                if dtp in ("integer", "float") and isinstance(rv, str) and re.fullmatch(r"0\d+", rv.strip()):
                    numeric_stats["leading_zero_value_typed_numeric(risk_of_id_corruption)"] += 1
                    ex("leading_zero_numeric", {"batch_index": bi, "label": f.get("field_label"), "raw": rv, "norm": nv}, 10)
            for d in sec.get("documents") or []:
                agg["documents_checked"] += 1
                if d.get("approval_date_raw"):
                    iso, why = indep_date(d["approval_date_raw"])
                    date_stats["document_approval_dates"] += 1
                    nvd = d.get("approval_date_normalized")
                    if why == "valid" and nvd == iso:
                        date_stats["doc_dates_valid_and_correct"] += 1
                    elif why != "valid" and not nvd:
                        date_stats["doc_dates_invalid_left_null"] += 1
                    elif why != "valid" and nvd:
                        date_stats["DOC_DATE_INVALID_BUT_NORMALIZED(silent_correction)"] += 1
                        ex("doc_date_silent_correction", {"batch_index": bi, "raw": d["approval_date_raw"], "norm": nvd, "why": why}, 10)
                    elif why == "valid" and nvd != iso:
                        date_stats["DOC_DATE_VALID_BUT_WRONG_NORMALIZATION"] += 1
                        ex("doc_date_wrong", {"batch_index": bi, "raw": d["approval_date_raw"], "norm": nvd, "indep": iso}, 10)
                cat, fn = cz(d.get("document_category")), cz(d.get("displayed_filename"))
                if not cat:
                    agg["documents_without_category"] += 1
                if cat and fn and cat == fn:
                    agg["documents_where_category_equals_filename"] += 1
                if not fn and has_real_link(d):
                    agg["documents_link_without_displayed_filename"] += 1

        # --- table rows leading-zero etc. skipped; duplicated table rows
        dup_rows = 0
        max_rows = 0
        for container, tab, sec, path in iter_norm_sections(norm, "tabs"):
            rws = [row_sig(r) for r in sec.get("table_rows") or []]
            max_rows = max(max_rows, len(rws))
            dup_rows += sum(v - 1 for v in Counter(rws).values() if v > 1)
        agg["duplicate_table_rows_total"] += dup_rows

        # --- conflicts
        cat_info = norm.get("catalogue_source_info") or {}
        field_index = defaultdict(set)
        for container, tab, sec, path in iter_norm_sections(norm):
            for f in sec.get("fields") or []:
                field_index[(cz(f.get("field_label")), cz(f.get("raw_value")))].add(tab)
        for c in norm.get("cross_section_conflicts") or []:
            projects_with_any_conflict.add(bi)
            conflict_concepts[c.get("canonical_concept")] += 1
            obs = c.get("observations") or []
            nvals = {cz(o.get("normalized_value")) for o in obs if cz(o.get("normalized_value"))}
            rvals = {cz(o.get("raw_value")) for o in obs}
            kind = "value_conflict" if len(nvals) > 1 else ("format_only_difference" if len(rvals) > 1 else "no_difference")
            conflict_kind[kind] += 1
            conflict_kind_by_concept[c.get("canonical_concept")][kind] += 1
            if kind == "value_conflict":
                projects_with_true_conflict.add(bi)
            for o in obs:
                if o.get("tab_label") == "Search Results Catalogue":
                    ok = any(cz(v) == cz(o.get("raw_value")) for v in cat_info.values())
                else:
                    ok = (cz(o.get("field_label")), cz(o.get("raw_value"))) in field_index
                if not ok:
                    agg["conflict_observations_not_traceable_to_stored_fields"] += 1
                    ex("conflict_untraceable", {"batch_index": bi, "obs": {k: o.get(k) for k in ("tab_label", "field_label", "raw_value")}}, 8)
                agg["conflict_observations_total"] += 1

        # --- unlinked pane label provenance
        commented = payload.get("commented_out_nav_tabs") or {}
        raw_panes = {x["id"]: x for x in payload.get("unlinked_dom_panes", [])}
        for pid, pane in (norm.get("unlinked_dom_panes") or {}).items():
            label = pane.get("tab_label")
            rp = raw_panes.get(pid) or raw_panes.get(pid.lstrip("#"))
            pane_label_variants[pid][label] += 1
            if rp is None:
                pane_provenance["normalized_pane_without_raw_pane"] += 1
                continue
            if cz(rp.get("label")) != cz(label):
                pane_provenance["LABEL_DIFFERS_BETWEEN_RAW_AND_NORMALIZED"] += 1
            cl = cz(commented.get(pid.lstrip("#")) or commented.get(pid))
            first_sec = cz((rp.get("sections") or [{}])[0].get("label")) if rp.get("sections") else ""
            if cl and cl == cz(label):
                src = "explicit_dom_comment (raw.commented_out_nav_tabs)"
            elif str(label).startswith("Unlinked Pane ("):
                src = "generic_fallback"
            elif first_sec and first_sec == cz(label):
                src = "matches_first_section_label_(heading_inside_pane_not_separately_persisted)"
            else:
                src = "provenance_not_determinable_from_persisted_evidence"
            pane_provenance[src] += 1
            pane_prov_by_id[pid][src] += 1
            # content preserved?
            if (rp.get("sections")) and not pane.get("sections"):
                pane_provenance["raw_pane_sections_missing_in_normalized"] += 1

        # --- metrics for outlier analysis
        cov = norm["coverage"]
        metric_rows.append({
            "batch_index": bi, "project_name": p["project_name"], "page_band": p["page_band"], "project_type": p["project_type"],
            "tabs": cov["total_tabs_discovered"], "sections": cov["total_sections_discovered"], "fields": cov["total_fields_discovered"],
            "table_rows": cov["total_table_rows_discovered"], "documents": cov["total_documents_discovered"],
            "pii_exclusions": len(norm.get("pii_exclusions") or []), "conflicts": len(norm.get("cross_section_conflicts") or []),
            "unlinked_panes": len(norm.get("unlinked_dom_panes") or {}), "max_rows_in_one_table": max_rows, "duplicate_table_rows": dup_rows,
            "raw_kb": round(rf.stat().st_size / 1024, 1), "normalized_kb": round(nf.stat().st_size / 1024, 1),
        })
        row["problems_count"] = len(row["problems"])
        per.append(row)

    # --- outliers (robust z-score, MAD)
    outliers = []
    for m in ("sections", "fields", "table_rows", "documents", "pii_exclusions", "raw_kb", "max_rows_in_one_table", "duplicate_table_rows"):
        vals = [r[m] for r in metric_rows]
        med = statistics.median(vals)
        mad = statistics.median(abs(v - med) for v in vals) or 1.0
        for r in metric_rows:
            z = 0.6745 * (r[m] - med) / mad
            if z > 6:
                outliers.append({"metric": m, "batch_index": r["batch_index"], "project_name": r["project_name"], "value": r[m],
                                 "median": med, "robust_z": round(z, 1)})
    outliers.sort(key=lambda x: -x["robust_z"])
    outlier_projects = sorted({o["batch_index"] for o in outliers})

    # --- deep dive on the top outliers by documents
    deep = []
    for r in sorted(metric_rows, key=lambda r: -r["documents"])[:3]:
        p = next(x for x in projects if x["batch_index"] == r["batch_index"])
        _, nf = project_files(p)
        n = jload(nf)
        cats = Counter()
        idents = Counter()
        by_tab = Counter()
        states = Counter()
        for container, tab, sec, path in iter_norm_sections(n, "tabs"):
            for d in sec.get("documents") or []:
                cats[cz(d.get("document_category"))] += 1
                idents[(d.get("document_identifier") or d.get("source_url") or "")] += 1
                by_tab[(tab, sec.get("section_label"))] += 1
                states[d.get("observation_state")] += 1
        deep.append({"batch_index": r["batch_index"], "project_name": r["project_name"], "documents": r["documents"],
                     "distinct_identifiers": len(idents), "identifier_duplicates": sum(v - 1 for v in idents.values() if v > 1),
                     "top_categories": cats.most_common(6), "top_sections": [(f"{a}>{b}", c) for (a, b), c in by_tab.most_common(4)], "states": dict(states)})

    # robust distribution summary
    def dist(m):
        vals = sorted(r[m] for r in metric_rows)
        return {"min": vals[0], "p25": vals[len(vals) // 4], "median": vals[len(vals) // 2], "p75": vals[3 * len(vals) // 4], "max": vals[-1]}

    out = {
        "generated_at_utc": now_iso(),
        "parity_aggregate": {k: v for k, v in agg.items()},
        "date_normalization_audit": dict(date_stats),
        "numeric_normalization_audit": dict(numeric_stats),
        "string_normalization_audit": dict(string_norm_diff),
        "cross_section_conflict_audit": {
            "conflicts_total": sum(conflict_kind.values()), "projects_with_any_conflict": len(projects_with_any_conflict),
            "projects_with_semantic_value_conflict": len(projects_with_true_conflict),
            "classification": dict(conflict_kind),
            "by_concept": {k: dict(v) for k, v in conflict_kind_by_concept.items()},
            "interpretation": "format_only_difference = the raw strings differ (e.g. 31/12/2018 vs 31-12-2018) but all normalized values are identical; these are not semantic conflicts.",
        },
        "unlinked_pane_label_provenance": {
            "provenance_counts": dict(pane_provenance), "by_pane_id": {k: dict(v) for k, v in pane_prov_by_id.items()},
            "label_variants_per_pane_id": {k: dict(v) for k, v in pane_label_variants.items()},
            "hardcoded_mapping_check": "UNLINKED_PANE_LABELS is {} in scripts/detail_dom_parser.py (verified by source inspection in this audit).",
        },
        "failure_vs_empty_audit": {
            "tabs_with_error_message": agg["tabs_with_error_message"], "tab_observation_states_all_projects": None,
            "tabs_normalized_empty_but_raw_has_content": agg["tabs_normalized_empty_but_raw_has_content"],
            "tabs_normalized_with_data_but_raw_has_no_content": agg["tabs_normalized_with_data_but_raw_has_no_content"],
        },
        "structural_outliers": {"method": "robust z-score (0.6745*(x-median)/MAD) > 6 on per-project counts", "outliers": outliers[:60],
                                  "outlier_project_indexes": outlier_projects, "distributions": {m: dist(m) for m in ("tabs", "sections", "fields", "table_rows", "documents", "pii_exclusions", "raw_kb")},
                                  "deep_dive_top_documents_projects": deep},
        "examples_by_finding": dict(examples),
        "per_project_metrics": metric_rows,
        "per_project_problem_flags": [r for r in per if r["problems"]],
    }
    return out


if __name__ == "__main__":
    o = main()
    for k in ("parity_aggregate", "date_normalization_audit", "numeric_normalization_audit", "string_normalization_audit", "cross_section_conflict_audit",
              "unlinked_pane_label_provenance", "failure_vs_empty_audit"):
        print(k, json.dumps(o[k], indent=1)[:3500])
    print(json.dumps(o["structural_outliers"]["outliers"][:12], indent=0))
    print(json.dumps(o["structural_outliers"]["deep_dive_top_documents_projects"], indent=0)[:2500])
    print(json.dumps({k: v[:3] for k, v in o["examples_by_finding"].items()}, indent=0)[:5000])
