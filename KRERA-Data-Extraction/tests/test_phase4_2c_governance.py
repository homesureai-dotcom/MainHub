"""
HomeSure Phase 4.2C — Canonical Promoter Identity Governance, Complete 2,057-Row
Review Reconciliation, Chunk Membership Audit & Unmanaged Field Preservation Tests.
Implements all 12 Workstream G requirements plus all 5 Workstream E failure-injection tests.
"""

from __future__ import annotations

import copy
import csv
import json
import sys
from pathlib import Path
from typing import Any, Dict, List

import pytest

EXTRACTION_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_ROOT = EXTRACTION_ROOT / "scripts"
FIRESTORE_IMPORT_ROOT = SCRIPTS_ROOT / "firestore_import"
BACKUP_DIR = EXTRACTION_ROOT / "data" / "phase4_2_backup_20261122"
REPORTS_DIR = EXTRACTION_ROOT / "reports" / "phase4_2"

for _p in (str(SCRIPTS_ROOT), str(FIRESTORE_IMPORT_ROOT)):
    if _p not in sys.path:
        sys.path.insert(0, _p)

from import_projects import (
    FIREBASE_PROJECT_ID,
    FIRESTORE_DATABASE,
    python_to_firestore_value,
)
from name_normalization import normalize_corporate_entity_name
from phase4_2_builder_sync import (
    apply_migration_manifest,
    export_live_backup,
    plan_migration_operations,
    reconcile_identities_and_ownership,
)
from phase4_2b_verification import (
    ApprovalValidationError,
    MANIFEST_SCHEMA_VERSION_V2_1,
    _simulate_project_patches,
    build_approval_record,
    validate_approval_record,
)
from phase4_2c_governance import (
    CHUNK_AUDIT_COLUMNS,
    COMPLETE_REGISTER_COLUMNS,
    CORPORATE_VERIFICATION_CLAIM_NONE,
    PROMOTER_AUDIT_COLUMNS,
    UNMANAGED_AUDIT_COLUMNS,
    ChunkMembershipAuditError,
    ReviewReconciliationError,
    UnauthorizedFieldRemovalError,
    audit_chunk_membership_complete,
    audit_unmanaged_fields,
    build_business_identity_decisions,
    build_complete_2057_review_register,
    build_promoter_name_normalization_audit,
    merge_preserving_unmanaged_fields,
    verify_chunk_membership_complete,
)


def _make_sample_project(
    pid: str,
    reg_no: str,
    project_name: str,
    promoter_name: str,
    old_bid: str,
    old_canonical: str,
    taluk: str = "Bengaluru East",
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
        "city": "Bengaluru",
        "regulatory_status": "APPROVED",
        "provenance": {
            "data_tier": "deep_extracted",
            "extraction_status": "extracted_verified",
            "content_hash": f"hash_{pid}",
        },
        "sourceRecordId": pid,
        "sourcePortal": "KRERA",
        "counts": {"total_units": 50, "total_fields": 30},
        "summary_metrics": {"total_units_inventories": {"value": "50"}},
        "towers_summary": [{"tower": "A"}],
    }


