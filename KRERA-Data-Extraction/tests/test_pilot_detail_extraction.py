"""
Automated Local-Fixture Unit Tests for Phase 2 Five-Project Detail Extraction Pilot

Tests the discovery-driven DOM parser (`scripts/detail_dom_parser.py`),
`KRERADiscoveryEngine` (`scripts/discovery_engine.py`), and generated pilot
outputs (`data/pilot/raw/*.json`, `data/pilot/normalized/*.json`) across all 5
pilot projects:
1. Godrej United
2. Godrej Air
3. PRESTIGE BOULEVARD
4. ecopolis Block-2
5. HASIRU VISTHARA
"""

from __future__ import annotations

import json
import re
from pathlib import Path

import pytest

from scripts.detail_dom_parser import parse_project_detail_modal_html
from scripts.discovery_engine import PAN_VALUE_REGEX, KRERADiscoveryEngine
from scripts.models import ObservationState, Project
from scripts.pilot_detail_extractor import lookup_pilot_catalogue_records

REPO_ROOT = Path(__file__).resolve().parent.parent
FIXTURES_DIR = REPO_ROOT / "tests" / "fixtures" / "pilot_modals"
SQLITE_PATH = REPO_ROOT / "data" / "k_rera_extraction.sqlite"
RAW_OUT_DIR = REPO_ROOT / "data" / "pilot" / "raw"
NORM_OUT_DIR = REPO_ROOT / "data" / "pilot" / "normalized"


@pytest.fixture(scope="module")
def pilot_catalogue_records():
    return lookup_pilot_catalogue_records(SQLITE_PATH)


@pytest.fixture(scope="module")
def parsed_pilot_projects(pilot_catalogue_records):
    engine = KRERADiscoveryEngine(enforce_pii_policy=True)
    results = {}
    for rec in pilot_catalogue_records:
        slug = rec["slug"]
        html_path = FIXTURES_DIR / f"{slug}.html"
        raw_html = html_path.read_text(encoding="utf-8")
        raw_payload = parse_project_detail_modal_html(
            raw_html=raw_html,
            portal_detail_element_id=rec["vpd_id"],
            catalogue_page_number=rec["page_number"],
            catalogue_row_order=rec["row_order"],
            scrub_raw_pii=True,
        )
        project = engine.create_project(rec["catalogue_row_dict"])
        project = engine.process_project_details(project, raw_payload)
        results[slug] = (rec, raw_payload, project)
    return results


def test_dynamic_sqlite_catalogue_lookup(pilot_catalogue_records):
    """Verifies that all 5 pilot projects are dynamically resolved from SQLite without hardcoding."""
    assert len(pilot_catalogue_records) == 5
    by_slug = {r["slug"]: r for r in pilot_catalogue_records}

    assert by_slug["godrej_united"]["vpd_id"] == "6"
    assert by_slug["godrej_united"]["page_number"] == 1

    assert by_slug["godrej_air"]["vpd_id"] == "25"
    assert by_slug["godrej_air"]["page_number"] == 1

    assert by_slug["prestige_boulevard"]["vpd_id"] == "132"
    assert by_slug["prestige_boulevard"]["page_number"] == 3

    assert by_slug["ecopolis_block_2"]["vpd_id"] == "131"
    assert by_slug["ecopolis_block_2"]["page_number"] == 3

    assert by_slug["hasiru_visthara"]["vpd_id"] == "15095"
    assert by_slug["hasiru_visthara"]["page_number"] == 446


