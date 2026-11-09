"""
Unit & Integration Tests for K-RERA Discovery-Driven Ingestion Engine

Validates:
1. Project with all observed tabs (e.g. Godrej United complete set).
2. Project with no Completion Details tab.
3. Project with an empty tab (e.g. Quarterly Updates present but empty).
4. Project with a different Completion Details structure (only docs/approval dates, no financial table).
5. Project with dynamically varying document categories.
6. Project where one tab fails extraction but the remaining tabs succeed.
7. Acceptance Criterion: Processing two projects with completely different tab structures
   using the identical engine instance without hardcoded logic.
8. Observability questions and anomaly preservation (e.g. '01-01-0001').
"""

import pytest
from scripts.discovery_engine import KRERADiscoveryEngine
from scripts.models import ObservationState


@pytest.fixture
def engine():
    return KRERADiscoveryEngine()


def test_scenario_1_project_with_all_observed_tabs(engine):
    """Scenario 1: Project with all 7 observed tabs (Full Godrej United baseline)."""
    catalogue_row = {
        "registration_no": "PRM/KA/RERA/1251/446/PR/171010/000001",
        "acknowledgement_no": "ACK/KA/RERA/2017/001",
        "project_name": "GODREJ UNITED",
        "promoter_name": "GODREJ PROPERTIES LIMITED",
        "district": "BENGALURU URBAN",
        "status": "APPROVED",
    }
    project = engine.create_project(catalogue_row)

    payload = {
        "tabs": [
            {
                "label": "Promoter Details",
                "sections": [
                    {
                        "label": "Promoter Identity",
                        "fields": {
                            "Promoter Type": "Company",
                            "Promoter Name": "GODREJ PROPERTIES LIMITED",
                            "Company Registration Number": "CIN123456789",
                        },
                    }
                ],
            },
            {
                "label": "Project Details",
                "sections": [
                    {
                        "label": "Registration History",
                        "fields": {
                            "Start Date": "15-06-2017",
                            "Original Proposed Completion": "31-05-2021",
                            "Covid Extension": "28-02-2022",
                        },
                    },
                    {
                        "label": "Financial Outlay",
                        "fields": {
                            "Total Project Cost": "5200000000",
                        },
                    },
                ],
            },
            {
                "label": "Uploaded Documents",
                "sections": [
                    {
                        "label": "Approvals",
                        "documents": [
                            {"category": "Commencement Certificate", "filename": "CC_signed.pdf", "url": "/docs/1"},
                            {"category": "Approved Building Plan", "filename": "Sanction_v2.pdf", "url": "/docs/2"},
                        ],
                    }
                ],
            },
            {"label": "Enquired Documents", "sections": [{"label": "Inquiries", "fields": {}}]},
            {
                "label": "Complaints",
                "sections": [
                    {
                        "label": "Dispute History",
                        "table_rows": [
                            {"filing_date": "10-10-2021", "disposal": "Disposed by Authority Bench 4"},
                            {"filing_date": "06-02-2024", "disposal": "Disposed by Adjudicating Officer"},
                        ],
                    }
                ],
            },
            {
                "label": "Quarterly Updates",
                "is_empty": True,
                "sections": [],
            },
            {
                "label": "Completion Details",
                "sections": [
                    {
                        "label": "Handover Metrics",
                        "fields": {
                            "Occupancy Certificate Received": "YES",
                            "Total Apartments": "512",
                            "Apartments Sold": "512",
                        },
                        "documents": [
                            {"category": "Occupancy Certificate", "filename": "OC_Final.pdf", "url": "/docs/oc"},
                        ],
                    }
                ],
            },
        ]
    }

    result = engine.process_project_details(project, payload)

    assert result.internal_id.startswith("KRERA_PRM_KA_RERA_1251_446_PR_171010_000001")
    assert len(result.tabs) == 7
    assert result.coverage.total_tabs_discovered == 7
    assert "Promoter Details" in result.coverage.tabs_processed
    assert "Completion Details" in result.coverage.tabs_processed
    assert "Quarterly Updates" in result.coverage.tabs_present_empty
    assert result.coverage.coverage_ratio() == 100.0


def test_scenario_2_project_with_no_completion_details_tab(engine):
    """Scenario 2: Project with no Completion Details tab (Under-construction project)."""
    catalogue_row = {
        "registration_no": "PRM/KA/RERA/1251/310/PR/200101/003456",
        "project_name": "SOBHA NEW LAUNCH",
        "district": "BENGALURU URBAN",
    }
    project = engine.create_project(catalogue_row)

    payload = {
        "tabs": [
            {
                "label": "Promoter Details",
                "sections": [{"label": "Corporate", "fields": {"Company Name": "SOBHA LIMITED"}}],
            },
            {
                "label": "Project Details",
                "sections": [{"label": "Timeline", "fields": {"Proposed Completion": "31-12-2027"}}],
            },
            {
                "label": "Uploaded Documents",
                "sections": [{"label": "Sanctions", "documents": [{"category": "Sanction Plan", "filename": "plan.pdf"}]}],
            },
        ],
        "checked_absent_tabs": ["Completion Details", "Quarterly Updates"],
    }

    result = engine.process_project_details(project, payload)

    # Must NOT fail extraction just because Completion Details is missing
    assert len(result.tabs) == 3
    assert "Completion Details" not in result.tabs
    assert "Completion Details" in result.coverage.tabs_not_present
    assert result.coverage.total_tabs_discovered == 3
    assert result.coverage.coverage_ratio() == 100.0
    assert len(result.coverage.tabs_processed) == 3


def test_scenario_3_project_with_empty_tab(engine):
    """Scenario 3: Project with an empty tab (Distinguishing present_empty from not_present)."""
    catalogue_row = {"registration_no": "PRM/KA/RERA/TEST/003"}
    project = engine.create_project(catalogue_row)

    payload = {
        "tabs": [
            {
                "label": "Project Details",
                "sections": [{"label": "Info", "fields": {"Status": "Ongoing"}}],
            },
            {
                "label": "Quarterly Updates",
                "is_empty": True,
                "sections": [],
            },
            {
                "label": "Complaints",
                "is_empty": True,
                "sections": [],
            },
        ]
    }

    result = engine.process_project_details(project, payload)

    assert result.tabs["Quarterly Updates"].observation_state == ObservationState.PRESENT_EMPTY
    assert result.tabs["Complaints"].observation_state == ObservationState.PRESENT_EMPTY
    assert "Quarterly Updates" in result.coverage.tabs_present_empty
    assert "Complaints" in result.coverage.tabs_present_empty

    # Answer Question 3: Which sections were empty or absent?
    empty_report = result.coverage.empty_or_absent_sections()
    assert "Quarterly Updates" in empty_report["empty_tabs"]
    assert "Complaints" in empty_report["empty_tabs"]


