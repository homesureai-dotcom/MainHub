"""
HomeSure Phase 4 — Canonical Bengaluru Geographical Classification & Exception Auditing

Preserves exact authoritative K-RERA `district` and `taluk` values while establishing
a canonical 5-taluk taxonomy for Bengaluru Urban:
  1. Anekal
  2. Bengaluru East
  3. Bengaluru North
  4. Bengaluru South
  5. Yelahanka

Never collapses Anekal or Yelahanka into directional zones, and never reclassifies
Bengaluru Rural projects as Bengaluru Urban solely because of marketing addresses.
"""

from __future__ import annotations

import re
from collections import Counter
from typing import Any, Dict, List, Optional


BENGALURU_URBAN_CANONICAL_TALUKS = (
    "Anekal",
    "Bengaluru East",
    "Bengaluru North",
    "Bengaluru South",
    "Yelahanka",
)

BENGALURU_RURAL_TALUKS = {
    "Devanahalli",
    "Hosakote",
    "Doddaballapura",
    "Nelamangala",
    "Ramanagara",
    "Kanakapura",
    "Magadi",
    "Channapatna",
}


def normalize_district(raw_district: Optional[str]) -> str:
    """Normalize whitespace and Bangalore/Bengaluru spelling while retaining Rural vs Urban."""
    s = " ".join((raw_district or "").split()).strip()
    if not s:
        return ""
    low = s.lower()
    if "urban" in low and ("bengaluru" in low or "bangalore" in low):
        return "Bengaluru Urban"
    if "rural" in low and ("bengaluru" in low or "bangalore" in low):
        return "Bengaluru Rural"
    return s


def normalize_taluk(raw_taluk: Optional[str], district: Optional[str] = None) -> Optional[str]:
    """
    Map raw portal taluk value into the canonical 5 Bengaluru Urban taluks
    (or canonical Rural taluk name), returning None if missing/unrecognized.
    """
    s = " ".join((raw_taluk or "").split()).strip()
    if not s:
        return None
    low = s.lower()

    if "anekal" in low:
        return "Anekal"
    if "yelahanka" in low:
        return "Yelahanka"
    if re.search(r"\beast\b", low) or "bengaluru east" in low or "bangalore east" in low:
        return "Bengaluru East"
    if re.search(r"\bnorth\b", low) or "bengaluru north" in low or "bangalore north" in low:
        return "Bengaluru North"
    if re.search(r"\bsouth\b", low) or "bengaluru south" in low or "bangalore south" in low:
        return "Bengaluru South"

    # Check known Bengaluru Rural taluks cleanly
    for rt in BENGALURU_RURAL_TALUKS:
        if rt.lower() == low or rt.lower() in low:
            return rt

    return s


def build_geography_block(
    raw_district: Optional[str],
    raw_taluk: Optional[str],
    project_address: Optional[str] = None,
    locality_hint: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Build authoritative canonical geography fields preserving exact source values.
    """
    orig_district = (raw_district or "").strip()
    orig_taluk = (raw_taluk or "").strip()
    norm_district = normalize_district(orig_district)
    norm_taluk = normalize_taluk(orig_taluk, norm_district)
    clean_address = " ".join((project_address or "").split()).strip() or None
    locality = (locality_hint or "").strip() or (norm_taluk or orig_taluk)

    return {
        "district": orig_district or "Bengaluru Urban",
        "normalizedDistrict": norm_district or "Bengaluru Urban",
        "taluk": orig_taluk,
        "normalizedTaluk": norm_taluk or "",
        "locality": locality,
        "projectAddress": clean_address,
        "geographySource": "KRERA_PORTAL_AUTHORITATIVE",
    }


def audit_geography_exceptions(records: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Audit a list of project/catalogue dicts for geographical anomalies without dropping any record.
    Checks: missing_district, missing_taluk, conflicting_district_taluk, unknown_taluk, address_ambiguity.
    """
    missing_district: List[Dict[str, Any]] = []
    missing_taluk: List[Dict[str, Any]] = []
    conflicting_district_taluk: List[Dict[str, Any]] = []
    unknown_taluk: List[Dict[str, Any]] = []
    address_ambiguity: List[Dict[str, Any]] = []
    district_counts: Counter = Counter()
    taluk_counts: Counter = Counter()

    urban_taluk_set = set(BENGALURU_URBAN_CANONICAL_TALUKS)
    rural_taluk_set = set(BENGALURU_RURAL_TALUKS)

    for rec in records:
        reg = rec.get("registration_number") or rec.get("reg_no") or ""
        pname = rec.get("project_name") or ""
        raw_d = (rec.get("district") or "").strip()
        raw_t = (rec.get("taluk") or "").strip()
        addr = (rec.get("project_address") or rec.get("projectAddress") or "").strip()
        norm_d = normalize_district(raw_d)
        norm_t = normalize_taluk(raw_t, norm_d)

        district_counts[norm_d or "MISSING"] += 1
        taluk_counts[norm_t or "MISSING"] += 1

        meta = {
            "registration_number": reg,
            "project_name": pname,
            "raw_district": raw_d,
            "raw_taluk": raw_t,
            "normalized_district": norm_d,
            "normalized_taluk": norm_t,
        }

        if not raw_d:
            missing_district.append(meta)
        if not raw_t:
            missing_taluk.append(meta)
        elif norm_d == "Bengaluru Urban" and norm_t not in urban_taluk_set:
            if norm_t in rural_taluk_set:
                conflicting_district_taluk.append(meta)
            else:
                unknown_taluk.append(meta)
        elif norm_d == "Bengaluru Rural" and norm_t not in rural_taluk_set:
            if norm_t in urban_taluk_set:
                conflicting_district_taluk.append(meta)
            else:
                unknown_taluk.append(meta)

        if norm_d == "Bengaluru Rural" and addr and re.search(r"\bbengaluru\b|\bbangalore\b", addr, re.I):
            address_ambiguity.append({**meta, "project_address": addr})
        elif norm_t == "Anekal" and addr and re.search(r"\bsarjapur\b", addr, re.I):
            # Boundary informational tracking (Sarjapur spans Bengaluru East and Anekal)
            address_ambiguity.append({**meta, "project_address": addr, "note": "Sarjapur boundary in Anekal taluk"})

    return {
        "total_audited": len(records),
        "district_counts": dict(district_counts),
        "taluk_counts": dict(taluk_counts),
        "missing_district_count": len(missing_district),
        "missing_taluk_count": len(missing_taluk),
        "conflicting_district_taluk_count": len(conflicting_district_taluk),
        "unknown_taluk_count": len(unknown_taluk),
        "address_ambiguity_count": len(address_ambiguity),
        "exceptions": {
            "missing_district": missing_district[:100],
            "missing_taluk": missing_taluk[:100],
            "conflicting_district_taluk": conflicting_district_taluk[:100],
            "unknown_taluk": unknown_taluk[:100],
            "address_ambiguity": address_ambiguity[:100],
        },
    }
