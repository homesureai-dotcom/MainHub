#!/usr/bin/env python3
"""
HomeSure Phase 4.2C — Canonical Promoter Identity Governance, Complete 2,057-Row
Review Reconciliation, Chunk Membership Audit & Unmanaged Field Preservation.
"""

from __future__ import annotations

import copy
import datetime
import hashlib
import json
import re
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

from build_and_upload_builders import build_builders_catalog_from_projects
from import_projects import firestore_value_to_python
from name_normalization import normalize_corporate_entity_name, resolve_builder_identity
from phase4_2b_verification import (
    MANAGED_BUILDER_DOC_FIELDS,
    _canonical_sha256,
    _simulate_project_patches,
)

PROMOTER_IDENTITY_TYPES = frozenset(
    {
        "KRERA_REGISTERED_PROMOTER",
        "FEATURED_BRAND",
        "JOINT_VENTURE",
        "UNKNOWN",
    }
)

IDENTITY_VERIFICATION_STATUSES = frozenset(
    {
        "SOURCE_BACKED",
        "NORMALIZED_FROM_SOURCE",
        "MANUAL_REVIEW_REQUIRED",
        "UNVERIFIED_EXTERNAL_ENTITY",
    }
)

CORPORATE_VERIFICATION_CLAIM_NONE = "NONE_CLAIMED_NO_MCA_GSTIN_VERIFICATION"

MANAGED_BUILDER_PROJECT_SUMMARY_FIELDS = frozenset(
    {
        "project_id",
        "project_name",
        "official_project_name",
        "normalized_project_name",
        "project_aliases",
        "promoter_name",
        "district",
        "taluk",
        "normalized_taluk",
        "city",
        "registration_number",
        "acknowledgement_number",
        "project_type",
        "regulatory_status",
        "approved_on",
        "proposed_completion_date",
        "project_start_date",
        "total_units",
        "total_towers",
        "total_documents",
        "total_complaints",
        "data_tier",
    }
)

COMPLETE_REGISTER_COLUMNS = [
    "project_id",
    "registration_number",
    "project_name",
    "original_builder_id",
    "corrected_builder_id",
    "original_promoter_name",
    "corrected_promoter_name",
    "canonical_promoter_name",
    "classification",
    "confidence_level",
    "review_status",
    "review_reason",
    "source_record_id",
    "source_file",
    "source_record_hash",
    "source_uri",
    "advisory_type",
    "reviewer_decision",
    "reviewer_notes",
]

CHUNK_AUDIT_COLUMNS = [
    "builder_id",
    "chunk_id",
    "expected_payload_hash",
    "actual_payload_hash",
    "expected_project_count",
    "actual_project_count",
    "expected_project_ids_hash",
    "actual_project_ids_hash",
    "membership_match",
    "comparison_result",
]

PROMOTER_AUDIT_COLUMNS = [
    "project_id",
    "registration_number",
    "project_name",
    "official_promoter_name",
    "normalized_promoter_name",
    "canonical_promoter_name",
    "promoter_aliases",
    "aliases_provenance_note",
    "promoter_identity_type",
    "identity_verification_status",
    "original_builder_id",
    "corrected_builder_id",
    "relationship_change",
    "in_499_register",
    "in_2057_changed",
    "differs_beyond_case_whitespace",
    "differs_alnum_substantive",
    "has_pvt_ltd_variant",
    "has_llp_suffix",
    "has_ms_prefix",
    "corporate_suffix_removed",
    "distinct_official_promoters_under_canonical_id",
    "corporate_verification_claim",
    "source_record_id",
    "source_file",
    "source_record_hash",
    "source_uri",
]

BUSINESS_DECISIONS_COLUMNS = [
    "project_id",
    "registration_number",
    "project_name",
    "classification",
    "original_builder_id",
    "corrected_builder_id",
    "original_builder_name",
    "corrected_builder_name",
    "official_promoter_name",
    "canonical_promoter_name",
    "promoter_identity_type",
    "identity_verification_status",
    "grouping_supported_by_krera_evidence",
    "evidence_distinction_category",
    "in_merge_candidate_pair",
    "in_jv_overlap_pair",
    "short_prefix_advisory",
    "corporate_suffix_changed",
    "source_record_id",
    "source_file",
    "source_record_hash",
    "source_uri",
    "decision_status",
    "recommended_action",
    "human_signoff_required",
    "rationale",
]

UNMANAGED_AUDIT_COLUMNS = [
    "document_path",
    "builder_id",
    "operation_type",
    "is_retained_active_doc",
    "original_top_level_fields",
    "proposed_top_level_fields",
    "unmanaged_top_level_fields_found",
    "unmanaged_nested_fields_found",
    "null_fields_in_original",
    "fields_added",
    "fields_changed",
    "fields_removed",
    "unmanaged_fields_status",
    "determination",
    "comparison_result",
]

_PVT_LTD_RE = re.compile(r"\b(?:private|pvt\.?|p\.?)\s*(?:limited|ltd\.?)\b", re.I)
_LLP_RE = re.compile(r"\b(?:llp|limited\s+liability\s+partnership)\b", re.I)
_MS_PREFIX_RE = re.compile(r"^\s*m\s*/?\s*s\.?(?=\s|[a-zA-Z])", re.I)
_CORP_SUFFIX_RE = re.compile(
    r"\b(?:private|pvt\.?|p\.?|limited|ltd\.?|llp|inc\.?|corp\.?|corporation|co\.?)\b",
    re.I,
)


class ChunkMembershipAuditError(RuntimeError):
    """Raised when chunk builder membership, duplicates, project assignment, or metadata fail verification."""


class UnauthorizedFieldRemovalError(RuntimeError):
    """Raised when a previously present field would be dropped without explicit authorization."""


class ReviewReconciliationError(RuntimeError):
    """Raised when the 2,057-row identity review register cannot reconcile exact counts."""


def _norm_case_ws(text: Optional[str]) -> str:
    return re.sub(r"\s+", " ", (text or "").strip()).lower()


def _norm_alnum_compact(text: Optional[str]) -> str:
    return re.sub(r"[^a-z0-9]", "", (text or "").lower())


def _extract_doc_id(doc: Dict[str, Any]) -> str:
    return str(doc.get("_doc_id") or doc.get("project_id") or "").strip()


def _has_valid_source(ev: Dict[str, Any]) -> bool:
    return bool(
        ev.get("source_promoter_matches_live")
        and ev.get("source_file")
        and ev.get("source_record_hash")
        and ev.get("source_record_id")
    )