def test_scenario_4_different_completion_details_structure(engine):
    """Scenario 4: Completion Details containing ONLY documents & approval dates (no financial fields)."""
    catalogue_row = {"registration_no": "PRM/KA/RERA/TEST/004"}
    project = engine.create_project(catalogue_row)

    payload = {
        "tabs": [
            {
                "label": "Completion Details",
                "sections": [
                    {
                        "label": "Completion Approvals List",
                        "type": "document_list",
                        "fields": {},  # No financials or unit counts!
                        "documents": [
                            {
                                "category": "Occupancy Certificate",
                                "filename": "BBMP_OC_dated.pdf",
                                "approval_date": "15-08-2023",
                            },
                            {
                                "category": "Fire Clearance Certificate",
                                "filename": "Fire_NOC.pdf",
                                "approval_date": "10-07-2023",
                            },
                            {
                                "category": "Lift Inspectorate Approval",
                                "filename": "Lift_Cert.pdf",
                                "approval_date": "01-01-0001",  # Known anomaly
                            },
                        ],
                    }
                ],
            }
        ]
    }

    result = engine.process_project_details(project, payload)

    comp_tab = result.tabs["Completion Details"]
    assert comp_tab.observation_state == ObservationState.PRESENT_WITH_DATA
    sec = comp_tab.sections[0]
    assert len(sec.fields) == 0
    assert len(sec.documents) == 3

    # Check that anomaly date '01-01-0001' is preserved and flagged, NOT converted or dropped
    lift_doc = [d for d in sec.documents if d.document_category == "Lift Inspectorate Approval"][0]
    assert lift_doc.approval_date_raw == "01-01-0001"
    assert "ANOMALY_SUSPICIOUS_APPROVAL_DATE" in lift_doc.anomaly_flags


def test_scenario_5_dynamically_varying_document_categories(engine):
    """Scenario 5: Project exposing custom or unusual document categories not in initial taxonomy."""
    catalogue_row = {"registration_no": "PRM/KA/RERA/TEST/005"}
    project = engine.create_project(catalogue_row)

    payload = {
        "tabs": [
            {
                "label": "Uploaded Documents",
                "sections": [
                    {
                        "label": "Special Disclosures",
                        "documents": [
                            {
                                "category": "High Rise Committee Clearance",
                                "filename": "HRC_approval_2022.pdf",
                            },
                            {
                                "category": "Metro Rail Corridor NOC",
                                "filename": "BMRCL_Clearance.pdf",
                            },
                            {
                                "category": "Lake Buffer Zone Certificate",
                                "filename": "Lake_NOC_final.pdf",
                                "flag_filename_mismatch": True,
                            },
                        ],
                    }
                ],
            }
        ]
    }

    result = engine.process_project_details(project, payload)

    sec = result.tabs["Uploaded Documents"].sections[0]
    categories = [d.document_category for d in sec.documents]
    assert "High Rise Committee Clearance" in categories
    assert "Metro Rail Corridor NOC" in categories
    assert "Lake Buffer Zone Certificate" in categories

    mismatch_doc = [d for d in sec.documents if d.document_category == "Lake Buffer Zone Certificate"][0]
    assert "FLAGGED_MISMATCH_SUSPECT_FILENAME" in mismatch_doc.anomaly_flags


def test_scenario_6_one_tab_fails_remaining_tabs_succeed(engine):
    """Scenario 6: Resilient extraction - one tab encounters error, rest succeed."""
    catalogue_row = {"registration_no": "PRM/KA/RERA/TEST/006"}
    project = engine.create_project(catalogue_row)

    payload = {
        "tabs": [
            {
                "label": "Promoter Details",
                "sections": [{"label": "Corporate", "fields": {"Name": "PRESTIGE ESTATES"}}],
            },
            {
                "label": "Project Details",
                "simulate_failure": True,
                "error_message": "Network timeout or DOM parsing error in Project Details table",
            },
            {
                "label": "Uploaded Documents",
                "sections": [{"label": "Files", "documents": [{"category": "Title Deed", "filename": "deed.pdf"}]}],
            },
        ]
    }

    result = engine.process_project_details(project, payload)

    # Failed tab is isolated
    assert result.tabs["Project Details"].observation_state == ObservationState.EXTRACTION_FAILED
    assert "Project Details" in result.coverage.tabs_extraction_failed
    assert len(result.coverage.errors) == 1
    assert "DOM parsing error" in result.coverage.errors[0]

    # Other tabs succeeded
    assert result.tabs["Promoter Details"].observation_state == ObservationState.PRESENT_WITH_DATA
    assert result.tabs["Uploaded Documents"].observation_state == ObservationState.PRESENT_WITH_DATA
    assert "Promoter Details" in result.coverage.tabs_processed
    assert "Uploaded Documents" in result.coverage.tabs_processed

    # Coverage ratio reflects successful tabs out of total discovered (2 of 3)
    assert result.coverage.coverage_ratio() == 66.67


def test_acceptance_criterion_two_completely_different_projects(engine):
    """Acceptance Criterion:
    The same ingestion engine must be capable of processing two K-RERA projects with
    completely different tab structures without requiring project-specific hardcoded extraction logic.
    """
    # Project Alpha: Commercial development with 2 tabs only (Project Details + Documents)
    project_alpha = engine.create_project({
        "registration_no": "PRM/KA/RERA/COMMERCIAL/101",
        "project_name": "ALPHA TECH PARK",
    })
    payload_alpha = {
        "tabs": [
            {
                "label": "Project Details",
                "sections": [{"label": "Commercial Specs", "fields": {"FAR Approved": "3.25", "Built Up Area": "120000"}}],
            },
            {
                "label": "Uploaded Documents",
                "sections": [{"label": "Approvals", "documents": [{"category": "Aviation NOC", "filename": "aai.pdf"}]}],
            },
        ]
    }

    # Project Beta: Plotted layout with 4 entirely different tabs
    project_beta = engine.create_project({
        "registration_no": "PRM/KA/RERA/PLOTS/202",
        "project_name": "BETA GREEN ACRES",
    })
    payload_beta = {
        "tabs": [
            {
                "label": "Promoter Details",
                "sections": [{"label": "Identity", "fields": {"Promoter": "INDIVIDUAL DEVELOPER"}}],
            },
            {
                "label": "Layout Plan Details",
                "sections": [{"label": "Plots", "fields": {"Total Sites": "240", "Park Area": "4500 sq.m"}}],
            },
            {
                "label": "Legal Title",
                "sections": [{"label": "Encumbrance", "fields": {"EC Period": "15 Years"}}],
            },
            {
                "label": "Site Inspection Reports",
                "sections": [{"label": "BMRDA Inspections", "documents": [{"category": "Release Order", "filename": "release.pdf"}]}],
            },
        ]
    }

    # Process both projects with the SAME engine instance
    res_alpha = engine.process_project_details(project_alpha, payload_alpha)
    res_beta = engine.process_project_details(project_beta, payload_beta)

    # Verify Project Alpha
    assert list(res_alpha.tabs.keys()) == ["Project Details", "Uploaded Documents"]
    assert res_alpha.coverage.total_tabs_discovered == 2
    assert res_alpha.coverage.coverage_ratio() == 100.0

    # Verify Project Beta
    assert list(res_beta.tabs.keys()) == ["Promoter Details", "Layout Plan Details", "Legal Title", "Site Inspection Reports"]
    assert res_beta.coverage.total_tabs_discovered == 4
    assert res_beta.coverage.coverage_ratio() == 100.0

    # Test the 5 observability questions on both projects
    # Question 1: What information did we find?
    assert res_alpha.coverage.summary()["tabs_successful"] == 2
    assert res_beta.coverage.summary()["tabs_successful"] == 4

    # Question 2: Which tabs were actually available?
    assert res_alpha.coverage.available_tabs() == ["Project Details", "Uploaded Documents"]
    assert res_beta.coverage.available_tabs() == ["Promoter Details", "Layout Plan Details", "Legal Title", "Site Inspection Reports"]

    # Question 3: Which sections were empty or absent?
    assert res_alpha.coverage.empty_or_absent_sections()["empty_tabs"] == []
    assert res_beta.coverage.empty_or_absent_sections()["empty_tabs"] == []

    # Question 4: What failed to extract?
    assert res_alpha.coverage.failed_extractions() == []
    assert res_beta.coverage.failed_extractions() == []

    # Question 5: How much of the available information was captured?
    assert res_alpha.coverage.coverage_ratio() == 100.0
    assert res_beta.coverage.coverage_ratio() == 100.0


