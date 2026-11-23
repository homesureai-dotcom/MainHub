"""
HomeSure Phase 4.2B — Identity Change Review, Exact Per-Project Invariants,
Exact Builder Payload Verification, Two-Stage Approval & Deferred Docs Tests
Implements all 20 mandatory test requirements (Section 9).
"""

import copy
import json
import sys
from pathlib import Path
from typing import Any, Dict, List

import pytest

EXTRACTION_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_ROOT = EXTRACTION_ROOT / "scripts"
FIRESTORE_IMPORT_ROOT = SCRIPTS_ROOT / "firestore_import"
for p in (str(SCRIPTS_ROOT), str(FIRESTORE_IMPORT_ROOT)):
    if p not in sys.path:
        sys.path.insert(0, p)

from build_and_upload_builders import build_builders_catalog_from_projects, chunk_builders_by_size
from import_projects import FIREBASE_PROJECT_ID, FIRESTORE_DATABASE, firestore_value_to_python, python_to_firestore_value
from phase4_2_builder_sync import (
    apply_migration_manifest,
    export_live_backup,
    plan_migration_operations,
    reconcile_identities_and_ownership,
)
from phase4_2a_hardening import (
    PostconditionFailureError,
    build_evidence_audit,
    load_source_evidence_index,
    validate_evidence_gate,
)
from phase4_2b_verification import (
    ApprovalValidationError,
    BuilderPayloadError,
    MANIFEST_SCHEMA_VERSION_V2_1,
    ProjectInvariantError,
    audit_builder_payloads_exact,
    audit_deferred_builder_documents,
    audit_project_invariants_exact,
    build_approval_record,
    build_identity_change_review,
    validate_approval_record,
    verify_builder_payloads_exact,
    verify_project_invariants_exact,
)


def _apply_firestore_ops(
    store_projects: Dict[str, Dict[str, Any]],
    store_builders: Dict[str, Dict[str, Any]],
    writes: List[Dict[str, Any]],
) -> int:
    prefix = f"projects/{FIREBASE_PROJECT_ID}/databases/{FIRESTORE_DATABASE}/documents/"
    for w in writes:
        if "delete" in w:
            col, doc_id = w["delete"][len(prefix) :].split("/", 1)
            (store_builders if col == "builders" else store_projects).pop(doc_id, None)
            continue
        upd = w["update"]
        col, doc_id = upd["name"][len(prefix) :].split("/", 1)
        decoded = firestore_value_to_python({"mapValue": {"fields": upd.get("fields", {})}})
        mask_paths = (w.get("updateMask") or {}).get("fieldPaths")
        target = store_builders if col == "builders" else store_projects
        if mask_paths:
            cur = target[doc_id]
            for fp in mask_paths:
                if "." not in fp:
                    if fp in decoded:
                        cur[fp] = copy.deepcopy(decoded[fp])
                    else:
                        cur.pop(fp, None)
                else:
                    top, sub = fp.split(".", 1)
                    if isinstance(decoded.get(top), dict) and sub in decoded[top]:
                        cur.setdefault(top, {})[sub] = copy.deepcopy(decoded[top][sub])
                    elif isinstance(cur.get(top), dict):
                        cur[top].pop(sub, None)
        else:
            doc = copy.deepcopy(decoded)
            doc["_doc_id"] = doc_id
            target[doc_id] = doc
    return len(writes)


def _make_sample_project(
    pid: str,
    reg_no: str,
    project_name: str,
    promoter_name: str,
    old_bid: str,
    old_canonical: str,
    taluk: str,
    data_tier: str,
    *,
    is_featured: bool = False,
) -> Dict[str, Any]:
    return {
        "_doc_id": pid,
        "project_id": pid,
        "registration_number": reg_no,
        "acknowledgement_number": f"ACK/{pid}",
        "project_name": project_name,
        "officialProjectName": project_name,
        "normalizedProjectName": project_name.upper(),
        "projectAliases": [project_name],
        "promoter_name": promoter_name,
        "officialBuilderName": promoter_name,
        "builder_id": old_bid,
        "canonical_builder_name": old_canonical,
        "normalizedBuilderName": old_canonical.lower(),
        "builderAliases": [],
        "is_featured_brand": is_featured,
        "nameNormalizationConfidence": "exact_entity",
        "needsManualReview": False,
        "taluk": taluk,
        "normalizedTaluk": taluk,
        "district": "Bengaluru Urban",
        "normalizedDistrict": "Bengaluru Urban",
        "regulatory_status": "APPROVED",
        "sourceRecordId": f"SRC_{pid}",
        "sourcePortal": "KRERA",
        "counts": {"towers": 2, "units": 120},
        "summary_metrics": {"phi_score": 80.0},
        "provenance": {
            "data_tier": data_tier,
            "extraction_status": "successful" if data_tier == "deep_extracted" else "catalogue_only",
            "content_hash": f"hash_{pid}",
        },
        "search_metadata": {"search_tokens": [pid]},
    }