def _make_evidence_audit(recon: Dict[str, Any], projects: List[Dict[str, Any]]) -> Dict[str, Any]:
    by_id = {p["_doc_id"]: p for p in projects}
    jv_bids = {b for jv in recon.get("jv_brand_overlaps") or [] for b in jv.get("builder_ids") or []}
    merge_bids = {b for mc in recon.get("merge_candidates") or [] for b in mc.get("builder_ids") or []}
    rows = []
    for pr in recon["project_rows"]:
        pid = pr["project_id"]
        pdoc = by_id[pid]
        orig_prom = str(pdoc["promoter_name"])
        corr_bid = pr["corrected_builder_id"]
        is_feat = bool(recon["new_groups"][corr_bid][0][1]["is_featured_brand"])
        rows.append(
            {
                "project_id": pid,
                "registration_number": pr["registration_number"],
                "project_name": pr["project_name"],
                "relationship_change": pr["relationship_change"],
                "existing_builder_id": pr["existing_builder_id"],
                "corrected_builder_id": corr_bid,
                "original_portal_promoter_name": orig_prom,
                "live_firestore_promoter_name": orig_prom,
                "normalized_promoter_name": normalize_corporate_entity_name(orig_prom) or orig_prom,
                "source_promoter_matches_live": True,
                "source_file": "data/phase4_recovery/phase4_recovery.sqlite",
                "source_record_id": f"src_{pid}",
                "source_uri": f"https://rera.karnataka.gov.in/{pid}",
                "extraction_timestamp": "2026-11-07T00:00:00Z",
                "source_record_hash": f"sha_{pid}",
                "assignment_mechanism": (
                    "EXPLICIT_BRAND_RULE_SOURCE_BACKED" if is_feat else "FALLBACK_PROMOTER_NORMALIZATION"
                ),
                "in_merge_candidate_pair": corr_bid in merge_bids,
                "in_jv_overlap_pair": corr_bid in jv_bids,
            }
        )
    return {"rows": rows}


def _fixture_universe() -> tuple[List[Dict[str, Any]], Dict[str, Dict[str, Any]]]:
    projects = [
        _make_sample_project(
            "P1",
            "PRM/KA/RERA/1251/446/PR/000001",
            "Prestige Heights",
            "M/s. Prestige Estates Projects Limited.",
            "builder_prestige_estates_old",
            "Prestige Old",
            is_featured=True,
        ),
        _make_sample_project(
            "P2",
            "PRM/KA/RERA/1251/446/PR/000002",
            "Alpha Green",
            "Alpha Infra Private Limited",
            "builder_alpha",
            "Alpha",
        ),
        _make_sample_project(
            "P3",
            "PRM/KA/RERA/1251/446/PR/000003",
            "Alpha Two",
            "ALPHA   INFRA   PVT. LTD.",
            "builder_alpha",
            "Alpha",
        ),
        _make_sample_project(
            "P4",
            "PRM/KA/RERA/1251/446/PR/000004",
            "Beta Square",
            "Beta Ventures LLP",
            "builder_alpha",
            "Alpha",
        ),
        _make_sample_project(
            "P5",
            "PRM/KA/RERA/1251/446/PR/000005",
            "Mini Oak",
            "AB",
            "builder_ab",
            "AB",
        ),
        _make_sample_project(
            "P6",
            "PRM/KA/RERA/1251/446/PR/000006",
            "RR Plaza",
            "RR. ENTERPRISES",
            "builder_rr_enterprises",
            "Rr Enterprises",
        ),
    ]
    builders_docs: Dict[str, Dict[str, Any]] = {
        "_catalog_chunk_1": {
            "_doc_id": "_catalog_chunk_1",
            "builders": [
                {"builder_id": "builder_prestige_estates_old", "builder_name": "Prestige Old", "builder_aliases": []},
                {"builder_id": "builder_alpha", "builder_name": "Alpha", "builder_aliases": []},
                {"builder_id": "builder_ab", "builder_name": "AB", "builder_aliases": []},
                {"builder_id": "builder_rr_enterprises", "builder_name": "Rr Enterprises", "builder_aliases": []},
            ],
        },
        "builder_rr_enterprises": {
            "_doc_id": "builder_rr_enterprises",
            "builder_id": "builder_rr_enterprises",
            "builder_name": "Rr Enterprises",
            "normalized_builder_name": "rr enterprises",
            "builder_aliases": ["RR ENTERPRISES"],
            "is_featured_brand": False,
            "project_count": 1,
            "legal_promoter_names": ["RR. ENTERPRISES"],
            "localities": ["Bengaluru East"],
            "project_ids": ["P6"],
            "projects": [],
        },
    }
    return projects, builders_docs


