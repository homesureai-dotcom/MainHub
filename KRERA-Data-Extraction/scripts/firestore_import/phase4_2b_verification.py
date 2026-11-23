#!/usr/bin/env python3
"""
HomeSure Phase 4.2B — Identity Change Review, Exact Per-Project Invariants,
Exact Builder Payload Verification, Two-Stage Approval Hardening & Deferred Docs Review.
"""

from __future__ import annotations

import copy
import datetime
import hashlib
import json
import sys
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Set, Tuple

WORKSPACE_ROOT = Path(__file__).resolve().parents[3]
EXTRACTION_ROOT = WORKSPACE_ROOT / "KRERA-Data-Extraction"
SCRIPTS_ROOT = EXTRACTION_ROOT / "scripts"
for _p in (str(SCRIPTS_ROOT), str(Path(__file__).resolve().parent)):
    if _p not in sys.path:
        sys.path.insert(0, _p)

from build_and_upload_builders import build_builders_catalog_from_projects
from import_projects import (
    FIREBASE_PROJECT_ID,
    FIRESTORE_DATABASE,
    firestore_value_to_python,
)
from name_normalization import resolve_builder_identity

MANIFEST_SCHEMA_VERSION_V2_1 = "2.1.0"
MIGRATION_VERSION_V2_1 = "phase4_2b_builder_sync_v2_1"
APPROVAL_MODEL_TWO_STAGE = "two_stage_external_record"
DEFAULT_APPROVAL_SCOPE = (
    "Stage 1 create_builder_docs + Stage 2 update_builder_docs (preserving unmanaged fields & retaining "
    "8 active canonical docs) + Stage 3 field-masked patch_projects + Stage 4 write_catalog_chunks + "
    "Stage 5 write_catalog_meta (deletions_enabled=false)"
)

MANAGED_BUILDER_DOC_FIELDS = frozenset(
    {
        "builder_id",
        "builder_name",
        "normalized_builder_name",
        "is_featured_brand",
        "builder_aliases",
        "legal_promoter_names",
        "localities",
        "project_count",
        "project_ids",
        "projects",
    }
)

PROJECT_INVARIANT_FIELDS = (
    "project_id",
    "registration_number",
    "project_name",
    "taluk",
    "district",
    "data_tier",
    "extraction_status",
    "regulatory_bundle_reference",
    "regulatory_provenance",
)

IDENTITY_CLASSIFICATIONS = frozenset(
    {
        "DISPLAY_NAME_NORMALIZATION",
        "SLUG_ONLY_CHANGE",
        "PROMOTER_ENTITY_SPLIT",
        "OWNERSHIP_REASSIGNMENT",
        "BRAND_PROMOTER_RELATIONSHIP",
        "UNRESOLVED_IDENTITY",
    }
)


class ApprovalValidationError(RuntimeError):
    """Raised when Stage 2 explicit human authorization is invalid or unbound."""


class ProjectInvariantError(RuntimeError):
    """Raised when any single project fails exact immutable invariant comparison."""


class BuilderPayloadError(RuntimeError):
    """Raised when any builder document payload or exact project membership fails verification."""