def test_modal_identity_verification_across_all_five_projects(parsed_pilot_projects):
    """Verifies that modal identity matches catalogue Project Name, Ack No, and Reg No for all 5 projects."""
    for slug, (rec, _, project) in parsed_pilot_projects.items():
        iv = project.identity_verification
        assert iv is not None, f"Missing identity_verification for {slug}"
        assert iv.is_verified is True, f"Identity verification failed for {slug}: {iv.verification_notes}"
        assert iv.modal_reg_no == rec["reg_no"]
        assert iv.modal_ack_no == rec["ack_no"]
        assert iv.modal_project_name.upper() == rec["project_name"].upper()
        assert iv.portal_detail_element_id == rec["vpd_id"]

    # Verify mismatch detection when wrong modal is opened
    engine = KRERADiscoveryEngine()
    dummy_proj = engine.create_project(
        {
            "PROJECT NAME": "Expected Project",
            "ACKNOWLEDGEMENT NO": "PR/KN/170729/999999",
            "REGISTRATION NO": "PRM/KA/RERA/1251/446/PR/171010/999999",
        }
    )
    mismatch_iv = engine.verify_project_identity(
        dummy_proj,
        {
            "project_name": "Wrong Project",
            "acknowledgement_number": "PR/KN/170729/000003",
            "registration_number": "PRM/KA/RERA/1251/446/PR/171010/000003",
        },
    )
    assert mismatch_iv.is_verified is False


def test_tab_and_unlinked_dom_pane_discovery_variants(parsed_pilot_projects):
    """Verifies visible navigation tabs vs unlinked DOM tab-panes across legacy and modern schemas."""
    # 1. Legacy 7-tab projects with Completion Details visible
    for slug in ("godrej_united", "godrej_air", "prestige_boulevard"):
        _, _, proj = parsed_pilot_projects[slug]
        assert proj.coverage.total_tabs_discovered == 7
        assert list(proj.tabs.keys()) == [
            "Promoter Details",
            "Project Details",
            "Uploaded Documents",
            "Enquired Documents",
            "Complaints",
            "Quarterly Updates",
            "Completion Details",
        ]
        assert "Land Details" in proj.coverage.tabs_not_present
        assert "Bank Details" in proj.coverage.tabs_not_present
        assert "Completion Details" not in proj.coverage.tabs_not_present
        assert "#postReg" in proj.unlinked_dom_panes
        assert proj.unlinked_dom_panes["#postReg"].observation_state == ObservationState.PRESENT_WITH_DATA
        assert proj.unlinked_dom_panes["#modPlan"].observation_state == ObservationState.PRESENT_EMPTY
        assert proj.unlinked_dom_panes["#extPlan"].observation_state == ObservationState.PRESENT_EMPTY

    # 2. ecopolis Block-2: Completion Details absent from visible nav, present as empty unlinked DOM pane
    _, _, eco = parsed_pilot_projects["ecopolis_block_2"]
    assert eco.coverage.total_tabs_discovered == 6
    assert "Completion Details" not in eco.tabs
    assert "Completion Details" in eco.coverage.tabs_not_present
    assert "#completion" in eco.unlinked_dom_panes
    comp_unlinked = eco.unlinked_dom_panes["#completion"]
    assert comp_unlinked.is_nav_visible is False
    assert comp_unlinked.dom_presence == "hidden_or_unlinked_dom_pane"
    assert comp_unlinked.observation_state == ObservationState.PRESENT_EMPTY

    # 3. HASIRU VISTHARA: Modern 8-tab schema with Land Details, Bank Details, populated Enquired Documents, and unlinked Cost Details (#menu3)
    _, _, hasiru = parsed_pilot_projects["hasiru_visthara"]
    assert hasiru.coverage.total_tabs_discovered == 8
    assert list(hasiru.tabs.keys()) == [
        "Promoter Details",
        "Land Details",
        "Project Details",
        "Bank Details",
        "Uploaded Documents",
        "Enquired Documents",
        "Complaints",
        "Quarterly Updates",
    ]
    assert "Completion Details" in hasiru.coverage.tabs_not_present
    assert hasiru.tabs["Enquired Documents"].observation_state == ObservationState.PRESENT_WITH_DATA
    assert len(hasiru.tabs["Enquired Documents"].sections[0].documents) == 4
    assert "#menu3" in hasiru.unlinked_dom_panes
    assert hasiru.unlinked_dom_panes["#menu3"].tab_label == "Cost Details"
    assert hasiru.unlinked_dom_panes["#menu3"].observation_state == ObservationState.PRESENT_WITH_DATA


