"""Audit section 1: independent document accounting reconciliation (read-only)."""
from __future__ import annotations

from collections import Counter, defaultdict

from audit.common import *  # noqa

UNAVAIL_STATES = {"not_available", "not_applicable"}
PLACEHOLDER_FLAG = "ANOMALY_PLACEHOLDER_FILENAME_NOT_APPLICABLE_OR_AVAILABLE"


def audit_project(proj, norm):
    cov = norm.get("coverage", {})
    docs_tabs, docs_unl = [], []
    for container, tab, sec, path in iter_norm_sections(norm):
        for d in sec.get("documents") or []:
            (docs_tabs if container == "tab" else docs_unl).append((tab, path, d))

    def classify(docs):
        c = Counter()
        keys = Counter()
        ident_loc = defaultdict(set)
        for tab, path, d in docs:
            st = d.get("observation_state")
            c["records"] += 1
            c[f"state:{st}"] += 1
            link = has_real_link(d)
            fn = (d.get("displayed_filename") or "").strip()
            ph = PLACEHOLDER_FLAG in (d.get("anomaly_flags") or [])
            if ph:
                c["placeholder_flag_total"] += 1
            if st in UNAVAIL_STATES:
                bucket = "unavailable_by_state"
            elif link or fn:
                bucket = "observed_with_link_or_filename"
                if link:
                    c["document_links"] += 1
                else:
                    c["filename_only_no_link"] += 1
                ukey = ((d.get("document_category") or "").strip().lower(),
                        (d.get("document_identifier") or d.get("source_url") or "").strip(), fn.lower())
                keys[ukey] += 1
                ident = (d.get("document_identifier") or d.get("source_url") or "").strip()
                if ident:
                    ident_loc[ident].add((tab, path))
            else:
                bucket = "unavailable_no_link_no_filename"
            c[bucket] += 1
            if ph:
                c[f"placeholder_in:{bucket}"] += 1
            if d.get("anomaly_flags"):
                for f in d["anomaly_flags"]:
                    c[f"flag:{f}"] += 1
            if "error" in str(st).lower() or "failed" in str(st).lower():
                c["failed_document_observations"] += 1
            if any("DATE_PARSE_FAILED" in f for f in d.get("anomaly_flags") or []):
                c["date_parse_failed_flag_on_document"] += 1
        c["unique_observation_keys"] = len(keys)
        c["duplicate_observations_same_key"] = sum(v - 1 for v in keys.values())
        c["identifiers_reused_across_distinct_locations"] = sum(1 for v in ident_loc.values() if len(v) > 1)
        return c

    ct, cu = classify(docs_tabs), classify(docs_unl)
    ids_tabs = {(d.get("document_identifier") or d.get("source_url") or "").strip() for _, _, d in docs_tabs if has_real_link(d)}
    ids_unl = {(d.get("document_identifier") or d.get("source_url") or "").strip() for _, _, d in docs_unl if has_real_link(d)}
    cu["unlinked_linked_ids_total"] = len(ids_unl)
    cu["unlinked_linked_ids_also_in_tabs"] = len(ids_unl & ids_tabs)
    cu["unlinked_linked_ids_only_in_unlinked_panes"] = len(ids_unl - ids_tabs)
    stored = {k: cov.get(k) for k in (
        "total_documents_discovered", "unique_document_observations_count", "document_links_count",
        "placeholder_document_entries_count", "unavailable_document_slots_count")}
    unavailable_tabs = ct["unavailable_by_state"] + ct["unavailable_no_link_no_filename"]
    rec = {
        "tabs_scope": dict(ct), "unlinked_scope": dict(cu),
        "stored_counters": stored,
        "recomputed_tabs_scope": {
            "total_records": ct["records"],
            "unique_observations": ct["unique_observation_keys"],
            "document_links": ct["document_links"],
            "placeholder_flag": ct["placeholder_flag_total"],
            "unavailable": unavailable_tabs,
        },
        "recomputed_tabs_plus_unlinked_total_records": ct["records"] + cu["records"],
    }
    rec["match_total_tabs_only"] = stored["total_documents_discovered"] == ct["records"]
    rec["match_total_tabs_plus_unlinked"] = stored["total_documents_discovered"] == ct["records"] + cu["records"]
    rec["match_unique"] = stored["unique_document_observations_count"] == ct["unique_observation_keys"]
    rec["match_links"] = stored["document_links_count"] == ct["document_links"]
    rec["match_placeholder"] = stored["placeholder_document_entries_count"] == ct["placeholder_flag_total"]
    rec["match_unavailable"] = stored["unavailable_document_slots_count"] == unavailable_tabs
    rec["identity_total_eq_unique_plus_dups_plus_unavailable"] = (
        ct["records"] == ct["unique_observation_keys"] + ct["duplicate_observations_same_key"] + unavailable_tabs)
    return rec