def _build_v2_1_fixture(tmp_path: Path):
    projects = [
        _make_sample_project(
            "p_sowp",
            "PRM/KA/RERA/1251/308/PR/0001",
            "SOWPARNIKA PRANATHI",
            "SOWPARNIKA PROJECTS AND INFRASTRUCTURE PRIVATE LIMITED",
            "builder_sowparnika_projects_and",
            "Sowparnika Projects & Infrastructure",
            "Anekal",
            "catalogue_summary",
        ),
        _make_sample_project(
            "p_sattva",
            "PRM/KA/RERA/1251/310/PR/0002",
            "SRI SRI SATTVA",
            "SRI SUMERU REALTY PRIVATE LIMITED",
            "builder_sattva_group",
            "Sattva Group (Salarpuria Sattva)",
            "Bengaluru North",
            "deep_extracted",
            is_featured=True,
        ),
        _make_sample_project(
            "p_abhee1",
            "PRM/KA/RERA/1251/446/PR/0003",
            "ABHEE LAKEVIEW",
            "ABHEE VENTURES PRIVATE LIMITED",
            "builder_abhee",
            "Abhee",
            "Bengaluru East",
            "deep_extracted",
        ),
        _make_sample_project(
            "p_abhee2",
            "PRM/KA/RERA/1251/446/PR/0004",
            "ABHEE PRIDE",
            "ABHEE DEVELOPERS PRIVATE LIMITED",
            "builder_abhee",
            "Abhee",
            "Bengaluru East",
            "catalogue_summary",
        ),
    ]
    # Seed ONLY pre-migration legacy builders in `builders_docs` so corrected builders are CREATE targets
    legacy_builders = [
        {
            "builder_id": "builder_abhee",
            "builder_name": "Abhee",
            "normalized_builder_name": "abhee",
            "is_featured_brand": False,
            "builder_aliases": [],
            "legal_promoter_names": ["ABHEE VENTURES PRIVATE LIMITED", "ABHEE DEVELOPERS PRIVATE LIMITED"],
            "localities": ["Bengaluru East"],
            "project_count": 2,
            "project_ids": ["p_abhee1", "p_abhee2"],
            "projects": [],
        },
        {
            "builder_id": "builder_sowparnika_projects_and",
            "builder_name": "Sowparnika Projects & Infrastructure",
            "normalized_builder_name": "sowparnika projects and",
            "is_featured_brand": False,
            "builder_aliases": [],
            "legal_promoter_names": ["SOWPARNIKA PROJECTS AND INFRASTRUCTURE PRIVATE LIMITED"],
            "localities": ["Anekal"],
            "project_count": 1,
            "project_ids": ["p_sowp"],
            "projects": [],
        },
        {
            "builder_id": "builder_sattva_group",
            "builder_name": "Sattva Group (Salarpuria Sattva)",
            "normalized_builder_name": "sattva",
            "is_featured_brand": True,
            "builder_aliases": [],
            "legal_promoter_names": ["SRI SUMERU REALTY PRIVATE LIMITED"],
            "localities": ["Bengaluru North"],
            "project_count": 1,
            "project_ids": ["p_sattva"],
            "projects": [],
        },
    ]
    builders_docs: Dict[str, Any] = {
        "_catalog_chunk_1": {
            "_doc_id": "_catalog_chunk_1",
            "chunk_id": "_catalog_chunk_1",
            "chunk_index": 1,
            "total_chunks": 1,
            "builders_count": len(legacy_builders),
            "builders": legacy_builders,
        },
        "_catalog_meta": {
            "_doc_id": "_catalog_meta",
            "meta_id": "_catalog_meta",
            "schema_version": "1.1.0",
            "total_chunks": 1,
            "chunk_ids": ["_catalog_chunk_1"],
            "total_builders": len(legacy_builders),
            "total_projects": len(projects),
            "deep_extracted_projects": 2,
            "catalogue_summary_projects": 2,
            "updated_at": "2026-11-22T00:00:00Z",
        },
    }
    for b in legacy_builders:
        builders_docs[b["builder_id"]] = {"_doc_id": b["builder_id"], **b}

    bm = export_live_backup(projects, builders_docs, tmp_path)
    plan = plan_migration_operations(
        projects,
        builders_docs,
        backup_manifest=bm,
        backup_dir=tmp_path,
        deletions_enabled=False,
        hardening_mode=True,
        schema_version=MANIFEST_SCHEMA_VERSION_V2_1,
    )
    return projects, builders_docs, bm, plan


