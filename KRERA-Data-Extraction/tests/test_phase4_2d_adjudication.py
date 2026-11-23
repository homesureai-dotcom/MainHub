"""
HomeSure Phase 4.2D — Human Identity Adjudication & Final Migration Readiness Tests.
Validates exact 54 business sign-off cases, 3 corporate suffix collisions (27 projects),
134 deduplicated manual-review rows, 408 vs 134 reconciliation, and zero mutations.
"""

from __future__ import annotations

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
REPORTS_DIR = EXTRACTION_ROOT / "reports" / "phase4_2"

for _p in (str(SCRIPTS_ROOT), str(FIRESTORE_IMPORT_ROOT)):
    if _p not in sys.path:
        sys.path.insert(0, _p)

from phase4_2d_adjudication import (
    BUSINESS_SIGNOFF_COLUMNS,
    MANUAL_CONSOLIDATION_COLUMNS,
    SUFFIX_COLLISION_BUILDER_IDS,
    SUFFIX_COLLISION_COLUMNS,
)


def _read_csv(name: str) -> tuple[list[str], list[dict[str, str]]]:
    path = REPORTS_DIR / name
    assert path.exists(), f"Missing deliverable: {path}"
    with path.open("r", encoding="utf-8", newline="") as fh:
        reader = csv.DictReader(fh)
        return list(reader.fieldnames or []), list(reader)