def _jv_builder_id_set(recon: Dict[str, Any]) -> Set[str]:
    bids: Set[str] = set()
    for jv in recon.get("jv_brand_overlaps") or []:
        bids.update(str(b) for b in (jv.get("builder_ids") or []) if b)
    return bids


def _merge_builder_id_set(recon: Dict[str, Any]) -> Set[str]:
    bids: Set[str] = set()
    for mc in recon.get("merge_candidates") or []:
        bids.update(str(b) for b in (mc.get("builder_ids") or []) if b)
    return bids


def _resolve_project_identity(pdoc: Dict[str, Any], pr: Dict[str, Any]) -> Dict[str, Any]:
    p_name = str(pdoc.get("officialProjectName") or pdoc.get("project_name") or pr.get("project_name") or "").strip()
    prom_name = str(
        pdoc.get("officialBuilderName") or pdoc.get("promoter_name") or pr.get("promoter_name") or ""
    ).strip()
    reg_no = str(pdoc.get("registration_number") or pr.get("registration_number") or "").strip()
    return resolve_builder_identity(p_name, prom_name, reg_no)


def _classify_project_change(
    pr: Dict[str, Any],
    ev: Dict[str, Any],
    intersects_jv: bool,
) -> str:
    rel = pr["relationship_change"]
    conf = str(pr.get("confidence_level") or "")
    mechanism = str(ev.get("assignment_mechanism") or "")
    has_valid_src = _has_valid_source(ev)
    orig_bid = pr["existing_builder_id"]
    corr_bid = pr["corrected_builder_id"]
    orig_bname = pr["existing_canonical_name"]
    corr_bname = pr["corrected_canonical_name"]

    if mechanism == "MANUAL_REVIEW_REQUIRED" or not has_valid_src or conf == "unresolved":
        return "UNRESOLVED_IDENTITY"
    if rel == "OWNERSHIP_CHANGE":
        return "OWNERSHIP_REASSIGNMENT"
    if rel == "SPLIT_ENTITY_SEPARATION":
        return "BRAND_PROMOTER_RELATIONSHIP" if intersects_jv else "PROMOTER_ENTITY_SPLIT"
    if orig_bid == corr_bid and orig_bname != corr_bname:
        return "DISPLAY_NAME_NORMALIZATION"
    return "SLUG_ONLY_CHANGE"


# ---------------------------------------------------------------------------
# Workstream A — Canonical Promoter Identity Model Audit (all 4,110 projects)
# ---------------------------------------------------------------------------