def test_three_completion_details_structural_variants(parsed_pilot_projects):
    """Verifies that all 3 Completion Details structures are handled without hardcoded section assumptions."""
    # Variant 1: Godrej United & Godrej Air (Full post-19/12/2020 structure with cost, development, docs, photos)
    _, _, gu = parsed_pilot_projects["godrej_united"]
    gu_comp = gu.tabs["Completion Details"]
    gu_sec_labels = [s.section_label for s in gu_comp.sections]
    assert "Project Cost Details" in gu_sec_labels
    assert "Development Details" in gu_sec_labels
    assert "Uploaded Documents" in gu_sec_labels
    assert "Photos Uploaded" in gu_sec_labels

    _, _, ga = parsed_pilot_projects["godrej_air"]
    ga_comp = ga.tabs["Completion Details"]
    ga_sec_labels = [s.section_label for s in ga_comp.sections]
    assert "Other Supporting Documents" in ga_sec_labels
    ga_other_docs_sec = next(
        s for s in ga_comp.sections if s.section_label == "Other Supporting Documents"
    )
    assert len(ga_other_docs_sec.documents) >= 1

    # Variant 2: PRESTIGE BOULEVARD (Short pre-19/12/2020 document-only structure with 01-01-0001 anomaly)
    _, _, pb = parsed_pilot_projects["prestige_boulevard"]
    pb_comp = pb.tabs["Completion Details"]
    assert len(pb_comp.sections) == 1
    pb_sec = pb_comp.sections[0]
    assert len(pb_sec.documents) == 4
    conveyance_doc = next(
        d for d in pb_sec.documents if "conveyance deed" in d.document_category.lower()
    )
    assert conveyance_doc.approval_date_raw == "01-01-0001"
    assert "ANOMALY_SUSPICIOUS_APPROVAL_DATE" in conveyance_doc.anomaly_flags
    assert "ANOMALY_PLACEHOLDER_FILENAME_NOT_APPLICABLE_OR_AVAILABLE" in conveyance_doc.anomaly_flags

    # Variant 3: ecopolis Block-2 & HASIRU VISTHARA (Absent nav tab, empty unlinked DOM template)
    for slug in ("ecopolis_block_2", "hasiru_visthara"):
        _, _, proj = parsed_pilot_projects[slug]
        assert "Completion Details" not in proj.tabs
        assert proj.unlinked_dom_panes["#completion"].observation_state == ObservationState.PRESENT_EMPTY


def test_observation_states_empty_not_applicable_and_not_available(parsed_pilot_projects):
    """Verifies accurate classification of present_empty, not_applicable, and not_available."""
    # Asymmetric Complaints sub-tabs on PRESTIGE BOULEVARD (77 Promoter vs 0 Project)
    _, _, pb = parsed_pilot_projects["prestige_boulevard"]
    comp_tab = pb.tabs["Complaints"]
    assert comp_tab.observation_state == ObservationState.PRESENT_WITH_DATA
    assert (
        comp_tab.sub_tabs["Complaints On this Promoter (77)"].observation_state
        == ObservationState.PRESENT_WITH_DATA
    )
    assert (
        comp_tab.sub_tabs["Complaints On this Project (0)"].observation_state
        == ObservationState.PRESENT_EMPTY
    )

    # Not Applicable field ("Is TDR Applicable ? : NO") on HASIRU VISTHARA
    _, _, hasiru = parsed_pilot_projects["hasiru_visthara"]
    tdr_sec = next(
        s
        for s in hasiru.tabs["Project Details"].sections
        if "transferable development rights" in s.section_label.lower()
    )
    assert tdr_sec.fields[0].observation_state == ObservationState.NOT_APPLICABLE

    # Gated Not Applicable document slot ("Whether any loan has been raised : NO" -> "Loan raised document")
    _, _, gu = parsed_pilot_projects["godrej_united"]
    cost_sec = next(
        s for s in gu.tabs["Completion Details"].sections if s.section_label == "Project Cost Details"
    )
    loan_proof_field = next(
        f for f in cost_sec.fields if "loan raised document" in f.field_label.lower()
    )
    assert loan_proof_field.observation_state == ObservationState.NOT_APPLICABLE

    # Not Available document slot (empty DOC_ID= link on Uploaded Documents > Project Approval)
    approval_sec = next(
        s for s in gu.tabs["Uploaded Documents"].sections if s.section_label == "Project Approval"
    )
    empty_docs = [
        d for d in approval_sec.documents if d.observation_state == ObservationState.NOT_AVAILABLE
    ]
    assert len(empty_docs) > 0