class TestWorkstreamGPhase42CGovernance:
    """Tests 1–12 matching Phase 4.2C Workstream G + Workstream E failure injections."""

    def test_01_official_promoter_names_remain_unchanged(self):
        projects, builders_docs = _fixture_universe()
        recon = reconcile_identities_and_ownership(projects, builders_docs)
        ev = _make_evidence_audit(recon, projects)
        plan = plan_migration_operations(projects, builders_docs, evidence_audit=ev)
        post = _simulate_project_patches(projects, plan["staged_ops"]["patch_projects"])

        # Exact unmodified K-RERA strings must survive on `/projects` and in audit
        audit = build_promoter_name_normalization_audit(recon, ev, projects)
        by_id = audit["by_id"]
        assert by_id["P1"]["official_promoter_name"] == "M/s. Prestige Estates Projects Limited."
        assert by_id["P2"]["official_promoter_name"] == "Alpha Infra Private Limited"
        assert by_id["P3"]["official_promoter_name"] == "ALPHA   INFRA   PVT. LTD."
        assert by_id["P4"]["official_promoter_name"] == "Beta Ventures LLP"
        assert by_id["P6"]["official_promoter_name"] == "RR. ENTERPRISES"

        post_by_id = {p["_doc_id"]: p for p in post}
        for orig in projects:
            pid = orig["_doc_id"]
            assert post_by_id[pid]["promoter_name"] == orig["promoter_name"]
            assert post_by_id[pid]["officialBuilderName"] == orig["officialBuilderName"]

    def test_02_canonical_promoter_normalization_is_separate(self):
        projects, builders_docs = _fixture_universe()
        recon = reconcile_identities_and_ownership(projects, builders_docs)
        ev = _make_evidence_audit(recon, projects)
        audit = build_promoter_name_normalization_audit(recon, ev, projects)

        assert list(audit["rows"][0].keys()) == PROMOTER_AUDIT_COLUMNS
        p1 = audit["by_id"]["P1"]
        assert p1["official_promoter_name"] == "M/s. Prestige Estates Projects Limited."
        assert p1["canonical_promoter_name"] == "Prestige Group"
        assert p1["official_promoter_name"] != p1["canonical_promoter_name"]
        assert p1["promoter_identity_type"] == "FEATURED_BRAND"
        assert p1["identity_verification_status"] == "NORMALIZED_FROM_SOURCE"
        assert p1["corporate_verification_claim"] == CORPORATE_VERIFICATION_CLAIM_NONE
        assert "aliases do not establish legal equivalence" in p1["aliases_provenance_note"].lower()

        p5 = audit["by_id"]["P5"]
        assert p5["identity_verification_status"] == "MANUAL_REVIEW_REQUIRED"

    def test_03_corporate_suffix_differences_not_treated_as_legal_proof(self):
        projects, builders_docs = _fixture_universe()
        recon = reconcile_identities_and_ownership(projects, builders_docs)
        ev = _make_evidence_audit(recon, projects)
        audit = build_promoter_name_normalization_audit(recon, ev, projects)

        # Alpha Infra Private Limited vs ALPHA INFRA PVT. LTD. vs Beta Ventures LLP vs M/s.
        p1 = audit["by_id"]["P1"]
        p2 = audit["by_id"]["P2"]
        p3 = audit["by_id"]["P3"]
        p4 = audit["by_id"]["P4"]

        assert p1["has_ms_prefix"] is True
        assert p2["has_pvt_ltd_variant"] is True
        assert p3["has_pvt_ltd_variant"] is True
        assert p4["has_llp_suffix"] is True
        assert p4["corporate_suffix_removed"] is True
        assert p2["corporate_verification_claim"] == CORPORATE_VERIFICATION_CLAIM_NONE

        # Real CSV check: corporate_verification_claim NEVER asserts MCA/GSTIN
        prom_csv = REPORTS_DIR / "phase4_2c_promoter_name_normalization_audit.csv"
        if prom_csv.exists():
            with prom_csv.open(encoding="utf-8") as fh:
                rrows = list(csv.DictReader(fh))
            assert len(rrows) == 4110
            assert all(r["corporate_verification_claim"] == CORPORATE_VERIFICATION_CLAIM_NONE for r in rrows)
            # Confirm distinct P192-style suffix differences are flagged
            assert any(r["has_pvt_ltd_variant"] == "True" for r in rrows)
            assert any(r["has_llp_suffix"] == "True" for r in rrows)
            assert any(r["has_ms_prefix"] == "True" for r in rrows)

    def test_04_complete_2057_review_register_reconciles_exactly(self):
        # 1. Tamper guard on synthetic reconciliation
        projects, builders_docs = _fixture_universe()
        recon = reconcile_identities_and_ownership(projects, builders_docs)
        ev = _make_evidence_audit(recon, projects)
        reg = build_complete_2057_review_register(recon, ev, projects)
        assert list(reg["rows"][0].keys()) == COMPLETE_REGISTER_COLUMNS
        assert reg["summary"]["auto_approved_count"] == 0
        assert all(r["reviewer_decision"] == "PENDING_HUMAN_DECISION" for r in reg["rows"])

        # Corrupt recon short_prefix_reviews so reconciliation count must fail loudly
        bad_recon = copy.deepcopy(recon)
        bad_recon["short_prefix_reviews"].append({"registrations": ["FAKE_1", "FAKE_2"]})
        with pytest.raises(ReviewReconciliationError):
            build_complete_2057_review_register(bad_recon, ev, projects)

        # 2. Exact reconciliation on generated 2,057-row CSV from real production backup/audit
        csv_path = REPORTS_DIR / "phase4_2c_complete_identity_review_register.csv"
        assert csv_path.exists(), f"Missing deliverable CSV: {csv_path}"
        with csv_path.open(encoding="utf-8") as fh:
            reader = csv.DictReader(fh)
            assert list(reader.fieldnames or []) == COMPLETE_REGISTER_COLUMNS
            rows = list(reader)

        assert len(rows) == 2057
        assert len({r["project_id"] for r in rows}) == 2057
        assert all(r["reviewer_decision"] == "PENDING_HUMAN_DECISION" for r in rows)
        assert not any(r["review_status"] == "APPROVED" for r in rows)

        manual_rows = [r for r in rows if r["review_status"] == "MANUAL_REVIEW_REQUIRED"]
        pending_rows = [r for r in rows if r["review_status"] == "PENDING_HUMAN_REVIEW"]
        assert len(manual_rows) + len(pending_rows) == 2057
        assert len(manual_rows) == 134
        assert len(pending_rows) == 1923

    def test_05_all_50_plus_advisories_explicitly_accounted_for(self):
        csv_42c = REPORTS_DIR / "phase4_2c_complete_identity_review_register.csv"
        csv_42b = REPORTS_DIR / "phase4_2b_identity_change_review.csv"
        assert csv_42c.exists() and csv_42b.exists()

        rows_42c = list(csv.DictReader(csv_42c.open(encoding="utf-8")))
        rows_42b = list(csv.DictReader(csv_42b.open(encoding="utf-8")))
        pids_42b = {r["project_id"] for r in rows_42b}
        manual_42b_in_499 = sum(1 for r in rows_42b if r["review_status"] == "MANUAL_REVIEW_REQUIRED")
        assert len(rows_42b) == 499
        assert manual_42b_in_499 == 36

        # Reconcile exact 86 = 36 (in 499) + 50 (MERGE_CANDIDATE in 1,558 slug-only)
        slug_only_rows = [r for r in rows_42c if r["project_id"] not in pids_42b]
        assert len(slug_only_rows) == 1558
        slug_only_merge = [r for r in slug_only_rows if "MERGE_CANDIDATE_PAIR" in r["advisory_type"]]
        assert len(slug_only_merge) == 50
        assert manual_42b_in_499 + len(slug_only_merge) == 86

        # Reconcile all 56 SHORT_PREFIX_ADVISORY + 4 slug-only JV overlaps
        short_prefix_rows = [r for r in rows_42c if "SHORT_PREFIX_ADVISORY" in r["advisory_type"]]
        assert len(short_prefix_rows) == 56
        assert all(r["review_status"] == "MANUAL_REVIEW_REQUIRED" for r in short_prefix_rows)
        slug_jv_rows = [r for r in slug_only_rows if "JV_BRAND_OVERLAP" in r["advisory_type"]]
        assert len(slug_jv_rows) == 4
        assert all(r["review_status"] == "MANUAL_REVIEW_REQUIRED" for r in slug_jv_rows)

    def test_06_all_499_split_and_reassignment_records_traceable(self):
        # Synthetic business decisions check
        projects, builders_docs = _fixture_universe()
        recon = reconcile_identities_and_ownership(projects, builders_docs)
        ev = _make_evidence_audit(recon, projects)
        prom_audit = build_promoter_name_normalization_audit(recon, ev, projects)
        comp_reg = build_complete_2057_review_register(recon, ev, projects)
        biz = build_business_identity_decisions(recon, ev, prom_audit, comp_reg)
        assert biz["summary"]["auto_approved_count"] == 0

        # Real 499-row business decisions deliverable check
        biz_csv = REPORTS_DIR / "phase4_2c_business_identity_decisions.csv"
        assert biz_csv.exists()
        rows = list(csv.DictReader(biz_csv.open(encoding="utf-8")))
        assert len(rows) == 499
        splits = sum(1 for r in rows if r["classification"] == "PROMOTER_ENTITY_SPLIT")
        jv = sum(1 for r in rows if r["classification"] == "BRAND_PROMOTER_RELATIONSHIP")
        own = sum(1 for r in rows if r["classification"] == "OWNERSHIP_REASSIGNMENT")
        assert splits == 488
        assert jv == 6
        assert own == 5
        assert all(
            r["source_record_id"] and r["source_file"] and r["source_record_hash"] and r["source_uri"]
            for r in rows
        )
        assert all(r["decision_status"] == "PENDING_BUSINESS_APPROVAL" for r in rows)
        assert all(r["human_signoff_required"] == "True" for r in rows)

    def test_07_every_catalogue_chunk_entry_is_audited(self):
        projects, builders_docs = _fixture_universe()
        manifest = plan_migration_operations(projects, builders_docs)
        res = verify_chunk_membership_complete(projects, manifest)
        assert res["status"] == "PASS"
        assert res["total_chunk_entries"] == res["unique_builders_in_chunks"] == manifest["builders_after"]
        assert res["total_project_memberships"] == len(projects)
        assert res["meta_matches_chunks"] is True
        assert list(res["rows"][0].keys()) == CHUNK_AUDIT_COLUMNS

        # Also validate full 2,236-row generated Phase 4.2C chunk membership CSV
        chunk_csv = REPORTS_DIR / "phase4_2c_chunk_membership_audit.csv"
        assert chunk_csv.exists()
        with chunk_csv.open(encoding="utf-8") as fh:
            reader = csv.DictReader(fh)
            assert list(reader.fieldnames or []) == CHUNK_AUDIT_COLUMNS
            crows = list(reader)
        assert len(crows) == 2236
        assert len({r["builder_id"] for r in crows}) == 2236
        assert {r["chunk_id"] for r in crows} == {f"_catalog_chunk_{i}" for i in range(1, 14)}
        assert sum(int(r["actual_project_count"]) for r in crows) == 4110
        assert all(r["membership_match"] == "True" and r["comparison_result"] == "MATCH" for r in crows)

    def test_08_duplicate_builder_membership_fails(self):
        projects, builders_docs = _fixture_universe()
        manifest = plan_migration_operations(projects, builders_docs)

        # Duplicate first builder entry inside the same chunk (or across chunks)
        corrupted = copy.deepcopy(manifest)
        chunk_fields = corrupted["staged_ops"]["write_catalog_chunks"][0]["update"]["fields"]
        builders_arr = chunk_fields["builders"]["arrayValue"]["values"]
        builders_arr.append(copy.deepcopy(builders_arr[0]))
        with pytest.raises(ChunkMembershipAuditError):
            verify_chunk_membership_complete(projects, corrupted)

    def test_09_incorrect_project_membership_fails(self):
        projects, builders_docs = _fixture_universe()
        manifest = plan_migration_operations(projects, builders_docs)

        # Swap project_ids inside a chunk builder entry
        corrupted = copy.deepcopy(manifest)
        chunk_fields = corrupted["staged_ops"]["write_catalog_chunks"][0]["update"]["fields"]
        first_builder_map = chunk_fields["builders"]["arrayValue"]["values"][0]["mapValue"]["fields"]
        first_builder_map["project_ids"] = python_to_firestore_value(["WRONG_PROJECT_ID"])
        with pytest.raises(ChunkMembershipAuditError):
            verify_chunk_membership_complete(projects, corrupted)

    # --- Workstream G Test 10 + All 5 Workstream E failure-injection scenarios ---

    def test_10a_existing_unmanaged_fields_survive_updates(self):
        projects, builders_docs = _fixture_universe()
        builders_docs["builder_rr_enterprises"]["custom_verified_badge"] = True
        plan = plan_migration_operations(projects, builders_docs)

        audit = audit_unmanaged_fields(builders_docs, plan, ["builder_rr_enterprises"])
        assert audit["status"] == "PASS"
        assert audit["docs_with_unmanaged_fields"] == 1
        row = [r for r in audit["rows"] if r["builder_id"] == "builder_rr_enterprises"][0]
        assert "custom_verified_badge" in row["unmanaged_top_level_fields_found"]
        assert row["determination"] == "UNMANAGED_FIELDS_EXIST_AND_PRESERVED"

    def test_10b_unknown_fields_survive_migration(self):
        old_doc = {
            "_doc_id": "b1",
            "builder_id": "b1",
            "builder_name": "B1",
            "unknown_future_v9_flag": "keep-me",
            "unknown_score_array": [10, 20, {"nested": "ok"}],
        }
        new_managed = {"builder_id": "b1", "builder_name": "B1 Updated"}
        merged = merge_preserving_unmanaged_fields(old_doc, new_managed)
        assert merged["unknown_future_v9_flag"] == "keep-me"
        assert merged["unknown_score_array"] == [10, 20, {"nested": "ok"}]

    def test_10c_null_values_not_silently_replaced(self):
        old_doc = {
            "_doc_id": "b1",
            "builder_id": "b1",
            "builder_name": "B1",
            "nullable_partner_note": None,
            "nested_nullable": {"optional_code": None, "tag": "v1"},
        }
        new_managed = {
            "builder_id": "b1",
            "builder_name": "B1",
            "nested_nullable": {"tag": "v2"},
        }
        merged = merge_preserving_unmanaged_fields(old_doc, new_managed)
        assert "nullable_partner_note" in merged and merged["nullable_partner_note"] is None
        assert "optional_code" in merged["nested_nullable"] and merged["nested_nullable"]["optional_code"] is None
        assert merged["nested_nullable"]["tag"] == "v2"

    def test_10d_nested_unrelated_fields_survive_updates(self):
        old_doc = {
            "_doc_id": "b1",
            "builder_id": "b1",
            "projects": [
                {
                    "project_id": "P6",
                    "project_name": "RR Plaza",
                    "editorial_notes": {"summary": "keep-nested", "flags": [1, 2]},
                    "legacy_badge_null": None,
                }
            ],
        }
        new_managed = {
            "builder_id": "b1",
            "projects": [{"project_id": "P6", "project_name": "RR Plaza Normalized"}],
        }
        merged = merge_preserving_unmanaged_fields(old_doc, new_managed)
        proj = merged["projects"][0]
        assert proj["project_name"] == "RR Plaza Normalized"
        assert proj["editorial_notes"] == {"summary": "keep-nested", "flags": [1, 2]}
        assert "legacy_badge_null" in proj and proj["legacy_badge_null"] is None

    def test_10e_intentional_removal_requires_explicit_authorization(self):
        old_doc = {
            "_doc_id": "b1",
            "builder_id": "b1",
            "builder_name": "B1",
            "builder_aliases": ["OLD_ALIAS"],
        }
        # Dropping `builder_aliases` without authorization MUST raise
        with pytest.raises(UnauthorizedFieldRemovalError):
            merge_preserving_unmanaged_fields(old_doc, {"builder_id": "b1", "builder_name": "B1"})

        # Explicitly authorizing removal succeeds
        merged = merge_preserving_unmanaged_fields(
            old_doc,
            {"builder_id": "b1", "builder_name": "B1"},
            authorized_removed_fields={"builder_aliases"},
        )
        assert "builder_aliases" not in merged

        # Verify generated CSV for real 16 UPDATE builder docs (8 retained active)
        unm_csv = REPORTS_DIR / "phase4_2c_unmanaged_field_audit.csv"
        assert unm_csv.exists()
        urows = list(csv.DictReader(unm_csv.open(encoding="utf-8")))
        assert len(urows) == 16
        assert sum(1 for r in urows if r["is_retained_active_doc"] == "True") == 8
        assert list(urows[0].keys()) == UNMANAGED_AUDIT_COLUMNS
        assert all(r["comparison_result"] == "MATCH" and r["fields_removed"] == "NONE" for r in urows)

    def test_11_manifest_approval_remains_false(self):
        m_path = BACKUP_DIR / "phase4_2b_migration_manifest.json"
        a_path = BACKUP_DIR / "phase4_2b_approval_record.json"
        assert m_path.exists() and a_path.exists()

        manifest = json.loads(m_path.read_text(encoding="utf-8"))
        approval = json.loads(a_path.read_text(encoding="utf-8"))

        assert manifest["manifest_schema_version"] == MANIFEST_SCHEMA_VERSION_V2_1
        assert "human_approval" not in manifest
        assert manifest["deletions_enabled"] is False
        assert manifest["hardening_mode"] is True
        assert approval["approved"] is False
        assert approval["approved_manifest_sha256"] == manifest["manifest_sha256"]

        with pytest.raises(ApprovalValidationError):
            validate_approval_record(approval, manifest, FIREBASE_PROJECT_ID, FIRESTORE_DATABASE)

    def test_12_production_writes_remain_disabled(self, monkeypatch):
        manifest = json.loads((BACKUP_DIR / "phase4_2b_migration_manifest.json").read_text(encoding="utf-8"))
        approval = json.loads((BACKUP_DIR / "phase4_2b_approval_record.json").read_text(encoding="utf-8"))

        # Guard any Firestore commit path: if reached, fail test immediately
        def _forbid_commit(*args, **kwargs):
            raise AssertionError("Firestore write attempted despite unapproved manifest!")

        import phase4_2a_hardening
        monkeypatch.setattr(phase4_2a_hardening, "commit_firestore_writes_verified", _forbid_commit)

        with pytest.raises(ApprovalValidationError):
            apply_migration_manifest(
                manifest,
                "dummy-token",
                backup_dir=BACKUP_DIR,
                approval_record=approval,
                read_state_fn=_forbid_commit,
                commit_fn=_forbid_commit,
            )
