"""
K-RERA Dynamic Discovery Ingestion Engine

Implements the discovery-driven workflow:
Project Discovery -> Project Detail Modal -> Strict Identity Verification -> Tab Discovery
(Visible Nav Tabs + Sub-Tabs + Unlinked DOM Panes) -> Section Discovery
-> Field/Table/Document Discovery -> PII Redaction -> Cross-Section Conflict Detection
-> Validation -> Persistence

Core principles:
1. Never assume that every K-RERA project has the same tabs, sections, fields,
   or documents. Unknown tabs, panes, sections, and categories are preserved.
2. Strict identity verification: Registration number, Acknowledgement number,
   and Project name must be verified before associating detail data with a
   catalogue record.
3. Strict PII exclusion across every extraction path (fields, tables, documents,
   images, nested subsections).
"""

from __future__ import annotations

import re
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Set, Tuple
import uuid

from .models import (
    CrossSectionConflict,
    DetailExtractionStatus,
    DocumentObservation,
    FieldObservation,
    IdentityVerification,
    ObservationState,
    PIIExclusionRecord,
    Project,
    ProjectExtractionCoverage,
    ProjectTabObservation,
    SectionObservation,
)

# Regex patterns for PII detection (using (?<![A-Za-z0-9]) / (?![A-Za-z0-9]) so punctuation/underscore-bounded tokens are matched)
GSTIN_VALUE_REGEX = re.compile(
    r"(?<![A-Za-z0-9])[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z](?![A-Za-z0-9])",
    re.IGNORECASE,
)
PAN_VALUE_REGEX = re.compile(
    r"(?<![A-Za-z0-9])[A-Z]{5}[0-9]{4}[A-Z](?![A-Za-z0-9])",
    re.IGNORECASE,
)
AADHAAR_GROUPED_VALUE_REGEX = re.compile(
    r"(?<![0-9])[2-9]\d{3}[\s._-]\d{4}[\s._-]\d{4}(?![0-9])"
)
AADHAAR_CONTINUOUS_VALUE_REGEX = re.compile(
    r"(?<![A-Za-z0-9])[2-9]\d{11}(?![A-Za-z0-9])"
)
AADHAAR_VALUE_REGEX = re.compile(
    r"(?:(?<![0-9])[2-9]\d{3}[\s._-]\d{4}[\s._-]\d{4}(?![0-9]))"
    r"|(?:(?<![A-Za-z0-9])[2-9]\d{11}(?![A-Za-z0-9]))"
)
EMAIL_VALUE_REGEX = re.compile(
    r"(?<![A-Za-z0-9._%+-])[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}(?![A-Za-z0-9])"
)
INDIAN_MOBILE_VALUE_REGEX = re.compile(
    r"(?<![0-9])(?:(?:\(\+?91\)|\+91|0091|91|0)[\s._-]*)?[6-9]\d{4}[\s._-]?\d{5}(?![0-9])"
    r"|(?<![0-9])(?:(?:\(\+?91\)|\+91|0091|91|0)[\s._-]*)?[6-9]\d{2}[\s._-]\d{3}[\s._-]\d{4}(?![0-9])"
    r"|(?<![0-9])(?:(?:\(\+?91\)|\+91|0091|91|0)[\s._-]*)?[6-9]\d{3}[\s._-]\d{3}[\s._-]\d{3}(?![0-9])"
)
RESIDENTIAL_ADDRESS_VALUE_REGEX = re.compile(
    r"(?:\b(?:house|flat|door|plot|apt|apartment|villa)\s*(?:no\.?|number|#)?\s*[:#-]?\s*[A-Za-z0-9/-]+)"
    r"|(?:#\s*\d+[A-Za-z/-]*\s*,)"
    r"|(?:\b\d+(?:st|nd|rd|th)\s+(?:cross|main|block|stage|phase|sector)\b.*\b(?:bengaluru|bangalore|mysuru|karnataka|5\d{5})\b)"
    r"|(?:\b(?:residency|nagar|layout|colony|extension|enclave|marg|street|avenue|lane)\b.*\b5\d{5}\b)",
    re.IGNORECASE,
)

PAN_LABEL_REGEX = re.compile(
    r"\bpan\b|\bpan\s+no\.?\b|\bpan\s+number\b|\bpan\s+card\b|\bincome\s+tax\s+pan\b",
    re.IGNORECASE,
)
AADHAAR_OR_ID_LABEL_REGEX = re.compile(
    r"\baadhaar\b|\baadhar\b|\buidai\b|\bvoter\s*id\b|\bpassport(?!\s+photo)\b"
    r"|\bdriving\s+licen[cs]e\b|\bration\s+card\b",
    re.IGNORECASE,
)
ID_DOC_FILENAME_REGEX = re.compile(
    r"(^|[^a-z0-9])(pan|pan[_\s.-]*card|aadhaar|aadhar|passport|voter[_\s.-]*id"
    r"|driving[_\s.-]*licen[cs]e|dl[_\s.-]*scan|ration[_\s.-]*card|id[_\s.-]*proof"
    r"|identity[_\s.-]*proof|address[_\s.-]*proof)([^a-z0-9]|$)",
    re.IGNORECASE,
)
PHOTO_LABEL_REGEX = re.compile(
    r"\bphotograph\b|\bphoto\s+id\b|\bpassport\s+photo\b|\bphoto\b|\bheadshot\b|\bportrait\b",
    re.IGNORECASE,
)
PERSONAL_PHOTO_FILENAME_REGEX = re.compile(
    r"(signatory|director|partner|promoter|member|passport|individual|owner|proprietor).*(photo|img|pic|scan)"
    r"|(photo|img|pic|headshot).*(signatory|director|partner|promoter|member|passport|individual|owner|proprietor)",
    re.IGNORECASE,
)

INDIVIDUAL_SECTION_KEYWORDS = (
    "signatory",
    "member",
    "partner",
    "director",
    "land owner",
    "landowner",
    "co-promoter",
    "individual",
    "proprietor",
)

RESIDENTIAL_ADDRESS_LABEL_REGEX = re.compile(
    r"\bpresent\s+address\b|\bpermanent\s+address\b|\bresidential\s+address\b"
    r"|\bresidence\s+address\b|\bhome\s+address\b",
    re.IGNORECASE,
)

INDIVIDUAL_ADDRESS_REGEX = re.compile(
    r"\bpresent\s+address\b|\bpermanent\s+address\b|\bcommunication\s+address\b"
    r"|\bresidential\s+address\b|\bresidence\s+address\b|\bhome\s+address\b"
    r"|\baddress\b|\bstreet\b|\bhouse\s+no\b",
    re.IGNORECASE,
)

INDIVIDUAL_CONTACT_LABEL_REGEX = re.compile(
    r"\bmobile\b|\bphone\b|\btelephone\b|\bcontact\s*no\.?\b|\bcontact\s*number\b"
    r"|\bcell\b|\be-?mail\b",
    re.IGNORECASE,
)

EXPLICIT_PERSONAL_CONTACT_LABEL_REGEX = re.compile(
    r"\b(personal|individual|signatory|director|partner|member|owner|proprietor)\s+"
    r"(mobile|phone|telephone|contact|e-?mail|address)\b",
    re.IGNORECASE,
)