def build_promoter_name_normalization_audit(
    recon: Dict[str, Any],
    evidence_audit: Dict[str, Any],
    projects: List[Dict[str, Any]],
) -> Dict[str, Any]:
    """
    Audit all projects separating unmodified K-RERA `official_promoter_name` from
    `canonical_promoter_name`, recording `promoter_aliases`, `promoter_identity_type`,
    `identity_verification_status`, and corporate suffix normalization flags without
    mutating the canonical identity mapping or claiming MCA/GSTIN verification.
    """
    proj_by_id = {_extract_doc_id(p): p for p in projects}
    ev_by_id = {str(r["project_id"]): r for r in (evidence_audit.get("rows") or [])}
    jv_bids = _jv_builder_id_set(recon)
    merge_bids = _merge_builder_id_set(recon)

    official_promoters_by_bid: Dict[str, Set[str]] = defaultdict(set)
    folded_promoters_by_bid: Dict[str, Set[str]] = defaultdict(set)
    canonical_name_by_bid: Dict[str, str] = {}
    project_records_prepared: List[Tuple[Dict[str, Any], Dict[str, Any], Dict[str, Any], Dict[str, Any], str]] = []

    for pr in sorted(recon.get("project_rows") or [], key=lambda x: str(x["project_id"])):
        pid = str(pr["project_id"])
        ev = ev_by_id.get(pid) or {}
        pdoc = proj_by_id.get(pid) or {}
        binfo = _resolve_project_identity(pdoc, pr)

        # Preserve exact K-RERA official promoter string without normalization.
        raw_official = (
            ev.get("original_portal_promoter_name")
            or pdoc.get("officialBuilderName")
            or pdoc.get("promoter_name")
            or pr.get("promoter_name")
            or ""
        )
        official_promoter = str(raw_official)
        corr_bid = str(pr["corrected_builder_id"])
        canonical_name = str(pr["corrected_canonical_name"])
        if official_promoter.strip():
            official_promoters_by_bid[corr_bid].add(official_promoter.strip())
            folded_promoters_by_bid[corr_bid].add(_norm_case_ws(official_promoter))
        canonical_name_by_bid[corr_bid] = canonical_name
        project_records_prepared.append((pr, ev, pdoc, binfo, official_promoter))

    rows: List[Dict[str, Any]] = []
    by_id: Dict[str, Dict[str, Any]] = {}
    id_type_counts: Counter[str] = Counter()
    ver_status_counts: Counter[str] = Counter()
    diff_cw_all = 0
    diff_cw_changed = 0
    diff_cw_499 = 0
    diff_substantive_499 = 0
    pvt_ltd_count = 0
    llp_count = 0
    ms_prefix_count = 0
    suffix_removed_count = 0

    for pr, ev, pdoc, binfo, official_promoter in project_records_prepared:
        pid = str(pr["project_id"])
        rel = str(pr["relationship_change"])
        orig_bid = str(pr["existing_builder_id"])
        corr_bid = str(pr["corrected_builder_id"])
        canonical_promoter = str(pr["corrected_canonical_name"])
        norm_promoter = str(ev.get("normalized_promoter_name") or normalize_corporate_entity_name(official_promoter) or official_promoter)
        has_valid_src = _has_valid_source(ev) if ev else bool(official_promoter.strip())

        intersects_jv = bool(orig_bid in jv_bids or corr_bid in jv_bids or ev.get("in_jv_overlap_pair"))
        intersects_merge = bool(corr_bid in merge_bids or ev.get("in_merge_candidate_pair"))
        is_short_prefix = bool(binfo.get("needs_manual_review"))
        conf = str(pr.get("confidence_level") or binfo.get("name_normalization_confidence") or "")

        if not official_promoter.strip() or (ev and not has_valid_src):
            identity_type = "UNKNOWN"
        elif intersects_jv:
            identity_type = "JOINT_VENTURE"
        elif bool(binfo.get("is_featured_brand")):
            identity_type = "FEATURED_BRAND"
        else:
            identity_type = "KRERA_REGISTERED_PROMOTER"

        if ev and not has_valid_src:
            verification_status = "UNVERIFIED_EXTERNAL_ENTITY"
        elif (
            is_short_prefix
            or intersects_jv
            or intersects_merge
            or rel == "OWNERSHIP_CHANGE"
            or conf in ("unresolved", "needs_manual_review", "manual_review_required")
        ):
            verification_status = "MANUAL_REVIEW_REQUIRED"
        elif _norm_case_ws(official_promoter) == _norm_case_ws(canonical_promoter) and identity_type == "KRERA_REGISTERED_PROMOTER":
            verification_status = "SOURCE_BACKED"
        else:
            verification_status = "NORMALIZED_FROM_SOURCE"

        assert identity_type in PROMOTER_IDENTITY_TYPES
        assert verification_status in IDENTITY_VERIFICATION_STATUSES

        diff_cw = _norm_case_ws(official_promoter) != _norm_case_ws(norm_promoter)
        diff_alnum = _norm_alnum_compact(official_promoter) != _norm_alnum_compact(norm_promoter)
        has_pvt_ltd = bool(_PVT_LTD_RE.search(official_promoter))
        has_llp = bool(_LLP_RE.search(official_promoter))
        has_ms = bool(_MS_PREFIX_RE.search(official_promoter))
        corp_suffix_removed = bool(
            (_CORP_SUFFIX_RE.search(official_promoter) or has_ms) and diff_cw
        )
        in_499 = rel in ("SPLIT_ENTITY_SEPARATION", "OWNERSHIP_CHANGE")
        in_2057 = rel != "UNCHANGED"
        distinct_promoters_count = len(official_promoters_by_bid.get(corr_bid, set()))

        if diff_cw:
            diff_cw_all += 1
            if in_2057:
                diff_cw_changed += 1
            if in_499:
                diff_cw_499 += 1
        if in_499 and diff_alnum:
            diff_substantive_499 += 1
        if has_pvt_ltd:
            pvt_ltd_count += 1
        if has_llp:
            llp_count += 1
        if has_ms:
            ms_prefix_count += 1
        if corp_suffix_removed:
            suffix_removed_count += 1

        id_type_counts[identity_type] += 1
        ver_status_counts[verification_status] += 1

        aliases = list(binfo.get("builder_aliases") or [])
        row = {
            "project_id": pid,
            "registration_number": str(pr.get("registration_number") or ""),
            "project_name": str(pr.get("project_name") or ""),
            "official_promoter_name": official_promoter,
            "normalized_promoter_name": norm_promoter,
            "canonical_promoter_name": canonical_promoter,
            "promoter_aliases": json.dumps(aliases, ensure_ascii=False),
            "aliases_provenance_note": "Derived from K-RERA portal promoter/brand rule only; aliases do not establish legal equivalence.",
            "promoter_identity_type": identity_type,
            "identity_verification_status": verification_status,
            "original_builder_id": orig_bid,
            "corrected_builder_id": corr_bid,
            "relationship_change": rel,
            "in_499_register": in_499,
            "in_2057_changed": in_2057,
            "differs_beyond_case_whitespace": diff_cw,
            "differs_alnum_substantive": diff_alnum,
            "has_pvt_ltd_variant": has_pvt_ltd,
            "has_llp_suffix": has_llp,
            "has_ms_prefix": has_ms,
            "corporate_suffix_removed": corp_suffix_removed,
            "distinct_official_promoters_under_canonical_id": distinct_promoters_count,
            "corporate_verification_claim": CORPORATE_VERIFICATION_CLAIM_NONE,
            "source_record_id": str(ev.get("source_record_id") or ""),
            "source_file": str(ev.get("source_file") or ""),
            "source_record_hash": str(ev.get("source_record_hash") or ""),
            "source_uri": str(ev.get("source_uri") or ""),
        }
        rows.append(row)
        by_id[pid] = row

    multi_promoter_builders = sorted(
        bid for bid, pset in official_promoters_by_bid.items() if len(pset) > 1
    )
    multi_folded_builders = sorted(
        bid for bid, pset in folded_promoters_by_bid.items() if len(pset) > 1
    )

    return {
        "rows": rows,
        "by_id": by_id,
        "summary": {
            "total_projects_audited": len(rows),
            "total_canonical_builders": len(canonical_name_by_bid),
            "differs_beyond_case_whitespace_all": diff_cw_all,
            "differs_beyond_case_whitespace_2057_changed": diff_cw_changed,
            "differs_beyond_case_whitespace_499_register": diff_cw_499,
            "differs_alnum_substantive_499_register": diff_substantive_499,
            "punctuation_only_diffs_in_499_register": diff_cw_499 - diff_substantive_499,
            "has_pvt_ltd_variant_count": pvt_ltd_count,
            "has_llp_suffix_count": llp_count,
            "has_ms_prefix_count": ms_prefix_count,
            "corporate_suffix_removed_count": suffix_removed_count,
            "canonical_ids_with_multiple_exact_promoters": len(multi_promoter_builders),
            "canonical_ids_with_multiple_folded_promoters": len(multi_folded_builders),
            "promoter_identity_type_counts": dict(id_type_counts),
            "identity_verification_status_counts": dict(ver_status_counts),
            "corporate_verification_claim": CORPORATE_VERIFICATION_CLAIM_NONE,
        },
    }


# ---------------------------------------------------------------------------
# Workstream B — Complete 2,057-Row Identity Review Reconciliation
# ---------------------------------------------------------------------------