@pytest.fixture(scope="module")
def real_4110_state():
    bdir = EXTRACTION_ROOT / "data/phase4_2_backup_20261122"
    p_file = bdir / "projects_builder_fields_backup.json"
    b_file = bdir / "builders_backup.json"
    bm_file = bdir / "backup_manifest.json"
    m_file = bdir / "phase4_2b_migration_manifest.json"
    if not (p_file.exists() and b_file.exists() and bm_file.exists()):
        pytest.skip("Real Phase 4.2 backup files missing")
    p_raw = json.loads(p_file.read_text(encoding="utf-8"))
    b_raw = json.loads(b_file.read_text(encoding="utf-8"))
    projects = [{**v, "_doc_id": k} for k, v in p_raw.items()]
    builders_docs = {k: {**v, "_doc_id": k} for k, v in b_raw.items()}
    recon = reconcile_identities_and_ownership(projects, builders_docs)
    src_idx = load_source_evidence_index(EXTRACTION_ROOT)
    ev = build_evidence_audit(recon, projects, src_idx)
    id_rev = build_identity_change_review(recon, ev, projects)
    bm = json.loads(bm_file.read_text(encoding="utf-8"))
    plan = (
        json.loads(m_file.read_text(encoding="utf-8"))
        if m_file.exists()
        else plan_migration_operations(
            projects,
            builders_docs,
            backup_manifest=bm,
            backup_dir=bdir,
            evidence_audit=ev,
            schema_version=MANIFEST_SCHEMA_VERSION_V2_1,
        )
    )
    return projects, builders_docs, recon, ev, id_rev, plan


# ===========================================================================
# 1–5: Workstream A — Identity Change Review & Separation
# ===========================================================================