def test_malformed_date_raw_preservation_and_canonical_normalization(engine):
    """Test that malformed dates like '01-01-0001' and '31-02-2021' preserve raw_value, set normalized_value=None, and record parse failure flags."""
    project = engine.create_project({"registration_no": "TEST/MALFORMED/DATE"})
    payload = {
        "tabs": [
            {
                "label": "Project Details",
                "sections": [
                    {
                        "label": "Timeline & Costs",
                        "fields": {
                            "Approval Date": "01-01-0001",
                            "Impossible Calendar Date": "31-02-2021",
                            "Valid Date": "15-06-2022",
                            "Total Project Cost (INR)": "1,25,00,000.50",
                            "Total Apartments Count": "1,024",
                            "Malformed Cost (INR)": "12,AB,000",
                        },
                        "documents": [
                            {
                                "category": "Occupancy Certificate",
                                "filename": "OC.pdf",
                                "url": "/download_jc?DOC_ID=9001",
                                "doc_id": "9001",
                                "approval_date": "20-11-2023",
                            },
                            {
                                "category": "Conveyance Deed",
                                "filename": "Not Applicable.pdf",
                                "url": "/download_jc?DOC_ID=9002",
                                "doc_id": "9002",
                                "approval_date": "01-01-0001",
                            },
                            {
                                "category": "Fire NOC",
                                "filename": "Fire.pdf",
                                "url": "/download_jc?DOC_ID=9003",
                                "doc_id": "9003",
                                "approval_date": "99-99-2022",
                            },
                        ],
                    }
                ],
            }
        ]
    }
    result = engine.process_project_details(project, payload)
    sec = result.tabs["Project Details"].sections[0]
    by_lbl = {f.field_label: f for f in sec.fields}

    # 1. Placeholder date '01-01-0001': raw preserved, normalized_value is None, flagged
    appr_field = by_lbl["Approval Date"]
    assert appr_field.raw_value == "01-01-0001"
    assert appr_field.normalized_value is None
    assert "ANOMALY_MALFORMED_PLACEHOLDER_DATE" in appr_field.anomaly_flags

    # 2. Invalid calendar date '31-02-2021': raw preserved, normalized_value is None, flagged
    bad_date_field = by_lbl["Impossible Calendar Date"]
    assert bad_date_field.raw_value == "31-02-2021"
    assert bad_date_field.normalized_value is None
    assert "ANOMALY_DATE_PARSE_FAILED" in bad_date_field.anomaly_flags

    # 3. Valid date '15-06-2022': raw preserved, canonical ISO '2022-06-15'
    valid_date_field = by_lbl["Valid Date"]
    assert valid_date_field.raw_value == "15-06-2022"
    assert valid_date_field.normalized_value == "2022-06-15"
    assert valid_date_field.data_type == "date_string"
    assert valid_date_field.anomaly_flags == []

    # 4. Comma-formatted float & integer numbers
    cost_field = by_lbl["Total Project Cost (INR)"]
    assert cost_field.raw_value == "1,25,00,000.50"
    assert cost_field.normalized_value == 12500000.50
    assert cost_field.data_type == "float"

    cnt_field = by_lbl["Total Apartments Count"]
    assert cnt_field.raw_value == "1,024"
    assert cnt_field.normalized_value == 1024
    assert cnt_field.data_type == "integer"

    # 5. Malformed numeric string in numeric-labelled field
    bad_num_field = by_lbl["Malformed Cost (INR)"]
    assert bad_num_field.raw_value == "12,AB,000"
    assert bad_num_field.normalized_value is None
    assert bad_num_field.data_type == "malformed_number"
    assert "ANOMALY_NUMERIC_PARSE_FAILED" in bad_num_field.anomaly_flags

    # 6. Document approval date canonicalization & failure flags
    docs_by_cat = {d.document_category: d for d in sec.documents}
    assert docs_by_cat["Occupancy Certificate"].approval_date_raw == "20-11-2023"
    assert docs_by_cat["Occupancy Certificate"].approval_date_normalized == "2023-11-20"

    assert docs_by_cat["Conveyance Deed"].approval_date_raw == "01-01-0001"
    assert docs_by_cat["Conveyance Deed"].approval_date_normalized is None
    assert "ANOMALY_MALFORMED_PLACEHOLDER_DATE" in docs_by_cat["Conveyance Deed"].anomaly_flags
    assert "ANOMALY_SUSPICIOUS_APPROVAL_DATE" in docs_by_cat["Conveyance Deed"].anomaly_flags

    assert docs_by_cat["Fire NOC"].approval_date_raw == "99-99-2022"
    assert docs_by_cat["Fire NOC"].approval_date_normalized is None
    assert "ANOMALY_DATE_PARSE_FAILED" in docs_by_cat["Fire NOC"].anomaly_flags


# ============================================================================
# Phase 2.1 P0: Strict Project Identity Verification Unit Tests (All 6 Cases)
# ============================================================================