def build_complete_2057_review_register(
    recon: Dict[str, Any],
    evidence_audit: Dict[str, Any],
    projects: List[Dict[str, Any]],
) -> Dict[str, Any]:
    """
    Build the exact one-row-per-changed-project review register (`2,057` rows),
    explicitly reconciling Phase 4.2B's `86` (`36` in 499 + `50` MERGE_CANDIDATE in slug-only)
    and surfacing all `SHORT_PREFIX_ADVISORY` (`needs_manual_review=True`) and `JV_BRAND_OVERLAP`
    flags without auto-approving or manufacturing any records.
    """
    proj_by_id = {_extract_doc_id(p): p for p in projects}
    ev_by_id = {str(r["project_id"]): r for r in (evidence_audit.get("rows") or [])}
    jv_bids = _jv_builder_id_set(recon)
    merge_bids = _merge_builder_id_set(recon)

    rows: List[Dict[str, Any]] = []
    by_id: Dict[str, Dict[str, Any]] = {}

    p42b_in_499_manual = 0
    p42b_in_slug_manual = 0
    p42b_total_pending = 0
    p42c_status_counts: Counter[str] = Counter()
    advisory_type_counts: Counter[str] = Counter()
    classification_counts: Counter[str] = Counter()
    short_prefix_by_rel: Counter[str] = Counter()
    jv_slug_only_count = 0

    # Verify 0 short-prefix flags exist inside UNCHANGED rows too so accounting is complete
    short_prefix_in_unchanged = 0

    for pr in sorted(recon.get("project_rows") or [], key=lambda x: str(x["project_id"])):
        pid = str(pr["project_id"])
        rel = str(pr["relationship_change"])
        ev = ev_by_id.get(pid) or {}
        pdoc = proj_by_id.get(pid) or {}
        binfo = _resolve_project_identity(pdoc, pr)
        is_short_prefix = bool(binfo.get("needs_manual_review"))

        if rel == "UNCHANGED":
            if is_short_prefix:
                short_prefix_in_unchanged += 1
            continue

        orig_bid = str(pr["existing_builder_id"])
        corr_bid = str(pr["corrected_builder_id"])
        canonical_prom = str(pr["corrected_canonical_name"])
        orig_prom = str(
            ev.get("original_portal_promoter_name")
            or pdoc.get("officialBuilderName")
            or pdoc.get("promoter_name")
            or pr.get("promoter_name")
            or ""
        )
        corr_prom = str(ev.get("normalized_promoter_name") or normalize_corporate_entity_name(orig_prom) or orig_prom)
        conf = str(pr.get("confidence_level") or binfo.get("name_normalization_confidence") or "")

        intersects_jv = bool(orig_bid in jv_bids or corr_bid in jv_bids or ev.get("in_jv_overlap_pair"))
        intersects_merge = bool(corr_bid in merge_bids or ev.get("in_merge_candidate_pair"))
        classification = _classify_project_change(pr, ev, intersects_jv)
        classification_counts[classification] += 1

        in_499 = rel in ("SPLIT_ENTITY_SEPARATION", "OWNERSHIP_CHANGE")

        # Reproduce exact Phase 4.2B status to reconcile 86 = 36 + 50 transparently
        if classification in ("OWNERSHIP_REASSIGNMENT", "BRAND_PROMOTER_RELATIONSHIP", "UNRESOLVED_IDENTITY") or intersects_merge or conf in ("needs_manual_review", "manual_review_required"):
            if in_499:
                p42b_in_499_manual += 1
            else:
                p42b_in_slug_manual += 1
        else:
            p42b_total_pending += 1

        # Explicit Phase 4.2C advisories
        advisories: List[str] = []
        if classification == "OWNERSHIP_REASSIGNMENT":
            advisories.append("OWNERSHIP_REASSIGNMENT")
        if intersects_jv:
            advisories.append("JV_BRAND_OVERLAP")
            if not in_499:
                jv_slug_only_count += 1
        if intersects_merge:
            advisories.append("MERGE_CANDIDATE_PAIR")
        if is_short_prefix:
            advisories.append("SHORT_PREFIX_ADVISORY")
            short_prefix_by_rel[rel] += 1
        if classification == "UNRESOLVED_IDENTITY":
            advisories.append("UNRESOLVED_SOURCE_EVIDENCE")

        advisory_str = "|".join(advisories) if advisories else "NONE"
        advisory_type_counts[advisory_str] += 1

        rev_status = "MANUAL_REVIEW_REQUIRED" if advisories else "PENDING_HUMAN_REVIEW"
        p42c_status_counts[rev_status] += 1

        if classification == "OWNERSHIP_REASSIGNMENT":
            reason = f"Brand/legacy ownership reassignment ({orig_bid} -> {corr_bid}) under '{orig_prom}'."
        elif classification == "BRAND_PROMOTER_RELATIONSHIP":
            reason = f"Promoter split ({orig_bid} -> {corr_bid}) intersecting known JV overlap; kept separate."
        elif classification == "PROMOTER_ENTITY_SPLIT":
            reason = f"Promoter entity split ({orig_bid} -> {corr_bid}) separating K-RERA promoter '{orig_prom}'."
        elif classification == "DISPLAY_NAME_NORMALIZATION":
            reason = f"Display normalization only under retained builder_id '{corr_bid}'."
        elif classification == "SLUG_ONLY_CHANGE":
            reason = f"Builder slug standardization ({orig_bid} -> {corr_bid}) for identical promoter '{orig_prom}'."
        else:
            reason = "Missing or unmatched K-RERA source evidence requiring manual verification."

        if advisories:
            notes = f"Active advisories: {', '.join(advisories)}. Source-backed in K-RERA; awaits human sign-off (0 auto-approved)."
        else:
            notes = "Source-backed K-RERA normalization; no special advisory; awaits batch human sign-off (0 auto-approved)."

        row = {
            "project_id": pid,
            "registration_number": str(pr.get("registration_number") or ""),
            "project_name": str(pr.get("project_name") or ""),
            "original_builder_id": orig_bid,
            "corrected_builder_id": corr_bid,
            "original_promoter_name": orig_prom,
            "corrected_promoter_name": corr_prom,
            "canonical_promoter_name": canonical_prom,
            "classification": classification,
            "confidence_level": conf,
            "review_status": rev_status,
            "review_reason": reason,
            "source_record_id": str(ev.get("source_record_id") or ""),
            "source_file": str(ev.get("source_file") or ""),
            "source_record_hash": str(ev.get("source_record_hash") or ""),
            "source_uri": str(ev.get("source_uri") or ""),
            "advisory_type": advisory_str,
            "reviewer_decision": "PENDING_HUMAN_DECISION",
            "reviewer_notes": notes,
        }
        rows.append(row)
        by_id[pid] = row

    expected_changed_total = sum(
        1 for pr in (recon.get("project_rows") or []) if pr.get("relationship_change") != "UNCHANGED"
    )
    if len(rows) != expected_changed_total:
        raise ReviewReconciliationError(
            f"Changed project count mismatch: register={len(rows)} != changed={expected_changed_total}"
        )

    p42b_total_manual = p42b_in_499_manual + p42b_in_slug_manual
    if p42b_total_manual + p42b_total_pending != len(rows):
        raise ReviewReconciliationError(
            f"Phase 4.2B review reconciliation sum mismatch: {p42b_total_manual} + {p42b_total_pending} != {len(rows)}"
        )

    total_short_prefix_projects = sum(short_prefix_by_rel.values())
    expected_short_prefix_from_recon = sum(
        len(sp.get("registrations") or []) for sp in (recon.get("short_prefix_reviews") or [])
    )
    if expected_short_prefix_from_recon and total_short_prefix_projects + short_prefix_in_unchanged != expected_short_prefix_from_recon:
        raise ReviewReconciliationError(
            f"Short-prefix advisory count mismatch: observed={total_short_prefix_projects + short_prefix_in_unchanged} != recon={expected_short_prefix_from_recon}"
        )

    return {
        "rows": rows,
        "by_id": by_id,
        "summary": {
            "total_changed_projects": len(rows),
            "phase4_2b_reconciliation": {
                "manual_review_required_total": p42b_total_manual,
                "manual_review_in_499_csv": p42b_in_499_manual,
                "manual_review_in_1558_slug_only": p42b_in_slug_manual,
                "discrepancy_explained": (
                    f"{p42b_in_slug_manual} MERGE_CANDIDATE intersections in SLUG_ONLY_CHANGE "
                    f"({p42b_in_499_manual} + {p42b_in_slug_manual} = {p42b_total_manual})"
                ),
                "pending_human_review_total": p42b_total_pending,
                "approved_total": 0,
            },
            "short_prefix_advisories": {
                "total_projects": total_short_prefix_projects,
                "in_unchanged_projects": short_prefix_in_unchanged,
                "builder_groups": len(recon.get("short_prefix_reviews") or []),
                "by_relationship_change": dict(short_prefix_by_rel),
            },
            "jv_brand_overlap_in_slug_only": jv_slug_only_count,
            "phase4_2c_review_status_counts": dict(p42c_status_counts),
            "advisory_type_counts": dict(advisory_type_counts),
            "classification_counts": dict(classification_counts),
            "auto_approved_count": 0,
        },
    }