class TestWorkstreamAIdentityReview:
    def test_01_all_494_split_cases_in_identity_review(self, real_4110_state):
        _, _, _, _, id_rev, _ = real_4110_state
        s = id_rev["summary"]
        assert s["split_case_count"] == 494
        assert s["auto_approved_count"] == 0
        split_rows = [
            r for r in id_rev["review_rows"]
            if r["classification"] in ("PROMOTER_ENTITY_SPLIT", "BRAND_PROMOTER_RELATIONSHIP")
        ]
        assert len(split_rows) == 494

    def test_02_all_5_ownership_changes_individually_reviewable(self, real_4110_state):
        _, _, _, _, id_rev, _ = real_4110_state
        own_rows = [r for r in id_rev["review_rows"] if r["classification"] == "OWNERSHIP_REASSIGNMENT"]
        assert len(own_rows) == 5
        assert {r["project_id"] for r in own_rows} == {
            "REG_PRM_KA_RERA_1251_310_PR_300625_007883",  # Sri Sri Sattva
            "REG_PRM_KA_RERA_1251_446_PR_240323_005820",  # THARUNS B V SATTVA
            "REG_PRM_KA_RERA_1251_310_PR_040324_006661",  # SRI SRI NAGAR
            "REG_PRM_KA_RERA_1251_310_PR_060424_006779",  # HARIVISHRAM
            "REG_PRM_KA_RERA_1251_310_PR_171015_000787",  # SURATARU
        }
        assert all(r["review_status"] == "MANUAL_REVIEW_REQUIRED" for r in own_rows)

    def test_03_slug_only_changes_classified_as_slug_only_not_legal_split(self, real_4110_state):
        _, _, _, _, id_rev, _ = real_4110_state
        cc = id_rev["summary"]["classification_counts"]
        assert cc["SLUG_ONLY_CHANGE"] == 1558
        assert cc["UNRESOLVED_IDENTITY"] == 0
        # Verify none of the 1,558 slug-only rows leaked into split review as entity splits
        assert len(id_rev["review_rows"]) == 499

    def test_04_missing_evidence_prevents_approval_gate(self):
        recon = {
            "project_rows": [
                {
                    "project_id": "p_missing_ev",
                    "registration_number": "PRM/KA/RERA/NONE",
                    "project_name": "MISSING EVID",
                    "promoter_name": "SOME BUILDER",
                    "existing_builder_id": "builder_a",
                    "existing_canonical_name": "Builder A",
                    "corrected_builder_id": "builder_some_builder",
                    "corrected_canonical_name": "Some Builder",
                    "taluk": "Anekal",
                    "relationship_change": "SPLIT_ENTITY_SEPARATION",
                    "confidence_level": "exact_entity",
                    "evidence": "Description only",
                }
            ],
            "jv_brand_overlaps": [],
            "merge_candidates": [],
            "new_groups": {},
        }
        ev = build_evidence_audit(recon, [{"_doc_id": "p_missing_ev", "officialBuilderName": "SOME BUILDER"}], {})
        assert validate_evidence_gate(ev["rows"])["status"] == "BLOCKED"
        rev = build_identity_change_review(recon, ev, [])
        assert rev["review_rows"][0]["classification"] == "UNRESOLVED_IDENTITY"
        assert rev["review_rows"][0]["review_status"] == "MANUAL_REVIEW_REQUIRED"

    def test_05_brand_promoter_relationships_remain_separate(self, real_4110_state):
        _, _, recon, _, id_rev, _ = real_4110_state
        assert len(recon["jv_brand_overlaps"]) == 9
        assert len(recon["merge_candidates"]) == 33
        jv_rows = [r for r in id_rev["review_rows"] if r["classification"] == "BRAND_PROMOTER_RELATIONSHIP"]
        assert len(jv_rows) > 0
        assert all(r["review_status"] == "MANUAL_REVIEW_REQUIRED" for r in jv_rows)


# ===========================================================================
# 6–11: Workstream B — Exact Per-Project Invariants
# ===========================================================================

class TestWorkstreamBProjectInvariants:
    def test_06_all_4110_project_invariant_comparisons_pass(self, real_4110_state):
        projects, _, _, _, _, plan = real_4110_state
        res = audit_project_invariants_exact(projects, plan)
        assert res["status"] == "PASS"
        assert res["projects_checked"] == 4110
        assert res["total_field_comparisons"] == 4110 * 9
        assert res["mismatch_count"] == 0

    def test_07_modified_registration_number_fails(self, tmp_path: Path):
        projects, _, _, _ = _build_v2_1_fixture(tmp_path)
        bad_post = copy.deepcopy(projects)
        bad_post[0]["registration_number"] = "PRM/KA/RERA/TAMPERED/9999"
        with pytest.raises(ProjectInvariantError, match="registration_number"):
            verify_project_invariants_exact(projects, bad_post)

    def test_08_modified_project_name_fails(self, tmp_path: Path):
        projects, _, _, _ = _build_v2_1_fixture(tmp_path)
        bad_post = copy.deepcopy(projects)
        bad_post[0]["officialProjectName"] = "TAMPERED PROJECT NAME"
        with pytest.raises(ProjectInvariantError, match="project_name"):
            verify_project_invariants_exact(projects, bad_post)

    def test_09_modified_taluk_fails(self, tmp_path: Path):
        projects, _, _, _ = _build_v2_1_fixture(tmp_path)
        bad_post = copy.deepcopy(projects)
        bad_post[0]["normalizedTaluk"] = "Bengaluru South"
        with pytest.raises(ProjectInvariantError, match="taluk"):
            verify_project_invariants_exact(projects, bad_post)

    def test_10_modified_data_tier_fails(self, tmp_path: Path):
        projects, _, _, _ = _build_v2_1_fixture(tmp_path)
        bad_post = copy.deepcopy(projects)
        bad_post[0]["provenance"]["data_tier"] = "deep_extracted"
        with pytest.raises(ProjectInvariantError, match="data_tier"):
            verify_project_invariants_exact(projects, bad_post)

    def test_11_modified_regulatory_reference_fails(self, tmp_path: Path):
        projects, _, _, _ = _build_v2_1_fixture(tmp_path)
        bad_post = copy.deepcopy(projects)
        bad_post[1]["counts"]["units"] = 9999
        with pytest.raises(ProjectInvariantError, match="regulatory_bundle_reference"):
            verify_project_invariants_exact(projects, bad_post)