class TestPhase42DAdjudication:
    """Verify all 5 Phase 4.2D deliverables & strict governance boundaries."""

    def test_01_business_signoff_register_54_rows_and_no_auto_approval(self):
        cols, rows = _read_csv("phase4_2d_business_signoff_register.csv")
        assert cols == BUSINESS_SIGNOFF_COLUMNS
        assert len(rows) == 54
        assert len({r["project_id"] for r in rows}) == 54

        cls_counts = Counter(r["classification"] for r in rows)
        assert cls_counts == {
            "PROMOTER_ENTITY_SPLIT": 43,
            "BRAND_PROMOTER_RELATIONSHIP": 6,
            "OWNERSHIP_REASSIGNMENT": 5,
        }

        for r in rows:
            assert r["project_name"] and r["registration_number"]
            assert r["original_builder_id"] and r["proposed_builder_id"]
            assert r["original_promoter_name"] and r["proposed_canonical_promoter_name"]
            assert r["krera_source_record"] and r["source_file"] and r["source_record_hash"]
            assert r["exact_reason_business_approval_required"]
            assert r["risk_of_incorrect_grouping"]
            assert r["risk_level"] in ("HIGH", "MEDIUM")
            assert r["recommended_decision"]
            assert r["required_additional_evidence"]
            assert r["human_decision"] == "PENDING_HUMAN_APPROVAL"
            assert r["reviewer"] == ""
            assert r["reviewer_notes"] == ""

    def test_02_suffix_collision_review_3_builders_27_projects_unverified_no_remapping(self):
        cols, rows = _read_csv("phase4_2d_suffix_collision_review.csv")
        assert cols == SUFFIX_COLLISION_COLUMNS
        assert len(rows) == 27
        assert set(SUFFIX_COLLISION_BUILDER_IDS) == {r["builder_id"] for r in rows}

        by_bid = Counter(r["builder_id"] for r in rows)
        assert by_bid == {
            "builder_shell_promoters_and_infra": 2,
            "builder_greennesto_builders_and_developers": 2,
            "builder_rajiv_gandhi_housing": 23,
        }

        det_by_bid = {r["builder_id"]: r["suffix_determination"] for r in rows}
        assert det_by_bid["builder_shell_promoters_and_infra"] == "UNCLEAR_IDENTITY"
        assert det_by_bid["builder_greennesto_builders_and_developers"] == "UNCLEAR_IDENTITY"
        assert det_by_bid["builder_rajiv_gandhi_housing"] == "ONE_REGISTERED_PROMOTER_NAMING_VARIATIONS_UNVERIFIED_MCA"

        for r in rows:
            assert r["independent_corporate_verification_status"] == "UNVERIFIED_EXTERNAL_CORPORATE_RELATIONSHIP"
            assert r["mapping_changed"] == "False"
            assert r["official_promoter_name"] and r["registration_number"]

    def test_03_manual_review_consolidation_134_unique_deduplicated_rows_exact_columns(self):
        cols, rows = _read_csv("phase4_2d_manual_review_consolidation.csv")
        assert cols == MANUAL_CONSOLIDATION_COLUMNS
        assert len(rows) == 134
        assert len({r["project_id"] for r in rows}) == 134

        for r in rows:
            assert r["project_id"] and r["registration_number"] and r["builder_id"]
            assert r["canonical_promoter_name"] and r["official_promoter_name"]
            assert r["review_flags"]
            assert r["source_evidence"]
            assert r["risk_level"] in ("HIGH", "MEDIUM")
            assert r["decision"] == "PENDING_HUMAN_DECISION"
            assert r["reviewer"] == ""

    def test_04_overlap_flags_reconcile_54_75_10_56_5_exact(self):
        _, rows = _read_csv("phase4_2d_manual_review_consolidation.csv")
        flag_totals: Counter[str] = Counter()
        for r in rows:
            for fl in r["review_flags"].split("|"):
                if fl:
                    flag_totals[fl] += 1

        assert flag_totals["BUSINESS_SIGNOFF_54"] == 54
        assert flag_totals["MERGE_CANDIDATE_PAIR"] == 75
        assert flag_totals["JV_BRAND_OVERLAP"] == 10
        assert flag_totals["SHORT_PREFIX_ADVISORY"] == 56
        assert flag_totals["OWNERSHIP_REASSIGNMENT"] == 5

        # Cross-check exact alignment with Workstream A 54-row CSV
        _, s54_rows = _read_csv("phase4_2d_business_signoff_register.csv")
        s54_pids = {r["project_id"] for r in s54_rows}
        cons_b54_pids = {r["project_id"] for r in rows if "BUSINESS_SIGNOFF_54" in r["review_flags"].split("|")}
        assert s54_pids == cons_b54_pids

    def test_05_status_reconciliation_408_equals_134_plus_274_unchanged(self):
        _, prom_rows = _read_csv("phase4_2c_promoter_name_normalization_audit.csv")
        _, cons_rows = _read_csv("phase4_2d_manual_review_consolidation.csv")
        m408 = [r for r in prom_rows if r["identity_verification_status"] == "MANUAL_REVIEW_REQUIRED"]
        assert len(m408) == 408

        m408_changed_ids = {r["project_id"] for r in m408 if r["in_2057_changed"] == "True"}
        m408_unchanged_ids = {r["project_id"] for r in m408 if r["in_2057_changed"] == "False"}
        cons_ids = {r["project_id"] for r in cons_rows}

        assert len(m408_changed_ids) == 134
        assert len(m408_unchanged_ids) == 274
        assert m408_changed_ids == cons_ids

    def test_06_phase4_2b_manifest_and_backups_untouched_and_unapproved(self):
        expected_hashes = {
            "backup_manifest.json": "6f0ea49fbcdff26113406f6c35aa36ec2a93a678dc6704bf799f9ffb5aaa56e3",
            "builders_backup.json": "b87acbe4ab8d976bb9e1cb7ec1749cc2f93f0fcd4385dc5636dec7a00fde5d3d",
            "phase4_2a_migration_manifest.json": "9451a3ea55b49a4b9b4e8db2fd988cc53e19d4ce634ac7edd26a83616c72d062",
            "phase4_2b_approval_record.json": "0977073dc08cc243d18a97e1a2a41885441bf05b26406a2c1a4859e91fab49dd",
            "phase4_2b_migration_manifest.json": "6528941e1e35fbafde14db77835847fde55bfefed9389f0c9fe757a1d5af3776",
            "projects_builder_fields_backup.json": "363f7a62cab86008291aee1279e9b0e1374e7e596f5277ffd1eb04dfe3d5dc2e",
        }
        for fn, exp_sha in expected_hashes.items():
            act_sha = hashlib.sha256((BACKUP_DIR / fn).read_bytes()).hexdigest()
            assert act_sha == exp_sha, f"Immutable artifact modified: {fn}"

        approval = json.loads((BACKUP_DIR / "phase4_2b_approval_record.json").read_text(encoding="utf-8"))
        assert approval["approved"] is False

    def test_07_final_reports_contain_required_sections_and_closing_statement(self):
        tax_md = (REPORTS_DIR / "phase4_2d_status_taxonomy.md").read_text(encoding="utf-8")
        assert "408" in tax_md and "134" in tax_md and "274" in tax_md
        assert "Project-Level Identity Verification" in tax_md
        assert "Builder-Level Identity Verification" in tax_md
        assert "Migration Approval" in tax_md
        assert "Legal / Corporate Verification" in tax_md

        ready_md = (REPORTS_DIR / "phase4_2d_final_migration_readiness.md").read_text(encoding="utf-8")
        assert "CONDITIONAL PASS" in ready_md
        assert "Technical Migration Readiness" in ready_md
        assert "does **not** constitute legal entity verification" in ready_md or "does not constitute legal entity verification" in ready_md
        assert ready_md.strip().endswith(
            "Phase 4.2D identity adjudication preparation completed. Production migration remains disabled pending explicit human approval."
        )
