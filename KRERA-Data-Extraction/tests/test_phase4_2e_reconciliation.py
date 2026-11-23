"""
HomeSure Phase 4.2E — Reconciliation, Manifest v1, Policy Compliance & 12 Failure-Injection Tests.

Strictly read-only against production Cloud Firestore (`0` writes, `0` deletes).
All failure-injection scenarios execute locally on isolated copies/tmp_path fixtures.
"""

from __future__ import annotations

import copy
import csv
import hashlib
import json
import sys
from collections import Counter
from pathlib import Path

import pytest

EXTRACTION_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_ROOT = EXTRACTION_ROOT / "scripts"
FIRESTORE_IMPORT_ROOT = SCRIPTS_ROOT / "firestore_import"
BACKUP_DIR = EXTRACTION_ROOT / "data" / "phase4_2_backup_20261122"
REPORTS_42E_DIR = EXTRACTION_ROOT / "reports" / "phase4_2e_final_reconciliation"

for _p in (str(SCRIPTS_ROOT), str(FIRESTORE_IMPORT_ROOT)):
    if _p not in sys.path:
        sys.path.insert(0, _p)

from import_projects import make_firestore_write_op
from phase4_2a_hardening import (
    CommitCountMismatchError,
    MANIFEST_SCHEMA_VERSION_V2_2,
    MISSING_FIELD_SENTINEL,
    ManifestValidationError,
    PostconditionFailureError,
    RollbackConflictError,
    commit_firestore_writes_verified,
    compute_canonical_sha256,
    detect_live_drift,
    validate_migration_manifest,
    verify_builder_catalog_postconditions,
    verify_project_stage_postconditions,
)
from phase4_2b_verification import (
    ApprovalValidationError,
    ProjectInvariantError,
    _simulate_project_patches,
    build_approval_record,
    verify_project_invariants_exact,
)
from phase4_2_builder_sync import apply_migration_manifest
from phase4_2e_reconciliation import (
    EXPECTED_BASELINE_FINGERPRINT,
    IMMUTABLE_SOURCE_ARTIFACTS,
    PHASE4_2E_MANIFEST_FILENAME,
    REVIEW_STATUS_TAXONOMY,
    build_phase4_2e_builders_catalog_from_projects,
    load_source_evidence_index,
    main as phase4_2e_cli_main,
    plan_phase4_2e_migration_manifest,
    resolve_phase4_2e_identities,
    verify_phase4_2e_builder_payloads_exact,
    verify_phase4_2e_chunk_membership_complete,
    _load_56_source_evidence_map,
    _load_p42c_flag_sets,
    _simulate_post_builders_map,
    build_safe_rollback_operations,
)