# ===========================================================================
# 12–14: Workstream C — Exact Builder Payloads & Project Membership
# ===========================================================================

class TestWorkstreamCBuilderPayloads:
    def test_12_builder_payload_catches_incorrect_field(self, tmp_path: Path):
        projects, builders_docs, _, plan = _build_v2_1_fixture(tmp_path)
        # Sanity check passes before tampering
        assert audit_builder_payloads_exact(projects, builders_docs, plan)["status"] == "PASS"

        tampered = copy.deepcopy(plan)
        tampered["staged_ops"]["create_builder_docs"][0]["update"]["fields"]["builder_name"] = python_to_firestore_value("WRONG NAME")
        with pytest.raises(BuilderPayloadError):
            verify_builder_payloads_exact(projects, builders_docs, tampered)

    def test_13_builder_membership_catches_swapped_project_id(self, tmp_path: Path):
        projects, builders_docs, _, plan = _build_v2_1_fixture(tmp_path)
        tampered = copy.deepcopy(plan)
        op0 = tampered["staged_ops"]["create_builder_docs"][0]
        # Keep exact project_count=1, swap project_id inside project_ids!
        op0["update"]["fields"]["project_ids"] = python_to_firestore_value(["p_swapped_fake"])
        with pytest.raises(BuilderPayloadError):
            verify_builder_payloads_exact(projects, builders_docs, tampered)

    def test_14_unmanaged_builder_fields_preserved(self, tmp_path: Path):
        projects, builders_docs, _, _ = _build_v2_1_fixture(tmp_path)
        bdocs = copy.deepcopy(builders_docs)
        # Seed an existing target builder doc with unmanaged CRM metadata and stale project_count
        bdocs["builder_abhee_ventures"] = {
            "_doc_id": "builder_abhee_ventures",
            "builder_id": "builder_abhee_ventures",
            "builder_name": "Abhee Ventures",
            "project_count": 99,
            "project_ids": ["p_abhee1"],
            "custom_crm_id": "CRM-777",
            "editorial_note": "Keep this editorial note",
        }
        plan2 = plan_migration_operations(
            projects,
            bdocs,
            deletions_enabled=False,
            hardening_mode=True,
            schema_version=MANIFEST_SCHEMA_VERSION_V2_1,
        )
        res = audit_builder_payloads_exact(projects, bdocs, plan2)
        assert res["status"] == "PASS"
        row = next(r for r in res["rows"] if r["document_path"] == "builders/builder_abhee_ventures")
        assert row["operation_type"] == "UPDATE"
        assert "custom_crm_id" in row["unmanaged_fields_preserved"]
        assert "editorial_note" in row["unmanaged_fields_preserved"]


# ===========================================================================
# 15–17: Workstream D — Two-Stage Approval Record Hardening
# ===========================================================================