def _canonical_sha256(obj: Any) -> str:
    raw = json.dumps(obj, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    return hashlib.sha256(raw).hexdigest()


# ---------------------------------------------------------------------------
# Workstream A — Detailed Identity Change Review (494 splits + 5 reassignments)
# ---------------------------------------------------------------------------

def build_identity_change_review(
    recon: Dict[str, Any],
    evidence_audit: Dict[str, Any],
    projects: List[Dict[str, Any]],
) -> Dict[str, Any]:
    """
    Separate all changed projects into the 6 explicit Phase 4.2B classifications,
    and build the review register covering all 494 split cases and 5 ownership changes
    without auto-approving records merely because a source row exists.
    """
    proj_by_id = {str(p.get("_doc_id") or p.get("project_id") or ""): p for p in projects}
    ev_by_id = {r["project_id"]: r for r in (evidence_audit.get("rows") or [])}

    jv_bids: Set[str] = set()
    for jv in recon.get("jv_brand_overlaps") or []:
        jv_bids.update(jv.get("builder_ids") or [])

    classification_counts: Dict[str, int] = {k: 0 for k in sorted(IDENTITY_CLASSIFICATIONS)}
    evidence_tier_counts = {
        "direct_source_evidence": 0,
        "fallback_only_evidence": 0,
        "missing_or_unmatched_evidence": 0,
    }
    review_status_counts: Dict[str, int] = {}
    review_rows: List[Dict[str, Any]] = []
    all_changed_classified: List[Dict[str, Any]] = []

    split_case_count = 0
    ownership_change_count = 0

    for pr in recon.get("project_rows") or []:
        rel = pr["relationship_change"]
        if rel == "UNCHANGED":
            continue

        pid = pr["project_id"]
        ev = ev_by_id.get(pid) or {}
        pdoc = proj_by_id.get(pid) or {}

        orig_bid = pr["existing_builder_id"]
        corr_bid = pr["corrected_builder_id"]
        orig_bname = pr["existing_canonical_name"]
        corr_bname = pr["corrected_canonical_name"]
        orig_prom = ev.get("original_portal_promoter_name") or pr["promoter_name"]
        corr_prom = ev.get("normalized_promoter_name") or orig_prom
        conf = pr.get("confidence_level") or ""
        mechanism = ev.get("assignment_mechanism") or ""
        has_valid_src = bool(ev.get("source_promoter_matches_live") and ev.get("source_file") and ev.get("source_record_hash"))
        intersects_jv = bool(orig_bid in jv_bids or corr_bid in jv_bids or ev.get("in_jv_overlap_pair"))
        intersects_merge = bool(ev.get("in_merge_candidate_pair"))

        if mechanism == "MANUAL_REVIEW_REQUIRED" or not has_valid_src or conf == "unresolved":
            classification = "UNRESOLVED_IDENTITY"
        elif rel == "OWNERSHIP_CHANGE":
            classification = "OWNERSHIP_REASSIGNMENT"
        elif rel == "SPLIT_ENTITY_SEPARATION":
            classification = "BRAND_PROMOTER_RELATIONSHIP" if intersects_jv else "PROMOTER_ENTITY_SPLIT"
        elif orig_bid == corr_bid and orig_bname != corr_bname:
            classification = "DISPLAY_NAME_NORMALIZATION"
        else:
            classification = "SLUG_ONLY_CHANGE"

        classification_counts[classification] = classification_counts.get(classification, 0) + 1

        if not has_valid_src:
            evidence_tier_counts["missing_or_unmatched_evidence"] += 1
        elif mechanism == "EXPLICIT_BRAND_RULE_SOURCE_BACKED":
            evidence_tier_counts["direct_source_evidence"] += 1
        else:
            evidence_tier_counts["fallback_only_evidence"] += 1

        # Strict non-auto-approval rule: source record alone NEVER marks a change approved
        if classification in ("OWNERSHIP_REASSIGNMENT", "BRAND_PROMOTER_RELATIONSHIP", "UNRESOLVED_IDENTITY"):
            rev_status = "MANUAL_REVIEW_REQUIRED"
        elif intersects_merge or conf in ("needs_manual_review", "manual_review_required"):
            rev_status = "MANUAL_REVIEW_REQUIRED"
        elif classification == "PROMOTER_ENTITY_SPLIT":
            rev_status = "PENDING_HUMAN_REVIEW"
        else:
            rev_status = "PENDING_HUMAN_REVIEW"

        review_status_counts[rev_status] = review_status_counts.get(rev_status, 0) + 1

        if classification == "OWNERSHIP_REASSIGNMENT":
            proposed_action = "REASSIGN_PROJECT_PROMOTER_IDENTITY"
            reason = (
                f"Brand-to-promoter or legacy group reassignment ({orig_bid} -> {corr_bid}) under K-RERA promoter "
                f"'{orig_prom}'. {pr['evidence']} Requires individual human sign-off."
            )
        elif classification == "BRAND_PROMOTER_RELATIONSHIP":
            proposed_action = "SEPARATE_PROMOTER_PRESERVING_JV_SEPARATION"
            reason = (
                f"Over-merged slug split ({orig_bid} -> {corr_bid}) intersecting known brand-vs-promoter JV overlap; "
                "promoter separated without auto-merging featured brand."
            )
        elif classification == "PROMOTER_ENTITY_SPLIT":
            proposed_action = "SPLIT_OVERMERGED_PROMOTER_IDENTITY"
            reason = (
                f"Separated K-RERA promoter '{orig_prom}' from over-merged group '{orig_bid}' into '{corr_bid}'. "
                "Verified against K-RERA source record; pending human business sign-off."
            )
        elif classification == "SLUG_ONLY_CHANGE":
            proposed_action = "STANDARDIZE_BUILDER_ID_SLUG"
            reason = f"Identifier slug standardization only ({orig_bid} -> {corr_bid}); display name '{orig_bname}' unchanged."
        elif classification == "DISPLAY_NAME_NORMALIZATION":
            proposed_action = "NORMALIZE_DISPLAY_TITLE_ONLY"
            reason = f"Display normalization without legal entity change ('{orig_bname}' -> '{corr_bname}')."
        else:
            proposed_action = "HOLD_UNRESOLVED_FOR_MANUAL_REVIEW"
            reason = "Missing/unmatched K-RERA source evidence or unresolved promoter identity."

        entry = {
            "project_id": pid,
            "project_name": pr["project_name"],
            "registration_number": pr["registration_number"],
            "taluk": pdoc.get("normalizedTaluk") or pr["taluk"],
            "original_builder_id": orig_bid,
            "corrected_builder_id": corr_bid,
            "original_builder_name": orig_bname,
            "corrected_builder_name": corr_bname,
            "original_promoter_name": orig_prom,
            "corrected_promoter_name": corr_prom,
            "source_record_id": ev.get("source_record_id") or "",
            "source_file": ev.get("source_file") or "",
            "source_record_hash": ev.get("source_record_hash") or "",
            "source_uri": ev.get("source_uri") or "",
            "confidence_level": conf,
            "classification": classification,
            "proposed_action": proposed_action,
            "review_status": rev_status,
            "review_reason": reason,
            "_reconciliation_rel": rel,
        }
        all_changed_classified.append(entry)

        if rel in ("SPLIT_ENTITY_SEPARATION", "OWNERSHIP_CHANGE"):
            if rel == "SPLIT_ENTITY_SEPARATION":
                split_case_count += 1
            else:
                ownership_change_count += 1
            review_rows.append({k: v for k, v in entry.items() if not k.startswith("_")})

    return {
        "review_rows": review_rows,
        "all_changed": all_changed_classified,
        "summary": {
            "total_changed_projects": len(all_changed_classified),
            "split_and_ownership_review_rows": len(review_rows),
            "split_case_count": split_case_count,
            "ownership_reassignment_count": ownership_change_count,
            "classification_counts": classification_counts,
            "evidence_tier_counts": evidence_tier_counts,
            "review_status_counts": review_status_counts,
            "auto_approved_count": 0,
        },
    }


# ---------------------------------------------------------------------------
# Workstream B — Exact Per-Project Invariant Verification (4,110 x 9 fields)
# ---------------------------------------------------------------------------

def extract_project_invariant_values(doc: Dict[str, Any]) -> Dict[str, Any]:
    """Extract all 9 immutable per-project fields deterministically for hashing and comparison."""
    prov = doc.get("provenance") if isinstance(doc.get("provenance"), dict) else {}
    return {
        "project_id": str(doc.get("_doc_id") or doc.get("project_id") or ""),
        "registration_number": str(doc.get("registration_number") or doc.get("reraRegistrationNumber") or ""),
        "project_name": {
            "project_name": doc.get("project_name"),
            "officialProjectName": doc.get("officialProjectName"),
            "normalizedProjectName": doc.get("normalizedProjectName"),
            "projectAliases": doc.get("projectAliases"),
        },
        "taluk": {
            "taluk": doc.get("taluk"),
            "normalizedTaluk": doc.get("normalizedTaluk"),
        },
        "district": {
            "district": doc.get("district"),
            "normalizedDistrict": doc.get("normalizedDistrict"),
        },
        "data_tier": prov.get("data_tier"),
        "extraction_status": prov.get("extraction_status"),
        "regulatory_bundle_reference": {
            "regulatory_status": doc.get("regulatory_status"),
            "sourceRecordId": doc.get("sourceRecordId"),
            "sourcePortal": doc.get("sourcePortal"),
            "catalogue_source_info": doc.get("catalogue_source_info"),
            "counts": doc.get("counts"),
            "summary_metrics": doc.get("summary_metrics"),
            "tab_observations_summary": doc.get("tab_observations_summary"),
            "unlinked_pane_summary": doc.get("unlinked_pane_summary"),
            "towers_summary": doc.get("towers_summary"),
            "inventory_configurations": doc.get("inventory_configurations"),
            "content_hash": prov.get("content_hash"),
        },
        "regulatory_provenance": prov,
    }


def _simulate_project_patches(
    pre_projects: List[Dict[str, Any]],
    patch_ops: List[Dict[str, Any]],
) -> List[Dict[str, Any]]:
    """Apply Firestore REST `patch_projects` ops cleanly onto deep copies of `pre_projects`."""
    by_id = {
        str(p.get("_doc_id") or p.get("project_id") or ""): copy.deepcopy(p)
        for p in pre_projects
    }
    for op in patch_ops:
        upd = op.get("update") or {}
        full_name = str(upd.get("name") or "")
        pid = full_name.split("/documents/projects/", 1)[1] if "/documents/projects/" in full_name else full_name.split("/")[-1]
        if pid not in by_id:
            continue
        cur = by_id[pid]
        decoded = firestore_value_to_python({"mapValue": {"fields": upd.get("fields", {})}})
        mask_paths = (op.get("updateMask") or {}).get("fieldPaths") or []
        for fp in mask_paths:
            if "." not in fp:
                if fp in decoded:
                    cur[fp] = copy.deepcopy(decoded[fp])
                else:
                    cur.pop(fp, None)
            else:
                top, sub = fp.split(".", 1)
                if isinstance(decoded.get(top), dict) and sub in decoded[top]:
                    if not isinstance(cur.get(top), dict):
                        cur[top] = {}
                    cur[top][sub] = copy.deepcopy(decoded[top][sub])
                elif isinstance(cur.get(top), dict):
                    cur[top].pop(sub, None)
    return list(by_id.values())


def verify_project_invariants_exact(
    pre_projects: List[Dict[str, Any]],
    post_projects: List[Dict[str, Any]],
) -> Dict[str, Any]:
    """
    Compare all 9 immutable fields on EVERY individual project before and after patches.
    Raises ProjectInvariantError immediately on missing/extra projects or any field hash diff.
    """
    pre_map = {str(p.get("_doc_id") or p.get("project_id") or ""): p for p in pre_projects}
    post_map = {str(p.get("_doc_id") or p.get("project_id") or ""): p for p in post_projects}

    if set(pre_map.keys()) != set(post_map.keys()):
        missing = sorted(set(pre_map) - set(post_map))[:5]
        extra = sorted(set(post_map) - set(pre_map))[:5]
        raise ProjectInvariantError(
            f"Project ID set changed during migration: missing={missing}, extra={extra}"
        )

    rows: List[Dict[str, Any]] = []
    mismatches: List[Dict[str, Any]] = []

    for pid in sorted(pre_map.keys()):
        pre_inv = extract_project_invariant_values(pre_map[pid])
        post_inv = extract_project_invariant_values(post_map[pid])
        reg_no = pre_inv["registration_number"]
        for field in PROJECT_INVARIANT_FIELDS:
            h_orig = _canonical_sha256(pre_inv[field])
            h_post = _canonical_sha256(post_inv[field])
            ok = h_orig == h_post
            res_str = "MATCH" if ok else "MISMATCH"
            row = {
                "project_id": pid,
                "registration_number": reg_no,
                "invariant_field": field,
                "original_value_hash": h_orig,
                "proposed_value_hash": h_post,
                "comparison_result": res_str,
            }
            rows.append(row)
            if not ok:
                mismatches.append(row)

    if mismatches:
        first = mismatches[0]
        raise ProjectInvariantError(
            f"{len(mismatches)} project invariant mismatch(es) detected; "
            f"first={first['project_id']} field={first['invariant_field']}"
        )

    return {
        "status": "PASS",
        "projects_checked": len(pre_map),
        "total_field_comparisons": len(rows),
        "mismatch_count": 0,
        "rows": rows,
        "mismatches": [],
    }


def audit_project_invariants_exact(
    pre_projects: List[Dict[str, Any]],
    manifest: Dict[str, Any],
) -> Dict[str, Any]:
    """Dry-run exact per-project invariant audit by simulating manifest patches non-destructively."""
    simulated_post = _simulate_project_patches(
        pre_projects, (manifest.get("staged_ops") or {}).get("patch_projects") or []
    )
    return verify_project_invariants_exact(pre_projects, simulated_post)


# ---------------------------------------------------------------------------
# Workstream C — Exact Builder Payload & Exact Project Membership Verification
# ---------------------------------------------------------------------------

def audit_builder_payloads_exact(
    pre_projects: List[Dict[str, Any]],
    existing_builders_docs: Dict[str, Dict[str, Any]],
    manifest: Dict[str, Any],
) -> Dict[str, Any]:
    """
    Independently compute intended builder payloads & exact project_id sets from simulated
    post-migration projects, and compare every CREATE/UPDATE builder document and every
    catalogue chunk entry byte-for-byte.
    """
    simulated_post_projects = _simulate_project_patches(
        pre_projects, (manifest.get("staged_ops") or {}).get("patch_projects") or []
    )
    expected_catalog_list = build_builders_catalog_from_projects(simulated_post_projects)
    expected_by_id = {b["builder_id"]: b for b in expected_catalog_list}

    rows: List[Dict[str, Any]] = []
    failures: List[Dict[str, Any]] = []
    staged = manifest.get("staged_ops") or {}

    for op_type, stage_key in (("CREATE", "create_builder_docs"), ("UPDATE", "update_builder_docs")):
        for op in staged.get(stage_key) or []:
            full_name = str((op.get("update") or {}).get("name") or "")
            bid = full_name.split("/")[-1]
            doc_path = f"builders/{bid}"
            actual_payload = firestore_value_to_python({"mapValue": {"fields": (op.get("update") or {}).get("fields", {})}})

            exp_managed = expected_by_id.get(bid)
            old_raw = existing_builders_docs.get(bid) or {}
            old_clean = {k: v for k, v in old_raw.items() if k != "_doc_id"}
            unmanaged = {
                k: v for k, v in old_clean.items() if k not in MANAGED_BUILDER_DOC_FIELDS
            }

            if exp_managed is None:
                failures.append({"document_path": doc_path, "reason": "Unexpected builder ID absent from expected catalog"})
                rows.append(
                    {
                        "document_path": doc_path,
                        "operation_type": op_type,
                        "expected_payload_hash": "",
                        "actual_proposed_payload_hash": _canonical_sha256(actual_payload),
                        "fields_added": "",
                        "fields_changed": "",
                        "fields_removed": "",
                        "unmanaged_fields_preserved": json.dumps(sorted(unmanaged.keys())),
                        "expected_project_count": 0,
                        "actual_project_count": int(actual_payload.get("project_count") or 0),
                        "exact_membership_match": False,
                        "comparison_result": "MISMATCH",
                    }
                )
                continue

            expected_payload = {**unmanaged, **exp_managed}
            exp_hash = _canonical_sha256(expected_payload)
            act_hash = _canonical_sha256(actual_payload)

            exp_pids = set(expected_payload.get("project_ids") or [])
            act_pids = set(actual_payload.get("project_ids") or [])
            membership_ok = exp_pids == act_pids and len(actual_payload.get("project_ids") or []) == len(act_pids)

            unmanaged_preserved = all(actual_payload.get(uk) == uv for uk, uv in unmanaged.items())

            # Compare against prior doc (empty for CREATE)
            added = sorted(set(actual_payload) - set(old_clean))
            removed = sorted(set(old_clean) - set(actual_payload))
            changed = sorted(k for k in (set(old_clean) & set(actual_payload)) if old_clean[k] != actual_payload[k])

            ok = (exp_hash == act_hash) and membership_ok and unmanaged_preserved
            if not ok:
                failures.append(
                    {
                        "document_path": doc_path,
                        "reason": (
                            f"hash_match={exp_hash == act_hash}, membership_match={membership_ok}, "
                            f"unmanaged_preserved={unmanaged_preserved}"
                        ),
                    }
                )

            rows.append(
                {
                    "document_path": doc_path,
                    "operation_type": op_type,
                    "expected_payload_hash": exp_hash,
                    "actual_proposed_payload_hash": act_hash,
                    "fields_added": "|".join(added),
                    "fields_changed": "|".join(changed),
                    "fields_removed": "|".join(removed),
                    "unmanaged_fields_preserved": "|".join(sorted(unmanaged.keys())) if unmanaged else "NONE_PRESENT",
                    "expected_project_count": len(exp_pids),
                    "actual_project_count": len(act_pids),
                    "exact_membership_match": membership_ok,
                    "comparison_result": "MATCH" if ok else "MISMATCH",
                }
            )

    # Also verify exact project_ids membership for every builder inside staged `_catalog_chunk_*`
    chunk_membership_mismatches: List[str] = []
    for op in staged.get("write_catalog_chunks") or []:
        decoded = firestore_value_to_python({"mapValue": {"fields": (op.get("update") or {}).get("fields", {})}})
        for b in decoded.get("builders") or []:
            bid = str(b.get("builder_id") or "")
            exp_b = expected_by_id.get(bid)
            if not exp_b or set(b.get("project_ids") or []) != set(exp_b.get("project_ids") or []):
                chunk_membership_mismatches.append(bid)

    if chunk_membership_mismatches:
        failures.append(
            {
                "document_path": "builders/_catalog_chunk_*",
                "reason": f"Chunk project_ids mismatch for: {chunk_membership_mismatches[:5]}",
            }
        )

    return {
        "status": "PASS" if not failures else "FAIL",
        "docs_audited": len(rows),
        "creates_audited": sum(1 for r in rows if r["operation_type"] == "CREATE"),
        "updates_audited": sum(1 for r in rows if r["operation_type"] == "UPDATE"),
        "chunk_builders_verified": len(expected_by_id),
        "mismatch_count": len(failures),
        "failures": failures,
        "rows": rows,
    }


def verify_builder_payloads_exact(
    pre_projects: List[Dict[str, Any]],
    existing_builders_docs: Dict[str, Dict[str, Any]],
    manifest: Dict[str, Any],
) -> Dict[str, Any]:
    """Strict gate wrapper raising BuilderPayloadError on any payload or membership mismatch."""
    res = audit_builder_payloads_exact(pre_projects, existing_builders_docs, manifest)
    if res["status"] != "PASS":
        raise BuilderPayloadError(f"Builder payload verification failed: {res['failures'][:3]}")
    return res


# ---------------------------------------------------------------------------
# Workstream D — Two-Stage Explicit Human Approval Record
# ---------------------------------------------------------------------------

def build_approval_record(
    manifest: Dict[str, Any],
    *,
    approved: bool = False,
    approved_by: Optional[str] = None,
    approved_at_utc: Optional[str] = None,
    approval_scope: str = DEFAULT_APPROVAL_SCOPE,
    notes: str = "Pending explicit human sign-off following Phase 4.2B audit.",
) -> Dict[str, Any]:
    """Construct Stage 2 human authorization record bound directly to `manifest['manifest_sha256']`."""
    env = f"{manifest['firebase_project_id']}/{manifest['firestore_database']}"
    return {
        "approval_record_version": "1.0.0",
        "approved": bool(approved),
        "approved_by": approved_by,
        "approved_at_utc": approved_at_utc,
        "approved_manifest_sha256": manifest["manifest_sha256"],
        "approval_scope": approval_scope,
        "approval_environment": env,
        "notes": notes,
    }


def validate_approval_record(
    approval_record: Any,
    manifest: Dict[str, Any],
    expected_project_id: str = FIREBASE_PROJECT_ID,
    expected_database: str = FIRESTORE_DATABASE,
) -> Dict[str, Any]:
    """
    Validate separate Stage 2 human authorization record against the exact manifest hash
    and production environment. Raises ApprovalValidationError on any mismatch or missing sign-off.
    """
    if not isinstance(approval_record, dict):
        raise ApprovalValidationError("Stage 2 approval record is missing or not a JSON object")

    required = (
        "approved",
        "approved_by",
        "approved_at_utc",
        "approved_manifest_sha256",
        "approval_scope",
        "approval_environment",
    )
    missing = [k for k in required if k not in approval_record]
    if missing:
        raise ApprovalValidationError(f"Approval record missing required fields: {missing}")

    if approval_record["approved"] is not True:
        raise ApprovalValidationError("Stage 2 approval record has approved != True")

    approver = str(approval_record.get("approved_by") or "").strip()
    if not approver:
        raise ApprovalValidationError("Approval record missing non-empty approved_by identity")

    ts = str(approval_record.get("approved_at_utc") or "").strip()
    try:
        datetime.datetime.fromisoformat(ts.replace("Z", "+00:00"))
    except ValueError as exc:
        raise ApprovalValidationError(f"Approval record has invalid UTC timestamp: {ts!r}") from exc

    scope = str(approval_record.get("approval_scope") or "").strip()
    if not scope:
        raise ApprovalValidationError("Approval record missing explicit approval_scope")

    expected_env = f"{expected_project_id}/{expected_database}"
    if approval_record.get("approval_environment") != expected_env:
        raise ApprovalValidationError(
            f"Approval environment mismatch: {approval_record.get('approval_environment')!r} != {expected_env!r}"
        )

    expected_hash = manifest.get("manifest_sha256")
    if not expected_hash or approval_record.get("approved_manifest_sha256") != expected_hash:
        raise ApprovalValidationError(
            f"Approval manifest SHA-256 mismatch: record={approval_record.get('approved_manifest_sha256')!r} != manifest={expected_hash!r}"
        )

    return {
        "status": "AUTHORIZED",
        "approved_by": approver,
        "approved_at_utc": ts,
        "approved_manifest_sha256": expected_hash,
        "approval_environment": expected_env,
    }


# ---------------------------------------------------------------------------
# Workstream E — 59 Deferred Builder Documents Audit
# ---------------------------------------------------------------------------

def audit_deferred_builder_documents(
    deferred_builder_ids: List[str],
    live_builders_docs: Dict[str, Dict[str, Any]],
    corrected_projects: List[Dict[str, Any]],
    corrected_catalog_builder_ids: Set[str],
    *,
    firestore_rules_public_read: bool = True,
    repo_direct_doc_consumers: int = 0,
    backend_function_consumers: int = 0,
    external_dependency_status: str = "UNKNOWN",
) -> Dict[str, Any]:
    """
    Audit every deferred builder document read-only. Never marks publicly exposed
    or unknown-external-dependency docs as safely deletable internal orphans.
    """
    chunk_builder_ids: Set[str] = set()
    for doc_id, doc in live_builders_docs.items():
        if doc_id.startswith("_catalog_chunk_"):
            for entry in doc.get("builders") or []:
                bid = str(entry.get("builder_id") or "").strip()
                if bid:
                    chunk_builder_ids.add(bid)

    ref_counts: Dict[str, int] = {}
    for p in corrected_projects:
        bid = str(p.get("builder_id") or "").strip()
        if bid:
            ref_counts[bid] = ref_counts.get(bid, 0) + 1

    rows: List[Dict[str, Any]] = []
    class_counts: Dict[str, int] = {}

    for bid in sorted(deferred_builder_ids):
        exists_live = bid in live_builders_docs
        proj_refs = ref_counts.get(bid, 0)
        in_live_chunks = bid in chunk_builder_ids
        in_corr_cat = bid in corrected_catalog_builder_ids
        in_repo_code = repo_direct_doc_consumers > 0
        in_backend = backend_function_consumers > 0

        if proj_refs > 0 or in_corr_cat:
            classification = "REQUIRED_ACTIVE_DOCUMENT"
            notes = f"Referenced by {proj_refs} corrected project(s); MUST remain intact."
        elif in_live_chunks and not in_corr_cat:
            if firestore_rules_public_read:
                classification = "ORPHANED_BUT_PUBLICLY_EXPOSED"
                notes = (
                    "Replaced old slug/split parent present in live pre-4.2 chunks; not referenced by Flutter/Functions, "
                    "but exposed publicly via `firestore.rules` (`allow read: if true`). Retain untouched pending explicit cleanup approval."
                )
            elif external_dependency_status == "UNKNOWN":
                classification = "UNKNOWN_EXTERNAL_DEPENDENCY"
                notes = "Not referenced in repository; external consumer status unknown."
            else:
                classification = "CATALOGUE_ONLY"
                notes = "Legacy chunk slug replaced by corrected catalog."
        else:
            if firestore_rules_public_read:
                classification = "ORPHANED_BUT_PUBLICLY_EXPOSED"
                notes = (
                    "Pre-Phase-4 orphaned document absent from live chunks and corrected catalogue; no repo direct consumer found, "
                    "but publicly readable via `firestore.rules` (`allow read: if true`). Do NOT delete without explicit approval."
                )
            elif external_dependency_status == "UNKNOWN":
                classification = "UNKNOWN_EXTERNAL_DEPENDENCY"
                notes = "External dependency status is UNKNOWN; retain untouched pending verification."
            else:
                classification = "ORPHANED_INTERNAL"
                notes = "Confirmed internal orphan with verified zero external dependencies."

        class_counts[classification] = class_counts.get(classification, 0) + 1
        rows.append(
            {
                "builder_id": bid,
                "document_path": f"builders/{bid}",
                "exists_in_live_firestore": exists_live,
                "referenced_by_corrected_project_count": proj_refs,
                "present_in_live_chunks": in_live_chunks,
                "present_in_corrected_catalogue": in_corr_cat,
                "referenced_by_current_app_code": in_repo_code,
                "referenced_by_backend_or_functions": in_backend,
                "exposed_through_firestore_rules": firestore_rules_public_read,
                "external_dependency_status": external_dependency_status,
                "classification": classification,
                "safe_to_delete_based_solely_on_repo_search": False,
                "untouched_in_phase4_2b": True,
                "notes": notes,
            }
        )

    return {
        "total_reviewed": len(rows),
        "classification_counts": class_counts,
        "rows": rows,
    }