def test_strict_identity_verification_all_six_cases():
    """Tests all 6 required identity verification cases and ensures failed/unverified identity blocks detail association."""
    from scripts.models import DetailExtractionStatus

    engine = KRERADiscoveryEngine(require_identity_verification=True)
    base_catalogue = {
        "PROJECT NAME": "Godrej United",
        "ACKNOWLEDGEMENT NO": "PR/KN/170729/000007",
        "REGISTRATION NO": "PRM/KA/RERA/1251/446/PR/171010/000003",
    }
    sample_tabs = [
        {
            "label": "Project Details",
            "sections": [{"label": "Overview", "fields": {"Project Type": "Residential"}}],
        }
    ]

    # Case 1: All three identifiers matching -> verified, details associated
    p1 = engine.create_project(base_catalogue)
    p1 = engine.process_project_details(
        p1,
        {
            "modal_identity": {
                "project_name": "GODREJ  UNITED",
                "acknowledgement_number": "PR/KN/170729/000007",
                "registration_number": "PRM/KA/RERA/1251/446/PR/171010/000003",
            },
            "tabs": sample_tabs,
        },
    )
    assert p1.identity_verification.is_verified is True
    assert p1.identity_verification.verification_status == "verified"
    assert p1.identity_verification.reg_no_matches is True
    assert p1.identity_verification.ack_no_matches is True
    assert p1.identity_verification.project_name_matches is True
    assert p1.extraction_status == DetailExtractionStatus.SUCCESSFUL
    assert "Project Details" in p1.tabs

    # Case 2: Registration number mismatch with other two matching -> NEVER accepted, details blocked
    p2 = engine.create_project(base_catalogue)
    p2 = engine.process_project_details(
        p2,
        {
            "modal_identity": {
                "project_name": "Godrej United",
                "acknowledgement_number": "PR/KN/170729/000007",
                "registration_number": "PRM/KA/RERA/1251/446/PR/171010/999999",
            },
            "tabs": sample_tabs,
        },
    )
    assert p2.identity_verification.is_verified is False
    assert p2.identity_verification.verification_status == "failed_mismatch"
    assert p2.identity_verification.reg_no_matches is False
    assert p2.identity_verification.ack_no_matches is True
    assert p2.identity_verification.project_name_matches is True
    assert p2.extraction_status == DetailExtractionStatus.IDENTITY_UNVERIFIED
    assert p2.tabs == {}

    # Case 3: Acknowledgement number mismatch -> failed_mismatch, details blocked
    p3 = engine.create_project(base_catalogue)
    p3 = engine.process_project_details(
        p3,
        {
            "modal_identity": {
                "project_name": "Godrej United",
                "acknowledgement_number": "PR/KN/170729/888888",
                "registration_number": "PRM/KA/RERA/1251/446/PR/171010/000003",
            },
            "tabs": sample_tabs,
        },
    )
    assert p3.identity_verification.is_verified is False
    assert p3.identity_verification.verification_status == "failed_mismatch"
    assert p3.identity_verification.ack_no_matches is False
    assert p3.extraction_status == DetailExtractionStatus.IDENTITY_UNVERIFIED
    assert p3.tabs == {}

    # Case 4: Project name mismatch -> failed_mismatch, details blocked
    p4 = engine.create_project(base_catalogue)
    p4 = engine.process_project_details(
        p4,
        {
            "modal_identity": {
                "project_name": "Completely Different Project",
                "acknowledgement_number": "PR/KN/170729/000007",
                "registration_number": "PRM/KA/RERA/1251/446/PR/171010/000003",
            },
            "tabs": sample_tabs,
        },
    )
    assert p4.identity_verification.is_verified is False
    assert p4.identity_verification.verification_status == "failed_mismatch"
    assert p4.identity_verification.project_name_matches is False
    assert p4.extraction_status == DetailExtractionStatus.IDENTITY_UNVERIFIED
    assert p4.tabs == {}

    # Case 5: Missing identifiers (e.g. modal registration_number missing) -> unverified_incomplete_identity, details blocked
    p5 = engine.create_project(base_catalogue)
    p5 = engine.process_project_details(
        p5,
        {
            "modal_identity": {
                "project_name": "Godrej United",
                "acknowledgement_number": "PR/KN/170729/000007",
                "registration_number": None,
            },
            "tabs": sample_tabs,
        },
    )
    assert p5.identity_verification.is_verified is False
    assert p5.identity_verification.verification_status == "unverified_incomplete_identity"
    assert p5.identity_verification.reg_no_matches is None
    assert p5.extraction_status == DetailExtractionStatus.IDENTITY_UNVERIFIED
    assert p5.tabs == {}

    # Case 6: Empty modal identity -> unverified_empty_modal, details blocked
    p6 = engine.create_project(base_catalogue)
    p6 = engine.process_project_details(
        p6,
        {
            "modal_identity": {
                "project_name": None,
                "acknowledgement_number": None,
                "registration_number": None,
            },
            "tabs": sample_tabs,
        },
    )
    assert p6.identity_verification.is_verified is False
    assert p6.identity_verification.verification_status == "unverified_empty_modal"
    assert p6.extraction_status == DetailExtractionStatus.IDENTITY_UNVERIFIED
    assert p6.tabs == {}


# ============================================================================
# Phase 2.1 P1: Dynamic Discovery Regression Tests (All 10 Scenarios)
# ============================================================================