class TestWorkstreamDApprovalHardening:
    def test_15_approval_record_binds_to_exact_manifest_hash(self, tmp_path: Path):
        projects, builders_docs, _, plan = _build_v2_1_fixture(tmp_path)
        assert "human_approval" not in plan
        rec = build_approval_record(
            plan,
            approved=True,
            approved_by="principal-reviewer@homesure.ai",
            approved_at_utc="2026-11-22T18:00:00Z",
        )
        ver = validate_approval_record(rec, plan, FIREBASE_PROJECT_ID, FIRESTORE_DATABASE)
        assert ver["status"] == "AUTHORIZED"
        assert ver["approved_manifest_sha256"] == plan["manifest_sha256"]

    def test_16_approval_record_for_different_manifest_rejected(self, tmp_path: Path):
        _, _, _, plan = _build_v2_1_fixture(tmp_path)
        rec = build_approval_record(
            plan,
            approved=True,
            approved_by="principal-reviewer@homesure.ai",
            approved_at_utc="2026-11-22T18:00:00Z",
        )
        rec["approved_manifest_sha256"] = "a" * 64  # bound to a different manifest
        with pytest.raises(ApprovalValidationError, match="SHA-256 mismatch"):
            validate_approval_record(rec, plan, FIREBASE_PROJECT_ID, FIRESTORE_DATABASE)

    def test_17_approval_remains_false_in_hardening_mode(self, tmp_path: Path):
        projects, builders_docs, _, plan = _build_v2_1_fixture(tmp_path)
        rec = build_approval_record(plan, approved=False)
        assert rec["approved"] is False
        with pytest.raises(ApprovalValidationError, match="approved != True"):
            validate_approval_record(rec, plan, FIREBASE_PROJECT_ID, FIRESTORE_DATABASE)
        with pytest.raises(ApprovalValidationError):
            apply_migration_manifest(
                plan,
                token="t",
                backup_dir=tmp_path,
                read_state_fn=lambda: (projects, builders_docs),
                commit_fn=lambda b, _t: len(b),
                approval_record=rec,
            )


# ===========================================================================
# 18–20: Workstream E & Postcondition Gates
# ===========================================================================

class TestWorkstreamEDeferredAndPostconditions:
    def test_18_59_deferred_docs_remain_untouched(self, real_4110_state):
        _, _, _, _, _, plan = real_4110_state
        assert len(plan["deferred_deletion_candidates"]) == 59
        assert plan["staged_ops"]["delete_stale_builders_docs"] == []
        assert plan["op_counts"]["delete_stale_individual_builder_docs"] == 0

    def test_19_publicly_exposed_docs_not_classified_deletable(self, real_4110_state):
        projects, builders_docs, _, _, _, plan = real_4110_state
        s_map = {s["project_id"]: s["new_builder_id"] for s in plan["project_patch_summaries"]}
        corrected_post = [{**p, "builder_id": s_map.get(p["_doc_id"], p.get("builder_id"))} for p in projects]
        res = audit_deferred_builder_documents(
            plan["deferred_deletion_candidates"],
            builders_docs,
            corrected_post,
            set(plan["expected_canonical_builder_ids"]),
            firestore_rules_public_read=True,
            repo_direct_doc_consumers=0,
            backend_function_consumers=0,
            external_dependency_status="UNKNOWN",
        )
        assert res["total_reviewed"] == 59
        assert "ORPHANED_INTERNAL" not in res["classification_counts"]
        assert res["classification_counts"]["ORPHANED_BUT_PUBLICLY_EXPOSED"] == 59
        assert all(not r["safe_to_delete_based_solely_on_repo_search"] for r in res["rows"])

    def test_20_failed_postcondition_prevents_migration_readiness(self, tmp_path: Path):
        projects, builders_docs, _, plan = _build_v2_1_fixture(tmp_path)
        approval = build_approval_record(
            plan,
            approved=True,
            approved_by="qa@homesure.ai",
            approved_at_utc="2026-11-22T18:00:00Z",
        )
        store_projects = {p["_doc_id"]: copy.deepcopy(p) for p in projects}
        store_builders = copy.deepcopy(builders_docs)

        # Inject a silent postcondition violation during patch_projects (mutate project_name)
        def sneaky_corrupt_commit(batch, _t):
            n = _apply_firestore_ops(store_projects, store_builders, batch)
            for op in batch:
                if "/projects/" in (op.get("update") or {}).get("name", ""):
                    store_projects["p_sowp"]["officialProjectName"] = "SILENTLY MUTATED TITLE"
            return n

        with pytest.raises(PostconditionFailureError, match="project_name"):
            apply_migration_manifest(
                plan,
                token="t",
                backup_dir=tmp_path,
                read_state_fn=lambda: (list(store_projects.values()), store_builders),
                commit_fn=sneaky_corrupt_commit,
                approval_record=approval,
            )