# ---------------------------------------------------------------------------
# Workstream C — Business Identity Review (499 Split & Reassignment Cases)
# ---------------------------------------------------------------------------

def build_business_identity_decisions(
    recon: Dict[str, Any],
    evidence_audit: Dict[str, Any],
    promoter_audit: Dict[str, Any],
    complete_register: Dict[str, Any],
) -> Dict[str, Any]:
    """
    Build structured business-identity audit decisions for all `499` split and
    ownership reassignment rows while preserving legal entity distinctions and
    keeping merge candidates / JV overlaps completely unmerged.
    """
    ev_by_id = {str(r["project_id"]): r for r in (evidence_audit.get("rows") or [])}
    prom_by_id = promoter_audit["by_id"]
    reg_by_id = complete_register["by_id"]

    rows: List[Dict[str, Any]] = []
    class_counts: Counter[str] = Counter()
    support_counts: Counter[str] = Counter()
    distinction_counts: Counter[str] = Counter()

    for pr in sorted(recon.get("project_rows") or [], key=lambda x: str(x["project_id"])):
        rel = str(pr["relationship_change"])
        if rel not in ("SPLIT_ENTITY_SEPARATION", "OWNERSHIP_CHANGE"):
            continue

        pid = str(pr["project_id"])
        ev = ev_by_id.get(pid) or {}
        pa = prom_by_id[pid]
        rr = reg_by_id[pid]
        classification = rr["classification"]
        class_counts[classification] += 1

        in_merge = bool(ev.get("in_merge_candidate_pair") or "MERGE_CANDIDATE_PAIR" in rr["advisory_type"])
        in_jv = bool(ev.get("in_jv_overlap_pair") or "JV_BRAND_OVERLAP" in rr["advisory_type"])
        is_short = "SHORT_PREFIX_ADVISORY" in rr["advisory_type"]
        corp_changed = bool(pa["corporate_suffix_removed"] or pa["differs_beyond_case_whitespace"])

        if classification == "BRAND_PROMOTER_RELATIONSHIP":
            distinction = "BRAND_VS_REGISTERED_PROMOTER_JV"
            rec_action = "SEPARATE_PROMOTER_PRESERVE_JV_BOUNDARY"
        elif classification == "OWNERSHIP_REASSIGNMENT":
            distinction = "BRAND_OR_LEGACY_OWNERSHIP_REASSIGNMENT"
            rec_action = "INDIVIDUAL_PROMOTER_OWNERSHIP_SIGNOFF"
        elif bool(pa["differs_beyond_case_whitespace"]) and not bool(pa["differs_alnum_substantive"]):
            distinction = "PROMOTER_SPELLING_OR_PUNCTUATION_VARIANT"
            rec_action = "SPLIT_OVERMERGED_PROMOTER_PRESERVE_OFFICIAL"
        else:
            distinction = "DIFFERENT_REGISTERED_PROMOTER_SEPARATION"
            rec_action = "SPLIT_OVERMERGED_PROMOTER_ENTITY"
        distinction_counts[distinction] += 1

        has_valid_src = _has_valid_source(ev) if ev else bool(pa["source_record_hash"])
        if not has_valid_src:
            support = "INSUFFICIENT_SOURCE_EVIDENCE"
        elif classification in ("OWNERSHIP_REASSIGNMENT", "BRAND_PROMOTER_RELATIONSHIP") or in_merge or is_short:
            support = "REQUIRES_BUSINESS_SIGNOFF_SOURCE_PRESENT"
        else:
            support = "SUPPORTED_BY_KRERA_PROMOTER_RECORD"
        support_counts[support] += 1

        rationale = (
            f"Official K-RERA promoter '{pa['official_promoter_name']}' mapped from legacy '{pr['existing_builder_id']}' "
            f"to '{pr['corrected_builder_id']}' (canonical '{pa['canonical_promoter_name']}'). "
            f"No MCA/GSTIN corporate legal verification claimed; fuzzy matching alone never establishes legal equivalence."
        )

        rows.append(
            {
                "project_id": pid,
                "registration_number": str(pr.get("registration_number") or ""),
                "project_name": str(pr.get("project_name") or ""),
                "classification": classification,
                "original_builder_id": str(pr["existing_builder_id"]),
                "corrected_builder_id": str(pr["corrected_builder_id"]),
                "original_builder_name": str(pr["existing_canonical_name"]),
                "corrected_builder_name": str(pr["corrected_canonical_name"]),
                "official_promoter_name": pa["official_promoter_name"],
                "canonical_promoter_name": pa["canonical_promoter_name"],
                "promoter_identity_type": pa["promoter_identity_type"],
                "identity_verification_status": pa["identity_verification_status"],
                "grouping_supported_by_krera_evidence": support,
                "evidence_distinction_category": distinction,
                "in_merge_candidate_pair": in_merge,
                "in_jv_overlap_pair": in_jv,
                "short_prefix_advisory": is_short,
                "corporate_suffix_changed": corp_changed,
                "source_record_id": rr["source_record_id"],
                "source_file": rr["source_file"],
                "source_record_hash": rr["source_record_hash"],
                "source_uri": rr["source_uri"],
                "decision_status": "PENDING_BUSINESS_APPROVAL",
                "recommended_action": rec_action,
                "human_signoff_required": True,
                "rationale": rationale,
            }
        )

    return {
        "rows": rows,
        "summary": {
            "total_reviewed": len(rows),
            "classification_counts": dict(class_counts),
            "support_counts": dict(support_counts),
            "distinction_counts": dict(distinction_counts),
            "merge_candidates_kept_separate": len(recon.get("merge_candidates") or []),
            "jv_overlaps_kept_separate": len(recon.get("jv_brand_overlaps") or []),
            "auto_approved_count": 0,
        },
    }