def test_dynamic_discovery_regression_suite_dom_to_normalized():
    """Tests all 10 P1 dynamic discovery regression scenarios through both `parse_project_detail_modal_html` and `KRERADiscoveryEngine`."""
    from scripts.detail_dom_parser import parse_project_detail_modal_html
    from scripts.models import DetailExtractionStatus

    engine = KRERADiscoveryEngine(enforce_pii_policy=True, require_identity_verification=True)

    # Synthetic HTML exercising:
    # (1) Unknown visible tab label ('Environmental & ESG Disclosures')
    # (2) Unknown unlinked DOM pane ('#customUnlinkedPane99')
    # (3) Reused pane IDs ('#menu1' as 'Land Details', '#menu5' as 'Appeal / FNH Details')
    # (4) Nested tabs ('Complaints' -> 'Promoter Complaints' & 'Project Complaints')
    # (5) Empty and populated sections
    # (6) Unknown table column counts (7 columns)
    # (7) Missing table headers (headerless 2-col key-value table & headerless 4-col table)
    # (8) Multiple document links in one cell (both .row and <table>)
    # (9) Missing document links and filenames (not_available vs gated not_applicable)
    # (10) Parser failure in one tab (data-simulate-parser-failure) while other tabs succeed
    synthetic_html = """
    <div>
      <div class="row">
        <p>Project Name : SYNTHETIC HEIGHTS</p>
        <p>Acknowledgement Number : PR/KN/260101/000111</p>
        <p>Registration Number : PRM/KA/RERA/1251/446/PR/260101/000111</p>
      </div>
      <ul class="nav nav-tabs">
        <li><a href="#home">Promoter Details</a></li>
        <li><a href="#menu1">Land Details</a></li>
        <li><a href="#esgTab">Environmental &amp; ESG Disclosures</a></li>
        <li><a href="#complaintsTab">Complaints</a></li>
        <li><a href="#brokenTab">Corrupted Tab</a></li>
      </ul>
      <div class="tab-content">
        <!-- Tab 1: Promoter Details with headerless 2-col table & multi-link row -->
        <div id="home" class="tab-pane active">
          <h1>Corporate Overview</h1>
          <div class="row">
            <div class="col-md-3"><p>Promoter Type :</p></div>
            <div class="col-md-3"><p>Company</p></div>
            <div class="col-md-3"><p>Promoter Name :</p></div>
            <div class="col-md-3"><p>SYNTHETIC BUILDERS PVT LTD</p></div>
          </div>
          <table>
            <tbody>
              <tr><td>Official Address :</td><td>100 MG Road, Bengaluru</td></tr>
              <tr><td>Present Address :</td><td>42 Private Residence, Indiranagar</td></tr>
            </tbody>
          </table>
        </div>

        <!-- Tab 2: Reused #menu1 ID mapped to 'Land Details' with 7-column table & headerless 4-column table -->
        <div id="menu1" class="tab-pane">
          <h1>7-Column Survey Matrix</h1>
          <table>
            <thead>
              <tr>
                <th>Sl No</th><th>Survey No</th><th>Khata No</th><th>Total Extent</th>
                <th>Kharab Area</th><th>Net Area</th><th>Title Document</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>1</td><td>45/2</td><td>K-88</td><td>12000</td><td>200</td><td>11800</td>
                <td>
                  <a href="https://rera.karnataka.gov.in/download_jc?DOC_ID=701">SaleDeed_Part1.pdf</a>
                  <a href="https://rera.karnataka.gov.in/download_jc?DOC_ID=702">SaleDeed_Part2.pdf</a>
                </td>
              </tr>
            </tbody>
          </table>
          <h1>Headerless 4-Column Table</h1>
          <table>
            <tbody>
              <tr><td>Zone A</td><td>Tower 1</td><td>18 Floors</td><td>Approved</td></tr>
            </tbody>
          </table>
        </div>

        <!-- Tab 3: Unknown visible tab label with multi-link .row, missing doc link, and gated N/A doc -->
        <div id="esgTab" class="tab-pane">
          <h1>Solar &amp; Rainwater Harvesting</h1>
          <div class="row">
            <div class="col-md-3"><p>Multi-Certificate Slot :</p></div>
            <div class="col-md-3">
              <a href="https://rera.karnataka.gov.in/download_jc?DOC_ID=801">Solar_NOC_1.pdf</a>
              <a href="https://rera.karnataka.gov.in/download_jc?DOC_ID=802">Solar_NOC_2.pdf</a>
            </div>
            <div class="col-md-3"><p>Missing Upload Slot :</p></div>
            <div class="col-md-3">
              <a href="https://rera.karnataka.gov.in/download_jc?DOC_ID="></a>
            </div>
          </div>
          <div class="row">
            <div class="col-md-3"><p>Whether any loan has been raised :</p></div>
            <div class="col-md-3"><p>NO</p></div>
            <div class="col-md-3"><p>Loan Sanction Document :</p></div>
            <div class="col-md-3">
              <a href="https://rera.karnataka.gov.in/download_jc?DOC_ID="></a>
            </div>
          </div>
          <h1>Empty ESG Section</h1>
          <div class="add-more">No Carbon Offset Credits Registered</div>
        </div>

        <!-- Tab 4: Nested sub-tabs -->
        <div id="complaintsTab" class="tab-pane">
          <ul class="nav nav-tabs">
            <li><a href="#subCompPromoter">Promoter Complaints (1)</a></li>
            <li><a href="#subCompProject">Project Complaints (0)</a></li>
          </ul>
          <div class="tab-content">
            <div id="subCompPromoter" class="tab-pane">
              <h1>Promoter Disputes</h1>
              <table>
                <thead><tr><th>Complaint No</th><th>Status</th></tr></thead>
                <tbody><tr><td>CMP/2025/01</td><td>Resolved</td></tr></tbody>
              </table>
            </div>
            <div id="subCompProject" class="tab-pane">
              <h1>Project Disputes</h1>
            </div>
          </div>
        </div>

        <!-- Tab 5: Simulated parser failure in one tab -->
        <div id="brokenTab" class="tab-pane" data-simulate-parser-failure="Simulated malformed DOM subtree in Corrupted Tab">
          <h1>Unreachable Section</h1>
        </div>

        <!-- Unlinked DOM Pane 1: Reused #menu5 ID -->
        <div id="menu5" class="tab-pane">
          <h1>Appeal Tribunal Records</h1>
          <div class="row">
            <div class="col-md-6"><p>Appeal Status :</p></div>
            <div class="col-md-6"><p>No Pending Appeals</p></div>
          </div>
        </div>

        <!-- Unlinked DOM Pane 2: Completely unknown unlinked DOM pane -->
        <div id="customUnlinkedPane99" class="tab-pane">
          <h2>Custom Forensic Audit Trail</h2>
          <div class="row">
            <div class="col-md-6"><p>Audit Status :</p></div>
            <div class="col-md-6"><p>Cleared</p></div>
          </div>
        </div>
      </div>
    </div>
    """

    raw_payload = parse_project_detail_modal_html(
        raw_html=synthetic_html,
        portal_detail_element_id="999",
        catalogue_page_number=1,
        catalogue_row_order=1,
        scrub_raw_pii=True,
    )
    proj = engine.create_project(
        {
            "PROJECT NAME": "SYNTHETIC HEIGHTS",
            "ACKNOWLEDGEMENT NO": "PR/KN/260101/000111",
            "REGISTRATION NO": "PRM/KA/RERA/1251/446/PR/260101/000111",
        }
    )
    proj = engine.process_project_details(proj, raw_payload)

    # (a) Unknown visible tab label captured dynamically
    assert "Environmental & ESG Disclosures" in proj.tabs
    esg_tab = proj.tabs["Environmental & ESG Disclosures"]
    assert esg_tab.observation_state == ObservationState.PRESENT_WITH_DATA

    # (b) Unknown unlinked DOM pane captured dynamically
    assert "#customUnlinkedPane99" in proj.unlinked_dom_panes
    custom_pane = proj.unlinked_dom_panes["#customUnlinkedPane99"]
    assert custom_pane.tab_label == "Custom Forensic Audit Trail"
    assert custom_pane.observation_state == ObservationState.PRESENT_WITH_DATA

    # (c) Reused pane IDs (#menu1 as Land Details, #menu5 resolved from its heading 'Appeal Tribunal Records', not hardcoded ID)
    assert proj.tabs["Land Details"].tab_identifier == "#menu1"
    assert "#menu5" in proj.unlinked_dom_panes
    assert proj.unlinked_dom_panes["#menu5"].tab_label == "Appeal Tribunal Records"

    # (d) Nested tabs (Complaints -> Promoter Complaints (1) vs Project Complaints (0))
    comp_tab = proj.tabs["Complaints"]
    assert comp_tab.sub_tabs["Promoter Complaints (1)"].observation_state == ObservationState.PRESENT_WITH_DATA
    assert comp_tab.sub_tabs["Project Complaints (0)"].observation_state == ObservationState.PRESENT_EMPTY

    # (e) Empty and populated sections
    esg_secs = {s.section_label: s for s in esg_tab.sections}
    assert esg_secs["Solar & Rainwater Harvesting"].observation_state == ObservationState.PRESENT_WITH_DATA
    assert esg_secs["Empty ESG Section"].observation_state == ObservationState.PRESENT_EMPTY

    # (f) Unknown table column counts (7-column table) & (h) Multiple document links in one table cell
    land_secs = {s.section_label: s for s in proj.tabs["Land Details"].sections}
    survey_sec = land_secs["7-Column Survey Matrix"]
    assert len(survey_sec.table_headers) == 7
    assert len(survey_sec.table_rows) == 1
    assert len(survey_sec.documents) == 2
    assert [d.displayed_filename for d in survey_sec.documents] == ["SaleDeed_Part1.pdf", "SaleDeed_Part2.pdf"]

    # (g) Missing table headers (headerless 4-column table fallback Column_1..Column_4, plus headerless 2-column KV table)
    h4_sec = land_secs["Headerless 4-Column Table"]
    assert h4_sec.table_rows[0]["Column_1"] == "Zone A"
    assert h4_sec.table_rows[0]["Column_4"] == "Approved"

    promoter_fields = {f.field_label: f.raw_value for f in proj.tabs["Promoter Details"].sections[0].fields}
    assert promoter_fields["Official Address"] == "100 MG Road, Bengaluru"
    assert "Present Address" not in promoter_fields  # Excluded as individual residential address PII

    # (h) Multiple document links in one .row cell & (i) Missing document links (not_available vs gated not_applicable)
    solar_docs = esg_secs["Solar & Rainwater Harvesting"].documents
    solar_multi = [d for d in solar_docs if d.document_category == "Multi-Certificate Slot"]
    assert len(solar_multi) == 2
    assert {d.document_identifier for d in solar_multi} == {"801", "802"}

    missing_slot = next(d for d in solar_docs if d.document_category == "Missing Upload Slot")
    assert missing_slot.observation_state == ObservationState.NOT_AVAILABLE

    gated_loan_slot = next(d for d in solar_docs if d.document_category == "Loan Sanction Document")
    assert gated_loan_slot.observation_state == ObservationState.NOT_APPLICABLE

    # Verify separated document coverage counts
    assert proj.coverage.document_links_count == 4  # 2 in Land Details + 2 in ESG
    assert proj.coverage.unique_document_observations_count == 4
    assert proj.coverage.unavailable_document_slots_count == 2  # 1 NOT_AVAILABLE + 1 NOT_APPLICABLE

    # (j) Parser failure in one tab isolated while other 4 tabs succeed -> DetailExtractionStatus.PARTIAL
    assert proj.tabs["Corrupted Tab"].observation_state == ObservationState.EXTRACTION_FAILED
    assert "Corrupted Tab" in proj.coverage.tabs_extraction_failed
    assert proj.extraction_status == DetailExtractionStatus.PARTIAL