def test_pii_redaction_and_zero_leakage_in_raw_and_normalized_outputs(parsed_pilot_projects):
    """Verifies that zero excluded PII is persisted in memory or in raw/normalized JSON files on disk."""
    for slug, (_, raw_payload, proj) in parsed_pilot_projects.items():
        assert len(proj.pii_exclusions) >= 6, f"Expected PII exclusions logged for {slug}"

        # Ensure corporate Promoter Name and Registration No are preserved on Company/LLP promoters
        promoter_sec = proj.tabs["Promoter Details"].sections[0]
        field_labels = [f.field_label for f in promoter_sec.fields]
        assert any("Name" in lbl for lbl in field_labels), f"Corporate Name missing in {slug}"

        # Ensure no PAN/Aadhaar, personal residential address, or individual contact exists in normalized tabs
        for t_obs in list(proj.tabs.values()) + list(proj.unlinked_dom_panes.values()):
            for s_obs in t_obs.sections:
                for f_obs in s_obs.fields:
                    assert not re.search(r"\b(pan|aadhaar|aadhar)\b", f_obs.field_label, re.I), (
                        f"Leaked PAN/Aadhaar field {f_obs.field_label} in {slug}"
                    )
                    assert not re.search(
                        r"\b(present\s+address|permanent\s+address|residential\s+address)\b",
                        f_obs.field_label,
                        re.I,
                    ), f"Leaked residential address field {f_obs.field_label} in {slug}"
                    assert not PAN_VALUE_REGEX.search(str(f_obs.raw_value or "")), (
                        f"Leaked PAN value in {slug}"
                    )
                for d_obs in s_obs.documents:
                    assert not re.search(r"\b(pan|aadhaar|aadhar)\b", d_obs.document_category, re.I), (
                        f"Leaked PAN/Aadhaar document {d_obs.document_category} in {slug}"
                    )

        # Ensure raw_payload also omits excluded fields, documents, and table columns completely
        for raw_tab in raw_payload["tabs"] + raw_payload["unlinked_dom_panes"]:
            for raw_sec in raw_tab.get("sections", []):
                for rf in raw_sec.get("fields", []):
                    assert not re.search(r"\b(pan|aadhaar|aadhar)\b", rf.get("label", ""), re.I)
                    assert not re.search(
                        r"\b(present\s+address|permanent\s+address|residential\s+address)\b",
                        rf.get("label", ""),
                        re.I,
                    )
                for rd in raw_sec.get("documents", []):
                    assert not re.search(r"\b(pan|aadhaar|aadhar)\b", rd.get("category", ""), re.I)

    # Verify serialized raw and normalized files on disk contain zero Indian PAN values, zero synthetic markers, and zero [REDACTED_PII placeholders
    raw_files = sorted(RAW_OUT_DIR.glob("*_raw.json"))
    norm_files = sorted(NORM_OUT_DIR.glob("*_normalized.json"))
    assert len(raw_files) == 5
    assert len(norm_files) == 5

    for fpath in raw_files + norm_files:
        text = fpath.read_text(encoding="utf-8")
        pan_matches = PAN_VALUE_REGEX.findall(text)
        assert pan_matches == [], f"Found unredacted PAN pattern {pan_matches} in {fpath.name}"
        assert "SYNTHETIC_PAN" not in text, f"Found unstripped synthetic PAN marker in {fpath.name}"
        assert "SYNTHETIC_INDIVIDUAL" not in text, f"Found unstripped synthetic PII marker in {fpath.name}"
        assert "SYNTHETIC_PERSONAL_PHOTO" not in text, f"Found unstripped synthetic photo marker in {fpath.name}"
        assert "[REDACTED_PII" not in text, f"Found retained [REDACTED_PII placeholder in {fpath.name}"
        assert "REDACTED_PAN_DOC" not in text, f"Found retained REDACTED_PAN_DOC URL in {fpath.name}"
        assert "REDACTED_PHOTO_DOC" not in text, f"Found retained REDACTED_PHOTO_DOC URL in {fpath.name}"