# ---------------------------------------------------------------------------
# Workstream D — Complete Builder Chunk Membership Audit
# ---------------------------------------------------------------------------

def audit_chunk_membership_complete(
    pre_projects: List[Dict[str, Any]],
    manifest: Dict[str, Any],
) -> Dict[str, Any]:
    """
    Perform row-level membership, duplicate-builder, payload-hash, project-assignment,
    and `_catalog_meta` parity verification across all staged `_catalog_chunk_*` docs.
    """
    staged = manifest.get("staged_ops") or {}
    simulated_post_projects = _simulate_project_patches(
        pre_projects, staged.get("patch_projects") or []
    )
    expected_catalog = build_builders_catalog_from_projects(simulated_post_projects)
    expected_by_id = {str(b["builder_id"]): b for b in expected_catalog}

    # Build expected project_id -> expected builder_id map directly from simulated post projects
    expected_proj_to_builder: Dict[str, str] = {}
    for b in expected_catalog:
        bid = str(b["builder_id"])
        for pid in b.get("project_ids") or []:
            expected_proj_to_builder[str(pid)] = bid

    rows: List[Dict[str, Any]] = []
    seen_builders: Dict[str, List[str]] = defaultdict(list)
    seen_project_assignments: Dict[str, List[str]] = defaultdict(list)
    duplicate_builders: List[Dict[str, Any]] = []
    failures: List[Dict[str, Any]] = []

    chunk_ops = list(staged.get("write_catalog_chunks") or [])
    actual_chunk_ids: List[str] = []

    def _chunk_sort_key(op: Dict[str, Any]) -> int:
        cid = str((op.get("update") or {}).get("name") or "").split("/")[-1]
        m = re.search(r"_(\d+)$", cid)
        return int(m.group(1)) if m else 0

    for op in sorted(chunk_ops, key=_chunk_sort_key):
        full_name = str((op.get("update") or {}).get("name") or "")
        chunk_doc_id = full_name.split("/")[-1]
        actual_chunk_ids.append(chunk_doc_id)
        decoded = firestore_value_to_python(
            {"mapValue": {"fields": (op.get("update") or {}).get("fields", {})}}
        )
        chunk_builders = decoded.get("builders") or []
        declared_count = int(decoded.get("builders_count") or 0)
        if declared_count != len(chunk_builders):
            failures.append(
                {
                    "chunk_id": chunk_doc_id,
                    "reason": f"Chunk builders_count metadata {declared_count} != actual len(builders) {len(chunk_builders)}",
                }
            )

        for b in sorted(chunk_builders, key=lambda x: str(x.get("builder_id") or "")):
            bid = str(b.get("builder_id") or "")
            seen_builders[bid].append(chunk_doc_id)
            if len(seen_builders[bid]) > 1:
                duplicate_builders.append({"builder_id": bid, "chunks": list(seen_builders[bid])})

            actual_pids = [str(p) for p in (b.get("project_ids") or [])]
            for pid in actual_pids:
                seen_project_assignments[pid].append(bid)

            exp_b = expected_by_id.get(bid)
            act_payload_hash = _canonical_sha256(b)
            act_pids_hash = _canonical_sha256(sorted(actual_pids))

            if exp_b is None:
                exp_payload_hash = ""
                exp_count = 0
                exp_pids_hash = ""
                membership_ok = False
            else:
                exp_pids = [str(p) for p in (exp_b.get("project_ids") or [])]
                exp_payload_hash = _canonical_sha256(exp_b)
                exp_count = len(exp_pids)
                exp_pids_hash = _canonical_sha256(sorted(exp_pids))
                membership_ok = (
                    len(actual_pids) == len(set(actual_pids))
                    and sorted(actual_pids) == sorted(exp_pids)
                    and exp_count == int(b.get("project_count") or 0)
                    and act_payload_hash == exp_payload_hash
                )

            duplicate_for_builder = len(seen_builders[bid]) > 1
            row_ok = bool(membership_ok and not duplicate_for_builder)
            if not row_ok:
                failures.append(
                    {
                        "chunk_id": chunk_doc_id,
                        "builder_id": bid,
                        "reason": (
                            f"duplicate={duplicate_for_builder}, payload_match={exp_payload_hash == act_payload_hash}, "
                            f"pids_match={exp_pids_hash == act_pids_hash}"
                        ),
                    }
                )

            rows.append(
                {
                    "builder_id": bid,
                    "chunk_id": chunk_doc_id,
                    "expected_payload_hash": exp_payload_hash,
                    "actual_payload_hash": act_payload_hash,
                    "expected_project_count": exp_count,
                    "actual_project_count": len(actual_pids),
                    "expected_project_ids_hash": exp_pids_hash,
                    "actual_project_ids_hash": act_pids_hash,
                    "membership_match": row_ok,
                    "comparison_result": "MATCH" if row_ok else "MISMATCH",
                }
            )

    missing_builders = sorted(set(expected_by_id.keys()) - set(seen_builders.keys()))
    extra_builders = sorted(set(seen_builders.keys()) - set(expected_by_id.keys()))
    if missing_builders or extra_builders:
        failures.append(
            {
                "chunk_id": "_catalog_chunk_*",
                "reason": f"Builder set diff: missing={missing_builders[:5]}, extra={extra_builders[:5]}",
            }
        )

    # Check all projects (4,110) are assigned uniquely and accurately
    duplicate_project_assignments = {
        pid: bids for pid, bids in seen_project_assignments.items() if len(bids) != 1
    }
    missing_projects = sorted(set(expected_proj_to_builder.keys()) - set(seen_project_assignments.keys()))
    wrong_builder_projects = [
        pid
        for pid, exp_bid in expected_proj_to_builder.items()
        if seen_project_assignments.get(pid) != [exp_bid]
    ]
    if duplicate_project_assignments or missing_projects or wrong_builder_projects:
        failures.append(
            {
                "chunk_id": "_catalog_chunk_*",
                "reason": (
                    f"Project membership issues: dup={len(duplicate_project_assignments)}, "
                    f"missing={len(missing_projects)}, wrong_builder={len(wrong_builder_projects)}"
                ),
            }
        )

    # Verify _catalog_meta matches actual chunk contents
    meta_ops = list(staged.get("write_catalog_meta") or [])
    meta_match = False
    if len(meta_ops) == 1:
        meta = firestore_value_to_python(
            {"mapValue": {"fields": (meta_ops[0].get("update") or {}).get("fields", {})}}
        )
        expected_deep = sum(
            1 for b in expected_catalog for pr in b.get("projects") or [] if pr.get("data_tier") == "deep_extracted"
        )
        expected_total_proj = sum(int(b.get("project_count") or 0) for b in expected_catalog)
        meta_match = (
            int(meta.get("total_chunks") or 0) == len(chunk_ops)
            and list(meta.get("chunk_ids") or []) == actual_chunk_ids
            and int(meta.get("total_builders") or 0) == len(expected_catalog)
            and int(meta.get("total_projects") or 0) == expected_total_proj
            and int(meta.get("deep_extracted_projects") or 0) == expected_deep
            and int(meta.get("catalogue_summary_projects") or 0) == (expected_total_proj - expected_deep)
        )
    if not meta_match:
        failures.append({"chunk_id": "_catalog_meta", "reason": "Catalogue metadata does not match actual chunk contents"})

    return {
        "status": "PASS" if not failures else "FAIL",
        "rows": rows,
        "total_chunk_entries": len(rows),
        "unique_builders_in_chunks": len(seen_builders),
        "expected_unique_builders": len(expected_by_id),
        "duplicate_builders": duplicate_builders,
        "missing_builders": missing_builders,
        "extra_builders": extra_builders,
        "total_project_memberships": sum(len(v) for v in seen_project_assignments.values()),
        "unique_projects_in_chunks": len(seen_project_assignments),
        "expected_unique_projects": len(expected_proj_to_builder),
        "duplicate_project_assignments": duplicate_project_assignments,
        "missing_projects": missing_projects,
        "wrong_builder_projects": wrong_builder_projects,
        "meta_matches_chunks": meta_match,
        "mismatch_count": len(failures),
        "failures": failures,
    }