def _read_csv(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    assert path.exists() and path.stat().st_size > 0, f"Missing/empty deliverable: {path}"
    with path.open("r", encoding="utf-8", newline="") as fh:
        reader = csv.DictReader(fh)
        return list(reader.fieldnames or []), list(reader)


def _load_backup_projects_and_builders() -> tuple[list[dict], dict[str, dict], dict]:
    b_bak = json.loads((BACKUP_DIR / "builders_backup.json").read_text(encoding="utf-8"))
    builders_docs = {k: {**v, "_doc_id": k} for k, v in b_bak.items()}
    p_bak = json.loads((BACKUP_DIR / "projects_builder_fields_backup.json").read_text(encoding="utf-8"))
    projects = []
    for pid, p in sorted(p_bak.items()):
        pc = dict(p)
        pc["_doc_id"] = pid
        projects.append(pc)
    b_manifest = json.loads((BACKUP_DIR / "backup_manifest.json").read_text(encoding="utf-8"))
    return projects, builders_docs, b_manifest


class TestPhase42EDeliverablesAndPolicies:
    """Validate all 12 generated Phase 4.2E deliverables, counts, policies & immutable locks."""

    def test_01_all_12_deliverables_exist_and_hashes_match(self):
        expected_files = [
            PHASE4_2E_MANIFEST_FILENAME,
            "phase4_2e_project_identity_reconciliation.csv",
            "phase4_2e_builder_identity_register.csv",
            "phase4_2e_evidence_decision_register.csv",
            "phase4_2e_unresolved_identity_register.csv",
            "phase4_2e_ownership_reassignment_register.csv",
            "phase4_2e_operation_dry_run.json",
            "phase4_2e_rollback_package.json",
            "phase4_2e_integrity_verification.json",
            "phase4_2e_test_report.md",
            "phase4_2e_final_reconciliation_report.md",
            "phase4_2e_artifact_hashes.json",
        ]
        for fn in expected_files:
            fp = REPORTS_42E_DIR / fn
            assert fp.exists() and fp.stat().st_size > 0, f"Missing/empty Phase 4.2E file: {fp}"

        hashes_doc = json.loads((REPORTS_42E_DIR / "phase4_2e_artifact_hashes.json").read_text(encoding="utf-8"))
        assert hashes_doc["approval_record_approved"] is False
        assert hashes_doc["baseline_fingerprint"] == EXPECTED_BASELINE_FINGERPRINT
        for fn, meta in hashes_doc["deliverable_hashes"].items():
            actual_sha = hashlib.sha256((REPORTS_42E_DIR / fn).read_bytes()).hexdigest()
            assert actual_sha == meta["sha256"], f"Artifact hash mismatch for {fn}"

    def test_02_manifest_schema_v2_2_and_immutable_artifacts_untouched(self):
        manifest = json.loads((REPORTS_42E_DIR / PHASE4_2E_MANIFEST_FILENAME).read_text(encoding="utf-8"))
        res = validate_migration_manifest(manifest, allow_deletions=False)
        assert res["status"] == "VALID"
        assert manifest["manifest_schema_version"] == MANIFEST_SCHEMA_VERSION_V2_2
        assert manifest["metadata"]["approved"] is False
        assert manifest["metadata"]["production_execution"] == "NOT_EXECUTED"
        assert manifest["deletions_enabled"] is False
        assert manifest["op_counts"]["delete_stale_chunks"] == 0
        assert manifest["op_counts"]["delete_stale_individual_builder_docs"] == 0
        assert manifest["op_counts"]["deferred_stale_individual_builder_docs"] == 59
        assert manifest["identity_policies"] == {
            "builder_identity_policy": "SOURCE",
            "possible_duplicate_policy": "SEPARATE",
            "brand_jv_policy": "PRESERVE",
            "ownership_reassignment_policy": "VERIFY",
        }
        assert manifest["review_status_taxonomy"] == REVIEW_STATUS_TAXONOMY
        assert manifest["builders_after"] == 2243
        assert manifest["projects_total"] == 4110
        assert manifest["deep_extracted_total"] == 1022
        assert manifest["catalogue_summary_total"] == 3088
        assert len(manifest["project_mappings"]) == 4110

        # Confirm all immutable Phase 4.2A-4.2D files remain untouched
        for rel_path, exp_sha in IMMUTABLE_SOURCE_ARTIFACTS.items():
            actual = hashlib.sha256((EXTRACTION_ROOT / rel_path).read_bytes()).hexdigest()
            assert actual == exp_sha, f"Immutable Phase 4.2A-4.2D artifact mutated: {rel_path}"

        approval = json.loads((BACKUP_DIR / "phase4_2b_approval_record.json").read_text(encoding="utf-8"))
        assert approval["approved"] is False

    def test_03_csv_counts_and_binding_policy_resolutions(self):
        _, proj_rows = _read_csv(REPORTS_42E_DIR / "phase4_2e_project_identity_reconciliation.csv")
        _, b_rows = _read_csv(REPORTS_42E_DIR / "phase4_2e_builder_identity_register.csv")
        _, ev_rows = _read_csv(REPORTS_42E_DIR / "phase4_2e_evidence_decision_register.csv")
        _, unres_rows = _read_csv(REPORTS_42E_DIR / "phase4_2e_unresolved_identity_register.csv")
        _, own_rows = _read_csv(REPORTS_42E_DIR / "phase4_2e_ownership_reassignment_register.csv")

        assert len(proj_rows) == 4110
        assert len(b_rows) == 2243
        assert len(ev_rows) == 56
        assert len(unres_rows) == 17  # 16 unresolved from 56-row register + 003719 S.V. BREZZA
        assert len(own_rows) == 5

        proj_by_id = {r["project_id"]: r for r in proj_rows}
        b_by_id = {r["builder_id"]: r for r in b_rows}
        assert len({r["registration_number"] for r in proj_rows}) == 4110
        assert all(r["proposed_builder_id"] in b_by_id for r in proj_rows)

        # Scope A — 5 Ownership Reassignments
        assert proj_by_id["REG_PRM_KA_RERA_1251_310_PR_040324_006661"]["proposed_builder_id"] == "builder_sri_sumeru_realty"
        assert proj_by_id["REG_PRM_KA_RERA_1251_310_PR_060424_006779"]["proposed_builder_id"] == "builder_sri_sumeru_realty"
        assert proj_by_id["REG_PRM_KA_RERA_1251_310_PR_171015_000787"]["proposed_builder_id"] == "builder_sri_sumeru_realty"
        assert proj_by_id["REG_PRM_KA_RERA_1251_310_PR_300625_007883"]["proposed_builder_id"] == "builder_sri_sumeru_realty"
        assert "SATTVA" in proj_by_id["REG_PRM_KA_RERA_1251_310_PR_300625_007883"]["brand_relationship"]
        bv_row = proj_by_id["REG_PRM_KA_RERA_1251_446_PR_240323_005820"]
        assert bv_row["proposed_builder_id"] == "builder_bv_builders"
        assert bv_row["official_promoter_name"] == "BV BUILDERS"
        assert bv_row["canonical_promoter_name"] == "BV Builders"

        # Shell mandatory legal-form split
        assert proj_by_id["REG_PRM_KA_RERA_1251_309_PR_171031_001305"]["proposed_builder_id"] == "builder_shell_promoters_and_infra_pvt_ltd"
        assert proj_by_id["REG_PRM_KA_RERA_1251_310_PR_270723_006098"]["proposed_builder_id"] == "builder_shell_promoters_and_infra_llp"

        # Affinity proprietorship (4 incl. Vaishnavi Harmony 007631) + provisional Brundaavana + distinct LLP
        assert b_by_id["builder_affinity_projects"]["project_count"] == "4"
        assert proj_by_id["REG_PRM_KA_RERA_1251_446_PR_270325_007631"]["proposed_builder_id"] == "builder_affinity_projects"
        assert b_by_id["builder_vaishnavi_group"]["project_count"] == "18"
        assert proj_by_id["REG_PRM_KA_RERA_1251_309_PR_180822_005163"]["proposed_builder_id"] == "builder_affinity_projects_provisional_005163"
        assert proj_by_id["REG_PRM_KA_RERA_1251_472_PR_240724_006946"]["proposed_builder_id"] == "builder_affinity_projects_llp"

        # Greennesto provisional split + mandatory metadata
        for pid, exp_bid in (
            ("REG_PRM_KA_RERA_1251_446_PR_211005_004334", "builder_greennesto_builders_and_developers"),
            ("REG_PRM_KA_RERA_1251_310_PR_201022_005350", "builder_greennesto_builders_and_developers_llp"),
        ):
            assert proj_by_id[pid]["proposed_builder_id"] == exp_bid
            assert b_by_id[exp_bid]["identity_review_required"] == "True"
            assert b_by_id[exp_bid]["identity_review_reason"] == "FORM_A_CONTINUITY_NOT_VERIFIED"
            assert b_by_id[exp_bid]["corporate_verification_status"] == "NOT_PERFORMED"

        # SS Builders, S2 Developers, SV Infra Homes provisional splits
        assert proj_by_id["REG_PRM_KA_RERA_1251_446_PR_171031_001614"]["proposed_builder_id"] == "builder_ss_builders"
        assert proj_by_id["REG_PRM_KA_RERA_1251_308_PR_201201_003728"]["proposed_builder_id"] == "builder_ss_builders_provisional_003728"
        assert proj_by_id["REG_PRM_KA_RERA_1251_446_PR_190731_002749"]["proposed_builder_id"] == "builder_s2_developers_provisional_002749"
        assert proj_by_id["REG_PRM_KA_RERA_1251_446_PR_250523_005943"]["proposed_builder_id"] == "builder_s2_developers_provisional_005943"
        assert proj_by_id["REG_PRM_KA_RERA_1251_308_PR_270924_007096"]["proposed_builder_id"] == "builder_sv_infra_homes_provisional_007096"
        assert proj_by_id["REG_PRM_KA_RERA_1251_308_PR_061026_008994"]["proposed_builder_id"] == "builder_sv_infra_homes_provisional_008994"

        # S2 Homes (2 confirmed), RGHCL (23 confirmed, 004171 kept separate merge candidate), Elite Projects, S.V. BREZZA
        assert b_by_id["builder_s2_homes"]["project_count"] == "2"
        assert proj_by_id["REG_PRM_KA_RERA_1251_308_PR_180120_001239"]["proposed_builder_id"] == "builder_s2_homes"
        assert proj_by_id["REG_PRM_KA_RERA_1251_308_PR_180222_001666"]["proposed_builder_id"] == "builder_s2_homes"
        assert b_by_id["builder_rajiv_gandhi_housing"]["project_count"] == "23"
        assert proj_by_id["REG_PRM_KA_RERA_1251_308_PR_210702_004171"]["proposed_builder_id"] == "builder_rajiv_gandhi_housing_corporation_limlted"
        assert proj_by_id["REG_PRM_KA_RERA_1251_310_PR_140223_005717"]["proposed_builder_id"] == "builder_elite_projects"
        assert proj_by_id["REG_PRM_KA_RERA_1251_309_PR_201125_003719"]["proposed_builder_id"] == "builder_sv_developers"

        # Data tiers & taluks intact
        assert Counter(r["data_tier"] for r in proj_rows) == {"deep_extracted": 1022, "catalogue_summary": 3088}
        assert Counter(r["taluk"] for r in proj_rows) == {
            "Anekal": 891,
            "Bengaluru North": 691,
            "Bengaluru East": 1279,
            "Bengaluru South": 1084,
            "Yelahanka": 165,
        }


@pytest.fixture(scope="module")
def baseline_fixture():
    projects, builders_docs, backup_manifest = _load_backup_projects_and_builders()
    predecessor = json.loads((BACKUP_DIR / "phase4_2b_migration_manifest.json").read_text(encoding="utf-8"))
    _, src_ev_by_pid = _load_56_source_evidence_map()
    sql_ev_idx = load_source_evidence_index(EXTRACTION_ROOT)
    merge_pids, jv_pids, short_pids = _load_p42c_flag_sets()
    resolved = resolve_phase4_2e_identities(
        projects,
        source_evidence_by_pid=src_ev_by_pid,
        sql_evidence_index=sql_ev_idx,
        merge_pids=merge_pids,
        jv_pids=jv_pids,
        short_pids=short_pids,
    )
    manifest = plan_phase4_2e_migration_manifest(
        projects,
        builders_docs,
        resolved,
        backup_manifest=backup_manifest,
        predecessor_manifest=predecessor,
        source_artifact_hashes=dict(IMMUTABLE_SOURCE_ARTIFACTS),
        generated_at_utc="2026-11-23T12:00:00+00:00",
    )
    return projects, builders_docs, backup_manifest, manifest, resolved


class TestPhase42EFailureInjections:
    """All 12 required failure-injection tests running strictly offline/in-memory (0 production writes)."""

    def test_fi_01_baseline_drift(self, baseline_fixture):
        projects, builders_docs, _, manifest, _ = baseline_fixture
        drift = detect_live_drift(manifest, projects, builders_docs, live_backup_fingerprint="0" * 64)
        assert drift["status"] == "DRIFT_DETECTED"
        assert any(i["field_path"] == "baseline_fingerprint" and i["severity"] == "CRITICAL" for i in drift["drift_items"])

    def test_fi_02_changed_builder_hash(self, baseline_fixture):
        projects, builders_docs, _, manifest, _ = baseline_fixture
        mutated_builders = copy.deepcopy(builders_docs)
        mutated_builders["builder_sattva_group"]["project_count"] = 999
        drift = detect_live_drift(manifest, projects, mutated_builders)
        assert drift["status"] == "DRIFT_DETECTED"
        assert any(i["document_path"] == "builders/builder_sattva_group" for i in drift["drift_items"])

    def test_fi_03_changed_project_membership(self, baseline_fixture):
        projects, builders_docs, _, manifest, resolved = baseline_fixture
        bad_manifest = copy.deepcopy(manifest)
        # Swap a chunk builder's project_ids membership inside chunk 1
        chunk_op = bad_manifest["staged_ops"]["write_catalog_chunks"][0]
        chunk_op["update"]["fields"]["builders"]["arrayValue"]["values"][0]["mapValue"]["fields"]["project_ids"]["arrayValue"]["values"].pop()
        with pytest.raises(RuntimeError, match="Chunk builder payload mismatch"):
            verify_phase4_2e_builder_payloads_exact(projects, builders_docs, bad_manifest, resolved)

    def test_fi_04_missing_project(self, baseline_fixture):
        projects, _, _, manifest, _ = baseline_fixture
        sim_post = _simulate_project_patches(projects, manifest["staged_ops"]["patch_projects"])
        with pytest.raises(ProjectInvariantError, match="Project ID set changed"):
            verify_project_invariants_exact(projects, sim_post[:-1])

    def test_fi_05_duplicate_registration(self, baseline_fixture):
        projects, _, _, _, resolved = baseline_fixture
        dup_projects = copy.deepcopy(projects)
        dup_projects[1]["registration_number"] = dup_projects[0]["registration_number"]
        with pytest.raises(PostconditionFailureError, match="Duplicate or empty registration numbers"):
            verify_project_stage_postconditions(
                dup_projects,
                {pid: r["builder_id"] for pid, r in resolved.items()},
                {
                    "projects_total": len(dup_projects),
                    "tier_counts": {"deep_extracted": 1022, "catalogue_summary": 3088},
                    "taluk_counts": {"Anekal": 891, "Bengaluru North": 691, "Bengaluru East": 1279, "Bengaluru South": 1084, "Yelahanka": 165},
                },
            )

    def test_fi_06_missing_chunk_entry(self, baseline_fixture):
        projects, _, _, manifest, resolved = baseline_fixture
        bad_manifest = copy.deepcopy(manifest)
        bad_manifest["staged_ops"]["write_catalog_chunks"][0]["update"]["fields"]["builders"]["arrayValue"]["values"].pop()
        with pytest.raises(RuntimeError, match="Builder ID set mismatch"):
            verify_phase4_2e_chunk_membership_complete(projects, bad_manifest, resolved)

    def test_fi_07_unmanaged_field_preservation(self, baseline_fixture):
        projects, builders_docs, backup_manifest, manifest, resolved = baseline_fixture
        # Inject an unmanaged custom field + explicit null field into live builder doc
        custom_builders = copy.deepcopy(builders_docs)
        custom_builders["builder_vaishnavi_group"]["custom_analytics_tag"] = {"tier": "gold", "notes": None}
        predecessor = json.loads((BACKUP_DIR / "phase4_2b_migration_manifest.json").read_text(encoding="utf-8"))
        m2 = plan_phase4_2e_migration_manifest(
            projects,
            custom_builders,
            resolved,
            backup_manifest=backup_manifest,
            predecessor_manifest=predecessor,
            source_artifact_hashes=dict(IMMUTABLE_SOURCE_ARTIFACTS),
            generated_at_utc=manifest["generated_at_utc"],
        )
        res = verify_phase4_2e_builder_payloads_exact(projects, custom_builders, m2, resolved)
        assert res["status"] == "PASS"
        sim_b = _simulate_post_builders_map(custom_builders, m2)
        assert sim_b["builder_vaishnavi_group"]["custom_analytics_tag"] == {"tier": "gold", "notes": None}

    def test_fi_08_partial_manifest_failure(self, baseline_fixture, tmp_path):
        projects, builders_docs, _, manifest, _ = baseline_fixture
        # 1) Simulate Firestore commit returning fewer writeResults than submitted writes
        fake_writes = manifest["staged_ops"]["write_catalog_meta"]
        with pytest.raises(CommitCountMismatchError, match="writeResults count mismatch"):
            commit_firestore_writes_verified(
                fake_writes,
                "fake-token",
                http_post_fn=lambda u, b, h: (200, json.dumps({"writeResults": []}).encode("utf-8")),
            )

        # 2) Simulate mid-stage failure inside apply_migration_manifest after authorization check
        approval = build_approval_record(
            manifest,
            approved=True,
            approved_by="test_reviewer",
            approved_at_utc="2026-11-23T12:00:00+00:00",
        )
        ckpt = tmp_path / "ckpt.json"
        call_counter = {"n": 0}

        def failing_commit(batch_ops, tok):
            call_counter["n"] += 1
            if call_counter["n"] >= 2:
                raise RuntimeError("Injected transient Firestore batch failure")
            return {"committed_count": len(batch_ops), "write_results_count": len(batch_ops)}

        with pytest.raises(RuntimeError, match="Injected transient Firestore batch failure"):
            apply_migration_manifest(
                manifest,
                "fake-token",
                backup_dir=BACKUP_DIR,
                read_state_fn=lambda: (projects, builders_docs),
                commit_fn=failing_commit,
                checkpoint_path=ckpt,
                require_human_approval=True,
                approval_record=approval,
            )
        assert ckpt.exists()

    def test_fi_09_rollback_newly_introduced_fields(self, baseline_fixture, tmp_path):
        projects, builders_docs, _, manifest, _ = baseline_fixture
        # Stage a mini backup where a project lacked `needsManualReview` before migration
        bak_dir = tmp_path / "bak"
        bak_dir.mkdir()
        proj_bak = json.loads((BACKUP_DIR / "projects_builder_fields_backup.json").read_text(encoding="utf-8"))
        sample_pid = next(
            p["project_id"]
            for p in manifest["project_patch_summaries"]
            if "needsManualReview" in p["changed_fields"]
        )
        proj_bak[sample_pid].pop("needsManualReview", None)
        b_bak = json.loads((BACKUP_DIR / "builders_backup.json").read_text(encoding="utf-8"))

        b_bytes = json.dumps(b_bak, indent=2, ensure_ascii=False, sort_keys=True).encode("utf-8")
        p_bytes = json.dumps(proj_bak, indent=2, ensure_ascii=False, sort_keys=True).encode("utf-8")
        (bak_dir / "builders_backup.json").write_bytes(b_bytes)
        (bak_dir / "projects_builder_fields_backup.json").write_bytes(p_bytes)
        orig_bm = json.loads((BACKUP_DIR / "backup_manifest.json").read_text(encoding="utf-8"))
        orig_bm["files"]["builders_backup.json"]["sha256"] = hashlib.sha256(b_bytes).hexdigest()
        orig_bm["files"]["projects_builder_fields_backup.json"]["sha256"] = hashlib.sha256(p_bytes).hexdigest()
        (bak_dir / "backup_manifest.json").write_text(json.dumps(orig_bm), encoding="utf-8")

        sim_post_p = _simulate_project_patches(projects, manifest["staged_ops"]["patch_projects"])
        sim_post_b = _simulate_post_builders_map(builders_docs, manifest)
        rb = build_safe_rollback_operations(bak_dir, manifest, sim_post_b, sim_post_p)
        assert sample_pid in rb["deleted_fields_by_project"]
        assert "needsManualReview" in rb["deleted_fields_by_project"][sample_pid]

    def test_fi_10_rollback_conflict(self, baseline_fixture):
        projects, builders_docs, _, manifest, _ = baseline_fixture
        sim_post_p = _simulate_project_patches(projects, manifest["staged_ops"]["patch_projects"])
        sim_post_b = _simulate_post_builders_map(builders_docs, manifest)
        # Inject an unrelated concurrent post-migration modification on a patched project
        target_pid = manifest["project_patch_summaries"][0]["project_id"]
        for p in sim_post_p:
            if p["_doc_id"] == target_pid:
                p["builder_id"] = "unrelated_concurrent_edit"
                break
        with pytest.raises(RollbackConflictError, match="Rollback aborted"):
            build_safe_rollback_operations(BACKUP_DIR, manifest, sim_post_b, sim_post_p)

    def test_fi_11_repeated_dry_run_idempotency(self, baseline_fixture):
        projects, builders_docs, backup_manifest, manifest, resolved = baseline_fixture
        predecessor = json.loads((BACKUP_DIR / "phase4_2b_migration_manifest.json").read_text(encoding="utf-8"))
        m_repeat = plan_phase4_2e_migration_manifest(
            projects,
            builders_docs,
            resolved,
            backup_manifest=backup_manifest,
            predecessor_manifest=predecessor,
            source_artifact_hashes=dict(IMMUTABLE_SOURCE_ARTIFACTS),
            generated_at_utc=manifest["generated_at_utc"],
        )
        assert m_repeat["manifest_sha256"] == manifest["manifest_sha256"]

        # Applying planner a second time to simulated post-migration state yields ZERO additional writes!
        sim_post_p = _simulate_project_patches(projects, manifest["staged_ops"]["patch_projects"])
        sim_post_b = _simulate_post_builders_map(builders_docs, manifest)
        m_second_pass = plan_phase4_2e_migration_manifest(
            sim_post_p,
            sim_post_b,
            resolved,
            backup_manifest=backup_manifest,
            predecessor_manifest=predecessor,
            source_artifact_hashes=dict(IMMUTABLE_SOURCE_ARTIFACTS),
            generated_at_utc=manifest["generated_at_utc"],
        )
        assert m_second_pass["op_counts"]["total_writes"] == 0

    def test_fi_12_prohibited_production_write_path(self, baseline_fixture):
        projects, builders_docs, _, manifest, _ = baseline_fixture
        unapproved = json.loads((BACKUP_DIR / "phase4_2b_approval_record.json").read_text(encoding="utf-8"))
        assert unapproved["approved"] is False

        writes_attempted = []
        with pytest.raises(ApprovalValidationError):
            apply_migration_manifest(
                manifest,
                "fake-token",
                backup_dir=BACKUP_DIR,
                read_state_fn=lambda: (projects, builders_docs),
                commit_fn=lambda ops, tok: writes_attempted.append(len(ops)),
                require_human_approval=True,
                approval_record=unapproved,
            )
        assert writes_attempted == []

        # CLI strictly exposes zero --apply write path
        with pytest.raises(SystemExit):
            phase4_2e_cli_main(["--apply"])

        # Schema validator rejects deletions or forbidden project fields
        bad_m = copy.deepcopy(manifest)
        bad_m["staged_ops"]["delete_stale_builders_docs"] = [{"delete": "projects/x"}]
        with pytest.raises(ManifestValidationError):
            validate_migration_manifest(bad_m, allow_deletions=False)