def main():
    projects = manifest_projects()
    per_project, agg = [], Counter()
    for p in projects:
        _, nf = project_files(p)
        norm = jload(nf)
        r = audit_project(p, norm)
        r["batch_index"] = p["batch_index"]
        r["project_name"] = p["project_name"]
        r["registration_number"] = p["reg_no"]
        per_project.append(r)
        for k, v in r["stored_counters"].items():
            agg[f"stored::{k}"] += v or 0
        for scope in ("tabs_scope", "unlinked_scope"):
            for k, v in r[scope].items():
                agg[f"{scope}::{k}"] += v
        for k in [k for k in r if k.startswith("match_") or k.startswith("identity_")]:
            agg[f"projects_true::{k}"] += int(bool(r[k]))
    a = dict(agg)
    T = "tabs_scope::"
    U = "unlinked_scope::"
    stored_total = a["stored::total_documents_discovered"]
    summary = {
        "stored_report_figures": {k.split("::")[1]: v for k, v in a.items() if k.startswith("stored::")},
        "recomputed": {
            "tabs_scope_total_records": a[T + "records"],
            "unlinked_scope_total_records": a.get(U + "records", 0),
            "tabs_plus_unlinked_total_records": a[T + "records"] + a.get(U + "records", 0),
            "unique_observation_keys": a[T + "unique_observation_keys"],
            "document_links": a[T + "document_links"],
            "filename_only_no_link": a.get(T + "filename_only_no_link", 0),
            "duplicate_observations_same_key": a[T + "duplicate_observations_same_key"],
            "identifiers_reused_across_distinct_locations": a[T + "identifiers_reused_across_distinct_locations"],
            "unavailable_by_state": a.get(T + "unavailable_by_state", 0),
            "unavailable_no_link_no_filename": a.get(T + "unavailable_no_link_no_filename", 0),
            "placeholder_flag_total": a.get(T + "placeholder_flag_total", 0),
            "placeholder_in_unique_bucket": a.get(T + "placeholder_in:observed_with_link_or_filename", 0),
            "placeholder_in_unavailable_by_state": a.get(T + "placeholder_in:unavailable_by_state", 0),
            "placeholder_in_unavailable_no_link": a.get(T + "placeholder_in:unavailable_no_link_no_filename", 0),
            "failed_document_observations": a.get(T + "failed_document_observations", 0),
            "date_parse_failed_flag_on_document": a.get(T + "date_parse_failed_flag_on_document", 0),
            "unlinked_panes_document_summary": {
                "records": a.get(U + "records", 0),
                "state_breakdown": {k.split("state:")[1]: v for k, v in a.items() if k.startswith(U + "state:")},
                "linked_ids_total_per_project_sum": a.get(U + "unlinked_linked_ids_total", 0),
                "linked_ids_also_present_in_visible_tabs": a.get(U + "unlinked_linked_ids_also_in_tabs", 0),
                "linked_ids_only_in_unlinked_panes": a.get(U + "unlinked_linked_ids_only_in_unlinked_panes", 0),
                "note": "These records are NOT included in total_documents_discovered/unique/links counters (those walk visible tabs only).",
            },
            "state_breakdown_tabs": {k.split("state:")[1]: v for k, v in a.items() if k.startswith(T + "state:")},
            "flag_breakdown_tabs": {k.split("flag:")[1]: v for k, v in a.items() if k.startswith(T + "flag:")},
        },
        "projects_where_stored_counter_matches_recomputation": {
            k.split("::")[1]: v for k, v in a.items() if k.startswith("projects_true::")},
    }
    s = summary["recomputed"]
    summary["reconciliation"] = {
        "naive_sum_of_three_reported_categories": (
            summary["stored_report_figures"]["unique_document_observations_count"]
            + summary["stored_report_figures"]["placeholder_document_entries_count"]
            + summary["stored_report_figures"]["unavailable_document_slots_count"]),
        "reported_total_records": stored_total,
        "naive_sum_minus_reported_total": (
            summary["stored_report_figures"]["unique_document_observations_count"]
            + summary["stored_report_figures"]["placeholder_document_entries_count"]
            + summary["stored_report_figures"]["unavailable_document_slots_count"]) - stored_total,
        "unique_plus_duplicates_plus_unavailable": (
            s["unique_observation_keys"] + s["duplicate_observations_same_key"]
            + s["unavailable_by_state"] + s["unavailable_no_link_no_filename"]),
    }
    out = {"generated_at_utc": now_iso(), "method": "Independent re-walk of 250 normalized JSON files (tabs, sub_tabs, subsections, unlinked panes).",
           "aggregate": summary, "per_project": per_project}
    return out


if __name__ == "__main__":
    out = main()
    print(json.dumps(out["aggregate"], indent=2)[:6000])