def verify_chunk_membership_complete(
    pre_projects: List[Dict[str, Any]],
    manifest: Dict[str, Any],
) -> Dict[str, Any]:
    """Strict wrapper raising ChunkMembershipAuditError on any chunk membership or duplicate failure."""
    res = audit_chunk_membership_complete(pre_projects, manifest)
    if res["status"] != "PASS":
        raise ChunkMembershipAuditError(
            f"Complete chunk membership audit failed ({res['mismatch_count']} failure(s)): {res['failures'][:3]}"
        )
    return res


# ---------------------------------------------------------------------------
# Workstream E — Recursive Unmanaged Field Preservation & Audit
# ---------------------------------------------------------------------------

def _preserve_nested_map(
    old_map: Dict[str, Any],
    new_map: Dict[str, Any],
    prefix: str,
    authorized_removed: Set[str],
    managed_subkeys: Optional[Set[str]] = None,
) -> Dict[str, Any]:
    """Merge maps while preserving unknown/unmanaged keys, explicit nulls, and nested unrelated maps."""
    out: Dict[str, Any] = {}
    for k, old_v in old_map.items():
        if k not in new_map:
            full_path = f"{prefix}.{k}" if prefix else k
            if managed_subkeys is not None and k in managed_subkeys and full_path not in authorized_removed:
                raise UnauthorizedFieldRemovalError(
                    f"Attempted unauthorized removal of managed nested field '{full_path}'"
                )
            if full_path in authorized_removed:
                continue
            out[k] = copy.deepcopy(old_v)
    for k, new_v in new_map.items():
        if k in old_map and isinstance(old_map[k], dict) and isinstance(new_v, dict):
            sub_prefix = f"{prefix}.{k}" if prefix else k
            out[k] = _preserve_nested_map(old_map[k], new_v, sub_prefix, authorized_removed)
        else:
            out[k] = copy.deepcopy(new_v)
    return out


def merge_preserving_unmanaged_fields(
    old_doc: Dict[str, Any],
    new_managed_doc: Dict[str, Any],
    *,
    managed_fields: Iterable[str] = MANAGED_BUILDER_DOC_FIELDS,
    authorized_removed_fields: Optional[Iterable[str]] = None,
) -> Dict[str, Any]:
    """
    Merge a proposed managed builder payload over an existing live/snapshot builder doc:
    - Preserves all top-level unmanaged/unknown fields and explicit `None` (`null`) values.
    - Recursively preserves unmanaged nested fields inside top-level dicts and inside `projects[]` items.
    - Rejects intentional removal of previously present managed fields unless explicitly listed in
      `authorized_removed_fields`.
    """
    managed_set = set(managed_fields)
    auth_removed = set(authorized_removed_fields or ())
    old_clean = {k: v for k, v in (old_doc or {}).items() if k != "_doc_id"}

    # Reject dropping any previously present top-level field (managed or unmanaged) unless authorized.
    for k in old_clean:
        if k in managed_set and k not in new_managed_doc and k not in auth_removed:
            raise UnauthorizedFieldRemovalError(
                f"Attempted unauthorized removal of managed field '{k}' without explicit authorization"
            )

    result: Dict[str, Any] = {}
    for k, v in old_clean.items():
        if k not in managed_set and k not in new_managed_doc and k not in auth_removed:
            result[k] = copy.deepcopy(v)

    for k, new_v in new_managed_doc.items():
        if k in old_clean and isinstance(old_clean[k], dict) and isinstance(new_v, dict):
            result[k] = _preserve_nested_map(old_clean[k], new_v, k, auth_removed)
        elif k == "projects" and isinstance(old_clean.get("projects"), list) and isinstance(new_v, list):
            old_by_pid = {
                str(item.get("project_id") or ""): item
                for item in old_clean["projects"]
                if isinstance(item, dict) and item.get("project_id")
            }
            merged_projects: List[Any] = []
            for item in new_v:
                if isinstance(item, dict) and str(item.get("project_id") or "") in old_by_pid:
                    old_item = old_by_pid[str(item["project_id"])]
                    merged_item = _preserve_nested_map(
                        old_item,
                        item,
                        "projects[]",
                        auth_removed,
                        managed_subkeys=set(MANAGED_BUILDER_PROJECT_SUMMARY_FIELDS),
                    )
                    merged_projects.append(merged_item)
                else:
                    merged_projects.append(copy.deepcopy(item))
            result[k] = merged_projects
        else:
            result[k] = copy.deepcopy(new_v)

    return result


