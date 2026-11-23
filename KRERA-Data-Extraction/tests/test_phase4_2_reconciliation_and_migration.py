"""
HomeSure Phase 4.2 — Builder Identity Reconciliation, Idempotency & Rollback Tests
"""

import copy
import hashlib
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
from import_projects import FIREBASE_PROJECT_ID, FIRESTORE_DATABASE, firestore_value_to_python
from name_normalization import resolve_builder_identity
from phase4_2_builder_sync import (
    apply_migration_manifest,
    build_rollback_operations,
    export_live_backup,
    plan_migration_operations,
    reconcile_identities_and_ownership,
)


def _doc_rel_path(full_name: str) -> str:
    prefix = f"projects/{FIREBASE_PROJECT_ID}/databases/{FIRESTORE_DATABASE}/documents/"
    assert full_name.startswith(prefix), f"Unexpected Firestore path: {full_name}"
    return full_name[len(prefix) :]


def _apply_firestore_ops_in_memory(
    store_projects: Dict[str, Dict[str, Any]],
    store_builders: Dict[str, Dict[str, Any]],
    writes: List[Dict[str, Any]],
) -> int:
    """In-memory Firestore documents:commit simulator supporting updateMask & delete."""
    for w in writes:
        if "delete" in w:
            rel = _doc_rel_path(w["delete"])
            col, doc_id = rel.split("/", 1)
            if col == "builders":
                store_builders.pop(doc_id, None)
            elif col == "projects":
                store_projects.pop(doc_id, None)
            continue

        upd = w["update"]
        rel = _doc_rel_path(upd["name"])
        col, doc_id = rel.split("/", 1)
        decoded = firestore_value_to_python({"mapValue": {"fields": upd.get("fields", {})}})
        mask_paths = (w.get("updateMask") or {}).get("fieldPaths")

        target = store_builders if col == "builders" else store_projects
        if mask_paths:
            assert doc_id in target, f"PATCH target missing in store: {rel}"
            cur = target[doc_id]
            for fpath in mask_paths:
                if "." not in fpath:
                    if fpath in decoded:
                        cur[fpath] = copy.deepcopy(decoded[fpath])
                    else:
                        cur.pop(fpath, None)
                else:
                    top, sub = fpath.split(".", 1)
                    if isinstance(decoded.get(top), dict) and sub in decoded[top]:
                        if not isinstance(cur.get(top), dict):
                            cur[top] = {}
                        cur[top][sub] = copy.deepcopy(decoded[top][sub])
                    elif isinstance(cur.get(top), dict):
                        cur[top].pop(sub, None)
        else:
            new_doc = copy.deepcopy(decoded)
            new_doc["_doc_id"] = doc_id
            target[doc_id] = new_doc
    return len(writes)


def _sample_project(
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
    old_norm: str = None,
    old_aliases: List[str] = None,
    confidence: str = "exact_entity",
    needs_manual_review: bool = False,
) -> Dict[str, Any]:
    return {
        "_doc_id": pid,
        "project_id": pid,
        "registration_number": reg_no,
        "acknowledgement_number": f"ACK/{pid}",
        "project_name": project_name,
        "officialProjectName": project_name,
        "normalizedProjectName": project_name,
        "promoter_name": promoter_name,
        "officialBuilderName": promoter_name,
        "projectAddress": f"{taluk}, Bengaluru Urban",
        "builder_id": old_bid,
        "canonical_builder_name": old_canonical,
        "normalizedBuilderName": old_norm if old_norm is not None else old_canonical.lower(),
        "builderAliases": list(old_aliases) if old_aliases is not None else [],
        "is_featured_brand": is_featured,
        "nameNormalizationConfidence": confidence,
        "needsManualReview": needs_manual_review,
        "normalizedTaluk": taluk,
        "taluk": taluk,
        "district": "Bengaluru Urban",
        "projectAliases": [project_name],
        "provenance": {"data_tier": data_tier, "source": "phase4_test"},
        "summary_metrics": {"phi_score": 82.5, "complaints_count": 1},
        "counts": {"towers": 3, "units": 240},
        "search_metadata": {
            "search_tokens": ["legacy_ack_token", f"ack_{pid}"],
            "normalized_builder_name_lower": (old_norm if old_norm is not None else old_canonical).lower(),
            "preserved_nested_flag": f"keep_{pid}",
        },
    }


def _sample_unchanged_project(
    pid: str,
    reg_no: str,
    project_name: str,
    promoter_name: str,
    taluk: str,
    data_tier: str,
) -> Dict[str, Any]:
    res = resolve_builder_identity(project_name, promoter_name, reg_no)
    return _sample_project(
        pid,
        reg_no,
        project_name,
        promoter_name,
        res["builder_id"],
        res["canonical_builder_name"],
        taluk,
        data_tier,
        is_featured=res["is_featured_brand"],
        old_norm=res["normalized_builder_name"],
        old_aliases=res["builder_aliases"],
        confidence=res["name_normalization_confidence"],
        needs_manual_review=res["needs_manual_review"],
    )


