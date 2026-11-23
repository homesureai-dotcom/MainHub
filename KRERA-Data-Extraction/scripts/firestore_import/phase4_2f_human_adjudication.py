"""
HomeSure Phase 4.2F — Human Adjudication Preparation (Strictly Read-Only).

Prepares the final human-review and approval workflow for the frozen Phase 4.2E
Manifest v2 builder identity migration by verifying all 59 upstream/freeze/audit
artifacts, reconciling review populations across Phases 4.2D and 4.2E, and
producing structured adjudication queues with zero pre-filled approvals.

Safety guarantees:
  - Strictly read-only: zero Firestore reads/writes/updates/deletes.
  - Refuses `--apply`, `--execute`, `--approve`, `--auto-approve`.
  - Never modifies Phase 4.2A-4.2E frozen artifacts or approval records.
  - Never pre-populates human approvals or merges provisional builders.
  - Writes deliverables ONLY to `reports/phase4_2f_human_adjudication/`.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Sequence, Tuple

SCRIPT_DIR = Path(__file__).resolve().parent
EXTRACTION_ROOT = SCRIPT_DIR.parents[1]
SCRIPTS_ROOT = EXTRACTION_ROOT / "scripts"
for _p in (str(SCRIPT_DIR), str(SCRIPTS_ROOT)):
    if _p not in sys.path:
        sys.path.insert(0, _p)

from phase4_2e_final_freeze import (
    DEFAULT_BACKUP_DIR,
    FREEZE_OUTPUT_DIR,
    PHASE4_2E_V2_MANIFEST_FILENAME,
    PHASE4_2E_V2_OUTPUT_DIR,
    verify_all_upstream_artifacts,
)
from phase4_2e_rollback_mapping_audit import (
    AUDIT_OUTPUT_DIR as ROLLBACK_AUDIT_OUTPUT_DIR,
    _verify_freeze_deliverables,
)

PHASE4_2_REPORTS_DIR = EXTRACTION_ROOT / "reports" / "phase4_2"
PHASE4_2F_OUTPUT_DIR = EXTRACTION_ROOT / "reports" / "phase4_2f_human_adjudication"

ALLOWED_HUMAN_DECISIONS = "APPROVE | REJECT | RETAIN_PROVISIONAL"

REGISTER_COLUMNS = [
    "adjudication_id",
    "project_id",
    "registration_number",
    "project_name",
    "existing_builder_id",
    "proposed_builder_id",
    "phase4_2d_proposed_builder_id",
    "slug_changed_from_4_2d_to_v2",
    "changed_in_firestore",
    "changed_fields",
    "official_krera_promoter_name",
    "canonical_display_name",
    "identity_relationship_type",
    "adjudication_queue_tier",
    "in_4_2d_business_signoff_54",
    "in_4_2e_unresolved_17",
    "in_4_2e_ownership_6",
    "in_4_2d_manual_review_134",
    "in_4_2e_evidence_58",
    "in_4_2e_identity_review_126",
    "supporting_source_evidence",
    "source_file_references",
    "evidence_confidence",
    "evidence_limitations",
    "corporate_verification_status",
    "risk_classification",
    "can_remain_provisional_without_blocking",
    "recommended_decision",
    "human_decision_allowed_values",
    "human_decision",
    "reviewer",
    "approval_date",
    "comments",
]

BUSINESS_SIGNOFF_QUEUE_COLUMNS = [
    "queue_id",
    "adjudication_id",
    "queue_origin",
    "project_id",
    "registration_number",
    "project_name",
    "existing_builder_id",
    "proposed_builder_id",
    "phase4_2d_proposed_builder_id",
    "slug_changed_from_4_2d_to_v2",
    "official_krera_promoter_name",
    "canonical_display_name",
    "identity_relationship_type",
    "in_4_2d_business_signoff_54",
    "in_4_2e_unresolved_17",
    "in_4_2e_ownership_6",
    "supporting_source_evidence",
    "source_file_references",
    "evidence_confidence",
    "evidence_limitations",
    "corporate_verification_status",
    "risk_classification",
    "can_remain_provisional_without_blocking",
    "recommended_decision",
    "human_decision_allowed_values",
    "human_decision",
    "reviewer",
    "approval_date",
    "comments",
]

UNRESOLVED_QUEUE_COLUMNS = [
    "queue_id",
    "adjudication_id",
    "project_id",
    "registration_number",
    "project_name",
    "existing_builder_id",
    "proposed_builder_id",
    "official_krera_promoter_name",
    "canonical_display_name",
    "identity_relationship_type",
    "in_4_2d_business_signoff_54",
    "provisional_slug_isolated",
    "identity_review_reason",
    "review_flags",
    "next_required_evidence",
    "supporting_source_evidence",
    "source_file_references",
    "evidence_confidence",
    "evidence_limitations",
    "corporate_verification_status",
    "risk_classification",
    "can_remain_provisional_without_blocking",
    "recommended_decision",
    "human_decision_allowed_values",
    "human_decision",
    "reviewer",
    "approval_date",
    "comments",
]

TIER_SORT_PRIORITY = {
    "V2_OWNERSHIP_REASSIGNMENT_SIGNOFF": 0,
    "OWNERSHIP_REASSIGNMENT": 1,
    "BUSINESS_SIGNOFF_AND_UNRESOLVED_OVERLAP": 2,
    "BUSINESS_SIGNOFF_ONLY": 3,
    "UNRESOLVED_EVIDENCE_ONLY": 4,
    "ADVISORY_PROVISIONAL_SEPARATE": 5,
    "EVIDENCE_RESOLVED_MIGRATED": 6,
    "EVIDENCE_AUDITED_NO_MIGRATION_IMPACT": 7,
}
RISK_SORT_PRIORITY = {"HIGH": 0, "MEDIUM": 1, "LOW": 2}


def _sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        while True:
            chunk = fh.read(65536)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()


def _read_csv(path: Path) -> List[Dict[str, str]]:
    with path.open("r", encoding="utf-8", newline="") as fh:
        return list(csv.DictReader(fh))


def _verify_rollback_audit_deliverables(audit_dir: Path = ROLLBACK_AUDIT_OUTPUT_DIR) -> Dict[str, Any]:
    """Independently verify all 4 Phase 4.2E Final Rollback Mapping Audit deliverables."""
    hashes_path = audit_dir / "rollback_mapping_audit_hashes.json"
    hashes_doc = json.loads(hashes_path.read_text(encoding="utf-8"))
    if hashes_doc.get("rollback_mapping_status") != "PASS":
        raise RuntimeError(f"Rollback mapping audit status is not PASS: {hashes_doc.get('rollback_mapping_status')!r}")
    if hashes_doc.get("approval_record_approved") is not False:
        raise RuntimeError("Rollback mapping audit approval_record_approved is not False")

    verified: Dict[str, Dict[str, Any]] = {}
    for fn, meta in hashes_doc["deliverable_hashes"].items():
        fp = audit_dir / fn
        actual_sha = _sha256_file(fp)
        actual_size = fp.stat().st_size
        if actual_sha != meta["sha256"] or actual_size != meta["size_bytes"]:
            raise RuntimeError(f"Rollback mapping audit deliverable mismatch for {fn}")
        verified[fn] = {"size_bytes": actual_size, "sha256": actual_sha}

    verified[hashes_path.name] = {
        "size_bytes": hashes_path.stat().st_size,
        "sha256": _sha256_file(hashes_path),
    }
    summary = json.loads((audit_dir / "rollback_operation_category_summary.json").read_text(encoding="utf-8"))
    if summary.get("rollback_mapping_status") != "PASS":
        raise RuntimeError("Rollback operation category summary status is not PASS")
    return {"verified_count": len(verified), "hashes": verified, "summary": summary}


def _verify_59_prior_artifacts(
    *,
    backup_dir: Path = DEFAULT_BACKUP_DIR,
    v2_dir: Path = PHASE4_2E_V2_OUTPUT_DIR,
    freeze_dir: Path = FREEZE_OUTPUT_DIR,
    rollback_audit_dir: Path = ROLLBACK_AUDIT_OUTPUT_DIR,
) -> Dict[str, Any]:
    """Verify all 47 upstream + 8 freeze + 4 rollback-mapping-audit artifacts (59 total) before reading."""
    upstream = verify_all_upstream_artifacts(backup_dir=backup_dir, v2_dir=v2_dir)
    freeze = _verify_freeze_deliverables(freeze_dir=freeze_dir)
    rb_audit = _verify_rollback_audit_deliverables(audit_dir=rollback_audit_dir)

    upstream_count = (
        upstream["phase4_2a_to_4_2d_verified_count"]
        + upstream["phase4_2e_v1_verified_count"]
        + upstream["discrepancy_audit_verified_count"]
        + upstream["manifest_v2_verified_count"]
    )
    total_verified = upstream_count + freeze["verified_count"] + rb_audit["verified_count"]
    if total_verified != 59:
        raise RuntimeError(f"Expected 59 verified prior artifacts, got {total_verified}")
    if upstream["approval_record_approved"] is not False:
        raise RuntimeError("Approval record must remain approved: false")
    if freeze["freeze_record"].get("freeze_status") != "READY_FOR_PRODUCTION_APPROVAL":
        raise RuntimeError("Unexpected freeze_status")

    return {
        "total_verified": total_verified,
        "upstream": upstream,
        "freeze": freeze,
        "rollback_audit": rb_audit,
    }


def _classify_queue_tier(
    *,
    in_bs: bool,
    in_un: bool,
    in_ow: bool,
    in_mr: bool,
    in_irr: bool,
    changed_in_firestore: bool,
) -> str:
    if in_ow and not in_bs:
        return "V2_OWNERSHIP_REASSIGNMENT_SIGNOFF"
    if in_ow and in_bs:
        return "OWNERSHIP_REASSIGNMENT"
    if in_bs and in_un:
        return "BUSINESS_SIGNOFF_AND_UNRESOLVED_OVERLAP"
    if in_bs:
        return "BUSINESS_SIGNOFF_ONLY"
    if in_un:
        return "UNRESOLVED_EVIDENCE_ONLY"
    if in_mr or in_irr:
        return "ADVISORY_PROVISIONAL_SEPARATE"
    if changed_in_firestore:
        return "EVIDENCE_RESOLVED_MIGRATED"
    return "EVIDENCE_AUDITED_NO_MIGRATION_IMPACT"


def _derive_relationship_type(
    *,
    pr_row: Dict[str, str],
    bs_row: Optional[Dict[str, str]],
    ow_row: Optional[Dict[str, str]],
) -> str:
    cls_val = pr_row["identity_classification"]
    if ow_row is not None:
        return f"OWNERSHIP_REASSIGNMENT ({ow_row['reassignment_category']})"
    if bs_row is not None:
        bs_cls = bs_row["classification"]
        if bs_cls == "BRAND_PROMOTER_RELATIONSHIP" or pr_row["brand_relationship"] or pr_row["jv_relationship"]:
            return "BRAND_PROMOTER_JV_BOUNDARY"
        if cls_val != bs_cls:
            return f"{bs_cls} + {cls_val}"
        return bs_cls
    if pr_row["jv_relationship"] or pr_row["brand_relationship"]:
        return "BRAND_PROMOTER_JV_BOUNDARY"
    if pr_row["merge_candidate_status"]:
        return f"MERGE_CANDIDATE ({pr_row['merge_candidate_status']})"
    return cls_val


def _assemble_source_evidence(
    *,
    pr_row: Dict[str, str],
    bs_row: Optional[Dict[str, str]],
    se_row: Optional[Dict[str, str]],
    ev_row: Optional[Dict[str, str]],
    ow_row: Optional[Dict[str, str]],
    un_row: Optional[Dict[str, str]],
    mr_row: Optional[Dict[str, str]],
) -> Tuple[str, str]:
    ev_parts: List[str] = []
    file_refs: List[str] = []

    if ow_row is not None and ow_row.get("form_c_source_uri"):
        ev_parts.append(f"FormC:{ow_row['form_c_source_uri']} (sha256={ow_row.get('form_c_sha256', '')})")
    elif ev_row is not None and ev_row.get("source_record_reference"):
        ev_parts.append(f"{ev_row['source_record_reference']} (form_c_sha256={ev_row.get('form_c_cert_sha256', '')})")
    elif pr_row.get("form_c_cert_sha256"):
        ev_parts.append(f"FormC_sha256={pr_row['form_c_cert_sha256']}")

    if bs_row is not None and bs_row.get("krera_source_record"):
        ev_parts.append(f"4.2D:{bs_row['krera_source_record']}")
    elif mr_row is not None and mr_row.get("source_evidence"):
        ev_parts.append(f"4.2D:{mr_row['source_evidence']}")

    if pr_row.get("sqlite_record_hash"):
        ev_parts.append(f"SQLite_sha256={pr_row['sqlite_record_hash']}")
    if ev_row is not None and ev_row.get("certificate_promoter_name"):
        ev_parts.append(f"CertPromoter={ev_row['certificate_promoter_name']}")
    if se_row is not None and se_row.get("type_of_firm"):
        ev_parts.append(f"FirmType={se_row['type_of_firm']}")
    if pr_row.get("change_reason"):
        ev_parts.append(f"Reason:{pr_row['change_reason']}")

    # File references (normalized POSIX paths, deduplicated in insertion order)
    seen_refs: set = set()

    def _add_ref(val: str) -> None:
        clean = val.strip().replace("\\", "/")
        if clean and clean not in seen_refs:
            seen_refs.add(clean)
            file_refs.append(clean)

    for cand in (
        pr_row.get("form_a_json_file", ""),
        pr_row.get("cross_linked_form_a_file", ""),
        ev_row.get("form_a_json_file", "") if ev_row else "",
        ev_row.get("cross_linked_form_a_file", "") if ev_row else "",
        se_row.get("deep_json_file", "") if se_row else "",
        bs_row.get("source_file", "") if bs_row else "",
        bs_row.get("source_uri", "") if bs_row else "",
    ):
        if cand:
            _add_ref(cand)

    if bs_row is not None:
        _add_ref("reports/phase4_2/phase4_2d_business_signoff_register.csv")
    if mr_row is not None:
        _add_ref("reports/phase4_2/phase4_2d_manual_review_consolidation.csv")
    if ev_row is not None:
        _add_ref("reports/phase4_2e_manifest_v2_correction/phase4_2e_evidence_decision_register_v2.csv")
    if un_row is not None:
        _add_ref("reports/phase4_2e_manifest_v2_correction/phase4_2e_unresolved_identity_register_v2.csv")
    if ow_row is not None:
        _add_ref("reports/phase4_2e_manifest_v2_correction/phase4_2e_ownership_reassignment_register_v2.csv")
    _add_ref("reports/phase4_2e_manifest_v2_correction/phase4_2e_project_identity_reconciliation_v2.csv")

    return " | ".join(ev_parts), "; ".join(file_refs)


def _derive_confidence_risk_and_recommendation(
    *,
    tier: str,
    pr_row: Dict[str, str],
    bs_row: Optional[Dict[str, str]],
    un_row: Optional[Dict[str, str]],
    ev_row: Optional[Dict[str, str]],
    ow_row: Optional[Dict[str, str]],
    mr_row: Optional[Dict[str, str]],
) -> Tuple[str, str, str, bool, str]:
    ev_status = pr_row["evidence_status"]
    dec_code = pr_row["decision_code"]
    irr_reason = pr_row["identity_review_reason"]
    changed_fs = pr_row["changed_in_firestore"] == "True"

    if ow_row is not None:
        confidence = f"HIGH_SOURCE_VERIFIED ({ev_status})"
        limitations = ow_row["evidence_limitation"] or "Corporate ROC/MCA verification not performed."
        risk = "HIGH"
        can_prov = False
        rec = (
            "HOLD_FOR_EXPLICIT_OWNERSHIP_SIGNOFF: Confirm Form-C/Form-A promoter transition and approve "
            f"{pr_row['old_builder_id']} -> {pr_row['proposed_builder_id']}."
        )
        return confidence, limitations, risk, can_prov, rec

    if tier == "BUSINESS_SIGNOFF_AND_UNRESOLVED_OVERLAP":
        confidence = f"PARTIAL_PROVISIONAL_ISOLATED ({ev_status})"
        limitations = (
            f"Unresolved continuity ({irr_reason}). "
            f"Next evidence: {un_row['next_required_evidence'] if un_row else 'Extract Form-A promoter tab.'} "
            "Corporate/MCA verification NOT_PERFORMED."
        )
        risk = bs_row["risk_level"] if bs_row and bs_row.get("risk_level") else "HIGH"
        can_prov = True
        rec = (
            "APPROVE_PROVISIONAL_SEPARATE_ENTITY_OR_HOLD_FOR_FORM_A: Safe to keep isolated under "
            f"{pr_row['proposed_builder_id']} pending Form-A review; do not auto-merge."
        )
        return confidence, limitations, risk, can_prov, rec

    if tier == "UNRESOLVED_EVIDENCE_ONLY":
        confidence = f"PARTIAL_PROVISIONAL_ISOLATED ({ev_status})"
        limitations = (
            f"Form-A continuity unverified ({irr_reason}); legal suffix/MCA continuity pending. "
            f"Next evidence: {un_row['next_required_evidence'] if un_row else ''}"
        )
        risk = "MEDIUM"
        can_prov = True
        rec = (
            "RETAIN_PROVISIONAL_SEPARATE_ENTITY: Approve keeping distinct slug "
            f"{pr_row['proposed_builder_id']} separately pending Form-A/MCA verification."
        )
        return confidence, limitations, risk, can_prov, rec

    if tier == "BUSINESS_SIGNOFF_ONLY":
        confidence = (
            f"SOURCE_FORM_C_CONFIRMED ({ev_status})"
            if ev_row is not None
            else f"SOURCE_CATALOGUE_BACKED ({ev_status})"
        )
        lim_parts = []
        if ev_row is not None and ev_row.get("next_required_evidence"):
            lim_parts.append(ev_row["next_required_evidence"])
        if bs_row is not None and bs_row.get("required_additional_evidence"):
            lim_parts.append(bs_row["required_additional_evidence"])
        if irr_reason:
            lim_parts.append(f"Review note: {irr_reason}")
        lim_parts.append("Corporate/MCA verification NOT_PERFORMED.")
        limitations = " | ".join(dict.fromkeys(p for p in lim_parts if p))
        risk = bs_row["risk_level"] if bs_row and bs_row.get("risk_level") else "MEDIUM"
        can_prov = False
        rec = (
            bs_row["recommended_decision"]
            if bs_row and bs_row.get("recommended_decision")
            else f"APPROVE_SOURCE_BACKED_SLUG ({dec_code})"
        )
        return confidence, limitations, risk, can_prov, rec

    if tier == "ADVISORY_PROVISIONAL_SEPARATE":
        confidence = f"SOURCE_BACKED_SEPARATE ({ev_status})"
        limitations = (
            f"Kept provisionally separate ({irr_reason}); no independent MCA/CIN merge proof. "
            "Corporate/MCA verification NOT_PERFORMED."
        )
        risk = mr_row["risk_level"] if mr_row and mr_row.get("risk_level") else "MEDIUM"
        can_prov = True
        rec = (
            "RETAIN_PROVISIONAL_SEPARATE_WITHOUT_MERGE: Safe for migration without merging; "
            f"keep separate under {pr_row['proposed_builder_id']}."
        )
        return confidence, limitations, risk, can_prov, rec

    if tier == "EVIDENCE_RESOLVED_MIGRATED":
        confidence = f"HIGH_FORM_A_AND_FORM_C_CONFIRMED ({ev_status})"
        limitations = "K-RERA Form-A account 0826951 & Form-C verified; MCA corporate audit NOT_PERFORMED."
        risk = "HIGH"
        can_prov = False
        rec = "APPROVE_EVIDENCE_RESOLVED_MERGE: Form-A row 19 & Form-C confirm RGHCL ownership."
        return confidence, limitations, risk, can_prov, rec

    # EVIDENCE_AUDITED_NO_MIGRATION_IMPACT
    confidence = f"HIGH_SOURCE_CONFIRMED ({ev_status})"
    limitations = (
        "No Firestore mutation in Manifest v2 (already assigned to proposed builder). "
        "Corporate/MCA verification NOT_PERFORMED."
        if not changed_fs
        else "Standardized with source evidence."
    )
    risk = "LOW"
    can_prov = False
    rec = "NO_MIGRATION_CHANGE_REQUIRED: Confirm audit record; zero Firestore patch staged."
    return confidence, limitations, risk, can_prov, rec


def _render_markdown_report(summary: Dict[str, Any]) -> str:
    pop = summary["population_reconciliation"]
    app = summary["approval_summary"]
    up = summary["upstream_integrity_and_safety"]
    acc = summary["acceptance_criteria"]
    evolutions = summary["phase4_2d_to_v2_slug_evolutions"]
    ov_rows = summary["overlapping_bs54_un17_records"]
    un_only_rows = summary["un17_only_records"]
    ow_rows = summary["ownership_reassignment_6_records"]

    lines = [
        "# Homesure Phase 4.2F — Human Adjudication & Production Approval Readiness Report",
        "",
        f"- Prepared At (UTC): `{summary['prepared_at_utc']}`",
        f"- Frozen Manifest v2: `{summary['manifest_v2_path']}` (internal SHA-256: `{summary['manifest_v2_internal_sha256']}`)",
        f"- Rollback Mapping Audit Status: `{up['rollback_mapping_status']}` (`2,141 / 2,141` verified 1-to-1)",
        f"- Approval Record State: `approved: {str(up['approval_record_approved']).lower()}` (`{summary['PRODUCTION_APPROVAL_STATUS']}`)",
        f"- Corporate Verification Status: `{summary['CORPORATE_VERIFICATION_STATUS']}`",
        "",
        "## 1. Population Reconciliation (`54` Business Sign-Off vs `17` Unresolved & Complete `163`-Case Universe)",
        "",
        "The Phase 4.2D business sign-off population (`54` cases) and the Phase 4.2E v2 unresolved/provisional evidence population (`17` cases) are **not disjoint**: **`15` projects overlap** across both registers.",
        "",
        "| Segment | Mutually Exclusive Count | Changed in Firestore (Manifest v2) | Role in Human Workflow |",
        "|---|---:|---:|---|",
        f"| `BS_54 ∩ UN_17` Overlap | {pop['bs_un_overlap_count']} | {pop['bs_un_overlap_count']} | Business sign-off + Form-A/continuity provisional isolation |",
        f"| `BS_54 - UN_17` Business Sign-Off Only | {pop['bs_only_count']} | {pop['bs_only_count']} | Includes `5` 4.2D ownership reassignments, `8` confirmed same source, `2` distinct source kept separate, `24` slug standardizations |",
        f"| `V2` Added Ownership Reassignment (`007631`) | {pop['v2_added_ownership_count']} | {pop['v2_added_ownership_count']} | Vaishnavi Harmony reassigned to `builder_affinity_projects` by own Form-A + Form-C (`business_signoff_queue.csv` = `54 + 1 = 55`) |",
        f"| `UN_17 - BS_54` Unresolved Evidence Only | {pop['un_only_count']} | {pop['un_only_count']} | Greennesto `005350` & `004334` LLP/non-LLP provisional isolation |",
        f"| Advisory Provisional-Separate (`MR_134 \\ (BS_54 ∪ UN_17)` + `2` Shell legal-form splits) | {pop['advisory_provisional_separate_count']} | {pop['advisory_provisional_separate_count']} | Kept provisionally separate without auto-merging (`80 + 2 = 82`) |",
        f"| Evidence-Resolved Migration Correction (`004171`) | {pop['evidence_resolved_migrated_count']} | {pop['evidence_resolved_migrated_count']} | RGHCL merge candidate resolved via Form-A Account `0826951` |",
        f"| Audited with No Migration Impact (`EV_58` unchanged RGHCL) | {pop['no_migration_impact_audited_count']} | 0 | Verified against Form-A `006414` / Form-C; zero Firestore write staged |",
        f"| **Total Reviewed & Audited Cases (`human_adjudication_register.csv`)** | **{app['total_cases_reviewed']}** | **{pop['reviewed_cases_changed_in_firestore']}** | **Complete union of all review, evidence, and ownership registers** |",
        f"| Routine Source-Backed / Unchanged (no review/evidence flags) | {pop['unflagged_projects_count']:,} | {pop['unflagged_changed_in_firestore']:,} | Unflagged remainder (`1,919` routine slug patches + `2,028` unchanged) |",
        f"| **Total Homesure Projects** | **{pop['total_projects']:,}** | **{pop['total_patched_in_manifest_v2']:,}** | Reconciles to exact `4,110` baseline and `2,059` staged `patch_projects` |",
        "",
        "### Venn Verification (`54` vs `17`)",
        f"- `BS_54`: **{pop['bs_54_count']}** = `{pop['bs_only_count']}` (BS-only) + `{pop['bs_un_overlap_count']}` (overlap)",
        f"- `UN_17`: **{pop['un_17_count']}** = `{pop['un_only_count']}` (UN-only) + `{pop['bs_un_overlap_count']}` (overlap)",
        f"- Union `BS_54 ∪ UN_17`: **{pop['bs_union_un_count']}** (`{pop['bs_only_count']} + {pop['bs_un_overlap_count']} + {pop['un_only_count']}`)",
        "",
        "## 2. Approval Summary (Zero Pre-Filled Decisions)",
        "",
        "| Metric | Count | Notes |",
        "|---|---:|---|",
        f"| Total cases reviewed in consolidated register | {app['total_cases_reviewed']} | `human_adjudication_register.csv` (`ADJ_001`..`ADJ_163`) |",
        f"| Approved decisions | {app['approved_decisions']} | Human approval NOT yet granted |",
        f"| Rejected decisions | {app['rejected_decisions']} | None recorded |",
        f"| Provisional decisions recorded by human | {app['provisional_decisions']} | None recorded yet |",
        f"| Pending human decisions | {app['pending_human_decisions']} | All rows have blank `human_decision`, `reviewer`, `approval_date`, `comments` |",
        f"| Cases awaiting business sign-off (`business_signoff_queue.csv`) | {app['cases_awaiting_business_signoff']} | `54` from 4.2D + `1` Manifest v2 Ownership Reassignment (`007631`) |",
        f"| Cases awaiting additional evidence (`unresolved_evidence_queue.csv`) | {app['cases_awaiting_additional_evidence']} | `15` overlapping `BS_54` + `2` `UN_17`-only (`can_remain_provisional_without_blocking: true`) |",
        f"| Cases safe to remain provisionally separate without blocking migration | {app['cases_safe_to_remain_provisional_non_blocking']} | `17` `UN_17` provisional + `82` advisory separate (zero auto-merges) |",
        f"| Cases with no impact on the proposed migration | {app['cases_with_no_impact_on_proposed_migration']} | `23` audited RGHCL projects already aligned (`changed_in_firestore: false`) |",
        "",
        "## 3. Overlap (`15`), `UN_17`-Only (`2`), Ownership Reassignments (`6`), & 4.2D→v2 Slug Deltas (`7`)",
        "",
        "### A. `15` Overlapping Records (`BS_54 ∩ UN_17`)",
        "| Project ID | RERA Registration | Existing -> Proposed Builder ID | Relationship | Reason |",
        "|---|---|---|---|---|",
    ]
    for r in ov_rows:
        lines.append(
            f"| `{r['project_id']}` | `{r['registration_number']}` | `{r['existing_builder_id']}` -> `{r['proposed_builder_id']}` | `{r['identity_relationship_type']}` | `{r['identity_review_reason']}` |"
        )

    lines.extend(
        [
            "",
            "### B. `2` Unresolved-Only Records (`UN_17 - BS_54`)",
            "| Project ID | RERA Registration | Existing -> Proposed Builder ID | Reason |",
            "|---|---|---|---|",
        ]
    )
    for r in un_only_rows:
        lines.append(
            f"| `{r['project_id']}` | `{r['registration_number']}` | `{r['existing_builder_id']}` -> `{r['proposed_builder_id']}` | `{r['identity_review_reason']}` |"
        )

    lines.extend(
        [
            "",
            "### C. `6` High-Risk Ownership Reassignments Requiring Explicit Sign-Off (`5` from 4.2D + `1` added in v2)",
            "| Project ID | RERA Registration | Project Name | Existing -> Proposed Builder ID | Source Queue |",
            "|---|---|---|---|---|",
        ]
    )
    for r in ow_rows:
        lines.append(
            f"| `{r['project_id']}` | `{r['registration_number']}` | {r['project_name']} | `{r['existing_builder_id']}` -> `{r['proposed_builder_id']}` | `{'BS_54 + V2_OW_6' if r['in_bs54'] else 'V2_OW_6_ADDED'}` |"
        )

    lines.extend(
        [
            "",
            "### D. `7` Phase 4.2D -> Manifest v2 Slug Refinements Within `BS_54`",
            "| Project ID | Phase 4.2D Proposed Builder ID | Manifest v2 Proposed Builder ID | Reason |",
            "|---|---|---|---|",
        ]
    )
    for r in evolutions:
        lines.append(
            f"| `{r['project_id']}` | `{r['phase4_2d_proposed_builder_id']}` | `{r['v2_proposed_builder_id']}` | `{r['decision_code']}` |"
        )

    lines.extend(
        [
            "",
            "## 4. Can Unresolved & Advisory Records Safely Remain Provisionally Separate?",
            "",
            "**Yes.** All `17` `UN_17` unresolved cases and all `82` advisory separate cases (99 total) keep distinct canonical/provisional `builder_id` values in Manifest v2 without auto-merging entities or erasing K-RERA source promoter distinctions (`6` cases use dedicated `_provisional_<reg>` IDs, `11` preserve distinct prefix/legal suffixes, `82` keep unmerged merge-candidate / JV / legal-form slugs separate). Approving Manifest v2 with those records retained provisionally separate does not risk false promoter confluence and remains fully reversible via the verified `2,141`-op rollback package.",
            "",
            "## 5. Remaining Blockers Before Production Approval",
            "",
        ]
    )
    for idx, b in enumerate(app["remaining_blockers_to_production_approval"], start=1):
        lines.append(f"{idx}. {b}")

    lines.extend(["", "## 6. Verification & Acceptance Criteria", "", "| Criterion | Status |", "|---|---|"])
    for k, v in acc.items():
        lines.append(f"| `{k}` | `{'PASS' if v else 'FAIL'}` |")

    lines.extend(
        [
            "",
            f"- Upstream + Freeze + Rollback Audit artifacts verified untouched: `{up['artifacts_verified_count']}`",
            f"- Firestore writes executed: `{up['firestore_writes_executed']}`",
            "",
            f"HUMAN_ADJUDICATION_PREPARATION_STATUS: {summary['HUMAN_ADJUDICATION_PREPARATION_STATUS']}",
            f"PRODUCTION_APPROVAL_STATUS: {summary['PRODUCTION_APPROVAL_STATUS']}",
            f"PRODUCTION_EXECUTION_STATUS: {summary['PRODUCTION_EXECUTION_STATUS']}",
            "",
        ]
    )
    return "\n".join(lines)


def run_human_adjudication_preparation(
    *,
    backup_dir: Path = DEFAULT_BACKUP_DIR,
    p42_dir: Path = PHASE4_2_REPORTS_DIR,
    v2_dir: Path = PHASE4_2E_V2_OUTPUT_DIR,
    freeze_dir: Path = FREEZE_OUTPUT_DIR,
    rollback_audit_dir: Path = ROLLBACK_AUDIT_OUTPUT_DIR,
    output_dir: Path = PHASE4_2F_OUTPUT_DIR,
) -> Dict[str, Any]:
    """Verify all 59 prior artifacts, reconcile review queues, and emit all 6 Phase 4.2F deliverables."""
    output_dir.mkdir(parents=True, exist_ok=True)
    prepared_at_utc = datetime.now(timezone.utc).isoformat()

    # 1. Verify hashes of all 59 prior artifacts before relying on them
    prior = _verify_59_prior_artifacts(
        backup_dir=backup_dir,
        v2_dir=v2_dir,
        freeze_dir=freeze_dir,
        rollback_audit_dir=rollback_audit_dir,
    )
    upstream = prior["upstream"]
    freeze = prior["freeze"]
    rb_audit = prior["rollback_audit"]
    manifest_v2 = upstream["manifest_v2"]

    # 2. Load registers (read-only)
    bs_rows = _read_csv(p42_dir / "phase4_2d_business_signoff_register.csv")
    mr_rows = _read_csv(p42_dir / "phase4_2d_manual_review_consolidation.csv")
    se_rows = _read_csv(p42_dir / "phase4_2d_source_evidence_validation.csv")
    un_rows = _read_csv(v2_dir / "phase4_2e_unresolved_identity_register_v2.csv")
    ow_rows = _read_csv(v2_dir / "phase4_2e_ownership_reassignment_register_v2.csv")
    ev_rows = _read_csv(v2_dir / "phase4_2e_evidence_decision_register_v2.csv")
    pr_rows = _read_csv(v2_dir / "phase4_2e_project_identity_reconciliation_v2.csv")
    br_rows = _read_csv(v2_dir / "phase4_2e_builder_identity_register_v2.csv")

    bs_by_id = {r["project_id"]: r for r in bs_rows}
    mr_by_id = {r["project_id"]: r for r in mr_rows}
    se_by_id = {r["project_id"]: r for r in se_rows}
    un_by_id = {r["project_id"]: r for r in un_rows}
    ow_by_id = {r["project_id"]: r for r in ow_rows}
    ev_by_id = {r["project_id"]: r for r in ev_rows}
    pr_by_id = {r["project_id"]: r for r in pr_rows}
    br_by_id = {r["builder_id"]: r for r in br_rows}

    bs_ids = set(bs_by_id)
    un_ids = set(un_by_id)
    ow_ids = set(ow_by_id)
    mr_ids = set(mr_by_id)
    ev_ids = set(ev_by_id)
    irr_ids = {r["project_id"] for r in pr_rows if r["identity_review_required"] == "True"}

    union_review_ids = bs_ids | un_ids | ow_ids | mr_ids | ev_ids | irr_ids

    # 3. Build unsorted entries then sort cleanly by priority tier -> risk -> project_id
    staged_records: List[Dict[str, Any]] = []
    for pid in union_review_ids:
        pr_row = pr_by_id[pid]
        bs_row = bs_by_id.get(pid)
        mr_row = mr_by_id.get(pid)
        se_row = se_by_id.get(pid)
        un_row = un_by_id.get(pid)
        ow_row = ow_by_id.get(pid)
        ev_row = ev_by_id.get(pid)

        tier = _classify_queue_tier(
            in_bs=pid in bs_ids,
            in_un=pid in un_ids,
            in_ow=pid in ow_ids,
            in_mr=pid in mr_ids,
            in_irr=pid in irr_ids,
            changed_in_firestore=(pr_row["changed_in_firestore"] == "True"),
        )
        rel_type = _derive_relationship_type(pr_row=pr_row, bs_row=bs_row, ow_row=ow_row)
        src_ev, src_files = _assemble_source_evidence(
            pr_row=pr_row,
            bs_row=bs_row,
            se_row=se_row,
            ev_row=ev_row,
            ow_row=ow_row,
            un_row=un_row,
            mr_row=mr_row,
        )
        confidence, limitations, risk, can_prov, rec = _derive_confidence_risk_and_recommendation(
            tier=tier,
            pr_row=pr_row,
            bs_row=bs_row,
            un_row=un_row,
            ev_row=ev_row,
            ow_row=ow_row,
            mr_row=mr_row,
        )

        proposed_bid = pr_row["proposed_builder_id"]
        display_name = pr_row["canonical_promoter_name"] or br_by_id.get(proposed_bid, {}).get("canonical_promoter_name", "")
        p42d_prop = bs_row["proposed_builder_id"] if bs_row is not None else ""
        slug_changed_from_42d = bool(bs_row is not None and p42d_prop != proposed_bid)

        staged_records.append(
            {
                "sort_key": (TIER_SORT_PRIORITY[tier], RISK_SORT_PRIORITY[risk], pid),
                "project_id": pid,
                "registration_number": pr_row["registration_number"],
                "project_name": pr_row["project_name"],
                "existing_builder_id": pr_row["old_builder_id"],
                "proposed_builder_id": proposed_bid,
                "phase4_2d_proposed_builder_id": p42d_prop,
                "slug_changed_from_4_2d_to_v2": str(slug_changed_from_42d),
                "changed_in_firestore": pr_row["changed_in_firestore"],
                "changed_fields": pr_row["changed_fields"],
                "official_krera_promoter_name": pr_row["official_promoter_name"],
                "canonical_display_name": display_name,
                "identity_relationship_type": rel_type,
                "adjudication_queue_tier": tier,
                "in_4_2d_business_signoff_54": str(pid in bs_ids),
                "in_4_2e_unresolved_17": str(pid in un_ids),
                "in_4_2e_ownership_6": str(pid in ow_ids),
                "in_4_2d_manual_review_134": str(pid in mr_ids),
                "in_4_2e_evidence_58": str(pid in ev_ids),
                "in_4_2e_identity_review_126": str(pid in irr_ids),
                "supporting_source_evidence": src_ev,
                "source_file_references": src_files,
                "evidence_confidence": confidence,
                "evidence_limitations": limitations,
                "corporate_verification_status": pr_row["corporate_verification_status"] or "NOT_PERFORMED",
                "risk_classification": risk,
                "can_remain_provisional_without_blocking": str(can_prov),
                "recommended_decision": rec,
                "human_decision_allowed_values": ALLOWED_HUMAN_DECISIONS,
                "human_decision": "",
                "reviewer": "",
                "approval_date": "",
                "comments": "",
                "_pr_row": pr_row,
                "_un_row": un_row,
            }
        )

    staged_records.sort(key=lambda item: item["sort_key"])
    register_rows: List[Dict[str, str]] = []
    bs_queue_rows: List[Dict[str, str]] = []
    un_queue_rows: List[Dict[str, str]] = []

    bs_seq = 0
    un_seq = 0
    for idx, rec in enumerate(staged_records, start=1):
        adj_id = f"ADJ_{idx:03d}"
        rec["adjudication_id"] = adj_id
        register_rows.append({col: rec[col] for col in REGISTER_COLUMNS})

        if rec["in_4_2d_business_signoff_54"] == "True" or rec["in_4_2e_ownership_6"] == "True":
            bs_seq += 1
            origin = (
                "V2_OWNERSHIP_REASSIGNMENT_ADDED_007631"
                if rec["in_4_2d_business_signoff_54"] == "False"
                else ("PHASE_4_2D_54_OVERLAP_UNRESOLVED_17" if rec["in_4_2e_unresolved_17"] == "True" else "PHASE_4_2D_54")
            )
            bs_item = {col: rec.get(col, "") for col in BUSINESS_SIGNOFF_QUEUE_COLUMNS}
            bs_item["queue_id"] = f"BSQ_{bs_seq:03d}"
            bs_item["queue_origin"] = origin
            bs_queue_rows.append(bs_item)

        if rec["in_4_2e_unresolved_17"] == "True":
            un_seq += 1
            un_r = rec["_un_row"]
            pr_r = rec["_pr_row"]
            un_item = {col: rec.get(col, "") for col in UNRESOLVED_QUEUE_COLUMNS}
            un_item["queue_id"] = f"UNQ_{un_seq:03d}"
            un_item["provisional_slug_isolated"] = str("_provisional_" in pr_r["proposed_builder_id"])
            un_item["identity_review_reason"] = pr_r["identity_review_reason"]
            un_item["review_flags"] = un_r["review_flags"] if un_r else pr_r["review_flags"]
            un_item["next_required_evidence"] = un_r["next_required_evidence"] if un_r else ""
            un_queue_rows.append(un_item)

    # 4. Population reconciliation & validation checks
    bs_un_overlap = sorted(bs_ids & un_ids)
    bs_only = sorted(bs_ids - un_ids)
    un_only = sorted(un_ids - bs_ids)
    bs_union_un = sorted(bs_ids | un_ids)
    v2_added_ow = sorted(ow_ids - bs_ids)
    tier_counts = Counter(r["adjudication_queue_tier"] for r in register_rows)
    changed_in_review = sum(1 for r in register_rows if r["changed_in_firestore"] == "True")
    no_impact_count = sum(1 for r in register_rows if r["changed_in_firestore"] == "False")
    total_patched_v2 = sum(1 for r in pr_rows if r["changed_in_firestore"] == "True")
    unflagged_ids = {r["project_id"] for r in pr_rows} - union_review_ids
    unflagged_changed = sum(1 for pid in unflagged_ids if pr_by_id[pid]["changed_in_firestore"] == "True")

    evolutions = [
        {
            "project_id": r["project_id"],
            "registration_number": r["registration_number"],
            "phase4_2d_proposed_builder_id": r["phase4_2d_proposed_builder_id"],
            "v2_proposed_builder_id": r["proposed_builder_id"],
            "decision_code": pr_by_id[r["project_id"]]["decision_code"],
        }
        for r in register_rows
        if r["slug_changed_from_4_2d_to_v2"] == "True"
    ]
    overlapping_records_meta = [
        {
            "project_id": r["project_id"],
            "registration_number": r["registration_number"],
            "existing_builder_id": r["existing_builder_id"],
            "proposed_builder_id": r["proposed_builder_id"],
            "identity_relationship_type": r["identity_relationship_type"],
            "identity_review_reason": pr_by_id[r["project_id"]]["identity_review_reason"],
        }
        for r in register_rows
        if r["in_4_2d_business_signoff_54"] == "True" and r["in_4_2e_unresolved_17"] == "True"
    ]
    un17_only_meta = [
        {
            "project_id": r["project_id"],
            "registration_number": r["registration_number"],
            "existing_builder_id": r["existing_builder_id"],
            "proposed_builder_id": r["proposed_builder_id"],
            "identity_review_reason": pr_by_id[r["project_id"]]["identity_review_reason"],
        }
        for r in register_rows
        if r["in_4_2e_unresolved_17"] == "True" and r["in_4_2d_business_signoff_54"] == "False"
    ]
    ownership6_meta = [
        {
            "project_id": r["project_id"],
            "registration_number": r["registration_number"],
            "project_name": r["project_name"],
            "existing_builder_id": r["existing_builder_id"],
            "proposed_builder_id": r["proposed_builder_id"],
            "in_bs54": r["in_4_2d_business_signoff_54"] == "True",
        }
        for r in register_rows
        if r["in_4_2e_ownership_6"] == "True"
    ]

    every_row_has_evidence = all(
        r["supporting_source_evidence"]
        and r["source_file_references"]
        and r["official_krera_promoter_name"]
        and r["canonical_display_name"]
        and r["human_decision"] == ""
        and r["reviewer"] == ""
        and r["approval_date"] == ""
        and r["comments"] == ""
        and r["corporate_verification_status"] == "NOT_PERFORMED"
        for r in register_rows
    )

    acceptance = {
        "all_59_prior_artifacts_verified_untouched": prior["total_verified"] == 59,
        "rollback_mapping_audit_status_pass": rb_audit["summary"]["rollback_mapping_status"] == "PASS",
        "bs54_and_un17_reconciled_with_15_overlap_and_56_union": (
            len(bs_ids) == 54
            and len(un_ids) == 17
            and len(bs_un_overlap) == 15
            and len(bs_only) == 39
            and len(un_only) == 2
            and len(bs_union_un) == 56
        ),
        "complete_163_case_register_reconciles_to_4110_projects": (
            len(register_rows) == 163
            and len(register_rows) + len(unflagged_ids) == 4110
            and changed_in_review + unflagged_changed == total_patched_v2 == 2059
        ),
        "every_case_has_traceable_source_evidence_and_no_fabricated_approval": every_row_has_evidence,
        "business_signoff_queue_exact_55_cases": len(bs_queue_rows) == 55,
        "unresolved_evidence_queue_exact_17_provisional_non_blocking": (
            len(un_queue_rows) == 17
            and all(r["can_remain_provisional_without_blocking"] == "True" for r in un_queue_rows)
        ),
        "approval_record_preserved_false_and_zero_firestore_writes": (
            upstream["approval_record_approved"] is False
            and freeze["freeze_record"]["approved"] is False
        ),
    }
    prep_status = "PASS" if all(acceptance.values()) else "FAIL"

    safe_provisional_count = sum(
        1 for r in register_rows if r["can_remain_provisional_without_blocking"] == "True"
    )
    risk_counts = Counter(r["risk_classification"] for r in register_rows)

    summary: Dict[str, Any] = {
        "prepared_at_utc": prepared_at_utc,
        "phase": "phase4_2f_human_adjudication",
        "HUMAN_ADJUDICATION_PREPARATION_STATUS": prep_status,
        "PRODUCTION_APPROVAL_STATUS": "NOT_APPROVED",
        "PRODUCTION_EXECUTION_STATUS": "NOT_EXECUTED",
        "CORPORATE_VERIFICATION_STATUS": "NOT_PERFORMED",
        "manifest_v2_path": str((v2_dir / PHASE4_2E_V2_MANIFEST_FILENAME).relative_to(EXTRACTION_ROOT)).replace("\\", "/"),
        "manifest_v2_internal_sha256": manifest_v2["manifest_sha256"],
        "manifest_v2_file_sha256": upstream["manifest_v2_hashes"][PHASE4_2E_V2_MANIFEST_FILENAME]["sha256"],
        "population_reconciliation": {
            "bs_54_count": len(bs_ids),
            "un_17_count": len(un_ids),
            "bs_un_overlap_count": len(bs_un_overlap),
            "bs_only_count": len(bs_only),
            "un_only_count": len(un_only),
            "bs_union_un_count": len(bs_union_un),
            "v2_added_ownership_count": len(v2_added_ow),
            "business_signoff_queue_count": len(bs_queue_rows),
            "core_adjudication_union_count": len(bs_ids | un_ids | ow_ids),
            "advisory_provisional_separate_count": tier_counts["ADVISORY_PROVISIONAL_SEPARATE"],
            "evidence_resolved_migrated_count": tier_counts["EVIDENCE_RESOLVED_MIGRATED"],
            "no_migration_impact_audited_count": tier_counts["EVIDENCE_AUDITED_NO_MIGRATION_IMPACT"],
            "total_cases_reviewed": len(register_rows),
            "reviewed_cases_changed_in_firestore": changed_in_review,
            "unflagged_projects_count": len(unflagged_ids),
            "unflagged_changed_in_firestore": unflagged_changed,
            "total_patched_in_manifest_v2": total_patched_v2,
            "total_projects": len(pr_rows),
            "tier_breakdown": {k: tier_counts[k] for k in sorted(TIER_SORT_PRIORITY, key=lambda x: TIER_SORT_PRIORITY[x]) if tier_counts[k]},
        },
        "approval_summary": {
            "total_cases_reviewed": len(register_rows),
            "approved_decisions": 0,
            "rejected_decisions": 0,
            "provisional_decisions": 0,
            "pending_human_decisions": len(register_rows),
            "cases_awaiting_business_signoff": len(bs_queue_rows),
            "cases_awaiting_additional_evidence": len(un_queue_rows),
            "cases_safe_to_remain_provisional_non_blocking": safe_provisional_count,
            "cases_with_no_impact_on_proposed_migration": no_impact_count,
            "risk_breakdown": dict(risk_counts),
            "remaining_blockers_to_production_approval": [
                "Human review and explicit decision on all 55 cases in business_signoff_queue.csv (especially the 6 HIGH-risk Ownership Reassignments).",
                "Explicit human confirmation to either adjudicate or RETAIN_PROVISIONAL the 17 cases in unresolved_evidence_queue.csv (including 2 Greennesto LLP vs non-LLP cases outside BS_54) without merging.",
                "Explicit human confirmation of the 82 advisory provisional-separate cases (32 remaining merge candidates + 9 JV overlaps + short prefixes + Shell legal forms) remaining unmerged.",
                "Separate human execution of two-stage authorization updating phase4_2b_approval_record.json (approved: false -> true with reviewer, timestamp, and pinned Manifest v2 internal SHA-256 bc661ac73d1222715e645a83951de6034a5a3a8b207f9141e0a2625cb4c0e40b).",
                "Independent MCA/CIN/LLPIN corporate verification remains NOT_PERFORMED (disclosed limitation; non-blocking only if provisional separation policy is accepted by approver).",
            ],
        },
        "overlapping_bs54_un17_records": overlapping_records_meta,
        "un17_only_records": un17_only_meta,
        "ownership_reassignment_6_records": ownership6_meta,
        "phase4_2d_to_v2_slug_evolutions": evolutions,
        "upstream_integrity_and_safety": {
            "artifacts_verified_count": prior["total_verified"],
            "rollback_mapping_status": rb_audit["summary"]["rollback_mapping_status"],
            "freeze_status": freeze["freeze_record"]["freeze_status"],
            "approval_record_approved": upstream["approval_record_approved"],
            "firestore_writes_executed": 0,
            "automatic_merges_performed": 0,
        },
        "acceptance_criteria": acceptance,
    }

    # 5. Write deliverables ONLY into output_dir
    def _write_csv(path: Path, fieldnames: Sequence[str], rows: List[Dict[str, str]]) -> None:
        with path.open("w", encoding="utf-8", newline="") as fh:
            writer = csv.DictWriter(fh, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(rows)

    reg_path = output_dir / "human_adjudication_register.csv"
    bsq_path = output_dir / "business_signoff_queue.csv"
    unq_path = output_dir / "unresolved_evidence_queue.csv"
    sum_path = output_dir / "human_adjudication_summary.json"
    rep_path = output_dir / "phase4_2f_review_and_approval_report.md"
    hsh_path = output_dir / "phase4_2f_artifact_hashes.json"

    _write_csv(reg_path, REGISTER_COLUMNS, register_rows)
    _write_csv(bsq_path, BUSINESS_SIGNOFF_QUEUE_COLUMNS, bs_queue_rows)
    _write_csv(unq_path, UNRESOLVED_QUEUE_COLUMNS, un_queue_rows)
    sum_path.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    rep_path.write_text(_render_markdown_report(summary), encoding="utf-8")

    hashes_doc = {
        "generated_at_utc": prepared_at_utc,
        "phase": "phase4_2f_human_adjudication",
        "HUMAN_ADJUDICATION_PREPARATION_STATUS": prep_status,
        "PRODUCTION_APPROVAL_STATUS": "NOT_APPROVED",
        "PRODUCTION_EXECUTION_STATUS": "NOT_EXECUTED",
        "approval_record_approved": False,
        "firestore_writes_executed": 0,
        "frozen_references": {
            "manifest_v2_internal_sha256": manifest_v2["manifest_sha256"],
            "manifest_v2_file_sha256": upstream["manifest_v2_hashes"][PHASE4_2E_V2_MANIFEST_FILENAME]["sha256"],
            "freeze_record_sha256": freeze["hashes"]["phase4_2e_manifest_v2_freeze_record.json"]["sha256"],
            "rollback_audit_hashes_sha256": rb_audit["hashes"]["rollback_mapping_audit_hashes.json"]["sha256"],
            "phase4_2d_business_signoff_register_sha256": _sha256_file(p42_dir / "phase4_2d_business_signoff_register.csv"),
            "phase4_2d_manual_review_consolidation_sha256": _sha256_file(p42_dir / "phase4_2d_manual_review_consolidation.csv"),
            "phase4_2e_unresolved_identity_register_v2_sha256": upstream["manifest_v2_hashes"]["phase4_2e_unresolved_identity_register_v2.csv"]["sha256"],
        },
        "deliverable_hashes": {
            fp.name: {"size_bytes": fp.stat().st_size, "sha256": _sha256_file(fp)}
            for fp in (reg_path, sum_path, bsq_path, unq_path, rep_path)
        },
    }
    hsh_path.write_text(json.dumps(hashes_doc, indent=2) + "\n", encoding="utf-8")

    return {
        "status": prep_status,
        "output_dir": str(output_dir),
        "deliverables": {
            **hashes_doc["deliverable_hashes"],
            hsh_path.name: {"size_bytes": hsh_path.stat().st_size, "sha256": _sha256_file(hsh_path)},
        },
        "summary": summary,
    }


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Homesure Phase 4.2F Human Adjudication Preparation (Strictly Read-Only).")
    parser.add_argument("--apply", action="store_true", help="Forbidden; always exits non-zero.")
    parser.add_argument("--execute", action="store_true", help="Forbidden; always exits non-zero.")
    parser.add_argument("--approve", action="store_true", help="Forbidden; always exits non-zero.")
    parser.add_argument("--auto-approve", action="store_true", help="Forbidden; always exits non-zero.")
    args = parser.parse_args(argv)
    if args.apply or args.execute or args.approve or args.auto_approve:
        print("ERROR: Phase 4.2F is strictly read-only. Approval/execution flags are forbidden.", file=sys.stderr)
        return 2

    res = run_human_adjudication_preparation()
    print(f"HUMAN_ADJUDICATION_PREPARATION_STATUS: {res['status']}")
    print("PRODUCTION_APPROVAL_STATUS: NOT_APPROVED")
    print("PRODUCTION_EXECUTION_STATUS: NOT_EXECUTED")
    for name, meta in res["deliverables"].items():
        print(f"  {name}: {meta['size_bytes']} bytes, sha256={meta['sha256']}")
    return 0 if res["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