def is_individual_section(
    section_label: str,
    tab_label: str = "",
    promoter_type: Optional[str] = None,
) -> bool:
    """Returns True when a section represents individual persons (signatories, directors, partners, landowners, or an Individual promoter)."""
    s_low = (section_label or "").lower()
    if any(kw in s_low for kw in INDIVIDUAL_SECTION_KEYWORDS):
        return True
    if promoter_type and any(
        pt in promoter_type.lower() for pt in ("individual", "proprietor")
    ):
        if "promoter" in s_low or "promoter" in (tab_label or "").lower():
            return True
    return False


def classify_pii_exclusion(
    field_label: str,
    raw_value: Optional[str],
    section_label: str,
    tab_label: str,
    is_document: bool = False,
    filename: Optional[str] = None,
    promoter_type: Optional[str] = None,
) -> Optional[Tuple[str, str]]:
    """Determines whether a field, document, or table cell must be excluded under HomeSure's PII policy.

    Returns (pii_category, reason) if excluded, else None.
    """
    lbl = (field_label or "").strip()
    lbl_low = lbl.lower()
    sec_low = (section_label or "").lower()
    tab_low = (tab_label or "").lower()
    val_str = str(raw_value or "").strip()
    fn_str = str(filename or (val_str if is_document else "") or "").strip()
    is_indiv = is_individual_section(section_label, tab_label, promoter_type=promoter_type)

    # 1. PAN or Aadhaar / Personal Identity labels, values, or filenames
    if PAN_LABEL_REGEX.search(lbl) or AADHAAR_OR_ID_LABEL_REGEX.search(lbl):
        return (
            "personal_or_entity_pan",
            f"Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='{lbl}').",
        )

    if is_indiv and re.search(r"\bid\s+proof\b|\bidentity\s+proof\b|\baddress\s+proof\b", lbl_low):
        return (
            "individual_contact_or_id",
            f"Excluded personal identity/address proof '{lbl}' in individual section '{section_label}'.",
        )

    # Check if value contains a standalone 10-char PAN (excluding 15-char corporate GSTIN)
    val_without_gstin = GSTIN_VALUE_REGEX.sub("", val_str)
    if (
        PAN_VALUE_REGEX.search(val_without_gstin)
        or "SYNTHETIC_PAN" in val_str
        or "SYNTHPAN" in val_str
        or "[REDACTED_PII" in val_str
    ):
        return (
            "personal_or_entity_pan",
            f"Excluded value matching Indian PAN pattern in field '{lbl}'.",
        )

    is_non_aadhaar_numeric_metric = bool(
        re.search(
            r"\b(?:cost|amount|inr|area|sqft|sq\.?\s*ft|sqm|sq\.?\s*m|survey|khata"
            r"|account(?:\s*(?:no\.?|number))?|escrow|ifsc|cin|llpin|din"
            r"|registration|acknowledgement|certificate|utr|longitude|latitude)\b",
            lbl_low,
            re.IGNORECASE,
        )
    )
    if AADHAAR_GROUPED_VALUE_REGEX.search(val_str) or (
        not is_non_aadhaar_numeric_metric and AADHAAR_CONTINUOUS_VALUE_REGEX.search(val_str)
    ):
        return (
            "personal_or_entity_pan",
            f"Excluded value matching Aadhaar number pattern in field '{lbl}'.",
        )

    # Check document filename for PAN / Aadhaar / Passport / Voter ID or embedded sensitive tokens
    if is_document and fn_str:
        fn_without_gstin = GSTIN_VALUE_REGEX.sub("", fn_str)
        # Strip standard ISO timestamp prefixes like 2017-11-15-11-10-02-807 before checking phone/Aadhaar in filenames
        fn_without_ts = re.sub(
            r"\b20\d{2}[-_.]\d{2}[-_.]\d{2}(?:[-_.]\d{2,3}){1,4}\b",
            "",
            fn_without_gstin,
        )
        if (
            ID_DOC_FILENAME_REGEX.search(fn_str)
            or PAN_VALUE_REGEX.search(fn_without_gstin)
            or AADHAAR_GROUPED_VALUE_REGEX.search(fn_without_ts)
            or AADHAAR_CONTINUOUS_VALUE_REGEX.search(fn_without_ts)
        ):
            return (
                "personal_or_entity_pan",
                f"Excluded identity document or filename containing PAN/Aadhaar/ID pattern (label='{lbl}').",
            )
        if EMAIL_VALUE_REGEX.search(fn_str) or INDIAN_MOBILE_VALUE_REGEX.search(fn_without_ts):
            return (
                "individual_contact_or_id",
                f"Excluded document filename containing embedded email or mobile number (label='{lbl}').",
            )

    # 2. Personal photographs (in Promoter/Signatory/Member/Partner/Land Owner sections)
    # Preserve 'Project Photo', 'Photos Uploaded', site/construction/building/tower/quarterly photos.
    has_explicit_personal_photo_marker = bool(
        re.search(
            r"\b(signatory|director|partner|promoter|member|passport|individual|owner|proprietor)\b",
            f"{lbl_low} {fn_str.lower()}",
        )
        or "REDACTED_PERSONAL_PHOTO" in val_str
        or "SYNTHETIC_PERSONAL_PHOTO" in fn_str
    )
    is_project_site_photo = (
        not has_explicit_personal_photo_marker
        and (
            any(
                kw in lbl_low or kw in sec_low
                for kw in (
                    "project photo",
                    "photos uploaded",
                    "photo uploaded",
                    "site photo",
                    "photo of site",
                    "building photo",
                    "construction photo",
                    "progress photo",
                    "tower photo",
                    "elevation photo",
                    "layout photo",
                    "aerial photo",
                    "borewell",
                    "stp",
                    "water",
                    "park",
                    "garden",
                    "road",
                    "boundary",
                    "clubhouse",
                    "amenity",
                    "east",
                    "west",
                    "north",
                    "south",
                )
            )
            or tab_low
            in (
                "completion details",
                "quarterly updates",
                "project details",
                "post-registration & tower details",
                "project extension details",
                "modification of plan details",
            )
            or (tab_low in ("uploaded documents", "enquired documents") and not is_indiv)
        )
    )
    if not is_project_site_photo:
        if PHOTO_LABEL_REGEX.search(lbl) or "REDACTED_PERSONAL_PHOTO" in val_str or "SYNTHETIC_PERSONAL_PHOTO" in fn_str:
            return (
                "personal_photograph",
                f"Excluded personal photograph field/link in '{section_label}' (label='{lbl}').",
            )
        if is_document and fn_str and PERSONAL_PHOTO_FILENAME_REGEX.search(fn_str):
            return (
                "personal_photograph",
                f"Excluded personal photograph filename in '{section_label}' (label='{lbl}').",
            )

    # 3. Individual residential/personal addresses
    if RESIDENTIAL_ADDRESS_LABEL_REGEX.search(lbl_low):
        return (
            "individual_residential_address",
            f"Excluded individual residential address '{lbl}' in section '{section_label}'.",
        )

    if EXPLICIT_PERSONAL_CONTACT_LABEL_REGEX.search(lbl_low):
        cat = (
            "individual_residential_address"
            if "address" in lbl_low
            else "individual_contact_or_id"
        )
        return (
            cat,
            f"Excluded explicit personal address/contact field '{lbl}' in section '{section_label}'.",
        )

    if is_indiv:
        # Preserve Official Address / Office Address if explicitly labelled as such
        is_official_addr = "official address" in lbl_low or "office address" in lbl_low
        if not is_official_addr and INDIVIDUAL_ADDRESS_REGEX.search(lbl_low):
            return (
                "individual_residential_address",
                f"Excluded individual personal address '{lbl}' inside individual section '{section_label}'.",
            )
        if INDIVIDUAL_CONTACT_LABEL_REGEX.search(lbl_low):
            return (
                "individual_contact_or_id",
                f"Excluded individual contact detail '{lbl}' inside individual section '{section_label}'.",
            )
        # Value-level check inside individual sections for unlabelled/headerless email, mobile phone, or residential address values
        if EMAIL_VALUE_REGEX.search(val_str):
            return (
                "individual_contact_or_id",
                f"Excluded individual email value in field '{lbl}' inside '{section_label}'.",
            )
        if (
            not any(k in lbl_low for k in ("pin", "zip", "registration", "din", "survey", "cost", "area"))
            and INDIAN_MOBILE_VALUE_REGEX.search(val_str)
        ):
            return (
                "individual_contact_or_id",
                f"Excluded individual mobile phone value in field '{lbl}' inside '{section_label}'.",
            )
        if not is_official_addr and (
            lbl_low.startswith("column_") or not lbl_low
        ) and RESIDENTIAL_ADDRESS_VALUE_REGEX.search(val_str):
            return (
                "individual_residential_address",
                f"Excluded unlabelled residential address value in '{lbl}' inside individual section '{section_label}'.",
            )

    return None


