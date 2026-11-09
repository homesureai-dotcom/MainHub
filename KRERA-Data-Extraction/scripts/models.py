"""
K-RERA Discovery-Driven Ingestion Data Models

Core principle:
Never assume that every K-RERA project has the same tabs, sections, fields,
or documents. The ingestion data model represents discovery-driven observations
preserving raw evidence, explicit missingness states, PII exclusions,
cross-section conflict tracking, and coverage metrics.
"""

from __future__ import annotations

from datetime import datetime, timezone
from enum import Enum
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class ObservationState(str, Enum):
    """Explicit observation states for tabs, sections, fields, and documents.

    Prevents confounding missing elements with empty records or extraction failures.
    """
    PRESENT_WITH_DATA = "present_with_data"
    PRESENT_EMPTY = "present_empty"
    NOT_PRESENT = "not_present"
    NOT_APPLICABLE = "not_applicable"
    NOT_AVAILABLE = "not_available"
    EXTRACTION_FAILED = "extraction_failed"


class DetailExtractionStatus(str, Enum):
    """High-level project extraction outcome for batch-readiness and checkpointing."""
    PENDING = "pending"
    SUCCESSFUL = "successful"
    PARTIAL = "partial"
    FAILED = "failed"
    IDENTITY_UNVERIFIED = "identity_unverified"


class IdentityVerification(BaseModel):
    """Strict verification that the opened project modal matches the source catalogue record."""
    catalogue_project_name: Optional[str] = None
    modal_project_name: Optional[str] = None
    catalogue_ack_no: Optional[str] = None
    modal_ack_no: Optional[str] = None
    catalogue_reg_no: Optional[str] = None
    modal_reg_no: Optional[str] = None
    portal_detail_element_id: Optional[str] = None
    catalogue_page_number: Optional[int] = None
    catalogue_row_order: Optional[int] = None
    is_verified: bool = False
    verification_status: str = "unverified"  # verified, failed_mismatch, unverified_incomplete_identity, unverified_empty_modal
    reg_no_matches: Optional[bool] = None
    ack_no_matches: Optional[bool] = None
    project_name_matches: Optional[bool] = None
    mismatch_reasons: List[str] = Field(default_factory=list)
    verification_notes: List[str] = Field(default_factory=list)
    verified_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class PIIExclusionRecord(BaseModel):
    """Audit record for a PII field, image, document link, or table cell excluded at ingestion."""
    project_id: str
    tab_label: str
    section_label: str
    field_or_column_label: str
    pii_category: str  # personal_or_entity_pan, personal_photograph, individual_residential_address, individual_contact_or_id
    redaction_action: str  # excluded_field, excluded_document_link, excluded_table_cell, excluded_image
    reason: str
    extraction_timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class CrossSectionConflict(BaseModel):
    """Tracks conflicting values for the same concept across different tabs/sections without silent resolution."""
    canonical_concept: str
    distinct_raw_values: List[str] = Field(default_factory=list)
    observations: List[Dict[str, Any]] = Field(default_factory=list)
    note: str = "Conflicting values preserved independently across sections."


class FieldObservation(BaseModel):
    """Field-level observation preserving original portal label, raw value, and provenance."""
    field_label: str
    raw_value: Optional[str] = None
    normalized_value: Optional[Any] = None
    data_type: Optional[str] = None
    observation_state: ObservationState = ObservationState.PRESENT_WITH_DATA
    project_id: Optional[str] = None
    tab_label: Optional[str] = None
    section_label: Optional[str] = None
    source_reference: Optional[str] = None
    source_link: Optional[str] = None
    annexure_reference: Optional[str] = None
    anomaly_flags: List[str] = Field(default_factory=list)
    extraction_timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class DocumentObservation(BaseModel):
    """Document observation tracking category-first classification and source links."""
    document_category: str
    displayed_filename: Optional[str] = None
    approval_date_raw: Optional[str] = None
    approval_date_normalized: Optional[str] = None
    source_url: Optional[str] = None
    document_identifier: Optional[str] = None
    annexure_reference: Optional[str] = None
    project_id: Optional[str] = None
    tab_label: Optional[str] = None
    section_label: Optional[str] = None
    observation_state: ObservationState = ObservationState.PRESENT_WITH_DATA
    file_metadata: Dict[str, Any] = Field(default_factory=dict)
    anomaly_flags: List[str] = Field(default_factory=list)
    extraction_timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    downloaded_at: Optional[datetime] = None


class SectionObservation(BaseModel):
    """Section within a discovered tab.

    Can contain key-value fields, tabular rows, document collections, and nested subsections.
    """
    section_label: str
    section_type: str = "generic"  # key_value, table, document_list, mixed
    observation_state: ObservationState = ObservationState.PRESENT_WITH_DATA
    parent_section_label: Optional[str] = None
    empty_message: Optional[str] = None
    fields: List[FieldObservation] = Field(default_factory=list)
    table_headers: List[str] = Field(default_factory=list)
    table_rows: List[Dict[str, Any]] = Field(default_factory=list)
    documents: List[DocumentObservation] = Field(default_factory=list)
    subsections: List[SectionObservation] = Field(default_factory=list)
    anomaly_flags: List[str] = Field(default_factory=list)