def _build_phase4_2_fixture():
    projects = [
        # 1. Completely unchanged featured builder (must incur 0 PATCH writes)
        _sample_unchanged_project(
            "proj_sobha_unchanged",
            "PRM/KA/RERA/1251/446/PR/200100/000000",
            "SOBHA NEOPOLIS",
            "SOBHA LIMITED",
            "Bengaluru East",
            "deep_extracted",
        ),
        # 2. Sattva group: 1 genuine Sattva + 2 featured-brand OWNERSHIP_CHANGE projects
        _sample_unchanged_project(
            "proj_sattva_1",
            "PRM/KA/RERA/1251/309/PR/200101/000001",
            "SATTVA SERENE LIFE",
            "SATTVA DEVELOPERS PRIVATE LIMITED",
            "Yelahanka",
            "deep_extracted",
        ),
        _sample_project(
            "proj_sri_sattva",
            "PRM/KA/RERA/1251/446/PR/200102/000002",
            "SRI SRI SATTVA",
            "SRI SUMERU REALTY LIMITED",
            "builder_sattva_group",
            "Sattva Group (Salarpuria Sattva)",
            "Bengaluru South",
            "catalogue_summary",
            is_featured=True,
        ),
        _sample_project(
            "proj_bv_sattva",
            "PRM/KA/RERA/1251/310/PR/200103/000003",
            "THARUNS B V SATTVA",
            "BV BUILDERS",
            "builder_sattva_group",
            "Sattva Group (Salarpuria Sattva)",
            "Bengaluru North",
            "deep_extracted",
            is_featured=True,
        ),
        # 3. Non-featured over-merged group splitting via SPLIT_ENTITY_SEPARATION
        _sample_project(
            "proj_adithya_const",
            "PRM/KA/RERA/1251/308/PR/200107/000007",
            "ADITHYA SERENE",
            "ADITHYA CONSTRUCTIONS",
            "builder_adithya",
            "Adithya",
            "Bengaluru East",
            "deep_extracted",
        ),
        _sample_project(
            "proj_adithya_dev",
            "PRM/KA/RERA/1251/308/PR/200108/000008",
            "ADITHYA PALMS",
            "ADITHYA DEVELOPERS",
            "builder_adithya",
            "Adithya",
            "Anekal",
            "catalogue_summary",
        ),
        # 4. Malformed '_and' slug repair (SLUG_CHANGE_ONLY, builder_id updated cleanly)
        _sample_project(
            "proj_sowparnika",
            "PRM/KA/RERA/1251/308/PR/200104/000004",
            "SOWPARNIKA PRANATHI",
            "SOWPARNIKA PROJECTS AND INFRASTRUCTURE PRIVATE LIMITED",
            "builder_sowparnika_projects_and",
            "Sowparnika Projects & Infrastructure",
            "Anekal",
            "catalogue_summary",
            old_norm=resolve_builder_identity(
                "SOWPARNIKA PRANATHI", "SOWPARNIKA PROJECTS AND INFRASTRUCTURE PRIVATE LIMITED"
            )["normalized_builder_name"],
            old_aliases=resolve_builder_identity(
                "SOWPARNIKA PRANATHI", "SOWPARNIKA PROJECTS AND INFRASTRUCTURE PRIVATE LIMITED"
            )["builder_aliases"],
        ),
        # 5. MERGE_CANDIDATE pair (MUST stay separate — never auto-merged)
        _sample_unchanged_project(
            "proj_abhee_1",
            "PRM/KA/RERA/1251/446/PR/200105/000005",
            "ABHEE LAKEVIEW",
            "ABHEE VENTURES PRIVATE LIMITED",
            "Bengaluru East",
            "deep_extracted",
        ),
        _sample_unchanged_project(
            "proj_abhee_2",
            "PRM/KA/RERA/1251/446/PR/200106/000006",
            "ABHEE SKYLINE",
            "ABHEEVENTURES LLP",
            "Bengaluru East",
            "catalogue_summary",
        ),
    ]

    builders_list = build_builders_catalog_from_projects(projects)
    chunks = chunk_builders_by_size(builders_list)
    builders_docs: Dict[str, Dict[str, Any]] = {}
    for idx, chunk in enumerate(chunks, start=1):
        cid = f"_catalog_chunk_{idx}"
        builders_docs[cid] = {
            "_doc_id": cid,
            "chunk_id": cid,
            "chunk_index": idx,
            "total_chunks": len(chunks),
            "builders_count": len(chunk),
            "builders": chunk,
        }
    builders_docs["_catalog_meta"] = {
        "_doc_id": "_catalog_meta",
        "meta_id": "_catalog_meta",
        "schema_version": "1.1.0",
        "total_chunks": len(chunks),
        "chunk_ids": [f"_catalog_chunk_{i}" for i in range(1, len(chunks) + 1)],
        "total_builders": len(builders_list),
        "total_projects": len(projects),
        "deep_extracted_projects": sum(1 for p in projects if p["provenance"]["data_tier"] == "deep_extracted"),
        "catalogue_summary_projects": sum(1 for p in projects if p["provenance"]["data_tier"] == "catalogue_summary"),
        "updated_at": "2026-11-22T00:00:00Z",
    }
    for b in builders_list:
        builders_docs[b["builder_id"]] = {"_doc_id": b["builder_id"], **b}
    # Inject a stale pre-Phase-4 orphaned individual builder doc not referenced by any project
    builders_docs["builder_stale_pre_phase4"] = {
        "_doc_id": "builder_stale_pre_phase4",
        "builder_id": "builder_stale_pre_phase4",
        "canonical_builder_name": "Stale Legacy Builder",
        "project_count": 0,
        "projects": [],
    }
    return projects, builders_docs