def parse_canonical_date(raw_str: str) -> Tuple[Optional[str], Optional[str]]:
    """Attempts to parse a date string into canonical ISO 'YYYY-MM-DD'.

    Returns (canonical_iso_date, anomaly_flag).
    - Placeholder dates ('01-01-0001', '00-00-0000', year < 1900) return (None, 'ANOMALY_MALFORMED_PLACEHOLDER_DATE').
    - Invalid calendar dates ('31-02-2021', '99-99-2020') return (None, 'ANOMALY_DATE_PARSE_FAILED').
    - Valid dates return ('YYYY-MM-DD', None).
    """
    s = (raw_str or "").strip()
    if not s:
        return None, None

    if any(pat in s for pat in ("01-01-0001", "00-00-0000", "01/01/0001", "0000-00-00", "01-01-1900")):
        return None, "ANOMALY_MALFORMED_PLACEHOLDER_DATE"

    # Match DD-MM-YYYY or DD/MM/YYYY
    m_dmy = re.match(r"^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$", s)
    if m_dmy:
        day, month, year = int(m_dmy.group(1)), int(m_dmy.group(2)), int(m_dmy.group(3))
        if year < 1900:
            return None, "ANOMALY_MALFORMED_PLACEHOLDER_DATE"
        try:
            dt = datetime(year, month, day)
            return dt.strftime("%Y-%m-%d"), None
        except ValueError:
            return None, "ANOMALY_DATE_PARSE_FAILED"

    # Match YYYY-MM-DD or YYYY/MM/DD
    m_ymd = re.match(r"^(\d{4})[-/](\d{1,2})[-/](\d{1,2})$", s)
    if m_ymd:
        year, month, day = int(m_ymd.group(1)), int(m_ymd.group(2)), int(m_ymd.group(3))
        if year < 1900:
            return None, "ANOMALY_MALFORMED_PLACEHOLDER_DATE"
        try:
            dt = datetime(year, month, day)
            return dt.strftime("%Y-%m-%d"), None
        except ValueError:
            return None, "ANOMALY_DATE_PARSE_FAILED"

    return None, "ANOMALY_DATE_PARSE_FAILED"


