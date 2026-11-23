"""
HomeSure Phase 4 — Canonical Name Normalization, Alias Generation & Builder Disambiguation

Provides deterministic, non-destructive name normalization across Python ingestion
and search indexing without ever automatically merging distinct RERA registrations.

Key invariants:
- Preserve exact K-RERA strings in `official_builder_name` and `official_project_name`.
- Handle case, extra whitespace, HTML entities (`&amp;`), `&` <-> `AND`, hyphens,
  punctuation, corporate suffixes (`PRIVATE LIMITED`, `PVT LTD`, `LLP`, etc.),
  and singular/plural variations (`DEGREE` <-> `DEGREES`).
- Prevent false-positive brand merges (`SOBHA RANI` != `Sobha Limited`, `... PRIDE` != `Pride Group`,
  `Disha Pursuit of Radiance` != `Radiance Realty`).
- Recognize verified brand SPVs (`APG ...` -> `Assetz Property Group`).
- Flag ambiguous fuzzy matches (`needs_manual_review = True`) rather than silently merging.
"""

from __future__ import annotations

import html
import re
from typing import Any, Dict, List, Optional, Tuple


CORPORATE_LEGAL_SUFFIX_PATTERNS = [
    r"\bPRIVATE\s+LIMITED\b",
    r"\bPVT\.?\s+LTD\.?\b",
    r"\bLIMITED\b",
    r"\bLIMETED\b",  # observed portal typo in Radiance Realty Developers India Limeted
    r"\bLTD\.?\b",
    r"\bLLP\b",
    r"\bLIMITED\s+LIABILITY\s+PARTNERSHIP\b",
    r"\bPARTNERSHIO\b",  # observed portal typo
    r"\bINCORPORATED\b",
    r"\bINC\.?\b",
    r"\bCORPORATION\b",
    r"\bCORP\.?\b",
    r"\bCO\.?\b",
]

LEGAL_SUFFIX_PATTERNS = CORPORATE_LEGAL_SUFFIX_PATTERNS + [
    r"\bENTERPRISES\b",
    r"\bDEVELOPERS\b",
    r"\bCONSTRUCTIONS\b",
    r"\bPROPERTIES\b",
    r"\bINFRASTRUCTURES\b",
    r"\bINFRASTRUCTURE\b",
    r"\bINFRA\b",
    r"\bHOLDINGS\b",
    r"\bPROJECTS\b",
    r"\bVENTURES\b",
    r"\bBUILDERS\b",
    r"\bESTATES\b",
    r"\bREALTY\b",
    r"\bHOMES\b",
    r"\bGROUP\b",
    r"\bINDIA\b",
]

LEADING_PREFIX_RE = re.compile(r"^(?:M\s*/?\s*S\.?|MESSRS\.?)\s+", re.IGNORECASE)

# Verified Assetz Property Group SPV corporate prefix (`APG ...`)
ASSETZ_SPV_PROMOTER_RE = re.compile(
    r"^\s*(?:M\s*/\s*S\.?\s+)?APG\s+[A-Z0-9\s&\.\-]+\b("
    r"PRIVATE\s+LIMITED|PVT\.?\s*LTD\.?|LIMITED|LTD\.?|LLP|"
    r"HOMES|RESIDENTIAL|HABITAT|ABODE|ENVIRONMENT|IMPERIAL|"
    r"LIFESTYLE|TOWNSHIPS|GREEN|COMMUNITY|SKYWARDS|PROJECTS|INTELLI"
    r")\b",
    re.IGNORECASE,
)

# Corporate Sobha entity check (explicitly excludes personal first-name promoters like "SOBHA RANI")
SOBHA_CORP_PROMOTER_RE = re.compile(
    r"^\s*(?:M\s*/\s*S\.?\s+)?SOBHA\s+(LIMITED|LTD\.?|DEVELOPERS|PROJECTS|ESTATES|CONSTRUCTIONS|CITY|VENTURES)\b",
    re.IGNORECASE,
)


