"""Audit section 4: how the 2,261 live-DOM comparisons were selected and what they cover (read-only)."""
from __future__ import annotations

import re
from collections import Counter, defaultdict

from audit.common import *  # noqa

SAMPLER_EXCLUDE = re.compile(r"pan|aadhaar|address|photo|mobile|email|phone", re.I)   # copied from capture_live_manual_comparison_snapshot JS
WS = re.compile(r"[\s\u00a0\u200b]+")


def collapse(s):
    return WS.sub(" ", str(s or "")).strip()


def classify_pair(live, ext):
    live, ext = str(live or ""), str(ext or "")
    if live == ext:
        return "exact_equal"
    if collapse(live) == collapse(ext):
        return "whitespace_only_difference"
    if re.sub(r"\s+", "", live) == re.sub(r"\s+", "", ext):
        return "whitespace_only_difference_incl_unicode_spaces"
    cl, ce = collapse(live), collapse(ext)
    if cl and ce and (cl in ce or ce in cl):
        return "containment_only_not_equal"
    return "different"


def main():
    comps = jload(P3C / "phase3c_live_dom_comparisons.json")
    comp_by_idx = {c["batch_index"]: c for c in comps}
    projects = manifest_projects()
    per_project = []
    totals = Counter()
    by_tab_compared = Counter()
    by_section_type_extracted = Counter()
    by_section_type_compared = Counter()
    pair_classes = Counter()
    ws_detail = Counter()
    containment_examples, different_examples = [], []
    pred_hits = pred_total = 0
    label_regex_excluded_company = Counter()

    for p in projects:
        _, nf = project_files(p)
        n = jload(nf)
        cov = n["coverage"]
        # field inventory (tabs scope and unlinked scope), first-seen label lookup like the production comparer
        fields_tabs = fields_unl = 0
        first_label = {}
        eligible_labels_in_order = []
        seen_labels = set()
        non_empty_tabs = 0
        sampler_blocked = 0
        kv_fields = 0
        for container, tab, sec, path in iter_norm_sections(n):
            stype = sec.get("section_type")
            for f in sec.get("fields") or []:
                if container == "tab":
                    fields_tabs += 1
                    by_section_type_extracted[stype] += 1
                    if (f.get("raw_value") or "") != "":
                        non_empty_tabs += 1
                    lbl = f.get("field_label")
                    if lbl not in first_label and f.get("raw_value") is not None:
                        first_label[lbl] = (tab, stype)
                    if stype == "key_value":
                        kv_fields += 1
                        if (f.get("raw_value") or "").strip():
                            if SAMPLER_EXCLUDE.search(lbl or ""):
                                sampler_blocked += 1
                                if re.search(r"company", lbl or "", re.I) and not re.search(r"address|photo|mobile|email|phone|aadhaar", lbl or "", re.I):
                                    label_regex_excluded_company[lbl] += 1
                            elif lbl not in seen_labels:
                                seen_labels.add(lbl)
                                eligible_labels_in_order.append(lbl)
                else:
                    fields_unl += 1
        c = comp_by_idx.get(p["batch_index"])
        samples = c["retained_field_samples"] if c else []
        compared = len(samples)
        predicted = set(eligible_labels_in_order[:10])
        for s in samples:
            pred_total += 1
            if s["label"] in predicted:
                pred_hits += 1
            tab, stype = first_label.get(s["label"], ("<not found>", None))
            by_tab_compared[tab] += 1
            by_section_type_compared[stype] += 1
            cls = classify_pair(s["live_portal_value"], s["extracted_value"])
            pair_classes[cls] += 1
            if cls == "containment_only_not_equal" and len(containment_examples) < 12:
                containment_examples.append({"batch_index": p["batch_index"], "label": s["label"], "live_len": len(s["live_portal_value"]),
                                             "extracted_len": len(s["extracted_value"]), "stored_matches_flag": s.get("matches")})
            if cls == "different" and len(different_examples) < 12:
                different_examples.append({"batch_index": p["batch_index"], "label": s["label"]})
            if cls in ("whitespace_only_difference", "whitespace_only_difference_incl_unicode_spaces"):
                lv, ev = s["live_portal_value"], s["extracted_value"]
                ws_detail["live_contains_newline"] += int("\n" in lv)
                ws_detail["live_has_consecutive_spaces_or_tabs"] += int(bool(re.search(r"[ \t]{2,}", lv)))
                ws_detail["live_has_leading_or_trailing_ws"] += int(lv != lv.strip())
                ws_detail["non_whitespace_characters_identical"] += int(re.sub(r"\s+", "", lv) == re.sub(r"\s+", "", ev))
        totals["extracted_fields_tabs_scope"] += fields_tabs
        totals["extracted_fields_unlinked_panes"] += fields_unl
        totals["extracted_fields_non_empty_raw_value_tabs"] += non_empty_tabs
        totals["extracted_key_value_section_fields"] += kv_fields
        totals["blocked_by_sampler_label_regex"] += sampler_blocked
        totals["eligible_distinct_labels_after_sampler_filter"] += len(eligible_labels_in_order)
        totals["compared"] += compared
        totals["stored_total_fields_discovered"] += cov["total_fields_discovered"]
        per_project.append({
            "batch_index": p["batch_index"], "project_name": p["project_name"], "page_band": p["page_band"],
            "fields_extracted_tabs_scope": fields_tabs, "stored_total_fields_discovered": cov["total_fields_discovered"],
            "fields_in_unlinked_panes_not_in_stored_total": fields_unl,
            "kv_fields_with_value": kv_fields, "eligible_distinct_labels_after_sampler_filter": len(eligible_labels_in_order),
            "fields_compared": compared, "coverage_of_extracted_fields_pct": round(100.0 * compared / fields_tabs, 2) if fields_tabs else None,
            "coverage_of_eligible_labels_pct": round(100.0 * compared / len(eligible_labels_in_order), 2) if eligible_labels_in_order else None,
            "comparison_present": c is not None,
        })
    zero = [x["batch_index"] for x in per_project if x["fields_compared"] == 0]
    covs = sorted(x["coverage_of_extracted_fields_pct"] for x in per_project if x["coverage_of_extracted_fields_pct"] is not None)
    counts = sorted(x["fields_compared"] for x in per_project)
    stored_ws_flag_true = sum(1 for c in comps for s in c["retained_field_samples"] if s.get("matches"))
    out = {
        "generated_at_utc": now_iso(),
        "headline": {
            "fields_extracted_stored_total": totals["stored_total_fields_discovered"],
            "fields_extracted_recomputed_tabs_scope": totals["extracted_fields_tabs_scope"],
            "fields_in_unlinked_panes_not_in_stored_total": totals["extracted_fields_unlinked_panes"],
            "fields_compared": totals["compared"],
            "comparison_coverage_pct_of_extracted": round(100.0 * totals["compared"] / totals["stored_total_fields_discovered"], 2),
            "exhaustive_validation": False,
            "statement": "The 2,261 comparisons are a bounded sample (max 10 live key/value pairs per project), NOT exhaustive validation of the extracted fields.",
        },
        "selection_mechanism": {
            "source": "scripts/phase3a_batch_extractor.py::capture_live_manual_comparison_snapshot + scripts/phase3c_batch_extractor.py::build_automated_live_dom_comparison_entry",
            "steps": [
                "In the live modal, iterate every '.row' under '#result' in DOM order and read child-div pairs (label, value).",
                "Skip pairs whose label matches /pan|aadhaar|address|photo|mobile|email|phone/i (substring match, no word boundary).",
                "Keep only the first occurrence of each label and stop collecting after 10 distinct labels (cap).",
                "At comparison time keep only labels that also exist (exact string match) among extracted field labels (first occurrence).",
                "Only the matched pairs are persisted as retained_field_samples; the unmatched live keys are NOT persisted.",
            ],
            "consequences": [
                "Fields from tables, document links, unlinked panes, and sections later in the modal are structurally unlikely to be sampled.",
                "Labels containing the substring 'pan' (e.g. 'Company ...'), 'photo', 'address' etc. are never sampled even when corporate.",
                "Live labels that fail exact-string equality with the extracted label are silently dropped (not counted as mismatches or misses).",
            ],
            "simulation_check": {"compared_labels": pred_total, "labels_predicted_by_rule_replay": pred_hits,
                                  "replay_agreement_pct": round(100.0 * pred_hits / pred_total, 2) if pred_total else None},
        },
        "eligibility_funnel_aggregate": {
            "extracted_fields_tabs_scope": totals["extracted_fields_tabs_scope"],
            "of_which_non_empty_raw_value": totals["extracted_fields_non_empty_raw_value_tabs"],
            "of_which_in_key_value_sections": totals["extracted_key_value_section_fields"],
            "key_value_fields_blocked_by_sampler_label_regex": totals["blocked_by_sampler_label_regex"],
            "distinct_eligible_labels_after_sampler_filter_per_project_sum": totals["eligible_distinct_labels_after_sampler_filter"],
            "excluded_by_10_label_cap_approx": totals["eligible_distinct_labels_after_sampler_filter"] - min(totals["eligible_distinct_labels_after_sampler_filter"], 10 * 250),
            "actually_compared": totals["compared"],
            "company_labelled_fields_blocked_only_because_company_contains_'pan'": dict(label_regex_excluded_company.most_common(10)),
        },
        "extracted_fields_by_section_type": dict(by_section_type_extracted),
        "compared_fields_by_section_type": dict(by_section_type_compared),
        "compared_fields_by_tab_category": dict(by_tab_compared.most_common()),
        "per_project_distribution": {
            "projects_with_zero_compared_fields": zero, "count_projects_with_zero_compared_fields": len(zero),
            "projects_with_comparison_record": sum(1 for x in per_project if x["comparison_present"]),
            "compared_fields_per_project_min_median_max": [counts[0], counts[len(counts) // 2], counts[-1]],
            "coverage_pct_of_extracted_per_project_min_median_max": [covs[0], covs[len(covs) // 2], covs[-1]],
        },
        "value_equality_audit": {
            "pair_classification_counts": dict(pair_classes),
            "persisted_matches_flag_true_count": stored_ws_flag_true,
            "strict_exact_mismatch_count_if_no_normalization": sum(v for k, v in pair_classes.items() if k != "exact_equal"),
            "whitespace_only_detail": dict(ws_detail),
            "containment_only_examples": containment_examples,
            "different_examples": different_examples,
            "verdict": None,
        },
        "evidence_integrity_note": (
            "phase3c_live_dom_comparisons.json and reports/phase3c_manual_comparisons.json were regenerated in place during the final "
            "report step with whitespace-tolerant matching; the original per-sample 'matches=false' flags and mismatched_field_details were "
            "overwritten. The underlying live/extracted value pairs were retained, so this audit recomputes strict equality from them."),
        "per_project": per_project,
    }
    v = out["value_equality_audit"]
    pc = v["pair_classification_counts"]
    v["verdict"] = ("whitespace normalization hides only whitespace-formatting differences (non-whitespace characters identical)"
                    if pc.get("different", 0) == 0 and pc.get("containment_only_not_equal", 0) == 0
                    else "WARNING: containment/different pairs exist beyond whitespace")
    return out


if __name__ == "__main__":
    o = main()
    print(json.dumps({k: o[k] for k in ("headline", "selection_mechanism", "eligibility_funnel_aggregate", "compared_fields_by_tab_category", "per_project_distribution", "value_equality_audit")}, indent=1)[:9000])
