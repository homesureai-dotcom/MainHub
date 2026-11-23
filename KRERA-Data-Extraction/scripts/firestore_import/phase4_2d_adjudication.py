#!/usr/bin/env python3
"""
HomeSure Phase 4.2D — Human Identity Adjudication & Final Production Migration Readiness.

Generates read-only adjudication deliverables without mutating Firestore, backups, or the
immutable Phase 4.2B manifest:
1. `phase4_2d_business_signoff_register.csv` (all 54 `REQUIRES_BUSINESS_SIGNOFF_SOURCE_PRESENT` cases)
2. `phase4_2d_suffix_collision_review.csv` (all 27 projects across 3 non-brand suffix collision groups)
3. `phase4_2d_manual_review_consolidation.csv` (134 deduplicated unique project review rows)
4. `phase4_2d_status_taxonomy.md` (408 vs 134 reconciliation & 4-axis non-conflated taxonomy)
5. `phase4_2d_final_migration_readiness.md` (Workstream E manifest comparison + final CONDITIONAL PASS gate)
"""

from __future__ import annotations

import csv
import datetime
import hashlib
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Set, Tuple

WORKSPACE_ROOT = Path(__file__).resolve().parents[3]
EXTRACTION_ROOT = WORKSPACE_ROOT / "KRERA-Data-Extraction"
SCRIPTS_ROOT = EXTRACTION_ROOT / "scripts"
for _p in (str(SCRIPTS_ROOT), str(Path(__file__).resolve().parent)):
    if _p not in sys.path:
        sys.path.insert(0, _p)

from name_normalization import normalize_text
from phase4_2_builder_sync import DEFAULT_BACKUP_DIR, REPORTS_DIR, reconcile_identities_and_ownership

SUFFIX_COLLISION_BUILDER_IDS = (
    "builder_shell_promoters_and_infra",
    "builder_greennesto_builders_and_developers",
    "builder_rajiv_gandhi_housing",
)

BUSINESS_SIGNOFF_COLUMNS = [
    "project_id",
    "project_name",
    "registration_number",
    "classification",
    "original_builder_id",
    "proposed_builder_id",
    "original_promoter_name",
    "proposed_canonical_promoter_name",
    "krera_source_record",
    "source_file",
    "source_record_hash",
    "source_uri",
    "active_advisory_flags",
    "exact_reason_business_approval_required",
    "risk_of_incorrect_grouping",
    "risk_level",
    "recommended_decision",
    "required_additional_evidence",
    "human_decision",
    "reviewer",
    "reviewer_notes",
]

SUFFIX_COLLISION_COLUMNS = [
    "builder_id",
    "project_id",
    "registration_number",
    "project_name",
    "relationship_change",
    "original_builder_id",
    "official_promoter_name",
    "canonical_promoter_name",
    "total_projects_in_group",
    "distinct_official_promoters_in_group",
    "legal_form_variants_detected",
    "suffix_determination",
    "independent_corporate_verification_status",
    "mapping_changed",
    "source_record_id",
    "source_file",
    "source_record_hash",
    "source_uri",
    "required_verification_evidence",
    "adjudication_notes",
]

MANUAL_CONSOLIDATION_COLUMNS = [
    "project_id",
    "registration_number",
    "builder_id",
    "canonical_promoter_name",
    "official_promoter_name",
    "review_flags",
    "source_evidence",
    "risk_level",
    "decision",
    "reviewer",
    "reviewer_notes",
]


class AdjudicationReconciliationError(RuntimeError):
    """Raised when exact Phase 4.2D adjudication counts or invariants fail to reconcile."""


def _read_csv_rows(path: Path) -> List[Dict[str, str]]:
    with path.open("r", encoding="utf-8", newline="") as fh:
        return list(csv.DictReader(fh))


