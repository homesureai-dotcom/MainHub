"""Audit section 5: identity, manifest, file and SQLite checkpoint integrity (read-only)."""
from __future__ import annotations

import hashlib
import os
import re
import sqlite3
from collections import Counter, defaultdict
from datetime import datetime, timezone

from audit.common import *  # noqa

REG_RE = re.compile(r"(?:TOR/)?PRM/KA/RERA/\d+/\d+/PR/\d+/\d+")
ACK_RE = re.compile(r"PR/KN/\d+/\d+")


def nws(s):
    return re.sub(r"\s+", " ", str(s or "")).strip().lower()


def load_db(path):
    c = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
    c.row_factory = sqlite3.Row
    rows = [dict(r) for r in c.execute("select * from detail_extraction_checkpoints")]
    errs = [dict(r) for r in c.execute("select * from detail_extraction_error_logs")]
    c.close()
    return rows, errs


def walk_keys(obj, key_name):
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k == key_name and isinstance(v, str):
                yield v
            yield from walk_keys(v, key_name)
    elif isinstance(obj, list):
        for v in obj:
            yield from walk_keys(v, key_name)


def main():
    manifest_doc = jload(P3C_MANIFEST)
    projects = manifest_doc["selected_projects"]
    p3a = jload(P3A_MANIFEST)["selected_projects"]
    p3b = jload(P3B_MANIFEST)["selected_projects"]
    issues = []

    # ---- manifest integrity
    keys = [p["canonical_project_key"] for p in projects]
    regs = [p["reg_no"].strip().upper() for p in projects]
    acks = [p["ack_no"].strip().upper() for p in projects]
    vpds = [str(p["vpd_id"]).strip() for p in projects]
    rec_keys = [p["record_key"] for p in projects]
    recomputed_sha = hashlib.sha256(json.dumps(projects, sort_keys=True, ensure_ascii=False).encode("utf-8")).hexdigest()
    alias_path = P3C / "phase3c_selected_250_manifest.json"
    manifest_block = {
        "entries": len(projects), "distinct_canonical_keys": len(set(keys)), "distinct_reg_no": len(set(regs)),
        "distinct_ack_no": len(set(acks)), "distinct_vpd_id": len(set(vpds)), "distinct_record_keys": len(set(rec_keys)),
        "frozen_flag": manifest_doc.get("frozen"), "stored_sha256": manifest_doc.get("manifest_projects_sha256"),
        "recomputed_sha256_of_selected_projects": recomputed_sha,
        "sha256_matches": recomputed_sha == manifest_doc.get("manifest_projects_sha256"),
        "alias_manifest_byte_identical": sha256_file(alias_path) == sha256_file(P3C_MANIFEST) if alias_path.exists() else None,
        "batch_index_sequence_1_to_250": sorted(p["batch_index"] for p in projects) == list(range(1, 251)),
        "canonical_key_reg_consistency": sum(1 for p in projects if p["reg_no"].strip().upper() in p["canonical_project_key"].upper()),
    }
    if not manifest_block["sha256_matches"]:
        issues.append("manifest sha256 does not match recomputation")

    # ---- overlap with 3A / 3B
    hist = p3a + p3b
    overlap = {
        "phase3a_entries": len(p3a), "phase3b_entries": len(p3b),
        "overlap_reg_no": sorted(set(regs) & {p["reg_no"].strip().upper() for p in hist}),
        "overlap_ack_no": sorted(set(acks) & {p["ack_no"].strip().upper() for p in hist}),
        "overlap_vpd_id": sorted(set(vpds) & {str(p["vpd_id"]).strip() for p in hist}),
        "overlap_canonical_key": sorted(set(keys) & {p["canonical_project_key"] for p in hist}),
        "overlap_record_key": sorted(set(rec_keys) & {p["record_key"] for p in hist}),
        "phase3a_phase3b_mutual_overlap_canonical_keys": sorted({p["canonical_project_key"] for p in p3a} & {p["canonical_project_key"] for p in p3b}),
    }

    # ---- per-project file/identity checks
    all_known_regs = {p["reg_no"].strip().upper(): ("3C", p["batch_index"]) for p in projects}
    for p in p3a:
        all_known_regs[p["reg_no"].strip().upper()] = ("3A", p["batch_index"])
    for p in p3b:
        all_known_regs[p["reg_no"].strip().upper()] = ("3B", p["batch_index"])
    per = []
    xref_hits = []
    prefix_expected = {p["file_prefix"] for p in projects}
    raw_on_disk = {f.name[:-len("_raw.json")] for f in P3C_RAW.glob("*_raw.json")}
    norm_on_disk = {f.name[:-len("_normalized.json")] for f in P3C_NORM.glob("*_normalized.json")}
    orphan_raw = sorted(raw_on_disk - prefix_expected)
    orphan_norm = sorted(norm_on_disk - prefix_expected)
    missing_raw = sorted(prefix_expected - raw_on_disk)
    missing_norm = sorted(prefix_expected - norm_on_disk)
    cum_rows, cum_errs = load_db(SQLITE_CUM)
    iso_rows, iso_errs = load_db(SQLITE_P3C)
    cum_by_key = {r["project_key"]: r for r in cum_rows}
    iso_by_key = {r["project_key"]: r for r in iso_rows}

    for p in projects:
        rf, nf = project_files(p)
        row = {"batch_index": p["batch_index"], "project_name": p["project_name"], "reg_no": p["reg_no"], "problems": []}
        if not rf.exists() or not nf.exists():
            row["problems"].append("missing raw/normalized file")
            per.append(row)
            continue
        raw, norm = jload(rf), jload(nf)
        cr = raw.get("catalogue_record", {})
        payload = raw.get("raw_dom_payload", {})
        mi = payload.get("modal_identity", {})
        iv = norm.get("identity_verification") or {}
        checks = {
            "raw_batch_index": raw.get("batch_index") == p["batch_index"],
            "raw_catalogue_reg": cr.get("reg_no") == p["reg_no"],
            "raw_catalogue_ack": cr.get("ack_no") == p["ack_no"],
            "raw_catalogue_vpd": str(cr.get("vpd_id")) == str(p["vpd_id"]),
            "raw_catalogue_key": cr.get("canonical_project_key") == p["canonical_project_key"],
            "modal_reg_eq_manifest": (mi.get("registration_number") or "").strip().upper() == p["reg_no"].strip().upper(),
            "modal_ack_eq_manifest": (mi.get("acknowledgement_number") or "").strip().upper() == p["ack_no"].strip().upper(),
            "modal_name_eq_manifest": nws(mi.get("project_name")) == nws(p["project_name"]),
            "modal_vpd_eq_manifest": str(mi.get("portal_detail_element_id")) == str(p["vpd_id"]),
            "norm_reg_eq_manifest": (norm.get("registration_number") or "").strip().upper() == p["reg_no"].strip().upper(),
            "norm_ack_eq_manifest": (norm.get("acknowledgement_number") or "").strip().upper() == p["ack_no"].strip().upper(),
            "norm_name_eq_manifest": nws(norm.get("project_name")) == nws(p["project_name"]),
            "norm_identity_verified": bool(iv.get("is_verified")),
            "norm_status_successful": norm.get("extraction_status") == "successful",
        }
        row["checks"] = checks
        row["problems"] += [k for k, v in checks.items() if not v]
        # cross-project attribution: every nested project_id equals this project's internal id
        internal = norm.get("internal_id")
        nested_ids = Counter(walk_keys(norm, "project_id"))
        foreign = {k: v for k, v in nested_ids.items() if k != internal}
        row["nested_project_id_values"] = len(nested_ids)
        row["nested_project_id_foreign"] = foreign
        if foreign:
            row["problems"].append("nested project_id differs from internal_id")
        # foreign registration / acknowledgement numbers appearing in the file text
        text = rf.read_text(encoding="utf-8") + nf.read_text(encoding="utf-8")
        own = p["reg_no"].strip().upper()
        found = {m.upper() for m in REG_RE.findall(text)}
        found_known_other = sorted(r for r in found if r != own and r in all_known_regs)
        found_unknown_other = sorted(r for r in found if r != own and r not in all_known_regs)
        row["other_known_phase_registration_numbers_found_in_file"] = [(r, *all_known_regs[r]) for r in found_known_other]
        row["other_registration_numbers_not_in_any_manifest_found_in_file"] = len(found_unknown_other)
        if found_known_other:
            xref_hits.append({"batch_index": p["batch_index"], "own_reg": own, "foreign_known_regs": found_known_other})
        # checkpoints
        c_iso, c_cum = iso_by_key.get(p["canonical_project_key"]), cum_by_key.get(p["canonical_project_key"])
        exp_raw = f"data\\batch_phase3c\\raw\\{p['file_prefix']}_raw.json"
        exp_norm = f"data\\batch_phase3c\\normalized\\{p['file_prefix']}_normalized.json"
        for name, c in (("isolated", c_iso), ("cumulative", c_cum)):
            if c is None:
                row["problems"].append(f"no {name} checkpoint")
                continue
            ok = {
                "status_successful": c["extraction_status"] == "successful",
                "reg": c["registration_number"] == p["reg_no"], "ack": c["acknowledgement_number"] == p["ack_no"],
                "vpd": str(c["portal_detail_element_id"]) == str(p["vpd_id"]),
                "page": c["catalogue_page_number"] == p["page_number"], "row_order": c["catalogue_row_order"] == p["row_order"],
                "raw_path": str(c["raw_output_path"]).replace("/", "\\") == exp_raw,
                "norm_path": str(c["normalized_output_path"]).replace("/", "\\") == exp_norm,
                "identity_status": str(c["identity_verification_status"]).lower() in ("verified", "true", "1", "identity_verified", "is_verified"),
            }
            row[f"checkpoint_{name}"] = {**ok, "attempt_count": c["attempt_count"], "is_retryable": c["is_retryable"],
                                          "identity_verification_status_value": c["identity_verification_status"]}
            row["problems"] += [f"{name}:{k}" for k, v in ok.items() if not v and k != "identity_status"]
        if c_iso and c_cum:
            same = all(c_iso[k] == c_cum[k] for k in ("payload_sha256", "extraction_status", "attempt_count", "raw_output_path", "normalized_output_path"))
            row["isolated_equals_cumulative_core_fields"] = same
            if not same:
                row["problems"].append("isolated vs cumulative checkpoint differ")
        if c_cum:
            row["payload_sha256_vs_normalized_file_sha256"] = ("equal" if c_cum["payload_sha256"] == sha256_file(nf) else "different_definition_or_stale")
        per.append(row)

    # ---- SQLite reconciliation
    hist_keys = {p["canonical_project_key"] for p in hist}
    cum_keys = set(cum_by_key)
    sqlite_block = {
        "isolated_rows": len(iso_rows), "isolated_status_counts": dict(Counter(r["extraction_status"] for r in iso_rows)),
        "isolated_keys_equal_manifest_keys": set(iso_by_key) == set(keys),
        "isolated_extra_keys": sorted(set(iso_by_key) - set(keys)), "isolated_missing_keys": sorted(set(keys) - set(iso_by_key)),
        "cumulative_rows": len(cum_rows), "cumulative_status_counts": dict(Counter(r["extraction_status"] for r in cum_rows)),
        "cumulative_keys_equal_union_3a_3b_3c": cum_keys == (hist_keys | set(keys)),
        "cumulative_extra_keys": sorted(cum_keys - (hist_keys | set(keys))), "cumulative_missing_keys": sorted((hist_keys | set(keys)) - cum_keys),
        "cumulative_successful_for_3a": sum(1 for p in p3a if cum_by_key.get(p["canonical_project_key"], {}).get("extraction_status") == "successful"),
        "cumulative_successful_for_3b": sum(1 for p in p3b if cum_by_key.get(p["canonical_project_key"], {}).get("extraction_status") == "successful"),
        "cumulative_successful_for_3c": sum(1 for p in projects if cum_by_key.get(p["canonical_project_key"], {}).get("extraction_status") == "successful"),
        "attempt_count_distribution_3c_isolated": dict(Counter(r["attempt_count"] for r in iso_rows)),
        "attempt_count_distribution_3c_cumulative": dict(Counter(cum_by_key[k]["attempt_count"] for k in keys if k in cum_by_key)),
        "isolated_error_log_rows": len(iso_errs), "cumulative_error_log_rows_total": len(cum_errs),
        "cumulative_error_log_rows_for_3c_keys": sum(1 for e in cum_errs if e["project_key"] in set(keys)),
        "cumulative_error_log_rows_for_3c_keys_by_stage_type": dict(Counter((e["error_stage"], e["error_type"]) for e in cum_errs if e["project_key"] in set(keys)).most_common()) if False else {
            f"{a}|{b}": v for (a, b), v in Counter((e["error_stage"], e["error_type"]) for e in cum_errs if e["project_key"] in set(keys)).items()},
        "cumulative_error_log_rows_for_3a_3b_keys": sum(1 for e in cum_errs if e["project_key"] in hist_keys),
    }

    # ---- file system
    files_block = {"raw_files": len(raw_on_disk), "normalized_files": len(norm_on_disk), "orphan_raw": orphan_raw,
                   "orphan_normalized": orphan_norm, "missing_raw": missing_raw, "missing_normalized": missing_norm}

    # ---- historical immutability evidence
    first_3c = min(os.path.getmtime(f) for f in P3C_RAW.glob("*_raw.json"))
    hist_files = [f for d in ("batch_phase3a", "batch_phase3b") for f in (ROOT / "data" / d).rglob("*") if f.is_file()]
    later = [str(f.relative_to(ROOT)) for f in hist_files if os.path.getmtime(f) > first_3c]
    hist_block = {
        "earliest_phase3c_raw_file_mtime_utc": datetime.fromtimestamp(first_3c, timezone.utc).isoformat(),
        "historical_files_checked": len(hist_files),
        "historical_files_modified_after_phase3c_started": later,
        "limitation": "No git repository or baseline hash file exists; immutability is evidenced by modification times only, not by hash comparison.",
    }

    # ---- extraction-time clustering to surface re-extractions
    ts = {}
    for p in projects:
        _, nf = project_files(p)
        n = jload(nf)
        ts[p["batch_index"]] = n.get("coverage", {}).get("extraction_timestamp")
    srt = sorted((t, i) for i, t in ts.items() if t)
    gaps = []
    for (t1, i1), (t2, i2) in zip(srt, srt[1:]):
        pass
    order_break = [i for (t, i) in srt if False]
    seq_by_time = [i for t, i in srt]
    out_of_order = [i for pos, i in enumerate(seq_by_time) if pos != i - 1]
    timing_block = {"projects_whose_extraction_time_order_differs_from_batch_index_order": out_of_order[:50],
                    "count": len(out_of_order),
                    "note": "A project extracted later than its batch position indicates re-extraction after a partial run (e.g., after a sub-batch validation halt)."}

    bad = [r for r in per if r["problems"]]
    out = {
        "generated_at_utc": now_iso(),
        "manifest": manifest_block, "overlap_with_phase3a_phase3b": overlap, "files_on_disk": files_block,
        "sqlite_reconciliation": sqlite_block, "historical_immutability_evidence": hist_block,
        "re_extraction_timing_evidence": timing_block,
        "cross_project_attribution": {
            "projects_with_foreign_nested_project_id": sum(1 for r in per if r.get("nested_project_id_foreign")),
            "projects_whose_files_mention_another_known_phase_registration_number": len(xref_hits),
            "mentions": xref_hits[:50],
            "interpretation": "A mention is informational (promoters list previous projects) and is not by itself evidence of mis-attribution; nested project_id values are the attribution check.",
        },
        "per_project_summary": {"projects_checked": len(per), "projects_with_problems": len(bad),
                                  "problem_breakdown": dict(Counter(pr for r in bad for pr in r["problems"]))},
        "problem_projects": [{"batch_index": r["batch_index"], "project_name": r["project_name"], "problems": r["problems"]} for r in bad],
        "per_project": per,
    }
    return out


if __name__ == "__main__":
    o = main()
    for k in ("manifest", "overlap_with_phase3a_phase3b", "files_on_disk", "sqlite_reconciliation", "historical_immutability_evidence", "re_extraction_timing_evidence", "cross_project_attribution", "per_project_summary"):
        print(k, json.dumps(o[k], indent=1)[:2500])