def audit_unmanaged_fields(
    existing_builders_docs: Dict[str, Dict[str, Any]],
    manifest: Dict[str, Any],
    retained_active_ids: Optional[Iterable[str]] = None,
) -> Dict[str, Any]:
    """
    Audit all `UPDATE` builder operations (including all retained active canonical docs)
    to determine explicitly whether unmanaged/unknown/null/nested fields exist in live data
    and verify zero field loss across original vs proposed payloads.
    """
    retained_set = set(retained_active_ids or manifest.get("retained_active_individual_builder_ids") or ())
    update_ops = (manifest.get("staged_ops") or {}).get("update_builder_docs") or []

    rows: List[Dict[str, Any]] = []
    docs_with_unmanaged = 0
    docs_with_removals = 0
    retained_audited = 0

    for op in sorted(update_ops, key=lambda o: str((o.get("update") or {}).get("name") or "")):
        full_name = str((op.get("update") or {}).get("name") or "")
        bid = full_name.split("/")[-1]
        doc_path = f"builders/{bid}"
        proposed = firestore_value_to_python({"mapValue": {"fields": (op.get("update") or {}).get("fields", {})}})
        old_raw = existing_builders_docs.get(bid) or {}
        old_clean = {k: v for k, v in old_raw.items() if k != "_doc_id"}

        unmanaged_top = sorted(k for k in old_clean if k not in MANAGED_BUILDER_DOC_FIELDS)
        unmanaged_nested_found: List[str] = []
        nested_preserved = True

        if isinstance(old_clean.get("projects"), list) and isinstance(proposed.get("projects"), list):
            prop_by_pid = {
                str(it.get("project_id") or ""): it
                for it in proposed["projects"]
                if isinstance(it, dict) and it.get("project_id")
            }
            for old_it in old_clean["projects"]:
                if isinstance(old_it, dict) and str(old_it.get("project_id") or "") in prop_by_pid:
                    prop_it = prop_by_pid[str(old_it["project_id"])]
                    unmanaged_keys = sorted(set(old_it.keys()) - MANAGED_BUILDER_PROJECT_SUMMARY_FIELDS)
                    for ek in unmanaged_keys:
                        unmanaged_nested_found.append(f"projects[{old_it['project_id']}].{ek}")
                        if ek not in prop_it or prop_it[ek] != old_it[ek]:
                            nested_preserved = False
                    # Also flag any standard key dropped unexpectedly
                    for mk in sorted(set(old_it.keys()) - set(prop_it.keys())):
                        if mk in MANAGED_BUILDER_PROJECT_SUMMARY_FIELDS:
                            nested_preserved = False

        null_fields = sorted(k for k, v in old_clean.items() if v is None)
        added = sorted(set(proposed.keys()) - set(old_clean.keys()))
        removed = sorted(set(old_clean.keys()) - set(proposed.keys()))
        changed = sorted(k for k in (set(old_clean.keys()) & set(proposed.keys())) if old_clean[k] != proposed[k])

        top_unmanaged_preserved = all(
            uk in proposed and proposed[uk] == old_clean[uk] for uk in unmanaged_top
        )
        all_unmanaged_preserved = top_unmanaged_preserved and nested_preserved
        ok = all_unmanaged_preserved and (len(removed) == 0)

        if unmanaged_top or unmanaged_nested_found:
            docs_with_unmanaged += 1
            status = "PRESERVED" if all_unmanaged_preserved else "LOST_OR_MODIFIED"
            determination = (
                "UNMANAGED_FIELDS_EXIST_AND_PRESERVED"
                if all_unmanaged_preserved
                else "UNMANAGED_FIELDS_LOST_FAIL"
            )
        else:
            status = "NONE_PRESENT"
            determination = "NO_UNMANAGED_FIELDS_EXIST_IN_LIVE_DOC"

        if removed:
            docs_with_removals += 1
        is_retained = bid in retained_set
        if is_retained:
            retained_audited += 1

        rows.append(
            {
                "document_path": doc_path,
                "builder_id": bid,
                "operation_type": "UPDATE",
                "is_retained_active_doc": is_retained,
                "original_top_level_fields": "|".join(sorted(old_clean.keys())),
                "proposed_top_level_fields": "|".join(sorted(proposed.keys())),
                "unmanaged_top_level_fields_found": "|".join(unmanaged_top) if unmanaged_top else "NONE",
                "unmanaged_nested_fields_found": "|".join(unmanaged_nested_found) if unmanaged_nested_found else "NONE",
                "null_fields_in_original": "|".join(null_fields) if null_fields else "NONE",
                "fields_added": "|".join(added) if added else "NONE",
                "fields_changed": "|".join(changed) if changed else "NONE",
                "fields_removed": "|".join(removed) if removed else "NONE",
                "unmanaged_fields_status": status,
                "determination": determination,
                "comparison_result": "MATCH" if ok else "MISMATCH",
            }
        )

    return {
        "status": "PASS" if all(r["comparison_result"] == "MATCH" for r in rows) else "FAIL",
        "updates_audited": len(rows),
        "retained_active_audited": retained_audited,
        "docs_with_unmanaged_fields": docs_with_unmanaged,
        "docs_with_field_removals": docs_with_removals,
        "rows": rows,
    }