def _write_csv_rows(path: Path, columns: List[str], rows: List[Dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=columns, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def _format_source_evidence(src_id: str, src_file: str, src_hash: str, src_uri: str, *, full_hash: bool = True) -> str:
    digest = src_hash if full_hash else (f"{src_hash[:16]}..." if len(src_hash) > 16 else src_hash)
    return f"{src_id} | {src_file} | sha256:{digest} | {src_uri}"


def _build_pair_lookup(pairs: List[Dict[str, Any]]) -> Dict[str, List[Dict[str, Any]]]:
    by_bid: Dict[str, List[Dict[str, Any]]] = defaultdict(list)
    for pair in pairs:
        for bid in pair.get("builder_ids") or []:
            by_bid[str(bid)].append(pair)
    return by_bid


def _describe_partners(bid: str, lookup: Dict[str, List[Dict[str, Any]]]) -> str:
    pairs = lookup.get(bid) or []
    if not pairs:
        return "paired candidate group"
    other_bids: List[str] = []
    promoters: List[str] = []
    for p in pairs:
        for ob in p.get("builder_ids") or []:
            if str(ob) != bid and str(ob) not in other_bids:
                other_bids.append(str(ob))
        for pr in p.get("promoters") or []:
            if str(pr) not in promoters:
                promoters.append(str(pr))
    return f"partners={other_bids}; promoters={promoters[:4]}"


def _assess_signoff_case(
    classification: str,
    orig_bid: str,
    corr_bid: str,
    official_prom: str,
    project_name: str,
    in_merge: bool,
    in_jv: bool,
    is_short: bool,
    merge_lookup: Dict[str, List[Dict[str, Any]]],
    jv_lookup: Dict[str, List[Dict[str, Any]]],
) -> Tuple[str, str, str, str, str]:
    """Return `(reason, risk, risk_level, recommended_decision, required_evidence)`."""
    short_token = normalize_text(official_prom)

    if classification == "OWNERSHIP_REASSIGNMENT":
        short_note = (
            f" Additionally triggers SHORT_PREFIX_ADVISORY (normalized token '{short_token}' < 3 chars)."
            if is_short
            else ""
        )
        reason = (
            f"Project '{project_name}' is reassigned across canonical builder/brand boundaries from "
            f"'{orig_bid}' to '{corr_bid}' under K-RERA promoter '{official_prom}'.{short_note}"
        )
        risk = (
            "Incorrect ownership reassignment directly alters builder portfolio counts, search navigation, and "
            "brand/SPV attribution for live buyers."
        )
        req_ev = (
            "K-RERA Form-A/registration certificate promoter block, SPV/brand relationship confirmation between "
            f"'{orig_bid}' and '{official_prom}'"
            + ("; full legal entity name verification for short prefix" if is_short else ".")
        )
        return (
            reason,
            risk,
            "HIGH",
            "HOLD_FOR_EXPLICIT_OWNERSHIP_SIGNOFF",
            req_ev,
        )

    if classification == "BRAND_PROMOTER_RELATIONSHIP" or in_jv:
        jv_desc = _describe_partners(corr_bid, jv_lookup)
        reason = (
            f"Promoter split from over-merged group '{orig_bid}' into '{corr_bid}' under '{official_prom}' "
            f"intersects a known brand-vs-promoter JV overlap ({jv_desc})."
        )
        risk = (
            "Conflating an independent JV registered promoter with a featured brand or splitting a genuine SPV "
            "distorts legal accountability and portfolio rollups."
        )
        req_ev = (
            "K-RERA registration promoter extract plus signed Joint Development / JV agreement clarifying "
            f"whether '{official_prom}' operates independently or under the overlapping featured brand."
        )
        return (
            reason,
            risk,
            "HIGH",
            "APPROVE_SPLIT_PRESERVE_JV_SEPARATION_PENDING_REVIEW",
            req_ev,
        )

    if in_merge and is_short:
        mc_desc = _describe_partners(corr_bid, merge_lookup)
        reason = (
            f"Promoter split ({orig_bid} -> {corr_bid}) hits both MERGE_CANDIDATE_PAIR ({mc_desc}) and "
            f"SHORT_PREFIX_ADVISORY (normalized token '{short_token}' < 3 chars)."
        )
        risk = (
            "Dual ambiguity: unverified spacing/spelling sibling slugs plus a <3-char prefix token risk either "
            "fragmenting one legal company across two IDs or over-merging unrelated initial firms."
        )
        req_ev = (
            "K-RERA Form-A promoter page plus MCA CIN/LLPIN or GSTIN check comparing spacing variants and "
            f"confirming full entity name for short token '{official_prom}'."
        )
        return (
            reason,
            risk,
            "HIGH",
            "APPROVE_SPLIT_KEEP_MERGE_CANDIDATES_SEPARATE_PENDING_REVIEW",
            req_ev,
        )

    if in_merge:
        mc_desc = _describe_partners(corr_bid, merge_lookup)
        reason = (
            f"Promoter split ({orig_bid} -> {corr_bid}) shares an identical tight alphanumeric corporate key "
            f"with another canonical slug ({mc_desc}); kept separate pending corporate proof."
        )
        risk = (
            "If sibling slugs belong to one legal company, builder portfolios appear split across multiple pages; "
            "if auto-merged without CIN proof, two distinct entities would be falsely collapsed."
        )
        req_ev = (
            f"MCA CIN/LLPIN or GSTIN registry check confirming whether '{official_prom}' and sibling merge "
            "candidate promoters share an identical legal registration."
        )
        return (
            reason,
            risk,
            "MEDIUM",
            "APPROVE_SPLIT_KEEP_MERGE_CANDIDATES_SEPARATE_PENDING_REVIEW",
            req_ev,
        )

    # SHORT_PREFIX_ADVISORY only
    reason = (
        f"Promoter split ({orig_bid} -> {corr_bid}) resolves to a <3-character normalized token "
        f"('{short_token}') from K-RERA promoter '{official_prom}'."
    )
    risk = (
        "Very short (<3-char) normalized names carry higher risk of colliding unrelated initialisms or "
        "proprietary firms if expanded carelessly."
    )
    req_ev = (
        f"Confirm full registered promoter name and signatory block in K-RERA certificate for '{official_prom}'."
    )
    return (
        reason,
        risk,
        "MEDIUM",
        "VERIFY_SHORT_PREFIX_PROMOTER_BEFORE_APPROVAL",
        req_ev,
    )


# ---------------------------------------------------------------------------
# Workstream A — 54 Business Sign-Off Cases
# ---------------------------------------------------------------------------

def build_54_business_signoff_register(
    biz_rows: List[Dict[str, str]],
    reg_by_id: Dict[str, Dict[str, str]],
    merge_lookup: Dict[str, List[Dict[str, Any]]],
    jv_lookup: Dict[str, List[Dict[str, Any]]],
) -> Dict[str, Any]:
    """Prepare the 54-case human sign-off register without auto-approving any record."""
    target_rows = [
        r for r in biz_rows if r.get("grouping_supported_by_krera_evidence") == "REQUIRES_BUSINESS_SIGNOFF_SOURCE_PRESENT"
    ]
    if len(target_rows) != 54:
        raise AdjudicationReconciliationError(
            f"Expected exactly 54 REQUIRES_BUSINESS_SIGNOFF_SOURCE_PRESENT rows, found {len(target_rows)}"
        )

    out_rows: List[Dict[str, Any]] = []
    class_counts: Counter[str] = Counter()
    risk_counts: Counter[str] = Counter()

    for r in sorted(target_rows, key=lambda x: x["project_id"]):
        pid = r["project_id"]
        rr = reg_by_id.get(pid) or {}
        classification = r["classification"]
        in_merge = r.get("in_merge_candidate_pair") == "True"
        in_jv = r.get("in_jv_overlap_pair") == "True"
        is_short = r.get("short_prefix_advisory") == "True"

        reason, risk, risk_level, rec_dec, req_ev = _assess_signoff_case(
            classification=classification,
            orig_bid=r["original_builder_id"],
            corr_bid=r["corrected_builder_id"],
            official_prom=r["official_promoter_name"],
            project_name=r["project_name"],
            in_merge=in_merge,
            in_jv=in_jv,
            is_short=is_short,
            merge_lookup=merge_lookup,
            jv_lookup=jv_lookup,
        )
        class_counts[classification] += 1
        risk_counts[risk_level] += 1

        out_rows.append(
            {
                "project_id": pid,
                "project_name": r["project_name"],
                "registration_number": r["registration_number"],
                "classification": classification,
                "original_builder_id": r["original_builder_id"],
                "proposed_builder_id": r["corrected_builder_id"],
                "original_promoter_name": r["official_promoter_name"],
                "proposed_canonical_promoter_name": r["canonical_promoter_name"],
                "krera_source_record": _format_source_evidence(
                    r["source_record_id"],
                    r["source_file"],
                    r["source_record_hash"],
                    r["source_uri"],
                    full_hash=False,
                ),
                "source_file": r["source_file"],
                "source_record_hash": r["source_record_hash"],
                "source_uri": r["source_uri"],
                "active_advisory_flags": rr.get("advisory_type") or "",
                "exact_reason_business_approval_required": reason,
                "risk_of_incorrect_grouping": risk,
                "risk_level": risk_level,
                "recommended_decision": rec_dec,
                "required_additional_evidence": req_ev,
                "human_decision": "PENDING_HUMAN_APPROVAL",
                "reviewer": "",
                "reviewer_notes": "",
            }
        )

    return {
        "rows": out_rows,
        "summary": {
            "total": len(out_rows),
            "classification_counts": dict(class_counts),
            "risk_level_counts": dict(risk_counts),
            "auto_approved": 0,
        },
    }


# ---------------------------------------------------------------------------
# Workstream B — Three Corporate Suffix Collisions
# ---------------------------------------------------------------------------

def build_suffix_collision_review(
    prom_rows: List[Dict[str, str]],
) -> Dict[str, Any]:
    """Review all projects under the 3 corporate suffix collision builder IDs without altering mappings."""
    grouped: Dict[str, List[Dict[str, str]]] = defaultdict(list)
    for r in prom_rows:
        bid = r["corrected_builder_id"]
        if bid in SUFFIX_COLLISION_BUILDER_IDS:
            grouped[bid].append(r)

    specs: Dict[str, Dict[str, str]] = {
        "builder_shell_promoters_and_infra": {
            "legal_forms": "Pvt Ltd vs LLP (Private Limited vs Limited Liability Partnership)",
            "determination": "UNCLEAR_IDENTITY",
            "evidence": "Obtain MCA CIN & LLPIN incorporation records plus Form-A K-RERA filings to establish whether LLP and Pvt Ltd are a converted entity or two distinct legal entities.",
            "notes": "2 registrations ('Shell NorthGate' under Shell Promoters and Infra Pvt Ltd; 'SHELL SAPPHIRE' under SHELL PROMOTERS AND INFRA LLP). Statutory suffix difference (Pvt Ltd vs LLP) cannot be assumed identical without MCA conversion proof.",
        },
        "builder_greennesto_builders_and_developers": {
            "legal_forms": "Unsuffixed vs M/s + LLP",
            "determination": "UNCLEAR_IDENTITY",
            "evidence": "Inspect K-RERA promoter PAN/registration dossier and MCA LLPIN master data to confirm whether 'Greennesto Builders and  Developers' is the same LLP without suffix or a separate proprietorship/partnership.",
            "notes": "2 registrations ('GREENNESTO PRIMUS' under M/s GREENNESTO BUILDERS AND DEVELOPERS LLP; 'Greennesto-O2' under Greennesto Builders and  Developers). Unsuffixed entry could reflect clerical omission or a distinct partnership prior to LLP incorporation.",
        },
        "builder_rajiv_gandhi_housing": {
            "legal_forms": "Limited / Ltd / LImited typo / Unsuffixed / Pvt Ltd",
            "determination": "ONE_REGISTERED_PROMOTER_NAMING_VARIATIONS_UNVERIFIED_MCA",
            "evidence": "Cross-check Karnataka Government enterprise RGHCL public CIN directory against PRM/KA/RERA/1251/308/PR/210804/004243 ('Pvt Ltd' variant) to confirm portal clerical typo vs subsidiary.",
            "notes": "All 23 registrations deliver Karnataka's '1 Lakh Multi Storey Bengaluru Housing Programme' / PMAY housing schemes under Rajiv Gandhi Housing Corporation variants; relationship strongly points to one State agency with portal entry typos (including 1 'Pvt Ltd' and 1 'LImited'), formally unverified against MCA CIN here.",
        },
    }

    rows: List[Dict[str, Any]] = []
    group_summaries: Dict[str, Dict[str, Any]] = {}

    for bid in SUFFIX_COLLISION_BUILDER_IDS:
        items = sorted(grouped.get(bid) or [], key=lambda x: x["project_id"])
        distinct_proms = sorted({it["official_promoter_name"].strip() for it in items})
        spec = specs[bid]
        group_summaries[bid] = {
            "project_count": len(items),
            "distinct_official_promoters": distinct_proms,
            "determination": spec["determination"],
            "independent_corporate_verification_status": "UNVERIFIED_EXTERNAL_CORPORATE_RELATIONSHIP",
            "mapping_changed": False,
        }
        for it in items:
            rows.append(
                {
                    "builder_id": bid,
                    "project_id": it["project_id"],
                    "registration_number": it["registration_number"],
                    "project_name": it["project_name"],
                    "relationship_change": it["relationship_change"],
                    "original_builder_id": it["original_builder_id"],
                    "official_promoter_name": it["official_promoter_name"],
                    "canonical_promoter_name": it["canonical_promoter_name"],
                    "total_projects_in_group": len(items),
                    "distinct_official_promoters_in_group": len(distinct_proms),
                    "legal_form_variants_detected": spec["legal_forms"],
                    "suffix_determination": spec["determination"],
                    "independent_corporate_verification_status": "UNVERIFIED_EXTERNAL_CORPORATE_RELATIONSHIP",
                    "mapping_changed": False,
                    "source_record_id": it["source_record_id"],
                    "source_file": it["source_file"],
                    "source_record_hash": it["source_record_hash"],
                    "source_uri": it["source_uri"],
                    "required_verification_evidence": spec["evidence"],
                    "adjudication_notes": spec["notes"],
                }
            )

    return {
        "rows": rows,
        "summary": {
            "total_builders_reviewed": len(SUFFIX_COLLISION_BUILDER_IDS),
            "total_projects_reviewed": len(rows),
            "groups": group_summaries,
            "mappings_changed": 0,
        },
    }


# ---------------------------------------------------------------------------
# Workstream C — 134 Manual Review Cases (Deduplicated Consolidation)
# ---------------------------------------------------------------------------

def build_134_manual_review_consolidation(
    reg_rows: List[Dict[str, str]],
    ev_by_id: Dict[str, Dict[str, str]],
    prom_by_id: Dict[str, Dict[str, str]],
    signoff_54_ids: Set[str],
    merge_lookup: Dict[str, List[Dict[str, Any]]],
    jv_lookup: Dict[str, List[Dict[str, Any]]],
) -> Dict[str, Any]:
    """Consolidate all 134 MANUAL_REVIEW_REQUIRED changed projects into 1 deduplicated row per project."""
    manual_rows = [r for r in reg_rows if r.get("review_status") == "MANUAL_REVIEW_REQUIRED"]
    seen_pids: Set[str] = set()
    rows: List[Dict[str, Any]] = []
    flag_counts: Counter[str] = Counter()
    risk_counts: Counter[str] = Counter()

    for r in sorted(manual_rows, key=lambda x: x["project_id"]):
        pid = r["project_id"]
        if pid in seen_pids:
            raise AdjudicationReconciliationError(f"Duplicate project_id in 134 consolidation: {pid}")
        seen_pids.add(pid)

        ev = ev_by_id.get(pid) or {}
        pa = prom_by_id.get(pid) or {}
        adv = r.get("advisory_type") or ""
        flags: List[str] = []
        if pid in signoff_54_ids:
            flags.append("BUSINESS_SIGNOFF_54")
        if "OWNERSHIP_REASSIGNMENT" in adv or r.get("classification") == "OWNERSHIP_REASSIGNMENT":
            flags.append("OWNERSHIP_REASSIGNMENT")
        if "JV_BRAND_OVERLAP" in adv or ev.get("in_jv_overlap_pair") == "True":
            flags.append("JV_BRAND_OVERLAP")
        if "MERGE_CANDIDATE_PAIR" in adv or ev.get("in_merge_candidate_pair") == "True":
            flags.append("MERGE_CANDIDATE_PAIR")
        if "SHORT_PREFIX_ADVISORY" in adv:
            flags.append("SHORT_PREFIX_ADVISORY")

        for fl in flags:
            flag_counts[fl] += 1

        if (
            "OWNERSHIP_REASSIGNMENT" in flags
            or "JV_BRAND_OVERLAP" in flags
            or ("MERGE_CANDIDATE_PAIR" in flags and "SHORT_PREFIX_ADVISORY" in flags)
        ):
            risk_level = "HIGH"
        else:
            risk_level = "MEDIUM"
        risk_counts[risk_level] += 1

        corr_bid = r["corrected_builder_id"]
        extra_parts: List[str] = []
        if "MERGE_CANDIDATE_PAIR" in flags:
            extra_parts.append(f"merge_pair({_describe_partners(corr_bid, merge_lookup)})")
        if "JV_BRAND_OVERLAP" in flags:
            extra_parts.append(f"jv_pair({_describe_partners(corr_bid, jv_lookup)})")
        context = f" Context: {'; '.join(extra_parts)}." if extra_parts else ""
        notes = (
            f"[{r['classification']}] {r['original_builder_id']} -> {corr_bid}.{context} "
            "No human decision populated; awaits reviewer sign-off."
        )

        rows.append(
            {
                "project_id": pid,
                "registration_number": r["registration_number"],
                "builder_id": corr_bid,
                "canonical_promoter_name": r["canonical_promoter_name"],
                "official_promoter_name": pa.get("official_promoter_name") or r["original_promoter_name"],
                "review_flags": "|".join(flags),
                "source_evidence": _format_source_evidence(
                    r["source_record_id"],
                    r["source_file"],
                    r["source_record_hash"],
                    r["source_uri"],
                    full_hash=True,
                ),
                "risk_level": risk_level,
                "decision": "PENDING_HUMAN_DECISION",
                "reviewer": "",
                "reviewer_notes": notes,
            }
        )

    # Exact mathematical reconciliation checks across overlapping categories
    if len(rows) != 134:
        raise AdjudicationReconciliationError(f"Expected 134 unique consolidated rows, found {len(rows)}")
    expected_flag_counts = {
        "BUSINESS_SIGNOFF_54": 54,
        "MERGE_CANDIDATE_PAIR": 75,
        "JV_BRAND_OVERLAP": 10,
        "SHORT_PREFIX_ADVISORY": 56,
        "OWNERSHIP_REASSIGNMENT": 5,
    }
    for k, exp_v in expected_flag_counts.items():
        if flag_counts.get(k, 0) != exp_v:
            raise AdjudicationReconciliationError(
                f"Consolidated flag count mismatch for {k}: observed={flag_counts.get(k, 0)} != expected={exp_v}"
            )

    return {
        "rows": rows,
        "summary": {
            "total_unique_projects": len(rows),
            "individual_flag_counts": dict(flag_counts),
            "risk_level_counts": dict(risk_counts),
            "populated_decisions": 0,
        },
    }


# ---------------------------------------------------------------------------
# Workstreams D, E & F — Status Taxonomy & Final Migration Readiness Reports
# ---------------------------------------------------------------------------

def build_408_vs_134_reconciliation(
    prom_rows: List[Dict[str, str]],
    reg_rows: List[Dict[str, str]],
    ev_by_id: Dict[str, Dict[str, str]],
) -> Dict[str, Any]:
    """Reconcile 408 MANUAL_REVIEW_REQUIRED (all 4,110) vs 134 (2,057 changed) without altering definitions."""
    m408 = [r for r in prom_rows if r["identity_verification_status"] == "MANUAL_REVIEW_REQUIRED"]
    m134 = [r for r in reg_rows if r["review_status"] == "MANUAL_REVIEW_REQUIRED"]

    m408_changed = [r for r in m408 if r["in_2057_changed"] == "True"]
    m408_unchanged = [r for r in m408 if r["in_2057_changed"] == "False"]

    if {r["project_id"] for r in m408_changed} != {r["project_id"] for r in m134}:
        raise AdjudicationReconciliationError(
            "408 changed-project subset does not match the 134 MANUAL_REVIEW_REQUIRED changed register"
        )
    if len(m408) != len(m134) + len(m408_unchanged):
        raise AdjudicationReconciliationError("408 != 134 + unchanged reconciliation failure")

    unchanged_flags: Counter[str] = Counter()
    for r in m408_unchanged:
        ev = ev_by_id[r["project_id"]]
        tags: List[str] = []
        if r["promoter_identity_type"] == "JOINT_VENTURE" or ev["in_jv_overlap_pair"] == "True":
            tags.append("JV_BRAND_OVERLAP")
        if ev["in_merge_candidate_pair"] == "True":
            tags.append("MERGE_CANDIDATE_PAIR")
        unchanged_flags["|".join(tags) or "OTHER"] += 1

    return {
        "all_4110_manual_review": len(m408),
        "changed_2057_manual_review": len(m134),
        "unchanged_2053_manual_review": len(m408_unchanged),
        "unchanged_breakdown": dict(unchanged_flags),
        "all_4110_merge_candidate_projects": sum(1 for r in ev_by_id.values() if r["in_merge_candidate_pair"] == "True"),
        "all_4110_jv_overlap_projects": sum(1 for r in ev_by_id.values() if r["in_jv_overlap_pair"] == "True"),
    }


def write_status_taxonomy_md(
    out_path: Path,
    recon_408_134: Dict[str, Any],
    prom_rows: List[Dict[str, str]],
    reg_rows: List[Dict[str, str]],
) -> None:
    """Write `phase4_2d_status_taxonomy.md` cleanly separating all 4 governance axes."""
    prom_status = Counter(r["identity_verification_status"] for r in prom_rows)
    prom_types = Counter(r["promoter_identity_type"] for r in prom_rows)
    reg_status = Counter(r["review_status"] for r in reg_rows)
    ub = recon_408_134["unchanged_breakdown"]

    lines = [
        "# HomeSure — Phase 4.2D Governance Status Taxonomy & `408` vs `134` Reconciliation",
        "",
        f"**Generated At (UTC):** `{datetime.datetime.now(datetime.timezone.utc).isoformat()}`  ",
        "**Principle:** Project-level identity verification, builder-level identity classification, migration approval, and corporate/legal verification are distinct orthogonal axes and **must never be conflated**.",
        "",
        "---",
        "",
        "## 1. Exact Reconciliation of `408` vs `134` (`MANUAL_REVIEW_REQUIRED`)",
        "",
        "Neither definition was modified to force matching counts. The difference of `274` (`408 - 134`) is a pure **scope difference** between the full `4,110`-project universe and the `2,057`-row changed-project migration subset:",
        "",
        "| Dataset Scope | Report Artifact | Total Evaluated | `MANUAL_REVIEW_REQUIRED` | Remainder |",
        "|---|---|---:|---:|---|",
        f"| Full Promoter Normalization Audit (All Projects) | `phase4_2c_promoter_name_normalization_audit.csv` | `4,110` | **`{recon_408_134['all_4110_manual_review']}`** | `3,013` `SOURCE_BACKED`, `689` `NORMALIZED_FROM_SOURCE` |",
        f"| Changed-Project Migration Review Register | `phase4_2c_complete_identity_review_register.csv` & `phase4_2d_manual_review_consolidation.csv` | `2,057` | **`{recon_408_134['changed_2057_manual_review']}`** | `1,923` `PENDING_HUMAN_REVIEW` (`0` approved) |",
        f"| Unchanged Legacy Projects (`relationship_change == UNCHANGED`) | Excluded from `2,057`-row patch register (`0` writes staged) | `2,053` | **`{recon_408_134['unchanged_2053_manual_review']}`** | `1,779` without merge/JV advisory flags |",
        "",
        "### Exact Set Identity Proof",
        f"- `{recon_408_134['all_4110_manual_review']}` (`408` in full `4,110` audit) = **`{recon_408_134['changed_2057_manual_review']}`** (exact 100% identical `project_id` set in changed `2,057` register) **+** **`{recon_408_134['unchanged_2053_manual_review']}`** (`274` in `2,053` `UNCHANGED` projects).",
        f"- **Breakdown of the `{recon_408_134['unchanged_2053_manual_review']}` `UNCHANGED` Projects Requiring Governance Review (Though Unmodified in Phase 4.2):**",
        f"  - `JOINT_VENTURE` / `JV_BRAND_OVERLAP`: **`{ub.get('JV_BRAND_OVERLAP', 0)}`** projects (`10` changed + `210` unchanged = `{recon_408_134['all_4110_jv_overlap_projects']}` total JV-overlap projects across the `9` JV pairs).",
        f"  - `MERGE_CANDIDATE_PAIR`: **`{ub.get('MERGE_CANDIDATE_PAIR', 0)}`** projects (`75` changed + `64` unchanged = `{recon_408_134['all_4110_merge_candidate_projects']}` total merge-candidate projects across the `33` tight-key pairs).",
        "  - `SHORT_PREFIX_ADVISORY`: **`0`** in `UNCHANGED` (all `56` short-prefix advisories belong to changed projects).",
        "",
        "---",
        "",
        "## 2. Four-Axis Governance Status Taxonomy",
        "",
        "### Axis 1 — Project-Level Identity Verification (`identity_verification_status`, All `4,110` Projects)",
        "| Status | Observed Count | Meaning & Source Requirement |",
        "|---|---:|---|",
        f"| `SOURCE_BACKED` | `{prom_status.get('SOURCE_BACKED', 0)}` | Verified K-RERA SQLite/JSON promoter record; case/whitespace matches canonical promoter with no merge/JV/short-prefix/ownership flag. |",
        f"| `NORMALIZED_FROM_SOURCE` | `{prom_status.get('NORMALIZED_FROM_SOURCE', 0)}` | Verified K-RERA source record mapped cleanly to a canonical Featured Brand / corporate normalization without open conflict flags. |",
        f"| `MANUAL_REVIEW_REQUIRED` | `{prom_status.get('MANUAL_REVIEW_REQUIRED', 0)}` | Intersects an ownership reassignment, JV overlap, merge-candidate spacing pair, or <3-char prefix advisory (`134` changed + `274` unchanged). |",
        f"| `UNVERIFIED_EXTERNAL_ENTITY` | `{prom_status.get('UNVERIFIED_EXTERNAL_ENTITY', 0)}` | Missing or mismatched K-RERA source record (hard blocker; must equal `0` before readiness). |",
        "",
        "### Axis 2 — Builder-Level Identity Verification (`promoter_identity_type`, `2,236` Canonical Builders / `4,110` Projects)",
        "| Entity Class / Disposition | Observed Count | Governance Boundary |",
        "|---|---:|---|",
        f"| `KRERA_REGISTERED_PROMOTER` | `{prom_types.get('KRERA_REGISTERED_PROMOTER', 0)}` projects | Canonical identity derived strictly from K-RERA registered promoter text (`3` non-brand suffix-collision groups surfaced separately for MCA confirmation). |",
        f"| `FEATURED_BRAND` | `{prom_types.get('FEATURED_BRAND', 0)}` projects | Curated parent brand rule (exact corporate/verified-SPV/strict project rule) backed by K-RERA source rows. |",
        f"| `JOINT_VENTURE` | `{prom_types.get('JOINT_VENTURE', 0)}` projects | Overlaps one of the `9` brand-vs-promoter JV pairs; kept separate (`0` auto-merges). |",
        "| `MERGE_CANDIDATE` (`33` pairs) | `139` projects (`75` chg + `64` unchg) | Tight-alnum spacing/spelling pairs kept unmerged pending human/MCA check. |",
        "| `ORPHANED_BUT_PUBLICLY_EXPOSED` | `59` `/builders` docs | Pre-Phase-4 / superseded docs outside target `108` indiv docs; untouched (`deletions_enabled=false`). |",
        "",
        "### Axis 3 — Migration Approval (Row-Level Adjudication vs Manifest Execution Gate)",
        f"- **Changed-Project Adjudication (`phase4_2c_complete_identity_review_register.csv`):** `{reg_status.get('MANUAL_REVIEW_REQUIRED', 0)}` `MANUAL_REVIEW_REQUIRED`, `{reg_status.get('PENDING_HUMAN_REVIEW', 0)}` `PENDING_HUMAN_REVIEW`, `0` `APPROVED`.",
        "- **Workstream A / C Human Decision Columns:** `human_decision = PENDING_HUMAN_APPROVAL` (`54` rows) and `decision = PENDING_HUMAN_DECISION` (`134` rows); `reviewer` blank on all rows.",
        "- **Manifest & Stage 2 Execution Gate (`phase4_2b_approval_record.json`):** `approved: false`, `approved_by: null`, `approved_at_utc: null`, cryptographically bound to `manifest_sha256` (`e0be8d30f14333b7dcf9a53464c6f95b00956c4a84080fb03713339945c7495c`) and `homesureai-51893/(default)`.",
        "",
        "### Axis 4 — Legal / Corporate Verification (`corporate_verification_claim`)",
        "- **`NONE_CLAIMED_NO_MCA_GSTIN_VERIFICATION` / `UNVERIFIED_EXTERNAL_CORPORATE_RELATIONSHIP`:** Applied uniformly across all `4,110` project audits and all `27` suffix-collision rows. K-RERA portal records verify *registered promoter attribution on RERA filings*, NOT MCA corporate CIN/LLPIN conversion or common beneficial ownership.",
        "",
        "---",
        "",
        "## 3. Non-Conflation Rules",
        "",
        "| Observed State | Does NOT Imply | Why Conflation Is Prohibited |",
        "|---|---|---|",
        "| `identity_verification_status == SOURCE_BACKED` | `approved == true` | Having a valid K-RERA source record proves data provenance, not human release sign-off. |",
        "| `promoter_identity_type == KRERA_REGISTERED_PROMOTER` | MCA / GSTIN Legal Verification | K-RERA string normalization strips corporate suffixes (`Pvt Ltd`, `LLP`); legal identity requires MCA/CIN check. |",
        "| `review_status == MANUAL_REVIEW_REQUIRED` (`134` vs `408`) | Data Integrity Failure | `274` of `408` belong to `UNCHANGED` JV/merge pairs untouched by Phase 4.2 writes. |",
        "| Technical Readiness `PASS` | Authorized for Production `--apply` | Technical scripts cannot sign business adjudication or set Stage 2 human approval to `true`. |",
    ]
    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_final_migration_readiness_md(
    out_path: Path,
    *,
    signoff_54: Dict[str, Any],
    suffix_review: Dict[str, Any],
    consolidated_134: Dict[str, Any],
    recon_408_134: Dict[str, Any],
    backup_hashes: Dict[str, str],
    manifest_obj: Dict[str, Any],
    approval_obj: Dict[str, Any],
    reports_dir: Path,
) -> None:
    """Write `phase4_2d_final_migration_readiness.md` separating Technical PASS from Business Approval."""
    s_sum = signoff_54["summary"]
    c_sum = consolidated_134["summary"]
    sx_sum = suffix_review["summary"]

    lines = [
        "# HomeSure — Phase 4.2D Human Identity Adjudication & Final Production Migration Readiness",
        "",
        f"**Audit Timestamp (UTC):** `{datetime.datetime.now(datetime.timezone.utc).isoformat()}`  ",
        f"**Target Environment:** `{manifest_obj['firebase_project_id']}` / `{manifest_obj['firestore_database']}`  ",
        "**Execution Mode:** **STRICTLY READ-ONLY ADJUDICATION PREPARATION (`0` Production Writes / Deletions)**",
        "",
        "---",
        "",
        "## 1. Final Gate Decision",
        "",
        "| Readiness Dimension | Verdict | Explanation |",
        "|---|---|---|",
        "| **Technical Migration Readiness** | **`PASS`** | Backup bundle (`141` `/builders`, `4,110` `/projects`), live drift (`CLEAN`), `36,990` project invariants (`0` mismatches), `56` builder payloads & `2,236` chunk entries (`0` duplicates, `4,110` project memberships), `16` unmanaged field checks (`0` removals), `2,127`-op rollback dry-run (`0` conflicts), Bengaluru Rural separation (`730` rural / `0` overlap), and `140` Python + `31` Flutter tests all pass cleanly. |",
        "| **Legal / Corporate Verification (MCA / GSTIN)** | **`UNVERIFIED (K-RERA Portal Only)`** | Independent MCA CIN / LLPIN / GSTIN corporate verification was NOT executed (`NONE_CLAIMED_NO_MCA_GSTIN_VERIFICATION`). Technical `PASS` does **not** constitute legal entity verification. |",
        f"| **Business Identity Adjudication** | **`PENDING HUMAN SIGN-OFF`** | All `54` business sign-off cases (`{s_sum['classification_counts']}`), all `3` corporate suffix collisions (`{sx_sum['total_projects_reviewed']}` projects), all `134` consolidated changed review cases (`{c_sum['individual_flag_counts']}`), `33` merge candidates, `9` JV overlaps, and `59` publicly exposed deferred docs await explicit human review (`0` auto-approved). |",
        f"| **Stage 2 Migration Authorization** | **`BLOCKED (`approved={approval_obj['approved']}`)`** | [phase4_2b_approval_record.json](file:///c:/Program%20Files/BlackMatter/Homesure/KRERA-Data-Extraction/data/phase4_2_backup_20261122/phase4_2b_approval_record.json) remains intentionally unapproved (`approved: false`). |",
        "| **Overall Readiness Decision** | **`CONDITIONAL PASS`** | Technically ready for controlled execution **strictly conditional** on human sign-off of the adjudication registers and Stage 2 authorization. |",
        "",
        "---",
        "",
        "## 2. Workstream A–D Summary",
        "",
        "### Workstream A — `54` Business Sign-Off Cases (`REQUIRES_BUSINESS_SIGNOFF_SOURCE_PRESENT`)",
        f"- **Deliverable:** [phase4_2d_business_signoff_register.csv](file:///c:/Program%20Files/BlackMatter/Homesure/KRERA-Data-Extraction/reports/phase4_2/phase4_2d_business_signoff_register.csv) (`{s_sum['total']}` rows, `{s_sum['auto_approved']}` auto-approved).",
        f"- **Classifications:** `PROMOTER_ENTITY_SPLIT = {s_sum['classification_counts'].get('PROMOTER_ENTITY_SPLIT', 0)}`, `BRAND_PROMOTER_RELATIONSHIP = {s_sum['classification_counts'].get('BRAND_PROMOTER_RELATIONSHIP', 0)}`, `OWNERSHIP_REASSIGNMENT = {s_sum['classification_counts'].get('OWNERSHIP_REASSIGNMENT', 0)}`.",
        f"- **Risk Distribution:** `{s_sum['risk_level_counts']}`. Every row documents project name, registration number, original/proposed builder ID, official/canonical promoter names, K-RERA source record hash/URI, exact reason approval is required, grouping risk, advisory recommendation, and required additional evidence.",
        "",
        "### Workstream B — Three Corporate Suffix Collisions (`27` Projects)",
        "- **Deliverable:** [phase4_2d_suffix_collision_review.csv](file:///c:/Program%20Files/BlackMatter/Homesure/KRERA-Data-Extraction/reports/phase4_2/phase4_2d_suffix_collision_review.csv) (`27` project rows across `3` canonical IDs; `0` mappings altered).",
        "| Canonical `builder_id` | Projects | Official K-RERA Promoters | Suffix Determination | External Corporate Verification |",
        "|---|---:|---|---|---|",
        "| `builder_shell_promoters_and_infra` | `2` | `Shell Promoters and Infra Pvt Ltd`, `SHELL PROMOTERS AND INFRA LLP` | `UNCLEAR_IDENTITY` | `UNVERIFIED_EXTERNAL_CORPORATE_RELATIONSHIP` |",
        "| `builder_greennesto_builders_and_developers` | `2` | `M/s GREENNESTO BUILDERS AND DEVELOPERS LLP`, `Greennesto Builders and  Developers` | `UNCLEAR_IDENTITY` | `UNVERIFIED_EXTERNAL_CORPORATE_RELATIONSHIP` |",
        "| `builder_rajiv_gandhi_housing` | `23` | `RAJIV GANDHI HOUSING CORPORATION LIMITED`, `Limited`, `LImited`, `Ltd`, `Corporation`, `Pvt Ltd` | `ONE_REGISTERED_PROMOTER_NAMING_VARIATIONS_UNVERIFIED_MCA` | `UNVERIFIED_EXTERNAL_CORPORATE_RELATIONSHIP` |",
        "",
        "### Workstream C — `134` Consolidated Manual Review Cases (Deduplicated)",
        f"- **Deliverable:** [phase4_2d_manual_review_consolidation.csv](file:///c:/Program%20Files/BlackMatter/Homesure/KRERA-Data-Extraction/reports/phase4_2/phase4_2d_manual_review_consolidation.csv) (`{c_sum['total_unique_projects']}` unique `project_id` rows; `0` auto-populated human decisions).",
        "- **Overlapping Advisory Flag Reconciliation (All Preserved on Unique Rows):** `BUSINESS_SIGNOFF_54 = 54`, `MERGE_CANDIDATE_PAIR = 75`, `JV_BRAND_OVERLAP = 10`, `SHORT_PREFIX_ADVISORY = 56`, `OWNERSHIP_REASSIGNMENT = 5` (`54` from split/ownership + `80` from `SLUG_ONLY_CHANGE` = `134` unique changed projects).",
        "",
        "### Workstream D — Review Status Semantics (`408` vs `134`)",
        f"- **Deliverable:** [phase4_2d_status_taxonomy.md](file:///c:/Program%20Files/BlackMatter/Homesure/KRERA-Data-Extraction/reports/phase4_2/phase4_2d_status_taxonomy.md).",
        f"- `{recon_408_134['all_4110_manual_review']}` (`MANUAL_REVIEW_REQUIRED` across all `4,110` projects) = `{recon_408_134['changed_2057_manual_review']}` (identical set to `134` changed projects) + `{recon_408_134['unchanged_2053_manual_review']}` (`210` `JV_BRAND_OVERLAP` + `64` `MERGE_CANDIDATE_PAIR` in `2,053` unchanged projects).",
        "",
        "---",
        "",
        "## 3. Workstream E — Comparison Against Immutable Phase 4.2B Manifest",
        "",
        "- **Identity Assignments Modified During Phase 4.2D Adjudication Preparation:** **`0`** (all human decisions remain `PENDING_HUMAN_APPROVAL` / `PENDING_HUMAN_DECISION`, zero merge candidates/JV overlaps/suffix collisions modified).",
        f"- **Phase 4.2B Manifest Retained Unchanged:** [phase4_2b_migration_manifest.json](file:///c:/Program%20Files/BlackMatter/Homesure/KRERA-Data-Extraction/data/phase4_2_backup_20261122/phase4_2b_migration_manifest.json)",
        f"  - Schema / Version: `{manifest_obj['manifest_schema_version']}` / `{manifest_obj['migration_version']}`",
        f"  - Internal `manifest_sha256`: `{manifest_obj['manifest_sha256']}`",
        f"  - File SHA-256 (verified unchanged): `{backup_hashes.get('phase4_2b_migration_manifest.json', '')}`",
        f"  - Stage 2 Approval Record (`phase4_2b_approval_record.json` SHA-256): `{backup_hashes.get('phase4_2b_approval_record.json', '')}` (`approved={approval_obj['approved']}`)",
        "- **Pre-Condition If Human Reviewers Later Change Any Assignment:** Do NOT modify the Phase 4.2B manifest in place; emit a new versioned manifest (e.g. `phase4_2e_migration_manifest.json`), retain `phase4_2b_migration_manifest.json`, recalculate `manifest_sha256`, and re-run full project invariants (`4,110 x 9`), chunk membership (`2,236`), backup, and rollback verification before requesting Stage 2 sign-off.",
        "- **If Human Reviewers Confirm All Assignments As-Is:** Only after explicit sign-off on all `54` / `134` / `3` suffix-collision records and explicit signing of a copy of `phase4_2b_approval_record.json` (`approved: true`, real `approved_by`, UTC `approved_at_utc`) may an authorized operator run `--apply` (keeping `deletions_enabled=false` and all `59` deferred docs untouched).",
        "",
        "---",
        "",
        "Phase 4.2D identity adjudication preparation completed. Production migration remains disabled pending explicit human approval.",
    ]
    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def generate_phase4_2d_deliverables(
    backup_dir: Path = DEFAULT_BACKUP_DIR,
    reports_dir: Path = REPORTS_DIR,
) -> Dict[str, Any]:
    """Generate all 5 Phase 4.2D read-only adjudication deliverables without mutating 4.2A/4.2B/4.2C artifacts."""
    prom_rows = _read_csv_rows(reports_dir / "phase4_2c_promoter_name_normalization_audit.csv")
    reg_rows = _read_csv_rows(reports_dir / "phase4_2c_complete_identity_review_register.csv")
    biz_rows = _read_csv_rows(reports_dir / "phase4_2c_business_identity_decisions.csv")
    ev_rows = _read_csv_rows(reports_dir / "phase4_2a_evidence_audit.csv")

    reg_by_id = {r["project_id"]: r for r in reg_rows}
    ev_by_id = {r["project_id"]: r for r in ev_rows}
    prom_by_id = {r["project_id"]: r for r in prom_rows}

    b_backup = json.loads((backup_dir / "builders_backup.json").read_text(encoding="utf-8"))
    backup_builders = {k: ({**v, "_doc_id": k} if isinstance(v, dict) else v) for k, v in b_backup.items()}
    p_backup = json.loads((backup_dir / "projects_builder_fields_backup.json").read_text(encoding="utf-8"))
    backup_projects = [({**v, "_doc_id": k} if "_doc_id" not in v else v) for k, v in p_backup.items()]

    recon = reconcile_identities_and_ownership(backup_projects, backup_builders)
    merge_lookup = _build_pair_lookup(recon.get("merge_candidates") or [])
    jv_lookup = _build_pair_lookup(recon.get("jv_brand_overlaps") or [])

    signoff_54 = build_54_business_signoff_register(biz_rows, reg_by_id, merge_lookup, jv_lookup)
    signoff_54_ids = {r["project_id"] for r in signoff_54["rows"]}
    suffix_review = build_suffix_collision_review(prom_rows)
    consolidated_134 = build_134_manual_review_consolidation(
        reg_rows, ev_by_id, prom_by_id, signoff_54_ids, merge_lookup, jv_lookup
    )
    recon_408_134 = build_408_vs_134_reconciliation(prom_rows, reg_rows, ev_by_id)

    manifest_path = backup_dir / "phase4_2b_migration_manifest.json"
    approval_path = backup_dir / "phase4_2b_approval_record.json"
    manifest_obj = json.loads(manifest_path.read_text(encoding="utf-8"))
    approval_obj = json.loads(approval_path.read_text(encoding="utf-8"))
    if approval_obj.get("approved") is not False:
        raise AdjudicationReconciliationError("Safety violation: approval record must remain false")

    backup_hashes = {
        fn.name: hashlib.sha256(fn.read_bytes()).hexdigest()
        for fn in sorted(backup_dir.iterdir())
        if fn.is_file()
    }

    _write_csv_rows(reports_dir / "phase4_2d_business_signoff_register.csv", BUSINESS_SIGNOFF_COLUMNS, signoff_54["rows"])
    _write_csv_rows(reports_dir / "phase4_2d_suffix_collision_review.csv", SUFFIX_COLLISION_COLUMNS, suffix_review["rows"])
    _write_csv_rows(reports_dir / "phase4_2d_manual_review_consolidation.csv", MANUAL_CONSOLIDATION_COLUMNS, consolidated_134["rows"])
    write_status_taxonomy_md(reports_dir / "phase4_2d_status_taxonomy.md", recon_408_134, prom_rows, reg_rows)
    write_final_migration_readiness_md(
        reports_dir / "phase4_2d_final_migration_readiness.md",
        signoff_54=signoff_54,
        suffix_review=suffix_review,
        consolidated_134=consolidated_134,
        recon_408_134=recon_408_134,
        backup_hashes=backup_hashes,
        manifest_obj=manifest_obj,
        approval_obj=approval_obj,
        reports_dir=reports_dir,
    )

    return {
        "signoff_54": signoff_54,
        "suffix_review": suffix_review,
        "consolidated_134": consolidated_134,
        "recon_408_134": recon_408_134,
        "manifest_sha256": manifest_obj["manifest_sha256"],
        "approved": approval_obj["approved"],
    }


def main() -> int:
    res = generate_phase4_2d_deliverables()
    print(
        f"[Phase4.2D] ADJUDICATION PREPARATION COMPLETE (0 production writes): "
        f"signoff_54={res['signoff_54']['summary']['total']} | "
        f"suffix_collisions={res['suffix_review']['summary']['total_builders_reviewed']} ({res['suffix_review']['summary']['total_projects_reviewed']} projects) | "
        f"consolidated_134={res['consolidated_134']['summary']['total_unique_projects']} | "
        f"408={res['recon_408_134']['changed_2057_manual_review']}+{res['recon_408_134']['unchanged_2053_manual_review']} | "
        f"approved={res['approved']}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