def test_pii_exclusion_across_individual_promoter_and_all_table_archetypes():
    """Verifies PII exclusion across Promoter Type = Individual, Partner/Signatory/Director/LandOwner tables, and Archetypes 1-5."""
    from scripts.detail_dom_parser import parse_project_detail_modal_html

    engine = KRERADiscoveryEngine(enforce_pii_policy=True)
    html_with_pii = """
    <div>
      <div class="row">
        <p>Project Name : GREEN VILLA</p>
        <p>Acknowledgement Number : PR/KN/260101/000222</p>
        <p>Registration Number : PRM/KA/RERA/1251/446/PR/260101/000222</p>
      </div>
      <ul class="nav nav-tabs">
        <li><a href="#home">Promoter Details</a></li>
        <li><a href="#docs">Uploaded Documents</a></li>
      </ul>
      <div class="tab-content">
        <div id="home" class="tab-pane active">
          <h1>Promoter Details</h1>
          <div class="row">
            <div class="col-md-3"><p>Promoter Type :</p></div>
            <div class="col-md-3"><p>Individual</p></div>
            <div class="col-md-3"><p>Name :</p></div>
            <div class="col-md-3"><p>Ramesh Kumar</p></div>
          </div>
          <div class="row">
            <div class="col-md-3"><p>Address :</p></div>
            <div class="col-md-3"><p>#12, 4th Cross, Malleshwaram</p></div>
            <div class="col-md-3"><p>Mobile Number :</p></div>
            <div class="col-md-3"><p>9876543210</p></div>
          </div>
          <div class="row">
            <div class="col-md-3"><p>Email ID :</p></div>
            <div class="col-md-3"><p>ramesh.personal@example.com</p></div>
            <div class="col-md-3"><p>PAN Number :</p></div>
            <div class="col-md-3"><p>ABCDE1234F</p></div>
          </div>
          <h1>Land Owner Details</h1>
          <table>
            <thead>
              <tr>
                <th>Land Owner Name</th>
                <th>Address</th>
                <th>Mobile</th>
                <th>Email</th>
                <th>Aadhaar No</th>
                <th>Photograph</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>Suresh Gowda</td>
                <td>#88 Residency Road</td>
                <td>9845012345</td>
                <td>suresh@example.com</td>
                <td>1234 5678 9012</td>
                <td><img src="/download_jc?DOC_ID=999" alt="Photo"/></td>
              </tr>
            </tbody>
          </table>
        </div>
        <div id="docs" class="tab-pane">
          <h1>Statutory Documents</h1>
          <table>
            <thead>
              <tr><th>Document Name</th><th>Document</th><th>Document Name</th><th>Document</th></tr>
            </thead>
            <tbody>
              <tr>
                <td>Commencement Certificate</td>
                <td><a href="/download_jc?DOC_ID=101">CC_Valid.pdf</a></td>
                <td>Approval Certificate</td>
                <td><a href="/download_jc?DOC_ID=102">Director_PAN_Card_Scan.pdf</a></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """

    raw_payload = parse_project_detail_modal_html(html_with_pii, scrub_raw_pii=True)
    raw_json_str = repr(raw_payload)

    # Ensure raw payload does NOT retain excluded values, URLs, document IDs, or filenames
    for forbidden in (
        "#12, 4th Cross, Malleshwaram",
        "9876543210",
        "ramesh.personal@example.com",
        "ABCDE1234F",
        "#88 Residency Road",
        "9845012345",
        "suresh@example.com",
        "1234 5678 9012",
        "Director_PAN_Card_Scan.pdf",
        "DOC_ID=102",
        "[REDACTED_PII",
    ):
        assert forbidden not in raw_json_str, f"Forbidden PII or placeholder '{forbidden}' retained in raw payload"

    proj = engine.create_project(
        {
            "PROJECT NAME": "GREEN VILLA",
            "ACKNOWLEDGEMENT NO": "PR/KN/260101/000222",
            "REGISTRATION NO": "PRM/KA/RERA/1251/446/PR/260101/000222",
        }
    )
    proj = engine.process_project_details(proj, raw_payload)
    norm_json_str = proj.model_dump_json()

    for forbidden in (
        "#12, 4th Cross, Malleshwaram",
        "9876543210",
        "ramesh.personal@example.com",
        "ABCDE1234F",
        "#88 Residency Road",
        "9845012345",
        "suresh@example.com",
        "1234 5678 9012",
        "Director_PAN_Card_Scan.pdf",
        "DOC_ID=102",
        "[REDACTED_PII",
    ):
        assert forbidden not in norm_json_str, f"Forbidden PII '{forbidden}' leaked into normalized JSON"

    # Non-PII fields and documents are preserved
    promoter_fields = {f.field_label: f.raw_value for f in proj.tabs["Promoter Details"].sections[0].fields}
    assert promoter_fields["Promoter Type"] == "Individual"
    assert promoter_fields["Name"] == "Ramesh Kumar"

    land_owner_rows = proj.tabs["Promoter Details"].sections[1].table_rows
    assert len(land_owner_rows) == 1
    assert land_owner_rows[0] == {"Land Owner Name": "Suresh Gowda"}

    docs = proj.tabs["Uploaded Documents"].sections[0].documents
    assert len(docs) == 1
    assert docs[0].document_category == "Commencement Certificate"
    assert docs[0].displayed_filename == "CC_Valid.pdf"
    assert len(proj.pii_exclusions) >= 10