class TestPhase42ReconciliationAndMigration:
    def test_reconciliation_splits_ownership_changes_and_preserves_merge_candidates(self):
        projects, builders_docs = _build_phase4_2_fixture()
        recon = reconcile_identities_and_ownership(projects, builders_docs)

        assert recon["existing_builders_count"] == 6
        assert recon["corrected_builders_count"] == 9
        assert recon["delta_builders"] == 3
        assert recon["total_projects_evaluated"] == 9
        assert recon["duplicate_project_ids"] == []
        assert recon["duplicate_registration_numbers"] == []
        assert recon["missing_builder_project_ids"] == []

        by_pid = {r["project_id"]: r for r in recon["project_rows"]}
        assert by_pid["proj_sobha_unchanged"]["relationship_change"] == "UNCHANGED"
        assert by_pid["proj_sattva_1"]["relationship_change"] == "UNCHANGED"
        assert by_pid["proj_sri_sattva"]["corrected_builder_id"] == "builder_sri_sumeru_realty"
        assert by_pid["proj_sri_sattva"]["relationship_change"] == "OWNERSHIP_CHANGE"
        assert by_pid["proj_bv_sattva"]["corrected_builder_id"] == "builder_bv_builders"
        assert by_pid["proj_bv_sattva"]["relationship_change"] == "OWNERSHIP_CHANGE"
        assert by_pid["proj_adithya_const"]["relationship_change"] == "SPLIT_ENTITY_SEPARATION"
        assert by_pid["proj_adithya_dev"]["relationship_change"] == "SPLIT_ENTITY_SEPARATION"
        assert by_pid["proj_sowparnika"]["corrected_builder_id"] == "builder_sowparnika_projects_and_infrastructure"
        assert by_pid["proj_sowparnika"]["relationship_change"] == "SLUG_CHANGE_ONLY"

        # MERGE_CANDIDATE (Abhee Ventures vs Abheeventures) MUST remain unmerged
        assert by_pid["proj_abhee_1"]["corrected_builder_id"] != by_pid["proj_abhee_2"]["corrected_builder_id"]
        assert len(recon["merge_candidates"]) == 1
        assert sorted(recon["merge_candidates"][0]["builder_ids"]) == [
            "builder_abhee_ventures",
            "builder_abheeventures",
        ]

    def test_field_mask_safety_zero_unchanged_patches_and_idempotency(self, tmp_path: Path):
        projects, builders_docs = _build_phase4_2_fixture()
        backup_manifest = export_live_backup(projects, builders_docs, tmp_path)
        plan = plan_migration_operations(
            projects,
            builders_docs,
            backup_manifest=backup_manifest,
            backup_dir=tmp_path,
            approved=True,
            approved_by="test-suite",
            approved_at_utc="2026-11-22T00:00:00Z",
        )

        forbidden_mask_fields = {
            "summary_metrics",
            "counts",
            "provenance",
            "provenance.data_tier",
            "projectAliases",
            "officialProjectName",
            "normalizedTaluk",
        }
        patch_ops = plan["staged_ops"]["patch_projects"]
        patched_pids = {op["update"]["name"].split("/")[-1] for op in patch_ops}

        # Unchanged projects MUST NOT be patched at all (and retain legacy ack tokens!)
        for unchanged_pid in ("proj_sobha_unchanged", "proj_sattva_1", "proj_abhee_1", "proj_abhee_2"):
            assert unchanged_pid not in patched_pids

        # Only the 5 changed projects receive surgical PATCHes
        assert patched_pids == {
            "proj_sri_sattva",
            "proj_bv_sattva",
            "proj_adithya_const",
            "proj_adithya_dev",
            "proj_sowparnika",
        }
        assert len(patch_ops) == 5

        for op in patch_ops:
            mask = set(op["updateMask"]["fieldPaths"])
            assert mask.isdisjoint(forbidden_mask_fields)
            assert "builder_id" in mask

        assert "builder_stale_pre_phase4" in plan["deferred_deletion_candidates"]
        assert plan["staged_ops"]["delete_stale_builders_docs"] == []

        # Simulate execution against in-memory Firestore
        store_projects = {p["_doc_id"]: copy.deepcopy(p) for p in projects}
        store_builders = copy.deepcopy(builders_docs)

        def fake_commit(batch, _token):
            return _apply_firestore_ops_in_memory(store_projects, store_builders, batch)

        def fake_read():
            return list(store_projects.values()), store_builders

        apply_res = apply_migration_manifest(
            plan,
            token="test-token",
            backup_dir=tmp_path,
            read_state_fn=fake_read,
            commit_fn=fake_commit,
            batch_size=2,
        )
        assert apply_res["status"] == "COMPLETED"
        assert apply_res["total_committed"] == plan["op_counts"]["total_writes"]
        assert apply_res["deletions_executed"] == 0

        # Verify untouched nested/regulatory fields & unchanged tokens survived completely intact
        assert store_projects["proj_sobha_unchanged"]["search_metadata"]["search_tokens"] == [
            "legacy_ack_token",
            "ack_proj_sobha_unchanged",
        ]
        for pid, pdoc in store_projects.items():
            assert pdoc["summary_metrics"]["phi_score"] == 82.5
            assert pdoc["counts"] == {"towers": 3, "units": 240}
            assert pdoc["search_metadata"]["preserved_nested_flag"] == f"keep_{pid}"

        # Re-planning against migrated state must be a strict 0-write no-op!
        plan_second = plan_migration_operations(list(store_projects.values()), store_builders)
        assert plan_second["op_counts"]["total_writes"] == 0

    def test_backup_checksums_and_deterministic_rollback(self, tmp_path: Path):
        projects, builders_docs = _build_phase4_2_fixture()
        original_projects = {p["_doc_id"]: copy.deepcopy(p) for p in projects}
        original_builders = copy.deepcopy(builders_docs)

        backup_manifest = export_live_backup(projects, builders_docs, tmp_path)
        for fname, meta in backup_manifest["files"].items():
            raw = (tmp_path / fname).read_bytes()
            assert hashlib.sha256(raw).hexdigest() == meta["sha256"]

        plan = plan_migration_operations(
            projects,
            builders_docs,
            backup_manifest=backup_manifest,
            backup_dir=tmp_path,
            approved=True,
            approved_by="test-suite",
            approved_at_utc="2026-11-22T00:00:00Z",
        )
        store_projects = copy.deepcopy(original_projects)
        store_builders = copy.deepcopy(original_builders)

        def fake_commit(batch, _token):
            return _apply_firestore_ops_in_memory(store_projects, store_builders, batch)

        def fake_read():
            return list(store_projects.values()), store_builders

        ckpt = tmp_path / "migration_checkpoint.json"
        apply_migration_manifest(
            plan,
            token="test-token",
            backup_dir=tmp_path,
            read_state_fn=fake_read,
            commit_fn=fake_commit,
            checkpoint_path=ckpt,
        )
        assert ckpt.exists()
        assert json.loads(ckpt.read_text(encoding="utf-8"))["status"] == "COMPLETED"
        # Hardening rule: stale doc is NOT deleted automatically!
        assert "builder_stale_pre_phase4" in store_builders
        assert "builder_sowparnika_projects_and_infrastructure" in store_builders

        # Rollback back to exact pre-migration snapshot using migration manifest
        rb_ops = build_rollback_operations(
            tmp_path, store_builders, list(store_projects.values()), migration_manifest=plan
        )
        assert len(rb_ops) > 0
        fake_commit(rb_ops, "test-token")

        assert set(store_builders.keys()) == set(original_builders.keys())
        for bid, orig_b in original_builders.items():
            assert store_builders[bid] == orig_b
        for pid, orig_p in original_projects.items():
            assert store_projects[pid]["builder_id"] == orig_p["builder_id"]
            assert store_projects[pid]["canonical_builder_name"] == orig_p["canonical_builder_name"]
            assert store_projects[pid]["summary_metrics"] == orig_p["summary_metrics"]
            assert store_projects[pid]["provenance"] == orig_p["provenance"]
            assert store_projects[pid]["search_metadata"] == orig_p["search_metadata"]