class KRERADiscoveryEngine:
    """Discovery-driven ingestion engine for K-RERA project detail structures."""

    def __init__(
        self,
        generate_uuid_fallback: bool = True,
        enforce_pii_policy: bool = True,
        require_identity_verification: bool = False,
    ):
        self.generate_uuid_fallback = generate_uuid_fallback
        self.enforce_pii_policy = enforce_pii_policy
        self.require_identity_verification = require_identity_verification

    def create_project(
        self,
        catalogue_row: Dict[str, Any],
        internal_id: Optional[str] = None,
    ) -> Project:
        """Step A: Project Discovery from catalogue row."""
        reg_no = (
            catalogue_row.get("registration_no")
            or catalogue_row.get("Registration No")
            or catalogue_row.get("REGISTRATION NO")
        )
        ack_no = (
            catalogue_row.get("acknowledgement_no")
            or catalogue_row.get("Acknowledgement No")
            or catalogue_row.get("ACKNOWLEDGEMENT NO")
        )

        if not internal_id:
            if reg_no and str(reg_no).strip():
                clean_reg = re.sub(r"[^A-Za-z0-9_-]", "_", str(reg_no).strip())
                internal_id = f"KRERA_{clean_reg}"
            elif ack_no and str(ack_no).strip():
                clean_ack = re.sub(r"[^A-Za-z0-9_-]", "_", str(ack_no).strip())
                internal_id = f"KRERA_ACK_{clean_ack}"
            else:
                internal_id = f"KRERA_GEN_{uuid.uuid4().hex[:12]}"

        project = Project(
            internal_id=internal_id,
            registration_number=reg_no,
            acknowledgement_number=ack_no,
            project_name=(
                catalogue_row.get("project_name")
                or catalogue_row.get("Project Name")
                or catalogue_row.get("PROJECT NAME")
            ),
            promoter_name=(
                catalogue_row.get("promoter_name")
                or catalogue_row.get("Promoter Name")
                or catalogue_row.get("PROMOTER NAME")
            ),
            district=(
                catalogue_row.get("district")
                or catalogue_row.get("District")
                or catalogue_row.get("DISTRICT")
            ),
            taluk=(
                catalogue_row.get("taluk")
                or catalogue_row.get("Taluk")
                or catalogue_row.get("TALUK")
            ),
            project_type=(
                catalogue_row.get("project_type")
                or catalogue_row.get("Project Type")
                or catalogue_row.get("PROJECT TYPE")
            ),
            status=(
                catalogue_row.get("status")
                or catalogue_row.get("Status")
                or catalogue_row.get("STATUS")
            ),
            approved_on=(
                catalogue_row.get("approved_on")
                or catalogue_row.get("Approved On")
                or catalogue_row.get("APPROVED ON")
            ),
            proposed_completion_date=(
                catalogue_row.get("proposed_completion_date")
                or catalogue_row.get("Proposed Completion Date")
                or catalogue_row.get("PROPOSED COMPLETION DATE")
            ),
            catalogue_source_info=catalogue_row,
        )
        return project

    def verify_project_identity(
        self,
        project: Project,
        modal_identity: Optional[Dict[str, Any]],
    ) -> IdentityVerification:
        """Strictly verifies that the opened modal's banner identity matches the source catalogue record.

        Rules:
        - Registration number must match exactly when available on both sides.
        - Acknowledgement number must match when available on both sides.
        - Project name is a required consistency check.
        - A registration-number mismatch is NEVER accepted even if the other two fields match.
        - Missing or incomplete identity information produces an explicit unverified state.
        """
        cat_name = re.sub(r"\s+", " ", (project.project_name or "")).strip()
        cat_ack = (project.acknowledgement_number or "").strip()
        cat_reg = (project.registration_number or "").strip()

        modal_dict = modal_identity if isinstance(modal_identity, dict) else {}
        mod_name = re.sub(r"\s+", " ", (modal_dict.get("project_name") or "")).strip()
        mod_ack = (modal_dict.get("acknowledgement_number") or "").strip()
        mod_reg = (modal_dict.get("registration_number") or "").strip()

        notes: List[str] = []
        mismatch_reasons: List[str] = []

        # 1. Check for completely empty modal identity
        if not mod_name and not mod_ack and not mod_reg:
            msg = "Modal identity is empty: no Project Name, Acknowledgement Number, or Registration Number found."
            notes.append(msg)
            mismatch_reasons.append(msg)
            verification = IdentityVerification(
                catalogue_project_name=cat_name or None,
                modal_project_name=None,
                catalogue_ack_no=cat_ack or None,
                modal_ack_no=None,
                catalogue_reg_no=cat_reg or None,
                modal_reg_no=None,
                portal_detail_element_id=modal_dict.get("portal_detail_element_id"),
                catalogue_page_number=modal_dict.get("catalogue_page_number"),
                catalogue_row_order=modal_dict.get("catalogue_row_order"),
                is_verified=False,
                verification_status="unverified_empty_modal",
                reg_no_matches=None,
                ack_no_matches=None,
                project_name_matches=None,
                mismatch_reasons=mismatch_reasons,
                verification_notes=notes,
            )
            project.identity_verification = verification
            return verification

        # 2. Evaluate each identifier
        reg_match: Optional[bool] = None
        ack_match: Optional[bool] = None
        name_match: Optional[bool] = None
        has_missing_identifier = False

        if cat_reg and mod_reg:
            reg_match = cat_reg.upper() == mod_reg.upper()
            if reg_match:
                notes.append(f"Registration number exact match: {mod_reg}")
            else:
                reason = f"Registration number mismatch: catalogue='{cat_reg}' vs modal='{mod_reg}'"
                notes.append(reason)
                mismatch_reasons.append(reason)
        else:
            has_missing_identifier = True
            reason = f"Incomplete registration number: catalogue='{cat_reg or None}' vs modal='{mod_reg or None}'"
            notes.append(reason)
            mismatch_reasons.append(reason)

        if cat_ack and mod_ack:
            ack_match = cat_ack.upper() == mod_ack.upper()
            if ack_match:
                notes.append(f"Acknowledgement number exact match: {mod_ack}")
            else:
                reason = f"Acknowledgement number mismatch: catalogue='{cat_ack}' vs modal='{mod_ack}'"
                notes.append(reason)
                mismatch_reasons.append(reason)
        else:
            has_missing_identifier = True
            reason = f"Incomplete acknowledgement number: catalogue='{cat_ack or None}' vs modal='{mod_ack or None}'"
            notes.append(reason)
            mismatch_reasons.append(reason)

        if cat_name and mod_name:
            name_match = cat_name.upper() == mod_name.upper()
            if name_match:
                notes.append(f"Project name exact match (case-insensitive): {mod_name}")
            else:
                reason = f"Project name mismatch: catalogue='{cat_name}' vs modal='{mod_name}'"
                notes.append(reason)
                mismatch_reasons.append(reason)
        else:
            has_missing_identifier = True
            reason = f"Incomplete project name: catalogue='{cat_name or None}' vs modal='{mod_name or None}'"
            notes.append(reason)
            mismatch_reasons.append(reason)

        # Strict decision logic:
        # Any explicit False in (reg_match, ack_match, name_match) is a failed_mismatch.
        # Otherwise any missing identifier is unverified_incomplete_identity.
        if reg_match is False or ack_match is False or name_match is False:
            is_verified = False
            verification_status = "failed_mismatch"
        elif has_missing_identifier:
            is_verified = False
            verification_status = "unverified_incomplete_identity"
        else:
            is_verified = True
            verification_status = "verified"

        verification = IdentityVerification(
            catalogue_project_name=cat_name or None,
            modal_project_name=mod_name or None,
            catalogue_ack_no=cat_ack or None,
            modal_ack_no=mod_ack or None,
            catalogue_reg_no=cat_reg or None,
            modal_reg_no=mod_reg or None,
            portal_detail_element_id=modal_dict.get("portal_detail_element_id"),
            catalogue_page_number=modal_dict.get("catalogue_page_number"),
            catalogue_row_order=modal_dict.get("catalogue_row_order"),
            is_verified=is_verified,
            verification_status=verification_status,
            reg_no_matches=reg_match,
            ack_no_matches=ack_match,
            project_name_matches=name_match,
            mismatch_reasons=mismatch_reasons,
            verification_notes=notes,
        )
        project.identity_verification = verification
        return verification

    def process_project_details(
        self,
        project: Project,
        portal_payload: Dict[str, Any],
    ) -> Project:
        """Executes discovery-driven tab, section, and field extraction.

        If `modal_identity` is present in `portal_payload` (or `require_identity_verification=True`),
        strict identity verification is enforced BEFORE associating any project detail tabs/panes
        with the catalogue record.
        """
        coverage = ProjectExtractionCoverage()

        if "modal_identity" in portal_payload or self.require_identity_verification:
            iv = self.verify_project_identity(project, portal_payload.get("modal_identity"))
            if not iv.is_verified:
                project.tabs = {}
                project.unlinked_dom_panes = {}
                project.extraction_status = DetailExtractionStatus.IDENTITY_UNVERIFIED
                err_msg = (
                    f"Blocked detail association due to unverified modal identity "
                    f"({iv.verification_status}): {'; '.join(iv.mismatch_reasons)}"
                )
                coverage.errors.append(err_msg)
                coverage.extraction_timestamp = datetime.now(timezone.utc)
                project.coverage = coverage
                project.updated_at = datetime.now(timezone.utc)
                return project

        discovered_tabs_data = portal_payload.get("tabs", [])
        unlinked_panes_data = portal_payload.get("unlinked_dom_panes", [])

        # Step B: Dynamic Visible Navigation Tab Discovery
        coverage.total_tabs_discovered = len(discovered_tabs_data)

        for tab_data in discovered_tabs_data:
            tab_obs = self._process_single_tab_payload(
                project=project,
                tab_data=tab_data,
                coverage=coverage,
                is_unlinked_pane=False,
            )
            project.tabs[tab_obs.tab_label] = tab_obs

        # Step B2: Dynamic Unlinked / Hidden DOM Tab-Pane Discovery
        for pane_data in unlinked_panes_data:
            pane_obs = self._process_single_tab_payload(
                project=project,
                tab_data=pane_data,
                coverage=coverage,
                is_unlinked_pane=True,
            )
            pane_key = pane_obs.tab_identifier or pane_obs.tab_label
            project.unlinked_dom_panes[pane_key] = pane_obs
            coverage.unlinked_dom_panes_discovered.append(f"{pane_obs.tab_label} ({pane_key})")
            if pane_obs.observation_state == ObservationState.PRESENT_WITH_DATA:
                coverage.unlinked_dom_panes_with_data.append(f"{pane_obs.tab_label} ({pane_key})")
            elif pane_obs.observation_state == ObservationState.PRESENT_EMPTY:
                coverage.unlinked_dom_panes_empty.append(f"{pane_obs.tab_label} ({pane_key})")

        # Track expected tabs not present (if caller checked specific tabs)
        expected_probes = portal_payload.get("checked_absent_tabs", [])
        for probe in expected_probes:
            if probe not in project.tabs:
                coverage.tabs_not_present.append(probe)

        # Compute separate document and slot counts across visible navigation tabs
        self._compute_document_coverage_metrics(project, coverage)

        # Detect cross-section conflicts without overwriting
        self.detect_cross_section_conflicts(project)

        coverage.pii_exclusions_count = len(project.pii_exclusions)
        coverage.conflicts_detected_count = len(project.cross_section_conflicts)
        coverage.extraction_timestamp = datetime.now(timezone.utc)
        project.coverage = coverage

        # Set high-level DetailExtractionStatus
        if coverage.total_tabs_discovered == 0:
            project.extraction_status = DetailExtractionStatus.FAILED
        elif coverage.tabs_extraction_failed or coverage.errors:
            if len(coverage.tabs_processed) + len(coverage.tabs_present_empty) > 0:
                project.extraction_status = DetailExtractionStatus.PARTIAL
            else:
                project.extraction_status = DetailExtractionStatus.FAILED
        else:
            project.extraction_status = DetailExtractionStatus.SUCCESSFUL

        project.updated_at = datetime.now(timezone.utc)
        return project

    def _compute_document_coverage_metrics(
        self,
        project: Project,
        coverage: ProjectExtractionCoverage,
    ) -> None:
        """Computes separate counts for unique documents, downloadable links, placeholders, and unavailable slots."""
        unique_keys: Set[Tuple[str, str, str]] = set()
        doc_links_count = 0
        placeholder_count = 0
        unavailable_count = 0

        def walk_sections(sections: List[SectionObservation]) -> None:
            nonlocal doc_links_count, placeholder_count, unavailable_count
            for sec in sections:
                for doc in sec.documents:
                    if doc.observation_state in (
                        ObservationState.NOT_AVAILABLE,
                        ObservationState.NOT_APPLICABLE,
                    ):
                        unavailable_count += 1
                    else:
                        has_real_link = bool(
                            doc.document_identifier
                            or (doc.source_url and not doc.source_url.endswith("DOC_ID="))
                        )
                        if has_real_link or doc.displayed_filename:
                            if has_real_link:
                                doc_links_count += 1
                            ukey = (
                                (doc.document_category or "").strip().lower(),
                                (doc.document_identifier or doc.source_url or "").strip(),
                                (doc.displayed_filename or "").strip().lower(),
                            )
                            unique_keys.add(ukey)
                        else:
                            unavailable_count += 1

                    if "ANOMALY_PLACEHOLDER_FILENAME_NOT_APPLICABLE_OR_AVAILABLE" in doc.anomaly_flags:
                        placeholder_count += 1

                if sec.subsections:
                    walk_sections(sec.subsections)

        for tab_obs in project.tabs.values():
            walk_sections(tab_obs.sections)

        coverage.unique_document_observations_count = len(unique_keys)
        coverage.document_links_count = doc_links_count
        coverage.placeholder_document_entries_count = placeholder_count
        coverage.unavailable_document_slots_count = unavailable_count

    def _process_single_tab_payload(
        self,
        project: Project,
        tab_data: Dict[str, Any],
        coverage: ProjectExtractionCoverage,
        is_unlinked_pane: bool = False,
    ) -> ProjectTabObservation:
        tab_label = tab_data.get("label", "Unknown Tab").strip()
        tab_id = tab_data.get("id")
        is_nav_visible = tab_data.get("is_nav_visible", not is_unlinked_pane)
        dom_presence = tab_data.get(
            "dom_presence",
            "hidden_or_unlinked_dom_pane" if is_unlinked_pane else "visible_nav_tab",
        )

        # Explicit failure simulation / parsing error
        if tab_data.get("simulate_failure"):
            error_msg = tab_data.get("error_message", f"Extraction failed on tab: {tab_label}")
            tab_obs = ProjectTabObservation(
                tab_label=tab_label,
                tab_identifier=tab_id,
                is_nav_visible=is_nav_visible,
                dom_presence=dom_presence,
                observation_state=ObservationState.EXTRACTION_FAILED,
                error_message=error_msg,
            )
            if not is_unlinked_pane:
                coverage.tabs_extraction_failed.append(tab_label)
            coverage.errors.append(error_msg)
            return tab_obs

        sections_data = tab_data.get("sections", [])
        sub_tabs_data = tab_data.get("sub_tabs", [])
        raw_content = tab_data.get("raw_content")

        tab_obs = ProjectTabObservation(
            tab_label=tab_label,
            tab_identifier=tab_id,
            is_nav_visible=is_nav_visible,
            dom_presence=dom_presence,
            observation_state=ObservationState.PRESENT_WITH_DATA,
        )

        # Process nested sub-tabs (e.g. Complaints -> Promoter vs Project)
        for sub_data in sub_tabs_data:
            sub_obs = self._process_single_tab_payload(
                project=project,
                tab_data=sub_data,
                coverage=coverage,
                is_unlinked_pane=True,
            )
            sub_obs.dom_presence = "nested_sub_tab"
            tab_obs.sub_tabs[sub_obs.tab_label] = sub_obs

        # Process sections
        for sec_data in sections_data:
            try:
                section_obs = self._extract_section(
                    project=project,
                    section_data=sec_data,
                    source_tab=tab_label,
                )
                tab_obs.sections.append(section_obs)
                if not is_unlinked_pane:
                    self._accumulate_section_coverage(tab_label, section_obs, coverage)
            except Exception as exc:
                err_msg = f"Section extraction failed in {tab_label} > {sec_data.get('label', 'Unknown')}: {exc}"
                tab_obs.sections.append(
                    SectionObservation(
                        section_label=sec_data.get("label", "Unknown Section"),
                        observation_state=ObservationState.EXTRACTION_FAILED,
                        anomaly_flags=[err_msg],
                    )
                )
                coverage.errors.append(err_msg)

        # Determine whether the tab as a whole has data or is empty
        has_any_section_data = any(
            self._section_tree_has_data(s) for s in tab_obs.sections
        )
        has_any_subtab_data = any(
            st.observation_state == ObservationState.PRESENT_WITH_DATA
            for st in tab_obs.sub_tabs.values()
        )

        explicit_empty = tab_data.get("is_empty", False)
        if explicit_empty or (not has_any_section_data and not has_any_subtab_data and not raw_content):
            tab_obs.observation_state = ObservationState.PRESENT_EMPTY
            if not is_unlinked_pane:
                coverage.tabs_present_empty.append(tab_label)
        else:
            tab_obs.observation_state = ObservationState.PRESENT_WITH_DATA
            if not is_unlinked_pane:
                coverage.tabs_processed.append(tab_label)

        return tab_obs

    def _section_tree_has_data(self, s: SectionObservation) -> bool:
        if s.observation_state != ObservationState.PRESENT_WITH_DATA:
            return False
        own_data = (
            any(
                f.observation_state
                in (ObservationState.PRESENT_WITH_DATA, ObservationState.NOT_APPLICABLE)
                for f in s.fields
            )
            or len(s.table_rows) > 0
            or any(
                d.observation_state == ObservationState.PRESENT_WITH_DATA
                for d in s.documents
            )
        )
        if own_data:
            return True
        return any(self._section_tree_has_data(sub) for sub in s.subsections)

    def _accumulate_section_coverage(
        self,
        tab_label: str,
        section_obs: SectionObservation,
        coverage: ProjectExtractionCoverage,
    ) -> None:
        coverage.total_sections_discovered += 1
        coverage.total_fields_discovered += len(section_obs.fields)
        coverage.total_table_rows_discovered += len(section_obs.table_rows)
        coverage.total_documents_discovered += len(section_obs.documents)
        sec_ref = f"{tab_label} > {section_obs.section_label}"
        if section_obs.observation_state == ObservationState.PRESENT_WITH_DATA:
            coverage.sections_present_with_data.append(sec_ref)
        elif section_obs.observation_state == ObservationState.PRESENT_EMPTY:
            coverage.sections_present_empty.append(sec_ref)
        for sub in section_obs.subsections:
            self._accumulate_section_coverage(tab_label, sub, coverage)

    def _extract_section(
        self,
        project: Project,
        section_data: Dict[str, Any],
        source_tab: str,
        parent_section_label: Optional[str] = None,
        inherited_promoter_type: Optional[str] = None,
    ) -> SectionObservation:
        """Dynamically extracts fields, tables, documents, and nested subsections while enforcing PII policy."""
        label = section_data.get("label", "Generic Section").strip()
        sec_type = section_data.get("type", "generic")
        empty_msg = section_data.get("empty_message")
        effective_section_context = f"{parent_section_label} > {label}" if parent_section_label else label

        # 1. Record pre-scrubbed PII exclusions passed from DOM parser
        for pii_item in section_data.get("excluded_pii", []):
            project.pii_exclusions.append(
                PIIExclusionRecord(
                    project_id=project.internal_id,
                    tab_label=source_tab,
                    section_label=label,
                    field_or_column_label=pii_item.get("field_or_column_label", "Excluded PII"),
                    pii_category=pii_item.get("pii_category", "personal_or_entity_pan"),
                    redaction_action=pii_item.get("redaction_action", "excluded_field"),
                    reason=pii_item.get("reason", f"Excluded PII in section '{label}'."),
                )
            )

        for img_excl in section_data.get("excluded_images", []):
            project.pii_exclusions.append(
                PIIExclusionRecord(
                    project_id=project.internal_id,
                    tab_label=source_tab,
                    section_label=label,
                    field_or_column_label=img_excl.get("label", "Photograph (img)"),
                    pii_category="personal_photograph",
                    redaction_action="excluded_image",
                    reason=img_excl.get(
                        "reason",
                        f"Excluded personal photograph <img> tag in section '{label}'.",
                    ),
                )
            )

        if section_data.get("is_empty", False):
            return SectionObservation(
                section_label=label,
                section_type=sec_type,
                observation_state=ObservationState.PRESENT_EMPTY,
                parent_section_label=parent_section_label,
                empty_message=empty_msg,
                table_headers=section_data.get("table_headers", []),
            )

        section_obs = SectionObservation(
            section_label=label,
            section_type=sec_type,
            observation_state=ObservationState.PRESENT_WITH_DATA,
            parent_section_label=parent_section_label,
            empty_message=empty_msg,
            table_headers=section_data.get("table_headers", []),
        )

        # Detect Promoter Type if present in this section's fields
        promoter_type = inherited_promoter_type
        raw_fields = section_data.get("fields", {})
        if isinstance(raw_fields, dict):
            for k, v in raw_fields.items():
                if "promoter type" in k.lower() and v:
                    promoter_type = str(v).strip()
                    break
        elif isinstance(raw_fields, list):
            for item in raw_fields:
                if "promoter type" in (item.get("label") or "").lower() and item.get("value"):
                    promoter_type = str(item.get("value")).strip()
                    break

        # 2. Extract Key-Value Fields
        if isinstance(raw_fields, dict):
            for f_label, f_val in raw_fields.items():
                if self.enforce_pii_policy:
                    pii_hit = classify_pii_exclusion(
                        f_label,
                        str(f_val) if f_val is not None else "",
                        effective_section_context,
                        source_tab,
                        promoter_type=promoter_type,
                    )
                    if pii_hit:
                        project.pii_exclusions.append(
                            PIIExclusionRecord(
                                project_id=project.internal_id,
                                tab_label=source_tab,
                                section_label=label,
                                field_or_column_label=f_label,
                                pii_category=pii_hit[0],
                                redaction_action="excluded_field",
                                reason=pii_hit[1],
                            )
                        )
                        continue
                field_obs = self._normalize_field(
                    f_label=f_label,
                    f_val=f_val,
                    source_ref=f"{source_tab} > {label}",
                    project_id=project.internal_id,
                    tab_label=source_tab,
                    section_label=label,
                )
                section_obs.fields.append(field_obs)
        elif isinstance(raw_fields, list):
            for item in raw_fields:
                f_label = item.get("label", "Unknown Field")
                f_val = item.get("value")
                f_link = item.get("source_link")
                f_annex = item.get("annexure_reference")
                explicit_state = item.get("observation_state")
                if self.enforce_pii_policy:
                    pii_hit = classify_pii_exclusion(
                        f_label,
                        str(f_val) if f_val is not None else "",
                        effective_section_context,
                        source_tab,
                        is_document=bool(f_link),
                        filename=str(f_val) if f_link else None,
                        promoter_type=promoter_type,
                    )
                    if pii_hit:
                        project.pii_exclusions.append(
                            PIIExclusionRecord(
                                project_id=project.internal_id,
                                tab_label=source_tab,
                                section_label=label,
                                field_or_column_label=f_label,
                                pii_category=pii_hit[0],
                                redaction_action="excluded_field",
                                reason=pii_hit[1],
                            )
                        )
                        continue
                field_obs = self._normalize_field(
                    f_label=f_label,
                    f_val=f_val,
                    source_ref=f"{source_tab} > {label}",
                    project_id=project.internal_id,
                    tab_label=source_tab,
                    section_label=label,
                    source_link=f_link,
                    annexure_reference=f_annex,
                    explicit_state=explicit_state,
                )
                section_obs.fields.append(field_obs)

        # 3. Extract Tabular Rows (filtering PII columns and PII document rows)
        table_rows = section_data.get("table_rows", [])
        if table_rows:
            cleaned_rows: List[Dict[str, Any]] = []
            for row_dict in table_rows:
                # Check if this row is a document-table row whose Document Name / Category is PII
                if self.enforce_pii_policy:
                    doc_row_cat = (
                        row_dict.get("Document Name")
                        or row_dict.get("Declaration")
                        or row_dict.get("Category")
                    )
                    doc_row_fn = row_dict.get("Document")
                    if doc_row_cat:
                        row_pii_hit = classify_pii_exclusion(
                            str(doc_row_cat),
                            str(doc_row_fn or ""),
                            effective_section_context,
                            source_tab,
                            is_document=True,
                            filename=str(doc_row_fn or ""),
                            promoter_type=promoter_type,
                        )
                        if row_pii_hit:
                            project.pii_exclusions.append(
                                PIIExclusionRecord(
                                    project_id=project.internal_id,
                                    tab_label=source_tab,
                                    section_label=label,
                                    field_or_column_label=str(doc_row_cat),
                                    pii_category=row_pii_hit[0],
                                    redaction_action="excluded_table_cell",
                                    reason=row_pii_hit[1],
                                )
                            )
                            continue

                clean_row: Dict[str, Any] = {}
                for col_k, col_v in row_dict.items():
                    if self.enforce_pii_policy:
                        pii_hit = classify_pii_exclusion(
                            col_k,
                            str(col_v) if col_v is not None else "",
                            effective_section_context,
                            source_tab,
                            promoter_type=promoter_type,
                        )
                        if pii_hit:
                            project.pii_exclusions.append(
                                PIIExclusionRecord(
                                    project_id=project.internal_id,
                                    tab_label=source_tab,
                                    section_label=label,
                                    field_or_column_label=col_k,
                                    pii_category=pii_hit[0],
                                    redaction_action="excluded_table_cell",
                                    reason=pii_hit[1],
                                )
                            )
                            continue
                    clean_row[col_k] = col_v
                if clean_row:
                    cleaned_rows.append(clean_row)
            section_obs.table_rows = cleaned_rows

        # 4. Extract Documents (filtering PII documents by category or filename)
        documents_data = section_data.get("documents", [])
        for doc_item in documents_data:
            doc_cat = doc_item.get("category", "Uncategorized Document").strip()
            doc_fn = doc_item.get("filename")
            if self.enforce_pii_policy:
                pii_hit = classify_pii_exclusion(
                    doc_cat,
                    doc_fn,
                    effective_section_context,
                    source_tab,
                    is_document=True,
                    filename=doc_fn,
                    promoter_type=promoter_type,
                )
                if pii_hit:
                    project.pii_exclusions.append(
                        PIIExclusionRecord(
                            project_id=project.internal_id,
                            tab_label=source_tab,
                            section_label=label,
                            field_or_column_label=doc_cat,
                            pii_category=pii_hit[0],
                            redaction_action="excluded_document_link",
                            reason=pii_hit[1],
                        )
                    )
                    continue
            doc_obs = self._extract_document(
                doc_item,
                source_ref=f"{source_tab} > {label}",
                project_id=project.internal_id,
                tab_label=source_tab,
                section_label=label,
            )
            section_obs.documents.append(doc_obs)

        # 5. Recursively process nested subsections (if any)
        for sub_sec_data in section_data.get("subsections", []):
            sub_sec_obs = self._extract_section(
                project=project,
                section_data=sub_sec_data,
                source_tab=source_tab,
                parent_section_label=effective_section_context,
                inherited_promoter_type=promoter_type,
            )
            section_obs.subsections.append(sub_sec_obs)

        # If a section had only empty fields/tables, no documents, and no populated subsections, mark PRESENT_EMPTY
        if not self._section_tree_has_data(section_obs):
            section_obs.observation_state = ObservationState.PRESENT_EMPTY

        return section_obs

    def _normalize_field(
        self,
        f_label: str,
        f_val: Any,
        source_ref: str,
        project_id: Optional[str] = None,
        tab_label: Optional[str] = None,
        section_label: Optional[str] = None,
        source_link: Optional[str] = None,
        annexure_reference: Optional[str] = None,
        explicit_state: Optional[ObservationState] = None,
    ) -> FieldObservation:
        """Normalizes a field value while strictly preserving raw strings and flagging parse failures/anomalies."""
        raw_str = str(f_val).strip() if f_val is not None else None
        anomalies: List[str] = []
        normalized: Any = f_val
        dtype = "string"
        lbl_low = (f_label or "").lower()

        if raw_str is None or raw_str == "":
            state = explicit_state or ObservationState.PRESENT_EMPTY
            return FieldObservation(
                field_label=f_label,
                raw_value="",
                normalized_value=None,
                data_type="null",
                observation_state=state,
                project_id=project_id,
                tab_label=tab_label,
                section_label=section_label,
                source_reference=source_ref,
                source_link=source_link,
                annexure_reference=annexure_reference,
            )

        state = explicit_state or ObservationState.PRESENT_WITH_DATA
        if raw_str.upper() in ("NOT APPLICABLE", "N/A", "NA"):
            state = ObservationState.NOT_APPLICABLE
        elif raw_str.upper() in ("NOT AVAILABLE",):
            state = ObservationState.NOT_AVAILABLE

        # 1. Check for suspicious placeholder dates (e.g., 01-01-0001 or 00-00-0000)
        if any(pat in raw_str for pat in ("01-01-0001", "00-00-0000", "01/01/0001", "0000-00-00")):
            anomalies.append("ANOMALY_MALFORMED_PLACEHOLDER_DATE")
            normalized = None
            dtype = "malformed_date"
        # 2. Check date-like patterns (DD-MM-YYYY, DD/MM/YYYY, YYYY-MM-DD)
        elif re.match(r"^\d{1,4}[-/]\d{1,2}[-/]\d{1,4}$", raw_str):
            iso_date, date_err = parse_canonical_date(raw_str)
            if iso_date:
                normalized = iso_date
                dtype = "date_string"
            else:
                anomalies.append(date_err or "ANOMALY_DATE_PARSE_FAILED")
                normalized = raw_str if date_err == "ANOMALY_MALFORMED_PLACEHOLDER_DATE" else None
                dtype = "malformed_date"
        # 3. Check if label explicitly expects a date but value is unparseable
        elif (
            re.search(r"\bdate\b|\bapplied\s+on\b|\bapproved\s+on\b", lbl_low)
            and not any(k in lbl_low for k in ("whether", "update", "status", "mandate", "till date"))
            and state == ObservationState.PRESENT_WITH_DATA
        ):
            iso_date, date_err = parse_canonical_date(raw_str)
            if iso_date:
                normalized = iso_date
                dtype = "date_string"
            else:
                anomalies.append(date_err or "ANOMALY_DATE_PARSE_FAILED")
                normalized = None
                dtype = "malformed_date"
        # 4. Check integer / float / comma-formatted numbers
        elif re.match(r"^-?\d+(\.\d+)?$", raw_str) or re.match(r"^-?\d{1,3}(,\d{2,3})+(\.\d+)?$", raw_str):
            clean_num = raw_str.replace(",", "")
            if "." in clean_num:
                try:
                    normalized = float(clean_num)
                    dtype = "float"
                except ValueError:
                    normalized = None
                    dtype = "malformed_number"
                    anomalies.append("ANOMALY_NUMERIC_PARSE_FAILED")
            else:
                try:
                    normalized = int(clean_num)
                    dtype = "integer"
                except ValueError:
                    normalized = None
                    dtype = "malformed_number"
                    anomalies.append("ANOMALY_NUMERIC_PARSE_FAILED")
        # 5. Check if label explicitly expects an INR currency amount but value failed numeric parse
        elif (
            ("(inr)" in lbl_low or lbl_low.startswith("cost of ") or lbl_low.startswith("total project cost"))
            and state == ObservationState.PRESENT_WITH_DATA
        ):
            anomalies.append("ANOMALY_NUMERIC_PARSE_FAILED")
            normalized = None
            dtype = "malformed_number"

        return FieldObservation(
            field_label=f_label,
            raw_value=raw_str,
            normalized_value=normalized,
            data_type=dtype,
            observation_state=state,
            project_id=project_id,
            tab_label=tab_label,
            section_label=section_label,
            source_reference=source_ref,
            source_link=source_link,
            annexure_reference=annexure_reference,
            anomaly_flags=anomalies,
        )

    def _extract_document(
        self,
        doc_data: Dict[str, Any],
        source_ref: str,
        project_id: Optional[str] = None,
        tab_label: Optional[str] = None,
        section_label: Optional[str] = None,
    ) -> DocumentObservation:
        """Extracts a document using category-first classification and flags anomalies."""
        category = doc_data.get("category", "Uncategorized Document").strip()
        filename = doc_data.get("filename")
        date_raw = doc_data.get("approval_date")
        source_url = doc_data.get("url")
        doc_id = doc_data.get("doc_id")
        annex_ref = doc_data.get("annexure_reference")
        explicit_state = doc_data.get("observation_state")
        anomalies: List[str] = []

        # Determine observation_state for empty/missing document links
        is_empty_link = (
            (not filename or str(filename).strip() == "")
            and (not doc_id or str(doc_id).strip() == "")
            and (not source_url or source_url.endswith("DOC_ID="))
        )
        if explicit_state:
            obs_state = explicit_state
        elif is_empty_link:
            obs_state = ObservationState.NOT_AVAILABLE
        else:
            obs_state = ObservationState.PRESENT_WITH_DATA

        # Normalize approval_date safely while preserving approval_date_raw
        date_norm: Optional[str] = None
        if date_raw and str(date_raw).strip():
            raw_d_str = str(date_raw).strip()
            iso_date, date_err = parse_canonical_date(raw_d_str)
            if iso_date:
                date_norm = iso_date
            else:
                anomalies.append("ANOMALY_SUSPICIOUS_APPROVAL_DATE")
                if date_err and date_err not in anomalies:
                    anomalies.append(date_err)
                date_norm = None

        # Check if filename is a placeholder like 'Not applicable.pdf' or 'NOT AVAILABLE.pdf'
        if filename:
            fn_low = str(filename).lower()
            if any(
                kw in fn_low
                for kw in ("not applicable", "not_applicable", "not available", "no financials")
            ):
                anomalies.append("ANOMALY_PLACEHOLDER_FILENAME_NOT_APPLICABLE_OR_AVAILABLE")

            # Check for obvious category vs filename mismatch (e.g., Lift certificate -> Bescom NOC.pdf)
            cat_low = category.lower()
            if "lift" in cat_low and "bescom" in fn_low:
                anomalies.append("FLAGGED_MISMATCH_SUSPECT_FILENAME")

        if filename and doc_data.get("flag_filename_mismatch"):
            if "FLAGGED_MISMATCH_SUSPECT_FILENAME" not in anomalies:
                anomalies.append("FLAGGED_MISMATCH_SUSPECT_FILENAME")

        return DocumentObservation(
            document_category=category,
            displayed_filename=filename,
            approval_date_raw=date_raw,
            approval_date_normalized=date_norm,
            source_url=source_url,
            document_identifier=doc_id,
            annexure_reference=annex_ref,
            project_id=project_id,
            tab_label=tab_label,
            section_label=section_label,
            observation_state=obs_state,
            file_metadata=doc_data.get("metadata", {}),
            anomaly_flags=anomalies,
        )

    def detect_cross_section_conflicts(self, project: Project) -> List[CrossSectionConflict]:
        """Scans extracted fields and registration tables across catalogue and tabs to flag conflicting values without overwriting."""
        concept_patterns = {
            "project_start_date": re.compile(r"^project\s+start\s+date$|^start\s+date$", re.I),
            "project_end_or_completion_date": re.compile(
                r"^proposed\s+completion\s+date$|^proposed\s+project\s+completion\s+date$|^project\s+end\s+date$|^original\s+proposed\s+completion$",
                re.I,
            ),
            "cost_of_land_inr": re.compile(r"^cost\s+of\s+land(\s*\(inr\))?$|^total\s+land\s+cost$", re.I),
            "cost_of_construction_inr": re.compile(
                r"^estimated\s+cost\s+of\s+construction(\s*\(inr\))?$|^cost\s+of\s+construction$|^total\s+construction\s+cost$",
                re.I,
            ),
            "total_project_cost_inr": re.compile(r"^total\s+project\s+cost(\s*\(inr\))?$", re.I),
        }

        buckets: Dict[str, List[Dict[str, Any]]] = {k: [] for k in concept_patterns}

        # Include catalogue proposed_completion_date if available
        if project.proposed_completion_date:
            cat_iso, _ = parse_canonical_date(project.proposed_completion_date)
            buckets["project_end_or_completion_date"].append(
                {
                    "tab_label": "Search Results Catalogue",
                    "section_label": "Catalogue Row",
                    "field_label": "PROPOSED COMPLETION DATE",
                    "raw_value": project.proposed_completion_date,
                    "normalized_value": cat_iso or project.proposed_completion_date,
                }
            )

        all_tab_collections = list(project.tabs.values()) + list(project.unlinked_dom_panes.values())
        for tab_obs in all_tab_collections:
            for sec_obs in tab_obs.sections:
                for f_obs in sec_obs.fields:
                    if f_obs.observation_state != ObservationState.PRESENT_WITH_DATA:
                        continue
                    for concept_key, pat in concept_patterns.items():
                        if pat.match(f_obs.field_label.strip()):
                            buckets[concept_key].append(
                                {
                                    "tab_label": tab_obs.tab_label,
                                    "section_label": sec_obs.section_label,
                                    "field_label": f_obs.field_label,
                                    "raw_value": f_obs.raw_value,
                                    "normalized_value": f_obs.normalized_value,
                                }
                            )
                # Also inspect Registration/Extensions table rows for Start Date and Proposed Completion Date
                for r_idx, row_dict in enumerate(sec_obs.table_rows):
                    reg_type = row_dict.get("Registration/Extensions") or f"Row {r_idx + 1}"
                    for col_k, col_v in row_dict.items():
                        val_str = str(col_v or "").strip()
                        if not val_str:
                            continue
                        for concept_key, pat in concept_patterns.items():
                            if pat.match(col_k.strip()):
                                row_iso, _ = parse_canonical_date(val_str)
                                buckets[concept_key].append(
                                    {
                                        "tab_label": tab_obs.tab_label,
                                        "section_label": f"{sec_obs.section_label} [{reg_type}]",
                                        "field_label": col_k,
                                        "raw_value": val_str,
                                        "normalized_value": row_iso or val_str,
                                    }
                                )

        conflicts: List[CrossSectionConflict] = []
        for concept_key, obs_list in buckets.items():
            if len(obs_list) < 2:
                continue
            distinct_raws = list(dict.fromkeys(str(o["raw_value"]) for o in obs_list if o["raw_value"]))
            if len(distinct_raws) > 1:
                conflicts.append(
                    CrossSectionConflict(
                        canonical_concept=concept_key,
                        distinct_raw_values=distinct_raws,
                        observations=obs_list,
                    )
                )

        project.cross_section_conflicts = conflicts
        return conflicts