def test_separated_document_coverage_counts_and_canonical_dates(parsed_pilot_projects):
    """Verifies separated document/slot coverage counts and canonical ISO dates across all 5 pilot projects."""
    for slug, (_, _, proj) in parsed_pilot_projects.items():
        cov = proj.coverage
        assert cov.unique_document_observations_count > 0
        assert cov.document_links_count > 0
        assert cov.total_documents_discovered == (
            cov.document_links_count + cov.unavailable_document_slots_count
            or cov.total_documents_discovered >= cov.unique_document_observations_count
        )

    # PRESTIGE BOULEVARD has placeholder document entry ('Not Applicable.pdf')
    _, _, pb = parsed_pilot_projects["prestige_boulevard"]
    assert pb.coverage.placeholder_document_entries_count == 1

    # Godrej United has 15 placeholder document entries ('Not Applicable.pdf'/'NA.pdf'/'Not Available.pdf'), unavailable document slots, and valid canonical ISO dates
    _, _, gu = parsed_pilot_projects["godrej_united"]
    assert gu.coverage.placeholder_document_entries_count == 15
    assert gu.coverage.unavailable_document_slots_count > 0
    comp_docs = next(
        s for s in gu.tabs["Completion Details"].sections if s.section_label == "Uploaded Documents"
    ).documents
    oc_doc = next(d for d in comp_docs if "occupancy certificate" in d.document_category.lower())
    assert oc_doc.approval_date_raw == "09-02-2022"
    assert oc_doc.approval_date_normalized == "2022-02-09"
    # Verify site photos Photo 1..4 in Completion Details > Photos Uploaded have real filenames, not synthetic markers
    photos_sec = next(
        s for s in gu.tabs["Completion Details"].sections if s.section_label == "Photos Uploaded"
    )
    assert len(photos_sec.documents) == 4
    for p_doc in photos_sec.documents:
        assert p_doc.displayed_filename and p_doc.displayed_filename.lower().endswith(
            (".pdf", ".jpg", ".jpeg", ".png")
        )
        assert "SYNTHETIC" not in p_doc.displayed_filename


def test_category_first_documents_and_cross_section_conflicts(parsed_pilot_projects):
    """Verifies category-first document classification, suspect filename flags, and cross-section conflict detection."""
    _, _, gu = parsed_pilot_projects["godrej_united"]

    # Check Lift Certificate -> Bescom NOC.pdf mismatch flag
    comp_docs_sec = next(
        s for s in gu.tabs["Completion Details"].sections if s.section_label == "Uploaded Documents"
    )
    lift_doc = next(
        d for d in comp_docs_sec.documents if "operation for lifts" in d.document_category.lower()
    )
    assert lift_doc.displayed_filename == "Bescom NOC.pdf"
    assert "FLAGGED_MISMATCH_SUSPECT_FILENAME" in lift_doc.anomaly_flags

    # Check cross-section conflicts on Godrej United (Start Date & Proposed Completion Date across Registration History, Project Details, Catalogue, and Completion Details)
    conflict_concepts = {c.canonical_concept: c for c in gu.cross_section_conflicts}
    assert "project_start_date" in conflict_concepts
    assert "project_end_or_completion_date" in conflict_concepts
    end_date_conflict = conflict_concepts["project_end_or_completion_date"]
    assert "31-05-2021" in end_date_conflict.distinct_raw_values
    assert "28-02-2022" in end_date_conflict.distinct_raw_values
    assert "28/02/2022" in end_date_conflict.distinct_raw_values