def test_unlinked_pane_semantic_identification_priority():
    """Proves that unlinked panes are never assigned global semantic labels based solely on DOM ID.

    Enforces priority:
    1. Explicit DOM comment label (e.g. <!-- <li><a href='#menu3'>...</a></li> -->).
    2. Actual heading inside the pane (h1/h2/h3/h4).
    3. Generic label: 'Unlinked Pane (#<id>)'.
    Preserves all discovered content and pane IDs independently of the label.
    """
    from scripts.detail_dom_parser import UNLINKED_PANE_LABELS, parse_project_detail_modal_html

    assert UNLINKED_PANE_LABELS == {}, "UNLINKED_PANE_LABELS must not hardcode semantic meaning by DOM ID"

    engine = KRERADiscoveryEngine(enforce_pii_policy=True, require_identity_verification=True)

    html = """
    <div id="result">
      <div class="row">
        <p>Project Name : UNLINKED PANE PRIORITY TEST</p>
        <p>Acknowledgement Number : PR/KN/260101/000333</p>
        <p>Registration Number : PRM/KA/RERA/1251/446/PR/260101/000333</p>
      </div>
      <ul class="nav nav-tabs">
        <li><a href="#home">Promoter Details</a></li>
        <!-- <li><a href="#menu3">Comment-Derived Financial Ledger</a></li> -->
      </ul>
      <div class="tab-content">
        <div id="home" class="tab-pane active">
          <h1>Promoter Details</h1>
          <div class="row">
            <div class="col-md-3"><p>Promoter Type :</p></div>
            <div class="col-md-3"><p>Company</p></div>
          </div>
        </div>

        <!-- Case 1: #menu3 has BOTH a comment label and an inner heading -> Comment label wins (Priority 1) -->
        <div id="menu3" class="tab-pane">
          <h1>Inner Heading Should Be Secondary To Comment</h1>
          <div class="row">
            <div class="col-md-3"><p>Ledger Balance :</p></div>
            <div class="col-md-3"><p>5000000</p></div>
          </div>
        </div>

        <!-- Case 2: #postReg has NO comment label, but has an inner heading -> Heading wins (Priority 2), NOT 'Post-Registration & Tower Details' -->
        <div id="postReg" class="tab-pane">
          <h2>Custom Geo-Coordinate Registry</h2>
          <div class="row">
            <div class="col-md-3"><p>Latitude :</p></div>
            <div class="col-md-3"><p>12.9716 N</p></div>
          </div>
        </div>

        <!-- Case 3: #modPlan and #menu5 have NO comment label and NO heading -> Generic label 'Unlinked Pane (#<id>)' wins (Priority 3) -->
        <div id="menu5" class="tab-pane">
          <div class="row">
            <div class="col-md-3"><p>Arbitration Reference :</p></div>
            <div class="col-md-3"><p>ARB/2026/77</p></div>
          </div>
        </div>

        <div id="extPlan" class="tab-pane">
          <div class="row">
            <div class="col-md-3"><p>Extension Note :</p></div>
            <div class="col-md-3"><p>Observed in generic unlinked pane</p></div>
          </div>
        </div>
      </div>
    </div>
    """

    raw_payload = parse_project_detail_modal_html(raw_html=html, scrub_raw_pii=True)
    proj = engine.create_project(
        {
            "PROJECT NAME": "UNLINKED PANE PRIORITY TEST",
            "ACKNOWLEDGEMENT NO": "PR/KN/260101/000333",
            "REGISTRATION NO": "PRM/KA/RERA/1251/446/PR/260101/000333",
        }
    )
    proj = engine.process_project_details(proj, raw_payload)

    # Verify Priority 1: Explicit DOM comment
    assert "#menu3" in proj.unlinked_dom_panes
    assert proj.unlinked_dom_panes["#menu3"].tab_label == "Comment-Derived Financial Ledger"
    assert proj.unlinked_dom_panes["#menu3"].sections[0].fields[0].raw_value == "5000000"

    # Verify Priority 2: Actual heading inside the pane (proving #postReg is NOT hardcoded to 'Post-Registration & Tower Details')
    assert "#postReg" in proj.unlinked_dom_panes
    assert proj.unlinked_dom_panes["#postReg"].tab_label == "Custom Geo-Coordinate Registry"
    assert proj.unlinked_dom_panes["#postReg"].sections[0].fields[0].raw_value == "12.9716 N"

    # Verify Priority 3: Generic label when neither comment nor heading is present
    assert "#menu5" in proj.unlinked_dom_panes
    assert proj.unlinked_dom_panes["#menu5"].tab_label == "Unlinked Pane (#menu5)"
    assert proj.unlinked_dom_panes["#menu5"].sections[0].fields[0].raw_value == "ARB/2026/77"

    assert "#extPlan" in proj.unlinked_dom_panes
    assert proj.unlinked_dom_panes["#extPlan"].tab_label == "Unlinked Pane (#extPlan)"
    assert proj.unlinked_dom_panes["#extPlan"].sections[0].fields[0].raw_value == "Observed in generic unlinked pane"