def decode_portal_text(raw: Optional[str]) -> str:
    """Decode HTML entities (&amp;, &nbsp;, etc.) and collapse whitespace without altering case."""
    if not raw:
        return ""
    s = html.unescape(str(raw))
    # Fix double-escaped or stray 'and amp' transcription artifacts observed in K-RERA searches
    s = re.sub(r"\s*&\s*amp\s*;?\s*", " & ", s, flags=re.IGNORECASE)
    s = s.replace("\u00a0", " ")
    return " ".join(s.split()).strip()


def normalize_text(raw: Optional[str]) -> str:
    """Produce canonical uppercase alphanumeric/space representation (`&` -> `AND`)."""
    s = decode_portal_text(raw)
    if not s:
        return ""
    s = re.sub(r"['’`]+", "", s)
    s = s.replace("&", " AND ")
    # Normalize dash variants and punctuation to spaces
    s = re.sub(r"[–—\-_/.,:;()\[\]{}\"@!#*+]+", " ", s)
    s = re.sub(r"\bAND\s+AMP\b", "AND", s, flags=re.IGNORECASE)
    s = re.sub(r"\s+", " ", s).strip().upper()
    return s


def _strip_suffixes(raw_promoter: Optional[str], patterns: List[str]) -> str:
    s = normalize_text(raw_promoter)
    if not s:
        return ""
    s = LEADING_PREFIX_RE.sub("", s).strip()
    changed = True
    while changed and s:
        changed = False
        for pat in patterns:
            new_s = re.sub(rf"(?:\s+|^){pat}\s*$", "", s, flags=re.IGNORECASE).strip()
            if new_s and new_s != s:
                s = new_s
                changed = True
    return re.sub(r"\s+", " ", s).strip()


def normalize_builder_name(raw_promoter: Optional[str]) -> str:
    """Normalize a builder/promoter legal name for matching while keeping official name separate."""
    return _strip_suffixes(raw_promoter, LEGAL_SUFFIX_PATTERNS)


def normalize_corporate_entity_name(raw_promoter: Optional[str]) -> str:
    """
    Strip only legal structure suffixes (`PVT LTD`, `LLP`, `LIMITED`, etc.) while
    preserving distinguishing nouns (`BUILDERS` vs `VENTURES` vs `INFRASTRUCTURES`).
    """
    s = _strip_suffixes(raw_promoter, CORPORATE_LEGAL_SUFFIX_PATTERNS)
    s = re.sub(r"\s+\bAND$", "", s).strip()
    return s