class ProjectTabObservation(BaseModel):
    """Dynamically discovered project tab or DOM tab-pane.

    Tabs are never assumed to exist in a fixed set or sequence.
    Distinguishes visible navigation tabs from hidden/unlinked DOM tab-panes.
    """
    tab_label: str
    tab_identifier: Optional[str] = None
    is_nav_visible: bool = True
    dom_presence: str = "visible_nav_tab"  # visible_nav_tab, nested_sub_tab, hidden_or_unlinked_dom_pane, not_present_in_dom
    observation_state: ObservationState = ObservationState.PRESENT_WITH_DATA
    discovery_timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    sections: List[SectionObservation] = Field(default_factory=list)
    sub_tabs: Dict[str, ProjectTabObservation] = Field(default_factory=dict)
    error_message: Optional[str] = None


class ProjectExtractionCoverage(BaseModel):
    """Quantifiable extraction observability and coverage metrics.

    Evaluated against structures ACTUALLY discovered, never against a rigid expected tab list.
    """
    total_tabs_discovered: int = 0
    tabs_processed: List[str] = Field(default_factory=list)
    tabs_present_empty: List[str] = Field(default_factory=list)
    tabs_not_present: List[str] = Field(default_factory=list)
    tabs_extraction_failed: List[str] = Field(default_factory=list)
    unlinked_dom_panes_discovered: List[str] = Field(default_factory=list)
    unlinked_dom_panes_with_data: List[str] = Field(default_factory=list)
    unlinked_dom_panes_empty: List[str] = Field(default_factory=list)
    sections_present_with_data: List[str] = Field(default_factory=list)
    sections_present_empty: List[str] = Field(default_factory=list)
    total_sections_discovered: int = 0
    total_fields_discovered: int = 0
    total_table_rows_discovered: int = 0
    total_documents_discovered: int = 0
    unique_document_observations_count: int = 0
    document_links_count: int = 0
    placeholder_document_entries_count: int = 0
    unavailable_document_slots_count: int = 0
    pii_exclusions_count: int = 0
    conflicts_detected_count: int = 0
    extraction_timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    errors: List[str] = Field(default_factory=list)
    validation_warnings: List[str] = Field(default_factory=list)

    def summary(self) -> Dict[str, Any]:
        """Answer Question 1: What information did we find for this project?"""
        return {
            "tabs_discovered": self.total_tabs_discovered,
            "tabs_successful": len(self.tabs_processed),
            "tabs_empty": len(self.tabs_present_empty),
            "unlinked_dom_panes": len(self.unlinked_dom_panes_discovered),
            "sections_captured": self.total_sections_discovered,
            "fields_captured": self.total_fields_discovered,
            "table_rows_captured": self.total_table_rows_discovered,
            "documents_captured": self.total_documents_discovered,
            "unique_document_observations": self.unique_document_observations_count,
            "document_links": self.document_links_count,
            "placeholder_document_entries": self.placeholder_document_entries_count,
            "unavailable_document_slots": self.unavailable_document_slots_count,
            "pii_exclusions_count": self.pii_exclusions_count,
            "conflicts_detected_count": self.conflicts_detected_count,
            "errors_count": len(self.errors),
            "warnings_count": len(self.validation_warnings),
        }

    def available_tabs(self) -> List[str]:
        """Answer Question 2: Which tabs were actually available?"""
        return list(dict.fromkeys(self.tabs_processed + self.tabs_present_empty + self.tabs_extraction_failed))

    def empty_or_absent_sections(self) -> Dict[str, List[str]]:
        """Answer Question 3: Which sections were empty or absent?"""
        return {
            "empty_tabs": self.tabs_present_empty,
            "not_present_tabs": self.tabs_not_present,
            "empty_sections": self.sections_present_empty,
            "empty_unlinked_dom_panes": self.unlinked_dom_panes_empty,
        }

    def failed_extractions(self) -> List[str]:
        """Answer Question 4: What failed to extract?"""
        return self.tabs_extraction_failed

    def coverage_ratio(self) -> float:
        """Answer Question 5: How much of the available portal information was successfully captured?"""
        if self.total_tabs_discovered == 0:
            return 0.0
        successful_tabs = len(self.tabs_processed) + len(self.tabs_present_empty)
        return round((successful_tabs / self.total_tabs_discovered) * 100.0, 2)


class Project(BaseModel):
    """Core Project entity representing a K-RERA registered development."""
    internal_id: str
    registration_number: Optional[str] = None
    acknowledgement_number: Optional[str] = None
    project_name: Optional[str] = None
    promoter_name: Optional[str] = None
    district: Optional[str] = None
    taluk: Optional[str] = None
    project_type: Optional[str] = None
    status: Optional[str] = None
    approved_on: Optional[str] = None
    proposed_completion_date: Optional[str] = None
    catalogue_source_info: Dict[str, Any] = Field(default_factory=dict)

    # High-level extraction status (successful, partial, failed, identity_unverified)
    extraction_status: DetailExtractionStatus = DetailExtractionStatus.PENDING

    # Identity Verification against modal header
    identity_verification: Optional[IdentityVerification] = None

    # Dynamic visible navigation tab observations
    tabs: Dict[str, ProjectTabObservation] = Field(default_factory=dict)

    # Unlinked / hidden DOM tab-panes present in modal HTML
    unlinked_dom_panes: Dict[str, ProjectTabObservation] = Field(default_factory=dict)

    # PII Exclusions & Cross-Section Conflict Audit
    pii_exclusions: List[PIIExclusionRecord] = Field(default_factory=list)
    cross_section_conflicts: List[CrossSectionConflict] = Field(default_factory=list)

    # Audit & Observability
    coverage: Optional[ProjectExtractionCoverage] = None
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
