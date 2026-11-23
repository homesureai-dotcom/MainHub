"""
HomeSure Phase 4.2E — Discrepancy Audit Tests (Strictly Read-Only).
"""

from __future__ import annotations

import csv
import hashlib
import json
import sys
from pathlib import Path

import pytest

EXTRACTION_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_ROOT = EXTRACTION_ROOT / "scripts"
FIRESTORE_IMPORT_ROOT = SCRIPTS_ROOT / "firestore_import"
for _p in (str(SCRIPTS_ROOT), str(FIRESTORE_IMPORT_ROOT)):
    if _p not in sys.path:
        sys.path.insert(0, _p)

from phase4_2e_discrepancy_audit import (
    AUDIT_OUTPUT_DIR,
    main as audit_cli_main,
    verify_all_prior_artifacts_untouched,
)


class TestPhase42EDiscrepancyAudit:
    """Validate all 5 discrepancy audit deliverables and strict immutability of prior artifacts."""

    def test_01_audit_deliverables_exist_and_prior_hashes_intact(self):
        expected = [
            "phase4_2e_discrepancy_audit.md",
            "phase4_2e_rghcl_membership_audit.csv",
            "phase4_2e_affinity_007631_evidence_audit.json",
            "phase4_2e_builder_count_bridge.json",
            "phase4_2e_status_taxonomy_audit.json",
        ]
        for fn in expected:
            fp = AUDIT_OUTPUT_DIR / fn
            assert fp.exists() and fp.stat().st_size > 0, f"Missing/empty audit deliverable: {fp}"

        prior = verify_all_prior_artifacts_untouched()
        assert prior["phase4_2a_to_4_2d_verified_count"] == 17
        assert len(prior["phase4_2e_verified_hashes"]) == 11
        assert prior["approval_record_approved"] is False

        # Verify sibling SHA-256 hashes recorded inside phase4_2e_discrepancy_audit.md match disk verbatim
        md_txt = (AUDIT_OUTPUT_DIR / "phase4_2e_discrepancy_audit.md").read_text(encoding="utf-8")
        for fn in expected[1:]:
            sha = hashlib.sha256((AUDIT_OUTPUT_DIR / fn).read_bytes()).hexdigest()
            assert sha in md_txt, f"Missing/stale SHA-256 for {fn} in discrepancy audit markdown"

    def test_02_rghcl_audit_establishes_24_form_a_and_004171_discrepancy(self):
        with (AUDIT_OUTPUT_DIR / "phase4_2e_rghcl_membership_audit.csv").open("r", encoding="utf-8", newline="") as fh:
            rows = list(csv.DictReader(fh))
        assert len(rows) == 24
        assert all(r["in_006414_form_a"] == "True" for r in rows)

        discrep = [r for r in rows if r["discrepancy_detected"] == "True"]
        assert len(discrep) == 1
        r4171 = discrep[0]
        assert r4171["registration_number"] == "PRM/KA/RERA/1251/308/PR/210702/004171"
        assert r4171["proposed_builder_id_in_42e"] == "builder_rajiv_gandhi_housing_corporation_limlted"
        assert r4171["in_manifest_v1_builder_rajiv_gandhi_housing"] == "False"
        assert r4171["in_42e_evidence_decision_56_csv"] == "False"
        assert r4171["in_42e_unresolved_csv"] == "False"

    def test_03_affinity_007631_audit_establishes_form_c_and_form_a_facts(self):
        aff = json.loads((AUDIT_OUTPUT_DIR / "phase4_2e_affinity_007631_evidence_audit.json").read_text(encoding="utf-8"))
        assert aff["project_id"] == "REG_PRM_KA_RERA_1251_446_PR_270325_007631"
        assert aff["registration_number"] == "PRM/KA/RERA/1251/446/PR/270325/007631"
        assert aff["form_c_certificate"]["official_registered_promoter_name"] == "AFFINITY PROJECTS"
        assert aff["form_c_certificate"]["sha256"] == "5269f0d60ed1e3d0b17fb61cbb15584debf188d3cf41ca6deb24e14a4e25e33b"
        assert aff["form_a_006539_cross_reference"]["lists_registration_number"] is True
        assert aff["form_a_006539_cross_reference"]["lists_only_project_title"] is False
        assert aff["form_a_007631_own_record"]["type_of_firm"] == "Proprietorship"
        assert aff["form_a_007631_own_record"]["previous_projects_table_links_006539"] is True
        assert aff["form_a_007631_own_record"]["vaishnavi_group_involvement_in_form_a"] is False
        assert aff["supporting_assignment_assessment"]["supported_by_krera_source_evidence"] is True
        assert aff["supporting_assignment_assessment"]["corporate_continuity_verification_status"] == "NOT_PERFORMED"
        assert len(aff["manifest_v1_discrepancies_found"]) == 2

    def test_04_builder_count_bridge_exact_zero_mismatch(self):
        b = json.loads((AUDIT_OUTPUT_DIR / "phase4_2e_builder_count_bridge.json").read_text(encoding="utf-8"))
        assert b["bridge_status"] == "EXACT_RECONCILIATION_PASS"
        assert b["mismatch_count"] == 0
        c = b["counts"]
        assert c["1_live_individual_builder_docs"] == 127
        assert c["2_unique_builder_ids_in_existing_chunks"] == 2062
        assert c["3_new_individual_builder_docs_CREATE"] == 41
        assert c["4_updated_individual_builder_docs_UPDATE"] == 26
        assert c["5_post_migration_builder_identities_chunk_only"] == 2134
        assert c["6_final_unique_builder_identities_across_13_chunks"] == 2243
        assert c["7_retained_deferred_legacy_individual_docs_untouched"] == 59
        assert c["net_identity_increase"] == 181
        assert c["post_migration_active_individual_docs"] == 109
        assert c["post_migration_total_builders_collection_docs"] == 182

    def test_05_status_taxonomy_and_no_apply_gate(self):
        tax = json.loads((AUDIT_OUTPUT_DIR / "phase4_2e_status_taxonomy_audit.json").read_text(encoding="utf-8"))
        state = tax["canonical_status_state"]
        assert state["RECONCILIATION_STATUS"] == "PASS"
        assert state["IDENTITY_REVIEW_STATUS"] == "PROVISIONAL"
        assert state["CORPORATE_VERIFICATION_STATUS"] == "NOT_PERFORMED"
        assert state["PRODUCTION_APPROVAL_STATUS"] == "NOT_APPROVED"
        assert tax["unresolved_identities_human_approved"] == 0

        md_txt = (AUDIT_OUTPUT_DIR / "phase4_2e_discrepancy_audit.md").read_text(encoding="utf-8")
        for token in (
            "RECONCILIATION_STATUS: PASS",
            "IDENTITY_REVIEW_STATUS: PROVISIONAL",
            "CORPORATE_VERIFICATION_STATUS: NOT_PERFORMED",
            "PRODUCTION_APPROVAL_STATUS: NOT_APPROVED",
        ):
            assert token in md_txt

        with pytest.raises(SystemExit):
            audit_cli_main(["--apply"])