# Brand rules:
# Each entry specifies:
#   id, canonical_name, promoter_patterns, project_patterns,
#   strict_project_prefix_only (if True, project match only counts at start or after '@'),
#   spv_promoter_patterns (verified SPV legal entities whose brand isn't in the entity name)
BRAND_DEFINITIONS: List[Dict[str, Any]] = [
    {
        "builder_id": "builder_sobha_limited",
        "canonical_name": "Sobha Limited",
        "promoter_patterns": [SOBHA_CORP_PROMOTER_RE, re.compile(r"^\s*SOBHA\s*$", re.I)],
        "project_patterns": [re.compile(r"\bSOBHA\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["SOBHA", "SOBHA LIMITED", "SOBHA LTD", "SOBHA DEVELOPERS"],
    },
    {
        "builder_id": "builder_assetz_group",
        "canonical_name": "Assetz Property Group",
        "promoter_patterns": [re.compile(r"\bASSETZ\b", re.I)],
        "project_patterns": [re.compile(r"\bASSETZ\b", re.I)],
        "spv_promoter_patterns": [ASSETZ_SPV_PROMOTER_RE],
        "aliases": ["ASSETZ", "ASSETZ PROPERTY GROUP", "APG"],
    },
    {
        "builder_id": "builder_godrej_properties",
        "canonical_name": "Godrej Properties",
        "promoter_patterns": [re.compile(r"\bGODREJ\b", re.I)],
        "project_patterns": [re.compile(r"\bGODREJ\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["GODREJ", "GODREJ PROPERTIES", "GODREJ PROPERTIES LIMITED"],
    },
    {
        "builder_id": "builder_brigade_group",
        "canonical_name": "Brigade Group",
        "promoter_patterns": [re.compile(r"\bBRIGADE\b", re.I)],
        "project_patterns": [re.compile(r"\bBRIGADE\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["BRIGADE", "BRIGADE GROUP", "BRIGADE ENTERPRISES"],
    },
    {
        "builder_id": "builder_prestige_group",
        "canonical_name": "Prestige Group",
        "promoter_patterns": [re.compile(r"\bPRESTIGE\b", re.I)],
        "project_patterns": [re.compile(r"^(?:THE\s+)?PRESTIGE\b", re.I), re.compile(r"\bPRESTIGE\s+(?:CITY|FINSBURY|LAKESIDE|SHANTINIKETAN|TECH|PARK|BOULEVARD|AVENUE|WATERFORD|ELM|PINE|SOMERVILLE|FALCON|SOUTHERN|FERNS|WOOD|AVON|CAMDEN|RAINTREE|NAUTICAL|LAVENDER|CLAIRE|SPRING|SUNCREST|OAK|TRANQUILITY|GLENBROOK|GREEN|PALMS|DOLPHIN|IVY|JINDAL|MERIDIAN|EDEN|ROYAL|BEVERLY)\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["PRESTIGE", "PRESTIGE GROUP", "PRESTIGE ESTATES PROJECTS"],
    },
    {
        "builder_id": "builder_sattva_group",
        "canonical_name": "Sattva Group (Salarpuria Sattva)",
        "promoter_patterns": [re.compile(r"\b(?:SATTVA|SALARPURIA)\b", re.I)],
        "project_patterns": [re.compile(r"^\s*(?:SALARPURIA|SATTVA)\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["SATTVA", "SALARPURIA", "SALARPURIA SATTVA", "SATTVA GROUP"],
    },
    {
        "builder_id": "builder_shriram_properties",
        "canonical_name": "Shriram Properties",
        "promoter_patterns": [re.compile(r"\b(?:SHRIRAM|SHRIPROP|SHRIVISION)\b", re.I)],
        "project_patterns": [re.compile(r"^\s*SHRIRAM\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["SHRIRAM", "SHRIRAM PROPERTIES", "SHRIPROP"],
    },
    {
        "builder_id": "builder_puravankara_group",
        "canonical_name": "Puravankara & Provident",
        "promoter_patterns": [re.compile(r"\b(?:PURAVANKARA|PROVIDENT)\b", re.I)],
        "project_patterns": [re.compile(r"^(?:PURVA|PURAVANKARA|PROVIDENT)\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["PURAVANKARA", "PURVA", "PROVIDENT"],
    },
    {
        "builder_id": "builder_total_environment",
        "canonical_name": "Total Environment",
        "promoter_patterns": [re.compile(r"\bTOTAL\s+ENVIRONMENT\b", re.I)],
        "project_patterns": [re.compile(r"\bTOTAL\s+ENVIRONMENT\b", re.I)],
        "spv_promoter_patterns": [re.compile(r"\b(?:FARAWAY\s+TREE\s+HOSPITALITY|AUTUMNLEAF)\b", re.I)],
        "aliases": ["TOTAL ENVIRONMENT", "TOTAL ENVIRONMENT BUILDING SYSTEMS"],
    },
    {
        "builder_id": "builder_embassy_group",
        "canonical_name": "Embassy Group",
        "promoter_patterns": [re.compile(r"\bEMBASSY\b", re.I)],
        "project_patterns": [re.compile(r"^\s*EMBASSY\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["EMBASSY", "EMBASSY GROUP", "EMBASSY PROPERTY"],
    },
    {
        "builder_id": "builder_sumadhura_group",
        "canonical_name": "Sumadhura Group",
        "promoter_patterns": [re.compile(r"\bSUMADHURA\b", re.I)],
        "project_patterns": [re.compile(r"^\s*SUMADHURA\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["SUMADHURA", "SUMADHURA INFRACON"],
    },
    {
        "builder_id": "builder_century_real_estate",
        "canonical_name": "Century Real Estate",
        "promoter_patterns": [re.compile(r"\bCENTURY\b", re.I)],
        "project_patterns": [re.compile(r"^\s*CENTURY\s+(?!21\b)(?:INDUS|INFINITI|RENATA|ARTIZAN|NOVUS|REGALIA|LIVA|ASTORIA|KINDLE|ETHOS|TRAILS|WINTERSUN|BREEZE|EDEN|MIRAI|HORIZON|MARVELLA|SILICON)\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["CENTURY", "CENTURY REAL ESTATE"],
    },
    {
        "builder_id": "builder_ds_max_properties",
        "canonical_name": "DS-Max Properties",
        "promoter_patterns": [re.compile(r"\bDS[\s\-]*MAX\b", re.I)],
        "project_patterns": [re.compile(r"\bDS[\s\-]*MAX\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["DS MAX", "DS-MAX", "DS MAX PROPERTIES"],
    },
    {
        "builder_id": "builder_concorde_group",
        "canonical_name": "Concorde Group",
        "promoter_patterns": [re.compile(r"\bCONCORDE\b", re.I)],
        "project_patterns": [re.compile(r"^\s*CONCORDE\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["CONCORDE", "CONCORDE GROUP"],
    },
    {
        "builder_id": "builder_mana_projects",
        "canonical_name": "Mana Projects",
        "promoter_patterns": [re.compile(r"\bMANA\s+(?:PROJECTS|CONSTRUCTIONS|INFRA|DEVELOPERS)\b", re.I)],
        "project_patterns": [re.compile(r"^\s*MANA\b", re.I), re.compile(r"@\s*MANA\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["MANA", "MANA PROJECTS"],
    },
    {
        "builder_id": "builder_sbr_group",
        "canonical_name": "SBR Group",
        "promoter_patterns": [re.compile(r"\bSBR\b", re.I)],
        "project_patterns": [re.compile(r"^\s*SBR\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["SBR", "SBR GROUP"],
    },
    {
        "builder_id": "builder_pride_group",
        "canonical_name": "Pride Group",
        "promoter_patterns": [re.compile(r"\bPRIDE\b", re.I)],
        # Strict: ONLY projects starting with "PRIDE " (prevents "GS LNS PRIDE", "ATHISH PRIDE", etc.)
        "project_patterns": [re.compile(r"^\s*PRIDE\s+", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["PRIDE GROUP", "PRIDE & EXPERT", "PRIDE HOUSING"],
    },
    {
        "builder_id": "builder_kns_infrastructure",
        "canonical_name": "KNS Infrastructure",
        "promoter_patterns": [re.compile(r"\bKNS\b", re.I)],
        "project_patterns": [re.compile(r"^\s*KNS\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["KNS", "KNS INFRASTRUCTURE"],
    },
    {
        "builder_id": "builder_adarsh_group",
        "canonical_name": "Adarsh Group",
        "promoter_patterns": [re.compile(r"\bADARSH\b", re.I)],
        "project_patterns": [re.compile(r"^\s*ADARSH\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["ADARSH", "ADARSH DEVELOPERS", "ADARSH GROUP"],
    },
    {
        "builder_id": "builder_rohan_builders",
        "canonical_name": "Rohan Builders",
        "promoter_patterns": [re.compile(r"\bROHAN\b", re.I)],
        "project_patterns": [re.compile(r"^\s*ROHAN\s+(?:TECH|IKSHA|UPAVAN|JHAROKA|NIDHI|AVASHA|AKRITI|ANTARA|HARITA)\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["ROHAN", "ROHAN BUILDERS"],
    },
    {
        "builder_id": "builder_vajram_group",
        "canonical_name": "Vajram Group",
        "promoter_patterns": [re.compile(r"\bVAJRAM\b", re.I)],
        "project_patterns": [re.compile(r"^\s*VAJRAM\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["VAJRAM", "VAJRAM GROUP"],
    },
    {
        "builder_id": "builder_keerthi_estates",
        "canonical_name": "Keerthi Estates",
        "promoter_patterns": [re.compile(r"\bKEERTHI\b", re.I)],
        "project_patterns": [re.compile(r"^\s*KEERTHI\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["KEERTHI", "KEERTHI ESTATES"],
    },
    {
        "builder_id": "builder_mahindra_lifespaces",
        "canonical_name": "Mahindra Lifespaces",
        "promoter_patterns": [re.compile(r"\bMAHINDRA\b", re.I)],
        "project_patterns": [re.compile(r"^\s*MAHINDRA\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["MAHINDRA", "MAHINDRA LIFESPACES"],
    },
    {
        "builder_id": "builder_bhartiya_urban",
        "canonical_name": "Bhartiya Urban",
        "promoter_patterns": [re.compile(r"\bBHARTIYA\b", re.I)],
        "project_patterns": [re.compile(r"^(?:BHARTIYA|NIKOO)\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["BHARTIYA", "BHARTIYA URBAN", "BHARTIYA CITY", "NIKOO HOMES"],
    },
    {
        "builder_id": "builder_aratt_builders",
        "canonical_name": "Aratt Builders",
        "promoter_patterns": [re.compile(r"\bARATT\b", re.I)],
        "project_patterns": [re.compile(r"^\s*ARATT\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["ARATT", "ARATTUKULAM"],
    },
    {
        "builder_id": "builder_bren_corporation",
        "canonical_name": "Bren Corporation",
        "promoter_patterns": [re.compile(r"\bBREN\b", re.I)],
        "project_patterns": [re.compile(r"^\s*BREN\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["BREN", "BREN CORPORATION"],
    },
    {
        "builder_id": "builder_nambiar_builders",
        "canonical_name": "Nambiar Builders",
        "promoter_patterns": [re.compile(r"\bNAMBIAR\b", re.I)],
        "project_patterns": [re.compile(r"^\s*NAMBIAR\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["NAMBIAR", "NAMBIAR BUILDERS"],
    },
    {
        "builder_id": "builder_snn_builders",
        "canonical_name": "SNN Builders",
        "promoter_patterns": [re.compile(r"\bSNN\b", re.I)],
        "project_patterns": [re.compile(r"^\s*SNN\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["SNN", "SNN BUILDERS", "SNN RAJ"],
    },
    {
        "builder_id": "builder_casagrand",
        "canonical_name": "Casagrand",
        "promoter_patterns": [re.compile(r"\bCASA\s*GRAND(?:E)?\b", re.I)],
        "project_patterns": [re.compile(r"^\s*CASA\s*GRAND(?:E)?\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["CASAGRAND", "CASA GRAND", "CASA GRANDE"],
    },
    {
        "builder_id": "builder_goyal_and_co",
        "canonical_name": "Goyal & Co",
        "promoter_patterns": [re.compile(r"\bGOYAL\b", re.I)],
        "project_patterns": [re.compile(r"^\s*GOYAL\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["GOYAL", "GOYAL & CO", "GOYAL AND CO", "HARIYANA"],
    },
    {
        "builder_id": "builder_mantri_developers",
        "canonical_name": "Mantri Developers",
        "promoter_patterns": [re.compile(r"\bMANTRI\b", re.I)],
        "project_patterns": [re.compile(r"^\s*MANTRI\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["MANTRI", "MANTRI DEVELOPERS"],
    },
    {
        "builder_id": "builder_birla_estates",
        "canonical_name": "Birla Estates",
        "promoter_patterns": [re.compile(r"\bBIRLA\b", re.I)],
        "project_patterns": [re.compile(r"^\s*BIRLA\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["BIRLA", "BIRLA ESTATES"],
    },
    {
        "builder_id": "builder_lodha_group",
        "canonical_name": "Lodha (Macrotech)",
        "promoter_patterns": [re.compile(r"\bLODHA\b", re.I)],
        "project_patterns": [re.compile(r"^\s*LODHA\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["LODHA", "MACROTECH"],
    },
    {
        "builder_id": "builder_gopalan_enterprises",
        "canonical_name": "Gopalan Enterprises",
        "promoter_patterns": [re.compile(r"\bGOPALAN\b", re.I)],
        "project_patterns": [re.compile(r"^\s*GOPALAN\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["GOPALAN", "GOPALAN ENTERPRISES"],
    },
    {
        "builder_id": "builder_confident_group",
        "canonical_name": "Confident Group",
        "promoter_patterns": [re.compile(r"\bCONFIDENT\b", re.I)],
        "project_patterns": [re.compile(r"^\s*CONFIDENT\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["CONFIDENT", "CONFIDENT GROUP"],
    },
    {
        "builder_id": "builder_vaishnavi_group",
        "canonical_name": "Vaishnavi Group",
        "promoter_patterns": [re.compile(r"\bVAISHNAVI\b", re.I)],
        "project_patterns": [re.compile(r"^\s*VAISHNAVI\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["VAISHNAVI", "VAISHNAVI GROUP"],
    },
    {
        "builder_id": "builder_radiance_realty",
        "canonical_name": "Radiance Realty",
        "promoter_patterns": [re.compile(r"\bRADIANCE\b", re.I)],
        "project_patterns": [re.compile(r"^\s*RADIANCE\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["RADIANCE", "RADIANCE REALTY"],
    },
    {
        "builder_id": "builder_vaswani_group",
        "canonical_name": "Vaswani Group",
        "promoter_patterns": [re.compile(r"\bVASWANI\b", re.I)],
        "project_patterns": [re.compile(r"^\s*VASWANI\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["VASWANI", "VASWANI GROUP"],
    },
    {
        "builder_id": "builder_sjr_primecorp",
        "canonical_name": "SJR Primecorp",
        "promoter_patterns": [re.compile(r"\bSJR\b", re.I)],
        "project_patterns": [re.compile(r"^\s*SJR\b", re.I)],
        "spv_promoter_patterns": [],
        "aliases": ["SJR", "SJR PRIMECORP"],
    },
]


def format_readable_promoter_name(raw_promoter: str) -> str:
    raw = decode_portal_text(raw_promoter)
    if not raw:
        return "Independent / Unspecified Promoter"
    if raw.isupper() or raw.islower():
        words = raw.split()
        acronyms = {"LLP", "PVT", "LTD", "BDA", "NRI", "KNS", "SBR", "JR", "SR", "M/S", "HUF", "II", "III", "APG", "SLV", "PSR"}
        out = []
        for w in words:
            clean_w = re.sub(r"[^A-Za-z]", "", w).upper()
            out.append(w.upper() if clean_w in acronyms else w.capitalize())
        return " ".join(out)
    return raw


def resolve_builder_identity(
    project_name: Optional[str],
    promoter_name: Optional[str],
    registration_number: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Deterministically resolve canonical builder metadata from raw portal fields
    with strict false-positive prevention and explicit confidence scoring.
    """
    official_builder = decode_portal_text(promoter_name) or "Unknown Promoter"
    official_project = decode_portal_text(project_name)
    norm_builder = normalize_builder_name(official_builder) or normalize_text(official_builder)

    # 1. Exact corporate promoter match
    for bdef in BRAND_DEFINITIONS:
        if any(pat.search(official_builder) for pat in bdef["promoter_patterns"]):
            aliases = sorted(set(bdef["aliases"] + [official_builder, norm_builder]) - {""})
            return {
                "builder_id": bdef["builder_id"],
                "canonical_builder_name": bdef["canonical_name"],
                "official_builder_name": official_builder,
                "normalized_builder_name": norm_builder,
                "builder_aliases": aliases,
                "is_featured_brand": True,
                "name_normalization_confidence": "exact_entity",
                "needs_manual_review": False,
                "review_reason": None,
            }

    # 2. Verified SPV corporate promoter match (e.g., APG Intelli Homes -> Assetz Property Group)
    for bdef in BRAND_DEFINITIONS:
        if any(pat.search(official_builder) for pat in bdef["spv_promoter_patterns"]):
            aliases = sorted(set(bdef["aliases"] + [official_builder, norm_builder]) - {""})
            return {
                "builder_id": bdef["builder_id"],
                "canonical_builder_name": bdef["canonical_name"],
                "official_builder_name": official_builder,
                "normalized_builder_name": norm_builder,
                "builder_aliases": aliases,
                "is_featured_brand": True,
                "name_normalization_confidence": "verified_spv",
                "needs_manual_review": False,
                "review_reason": None,
            }

    # 3. Branded project-name match (e.g., "United Oxygen Company" -> "Godrej United")
    for bdef in BRAND_DEFINITIONS:
        if any(pat.search(official_project) for pat in bdef["project_patterns"]):
            aliases = sorted(set(bdef["aliases"] + [official_builder, norm_builder]) - {""})
            return {
                "builder_id": bdef["builder_id"],
                "canonical_builder_name": bdef["canonical_name"],
                "official_builder_name": official_builder,
                "normalized_builder_name": norm_builder,
                "builder_aliases": aliases,
                "is_featured_brand": True,
                "name_normalization_confidence": "brand_project_match",
                "needs_manual_review": False,
                "review_reason": None,
            }

    # 4. Fallback to normalized legal promoter entity (prevents false-positive collapses)
    # Check if an individual/ambiguous name looks similar to a major brand (e.g. SOBHA RANI)
    needs_review = False
    review_reason = None
    if re.search(r"\bSOBHA\b", official_builder, re.I) and not SOBHA_CORP_PROMOTER_RE.search(official_builder):
        needs_review = False  # Confirmed individual promoter SOBHA RANI, intentionally distinct from Sobha Limited
    elif len(norm_builder) < 3:
        needs_review = True
        review_reason = f"Very short normalized promoter name: '{official_builder}'"

    entity_slug_base = normalize_corporate_entity_name(official_builder) or norm_builder
    compact_slug = re.sub(r"[^a-z0-9]+", "_", entity_slug_base.lower()).strip("_")
    compact_slug = re.sub(r"_and$", "", compact_slug)
    if not compact_slug:
        compact_slug = re.sub(r"[^a-z0-9]+", "_", official_builder.lower()).strip("_") or "unknown"
    builder_id = f"builder_{compact_slug[:60]}"
    display_name = format_readable_promoter_name(official_builder)
    aliases = sorted({a for a in (official_builder, norm_builder, display_name) if a})

    return {
        "builder_id": builder_id,
        "canonical_builder_name": display_name,
        "official_builder_name": official_builder,
        "normalized_builder_name": norm_builder,
        "builder_aliases": aliases,
        "is_featured_brand": False,
        "name_normalization_confidence": "fallback_promoter",
        "needs_manual_review": needs_review,
        "review_reason": review_reason,
    }


def generate_project_aliases(
    official_project_name: str,
    builder_info: Dict[str, Any],
) -> List[str]:
    """
    Generate deterministic search aliases for a project name without collapsing
    distinct registration numbers.
    """
    aliases = set()
    clean_proj = decode_portal_text(official_project_name)
    norm_proj = normalize_text(clean_proj)
    if clean_proj:
        aliases.add(clean_proj)
    if norm_proj:
        aliases.add(norm_proj)

    # Handle '&' <-> 'AND' variations explicitly
    if "&" in clean_proj:
        aliases.add(clean_proj.replace("&", "AND"))
        aliases.add(re.sub(r"\s+", " ", clean_proj.replace("&", " and ")).strip())
    if re.search(r"\bAND\b", norm_proj):
        aliases.add(re.sub(r"\bAND\b", "&", norm_proj))

    # Handle singular/plural Degree <-> Degrees (e.g., "63 Degree East" <-> "63 Degrees East")
    if re.search(r"\bDEGREES?\b", norm_proj):
        aliases.add(re.sub(r"\bDEGREE\b", "DEGREES", norm_proj))
        aliases.add(re.sub(r"\bDEGREES\b", "DEGREE", norm_proj))

    # For verified SPV projects whose official project title omits the parent brand
    # (e.g., "63 Degree East - Tower A" under APG Intelli Homes -> "Assetz 63 Degree East - Tower A")
    if builder_info.get("builder_id") == "builder_assetz_group" and "assetz" not in norm_proj.lower():
        aliases.add(f"ASSETZ {norm_proj}")
        aliases.add(f"Assetz {clean_proj}")
        if re.search(r"\bDEGREE\b", norm_proj):
            deg_norm = re.sub(r"\bDEGREE\b", "DEGREES", norm_proj)
            deg_clean = re.sub(r"\bDegree\b", "Degrees", clean_proj, flags=re.I)
            aliases.add(f"ASSETZ {deg_norm}")
            aliases.add(f"Assetz {deg_clean}")

    # Strip trailing phase/wing suffix for base search alias (kept only as an alias, never as identity)
    base_name = re.sub(
        r"\s*(?:[-–]\s*)?(?:PHASE|PH|TOWER|WING|BLOCK)\b.*$",
        "",
        norm_proj,
        flags=re.IGNORECASE,
    ).strip()
    if base_name and len(base_name) >= 4 and base_name != norm_proj:
        aliases.add(base_name)
        if re.search(r"\bDEGREE\b", base_name):
            aliases.add(re.sub(r"\bDEGREE\b", "DEGREES", base_name))
        if builder_info.get("builder_id") == "builder_assetz_group" and "assetz" not in base_name.lower():
            aliases.add(f"ASSETZ {base_name}")
            if re.search(r"\bDEGREE\b", base_name):
                deg_base = re.sub(r"\bDEGREE\b", "DEGREES", base_name)
                aliases.add(f"ASSETZ {deg_base}")

    # Strip leading 'ASSETZ ' so queries omitting brand prefix (e.g. "Ren and Rei") still match alias list cleanly
    if norm_proj.startswith("ASSETZ "):
        stripped = norm_proj[len("ASSETZ "):].strip()
        if stripped:
            aliases.add(stripped)
            if "&" in clean_proj:
                aliases.add(re.sub(r"\bAND\b", "&", stripped))

    return sorted(a for a in aliases if a)


def build_project_normalization(
    project_name: Optional[str],
    promoter_name: Optional[str],
    registration_number: str,
    canonical_project_id: str,
    source_record_id: Optional[str] = None,
    source_portal: str = "K-RERA Karnataka",
) -> Dict[str, Any]:
    """Build complete canonical normalization & provenance block for a project."""
    official_proj = decode_portal_text(project_name)
    norm_proj = normalize_text(official_proj)
    builder_info = resolve_builder_identity(official_proj, promoter_name, registration_number)
    project_aliases = generate_project_aliases(official_proj, builder_info)

    return {
        "officialBuilderName": builder_info["official_builder_name"],
        "normalizedBuilderName": builder_info["normalized_builder_name"],
        "officialProjectName": official_proj,
        "normalizedProjectName": norm_proj,
        "builderAliases": builder_info["builder_aliases"],
        "projectAliases": project_aliases,
        "reraRegistrationNumber": (registration_number or "").strip(),
        "canonicalProjectId": canonical_project_id,
        "sourcePortal": source_portal,
        "sourceRecordId": source_record_id or canonical_project_id,
        "nameNormalizationConfidence": builder_info["name_normalization_confidence"],
        "needsManualReview": builder_info["needs_manual_review"],
        "reviewReason": builder_info["review_reason"],
        "builderId": builder_info["builder_id"],
        "canonicalBuilderName": builder_info["canonical_builder_name"],
        "isFeaturedBrand": builder_info["is_featured_brand"],
    }


def build_normalized_search_tokens(
    *texts: Optional[str],
    max_tokens: int = 160,
) -> List[str]:
    """Generate rich normalized lowercase search tokens supporting prefixes, &/and, and RERA IDs."""
    tokens = set()
    for text in texts:
        if not text or not isinstance(text, str):
            continue
        decoded = decode_portal_text(text).lower()
        if not decoded:
            continue
        tokens.add(decoded)
        norm = normalize_text(decoded).lower()
        if norm:
            tokens.add(norm)
        compact = re.sub(r"[^a-z0-9]+", "", decoded)
        if len(compact) >= 3:
            tokens.add(compact)
        for source_str in (decoded, norm):
            for w in re.split(r"[^a-z0-9]+", source_str):
                if len(w) >= 2:
                    tokens.add(w)
                    for prefix_len in range(3, min(len(w), 9)):
                        tokens.add(w[:prefix_len])
    return sorted(tokens)[:max_tokens]
