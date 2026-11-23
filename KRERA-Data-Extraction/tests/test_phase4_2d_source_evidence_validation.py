"""
HomeSure Phase 4.2D — Source Evidence Validation Tests.
Verifies all 5 source-validation deliverables, required columns, allowed outcomes,
exact scope counts, unexpanded Scope B initials, unconfirmed Scope D JVs, zero MCA claims,
and zero mutations to prior Phase 4.2A/4.2B/4.2D artifacts.
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

from phase4_2d_source_evidence_validation import (
    ALLOWED_EVIDENCE_STATUSES,
    MASTER_COLUMNS,
    OWNERSHIP_COLUMNS,
    SHORT_PREFIX_COLUMNS,
    SUFFIX_RECONCILIATION_COLUMNS,
    VALID_SUFFIX_CATEGORIES,
)


def _read_csv(name: str) -> tuple[list[str], list[dict[str, str]]]:
    path = REPORTS_DIR / name
    assert path.exists() and path.stat().st_size > 0, f"Missing/empty deliverable: {path}"
    with path.open("r", encoding="utf-8", newline="") as fh:
        reader = csv.DictReader(fh)
        return list(reader.fieldnames or []), list(reader)


class TestPhase42DSourceEvidenceValidation:
    """Verify source evidence deliverables against Homesure policies."""

    def test_01_master_56_rows_and_allowed_outcomes(self):
        cols, rows = _read_csv("phase4_2d_source_evidence_validation.csv")
        assert cols == MASTER_COLUMNS
        assert len(rows) == 56

        by_scope = Counter(r["scope"] for r in rows)
        assert by_scope == {
            "SCOPE_A_OWNERSHIP": 5,
            "SCOPE_B_SHORT_PREFIX": 18,
            "SCOPE_C_SUFFIX_COLLISION": 27,
            "SCOPE_D_BRAND_PROMOTER": 6,
        }

        for r in rows:
            assert r["project_id"]
            assert r["registration_number"]
            assert r["official_promoter_name"]
            assert r["source_record_reference"]
            assert len(r["source_document_hash"]) == 64
            assert r["evidence_status"] in ALLOWED_EVIDENCE_STATUSES
            assert r["recommended_adjudication"]
            assert r["certificate_matches_extracted_name"] == "True"

    def test_02_scope_a_five_ownership_verifications(self):
        cols, rows = _read_csv("phase4_2d_ownership_verification.csv")
        assert cols == OWNERSHIP_COLUMNS
        assert len(rows) == 5

        by_reg = {r["registration_number"]: r for r in rows}
        sumeru_regs = {
            "PRM/KA/RERA/1251/310/PR/040324/006661",
            "PRM/KA/RERA/1251/310/PR/060424/006779",
            "PRM/KA/RERA/1251/310/PR/171015/000787",
            "PRM/KA/RERA/1251/310/PR/300625/007883",
        }
        for reg in sumeru_regs:
            assert by_reg[reg]["evidence_status"] == "CONFIRMED_SAME_SOURCE_PROMOTER"
            assert "SRI SUMERU REALTY PRIVATE LIMITED" in by_reg[reg]["certificate_promoter_name"].upper()

        bv = by_reg["PRM/KA/RERA/1251/446/PR/240323/005820"]
        assert bv["evidence_status"] == "DISTINCT_SOURCE_PROMOTERS"
        assert bv["certificate_promoter_name"].upper() == "BV BUILDERS"
        assert bv["proposed_builder_id"] == "builder_bv_builders"

    def test_03_scope_b_18_short_prefix_unexpanded(self):
        cols, rows = _read_csv("phase4_2d_short_prefix_verification.csv")
        assert cols == SHORT_PREFIX_COLUMNS
        assert len(rows) == 18

        for r in rows:
            assert r["initials_unexpanded"] == "True"
            assert r["certificate_matches_extracted_name"] == "True"
            assert r["evidence_status"] in ALLOWED_EVIDENCE_STATUSES

        # Confirm SS Builders opposite-address split/hold recommendation is preserved
        ss_rows = [r for r in rows if r["proposed_builder_id"] == "builder_ss_builders"]
        assert len(ss_rows) == 2
        assert all("RECOMMEND_SPLIT" in r["recommended_adjudication"] for r in ss_rows)

    def test_04_scope_c_27_suffix_reconciliations(self):
        cols, rows = _read_csv("phase4_2d_suffix_identity_reconciliation.csv")
        assert cols == SUFFIX_RECONCILIATION_COLUMNS
        assert len(rows) == 27

        by_bid = Counter(r["builder_id"] for r in rows)
        assert by_bid == {
            "builder_shell_promoters_and_infra": 2,
            "builder_greennesto_builders_and_developers": 2,
            "builder_rajiv_gandhi_housing": 23,
        }

        for r in rows:
            assert r["suffix_reconciliation_category"] in VALID_SUFFIX_CATEGORIES
            assert r["evidence_status"] in ALLOWED_EVIDENCE_STATUSES

        rghcl = [r for r in rows if r["builder_id"] == "builder_rajiv_gandhi_housing"]
        assert all(r["listed_in_master_account_table"] == "True" for r in rghcl)
        assert all(r["evidence_status"] == "CONFIRMED_SAME_SOURCE_PROMOTER" for r in rghcl)

        shell = [r for r in rows if r["builder_id"] == "builder_shell_promoters_and_infra"]
        assert all(r["suffix_reconciliation_category"] == "DIFFERENT_LEGAL_FORMS" for r in shell)
        assert all(r["evidence_status"] == "DISTINCT_SOURCE_PROMOTERS" for r in shell)

    def test_05_scope_d_brand_promoter_and_affinity_llp_split(self):
        _, master = _read_csv("phase4_2d_source_evidence_validation.csv")
        d_rows = [r for r in master if r["scope"] == "SCOPE_D_BRAND_PROMOTER"]
        assert len(d_rows) == 6
        by_reg = {r["registration_number"]: r for r in d_rows}

        # Policy 3: never claim confirmed JV on any of the 6
        for r in d_rows:
            low_notes = r["evidence_notes"].lower()
            assert (
                "no vaishnavi group jv exists in source" in low_notes
                or "do not claim confirmed jv" in low_notes
                or "without claiming jv" in low_notes
            )
            assert "confirmed jv:" not in low_notes

        # Affinity LLP (006946) proven distinct legal form / K-RERA account from Proprietorship
        llp = by_reg["PRM/KA/RERA/1251/472/PR/240724/006946"]
        assert llp["evidence_status"] == "DISTINCT_SOURCE_PROMOTERS"
        assert "RECOMMEND_SPLIT" in llp["recommended_adjudication"]

    def test_06_gap_report_and_immutable_artifacts_untouched(self):
        md_path = REPORTS_DIR / "phase4_2d_final_evidence_gap_report.md"
        assert md_path.exists()
        txt = md_path.read_text(encoding="utf-8")
        assert "56" in txt
        assert "NONE" in txt
        assert "Production migration remains unauthorized" in txt

        immutable_hashes = {
            BACKUP_DIR / "backup_manifest.json": "6f0ea49fbcdff26113406f6c35aa36ec2a93a678dc6704bf799f9ffb5aaa56e3",
            BACKUP_DIR / "builders_backup.json": "b87acbe4ab8d976bb9e1cb7ec1749cc2f93f0fcd4385dc5636dec7a00fde5d3d",
            BACKUP_DIR / "phase4_2a_migration_manifest.json": "9451a3ea55b49a4b9b4e8db2fd988cc53e19d4ce634ac7edd26a83616c72d062",
            BACKUP_DIR / "phase4_2b_approval_record.json": "0977073dc08cc243d18a97e1a2a41885441bf05b26406a2c1a4859e91fab49dd",
            BACKUP_DIR / "phase4_2b_migration_manifest.json": "6528941e1e35fbafde14db77835847fde55bfefed9389f0c9fe757a1d5af3776",
            BACKUP_DIR / "projects_builder_fields_backup.json": "363f7a62cab86008291aee1279e9b0e1374e7e596f5277ffd1eb04dfe3d5dc2e",
            REPORTS_DIR / "phase4_2d_business_signoff_register.csv": "dc6a1de67983acb95b451396658ad765145523779385393ca95db3c9bd32b6b1",
            REPORTS_DIR / "phase4_2d_suffix_collision_review.csv": "08860b70af7e0c30a12b57c710370327d421ff500d5134496a09eb1698c7bbe5",
            REPORTS_DIR / "phase4_2d_manual_review_consolidation.csv": "cecea5963f7c97831600774f2a99e71f375d731c5285f6f5aeef756318760359",
            REPORTS_DIR / "phase4_2d_status_taxonomy.md": "c29f9d9f54024492d377f955034cdea50a5690b68783e2a25f427edc315e5fe8",
            REPORTS_DIR / "phase4_2d_final_migration_readiness.md": "3125bdb9972aeff68b3c89f21dccb2ba1735582a4556109e91ffa505817b60ce",
        }
        for path, exp_sha in immutable_hashes.items():
            act = hashlib.sha256(path.read_bytes()).hexdigest()
            assert act == exp_sha, f"Immutable file changed: {path}"

        approval = json.loads((BACKUP_DIR / "phase4_2b_approval_record.json").read_text(encoding="utf-8"))
        assert approval["approved"] is False