def test_pii_adversarial_synthetic_fixtures():
    """Adversarial PII test suite covering all 9 required vectors while preserving corporate & site info."""
    from scripts.detail_dom_parser import parse_project_detail_modal_html

    engine = KRERADiscoveryEngine(enforce_pii_policy=True, require_identity_verification=True)

    adversarial_html = """
    <div id="result">
      <div class="row">
        <p>Project Name : ADVERSARIAL SKYLINE</p>
        <p>Acknowledgement Number : PR/KN/260101/000444</p>
        <p>Registration Number : PRM/KA/RERA/1251/446/PR/260101/000444</p>
      </div>
      <ul class="nav nav-tabs">
        <li><a href="#home">Promoter Details</a></li>
        <li><a href="#menu1">Project Details</a></li>
        <li><a href="#menu2">Uploaded Documents</a></li>
      </ul>
      <div class="tab-content">
        <div id="home" class="tab-pane active">
          <h1>Promoter Details</h1>
          <div class="row">
            <div class="col-md-3"><p>Promoter Type :</p></div>
            <div class="col-md-3"><p>Company</p></div>
            <div class="col-md-3"><p>Company Name :</p></div>
            <div class="col-md-3"><p>SKYLINE INFRASTRUCTURES PRIVATE LIMITED</p></div>
          </div>
          <div class="row">
            <div class="col-md-3"><p>Official Address :</p></div>
            <div class="col-md-3"><p>Level 9, Prestige Trade Tower, Palace Road, Bengaluru 560001</p></div>
            <div class="col-md-3"><p>GSTIN Number :</p></div>
            <div class="col-md-3"><p>29AAACS8899K1Z5</p></div>
          </div>
          <div class="row">
            <div class="col-md-3"><p>Corporate Email :</p></div>
            <div class="col-md-3"><p>compliance@skylineinfra.co.in</p></div>
            <div class="col-md-3"><p>Registration Certificate :</p></div>
            <div class="col-md-3"><a href="/download_jc?DOC_ID=5001">Certificate_of_Incorporation.pdf</a></div>
          </div>
          <div class="row">
            <div class="col-md-3"><p>Tax Note :</p></div>
            <div class="col-md-3"><p>Ref_PAN_Token:_ABCDE1234F_and_(FGHJK5678L)</p></div>
            <div class="col-md-3"><p>Continuous UID :</p></div>
            <div class="col-md-3"><p>456789012345</p></div>
          </div>
          <div class="row">
            <div class="col-md-3"><p>Grouped UID Underscore :</p></div>
            <div class="col-md-3"><p>5678_1234_9012</p></div>
            <div class="col-md-3"><p>Grouped UID Dot :</p></div>
            <div class="col-md-3"><p>6789.2345.1098</p></div>
          </div>

          <h1>Authorized Signatory & Director Details</h1>
          <!-- 4-column headerless key-value table + nested individual table -->
          <table>
            <tbody>
              <tr>
                <td>Signatory Name :</td>
                <td>Vikramaditya Rao</td>
                <td>Designation :</td>
                <td>Managing Director</td>
              </tr>
              <tr>
                <td>Residential Address :</td>
                <td>Flat No. 402, 5th Cross, Indiranagar, Bengaluru 560038</td>
                <td>Personal Email :</td>
                <td>vikram.personal@gmail.com</td>
              </tr>
              <tr>
                <td>Mobile (+91 hyphen) :</td>
                <td>+91-98450-11223</td>
                <td>Mobile (0091 dot) :</td>
                <td>0091.98801.22334</td>
              </tr>
              <tr>
                <td>Mobile (0 prefix space) :</td>
                <td>097400 33445</td>
                <td>Photograph :</td>
                <td><a href="/download_jc?DOC_ID=5002">Director_Vikram_Photo_Scan.jpg</a></td>
              </tr>
            </tbody>
          </table>

          <!-- Outer table wrapping a nested headerless individual table -->
          <table>
            <thead>
              <tr><th>Group Entity</th><th>Nested Member Matrix</th></tr>
            </thead>
            <tbody>
              <tr>
                <td>Holding Group A</td>
                <td>
                  <table>
                    <tbody>
                      <tr>
                        <td>Ananya Sharma</td>
                        <td>#18, 2nd Main, Jayanagar, Bengaluru 560041</td>
                        <td>(+91) 99001-44556</td>
                        <td>ananya.sharma@yahoo.com</td>
                        <td>789012345678</td>
                        <td>PAN:MNOPQ9012R</td>
                      </tr>
                    </tbody>
                  </table>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div id="menu1" class="tab-pane">
          <h1>Project Details</h1>
          <div class="row">
            <div class="col-md-3"><p>Project Site Address :</p></div>
            <div class="col-md-3"><p>Sy No 88/2, Whitefield Main Road, Bengaluru East 560066</p></div>
            <div class="col-md-3"><p>Estimated Cost of Construction (INR) :</p></div>
            <div class="col-md-3"><p>345678901234</p></div>
          </div>
        </div>

        <div id="menu2" class="tab-pane">
          <h1>Uploaded Documents</h1>
          <table>
            <thead>
              <tr><th>Document Name</th><th>Document</th><th>Document Name</th><th>Document</th></tr>
            </thead>
            <tbody>
              <tr>
                <td>Project Photo</td>
                <td><a href="/download_jc?DOC_ID=6001">Site_Tower_A_East_Elevation_Photo.jpg</a></td>
                <td>Audit Document</td>
                <td><a href="/download_jc?DOC_ID=6002">Form3CB_2025_STUVW3456X_Signed.pdf</a></td>
              </tr>
              <tr>
                <td>KYC Attachment 1</td>
                <td><a href="/download_jc?DOC_ID=6003">Scan_Driving_Licence_Copy.pdf</a></td>
                <td>KYC Attachment 2</td>
                <td><a href="/download_jc?DOC_ID=6004">Doc_890123456789_Aadhaar.pdf</a></td>
              </tr>
              <tr>
                <td>KYC Attachment 3</td>
                <td><a href="/download_jc?DOC_ID=6005">Consent_kiran.owner@gmail.com_letter.pdf</a></td>
                <td>KYC Attachment 4</td>
                <td><a href="/download_jc?DOC_ID=6006">Verification_+91-98455-77889_record.pdf</a></td>
              </tr>
              <tr>
                <td>KYC Attachment 5</td>
                <td><a href="/download_jc?DOC_ID=6007">Voter_ID_Front_Back.pdf</a></td>
                <td>Sanctioned Plan</td>
                <td><a href="/download_jc?DOC_ID=6008">BBMP_Sanctioned_Layout_Plan_2026.pdf</a></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """

    raw_payload = parse_project_detail_modal_html(raw_html=adversarial_html, scrub_raw_pii=True)
    proj = engine.create_project(
        {
            "PROJECT NAME": "ADVERSARIAL SKYLINE",
            "ACKNOWLEDGEMENT NO": "PR/KN/260101/000444",
            "REGISTRATION NO": "PRM/KA/RERA/1251/446/PR/260101/000444",
        }
    )
    proj = engine.process_project_details(proj, raw_payload)

    combined_output = repr(raw_payload) + "\n" + proj.model_dump_json()

    # 1. Verify all adversarial PII tokens are completely absent from both raw and normalized outputs
    forbidden_tokens = [
        "ABCDE1234F",
        "FGHJK5678L",
        "MNOPQ9012R",
        "STUVW3456X",
        "456789012345",
        "5678_1234_9012",
        "6789.2345.1098",
        "789012345678",
        "890123456789",
        "Flat No. 402, 5th Cross, Indiranagar",
        "#18, 2nd Main, Jayanagar",
        "vikram.personal@gmail.com",
        "ananya.sharma@yahoo.com",
        "kiran.owner@gmail.com",
        "98450-11223",
        "98801.22334",
        "97400 33445",
        "99001-44556",
        "98455-77889",
        "Director_Vikram_Photo_Scan.jpg",
        "Scan_Driving_Licence_Copy.pdf",
        "Voter_ID_Front_Back.pdf",
        "DOC_ID=5002",
        "DOC_ID=6002",
        "DOC_ID=6003",
        "DOC_ID=6004",
        "DOC_ID=6005",
        "DOC_ID=6006",
        "DOC_ID=6007",
    ]
    for tok in forbidden_tokens:
        assert tok not in combined_output, f"Adversarial PII token leaked: {tok}"

    # 2. Verify corporate promoter & legitimate project/site information are retained
    retained_tokens = [
        "SKYLINE INFRASTRUCTURES PRIVATE LIMITED",
        "Level 9, Prestige Trade Tower, Palace Road, Bengaluru 560001",
        "29AAACS8899K1Z5",
        "compliance@skylineinfra.co.in",
        "Certificate_of_Incorporation.pdf",
        "Vikramaditya Rao",
        "Managing Director",
        "Holding Group A",
        "Ananya Sharma",
        "Sy No 88/2, Whitefield Main Road, Bengaluru East 560066",
        "345678901234",
        "Site_Tower_A_East_Elevation_Photo.jpg",
        "BBMP_Sanctioned_Layout_Plan_2026.pdf",
    ]
    for keep in retained_tokens:
        assert keep in proj.model_dump_json(), f"Legitimate corporate/site datum was over-redacted: {keep}"


