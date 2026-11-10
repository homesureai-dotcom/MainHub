#!/usr/bin/env python3
"""
Builds and uploads canonical Builder records (`/builders`) to Cloud Firestore
from the 875 verified K-RERA projects in `homesureai-51893`.
"""

import json
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Tuple

from import_projects import (
    EXTRACTION_ROOT,
    commit_firestore_writes,
    get_firebase_Auth_token,
    make_firestore_write_op,
)

# Canonical brand matching rules: (Canonical Display Name, Builder ID, list of regex patterns)
BRAND_RULES: List[Tuple[str, str, List[str]]] = [
    ("Godrej Properties", "builder_godrej_properties", [r"\bgodrej\b"]),
    ("Brigade Group", "builder_brigade_group", [r"\bbrigade\b"]),
    ("Prestige Group", "builder_prestige_group", [r"\bprestige\b"]),
    ("Sobha Limited", "builder_sobha_limited", [r"\bsobha\b"]),
    ("Sattva Group (Salarpuria Sattva)", "builder_sattva_group", [r"\bsattva\b", r"\bsalarpuria\b"]),
    ("Shriram Properties", "builder_shriram_properties", [r"\bshriram\b"]),
    ("Puravankara & Provident", "builder_puravankara_group", [r"\bpuravankara\b", r"\bprovident\b"]),
    ("Total Environment", "builder_total_environment", [r"\btotal environment\b"]),
    ("Embassy Group", "builder_embassy_group", [r"\bembassy\b"]),
    ("Sumadhura Group", "builder_sumadhura_group", [r"\bsumadhura\b"]),
    ("Century Real Estate", "builder_century_real_estate", [r"\bcentury\b"]),
    ("Assetz Property Group", "builder_assetz_group", [r"\bassetz\b"]),
    ("DS-Max Properties", "builder_ds_max_properties", [r"\bds[-\s]?max\b"]),
    ("Concorde Group", "builder_concorde_group", [r"\bconcorde\b"]),
    ("Mana Projects", "builder_mana_projects", [r"\bmana\b"]),
    ("SBR Group", "builder_sbr_group", [r"\bsbr\b"]),
    ("Pride Group", "builder_pride_group", [r"\bpride\b"]),
    ("KNS Infrastructure", "builder_kns_infrastructure", [r"\bkns\b"]),
    ("Adarsh Group", "builder_adarsh_group", [r"\badarsh\b"]),
    ("Rohan Builders", "builder_rohan_builders", [r"\brohan\b"]),
    ("Vajram Group", "builder_vajram_group", [r"\bvajram\b"]),
    ("Keerthi Estates", "builder_keerthi_estates", [r"\bkeerthi\b"]),
    ("Mahindra Lifespaces", "builder_mahindra_lifespaces", [r"\bmahindra\b"]),
    ("Bhartiya Urban", "builder_bhartiya_urban", [r"\bbhartiya\b"]),
    ("Aratt Builders", "builder_aratt_builders", [r"\baratt\b"]),
    ("Bren Corporation", "builder_bren_corporation", [r"\bbren\b"]),
    ("Nambiar Builders", "builder_nambiar_builders", [r"\bnambiar\b"]),
    ("SNN Builders", "builder_snn_builders", [r"\bsnn\b"]),
    ("Casagrand", "builder_casagrand", [r"\bcasagrand\b"]),
    ("Goyal & Co", "builder_goyal_and_co", [r"\bgoyal\b"]),
]


def resolve_builder_identity(project_name: str, promoter_name: str) -> Tuple[str, str, bool]:
    """
    Return (builder_id, builder_display_name, is_featured_brand) for a project.
    Checks BRAND_RULES against promoter_name and project_name first, then falls back
    to normalized promoter_name.
    """
    combined = f"{promoter_name} {project_name}".lower()
    for display_name, builder_id, patterns in BRAND_RULES:
        for pat in patterns:
            if re.search(pat, combined, flags=re.IGNORECASE):
                return builder_id, display_name, True

    raw_promoter = (promoter_name or "Unknown Promoter").strip()
    compact_slug = re.sub(r"[^a-z0-9]+", "_", raw_promoter.lower()).strip("_")
    builder_id = f"builder_{compact_slug[:60]}" if compact_slug else "builder_unknown"

    # Format ALL-CAPS or all-lowercase promoter names into clean readable casing
    if raw_promoter.isupper() or raw_promoter.islower():
        words = raw_promoter.split()
        formatted_words = []
        acronyms = {"LLP", "PVT", "LTD", "BDA", "NRI", "KNS", "SBR", "JR", "SR", "M/S", "HUF", "II", "III"}
        for w in words:
            clean_w = re.sub(r"[^A-Za-z]", "", w).upper()
            if clean_w in acronyms:
                formatted_words.append(w.upper())
            else:
                formatted_words.append(w.capitalize())
        display_name = " ".join(formatted_words)
    else:
        display_name = raw_promoter

    return builder_id, display_name, False


def main() -> int:
    report_path = EXTRACTION_ROOT / "data" / "firestore_import_live_report.json"
    if not report_path.exists():
        print(f"Error: {report_path} not found.", file=sys.stderr)
        return 1

    report = json.loads(report_path.read_text(encoding="utf-8"))
    all_projects = report.get("all_projects") or []
    print(f"[Builders] Loaded {len(all_projects)} projects from live report.")

    builders_map: Dict[str, Dict[str, Any]] = {}

    for p in all_projects:
        p_name = (p.get("project_name") or "").strip()
        prom_name = (p.get("promoter_name") or "").strip()
        b_id, b_name, is_brand = resolve_builder_identity(p_name, prom_name)

        if b_id not in builders_map:
            builders_map[b_id] = {
                "builder_id": b_id,
                "builder_name": b_name,
                "is_featured_brand": is_brand,
                "legal_promoter_names": set(),
                "localities": set(),
                "projects": [],
            }

        entry = builders_map[b_id]
        if prom_name:
            entry["legal_promoter_names"].add(prom_name)
        if p.get("taluk"):
            entry["localities"].add(p["taluk"])

        entry["projects"].append({
            "project_id": p["project_id"],
            "project_name": p_name,
            "promoter_name": prom_name,
            "taluk": p.get("taluk") or "",
            "city": "Bengaluru",
            "registration_number": p.get("registration_number") or "",
            "acknowledgement_number": p.get("acknowledgement_number") or "",
            "project_type": p.get("project_type") or "",
            "regulatory_status": p.get("regulatory_status") or "",
            "total_documents": p.get("total_documents") or 0,
            "total_complaints": p.get("total_complaints") or 0,
        })

    # Convert sets and sort projects within each builder alphabetically
    builders_list: List[Dict[str, Any]] = []
    for b_id, b_data in builders_map.items():
        projs = sorted(b_data["projects"], key=lambda x: x["project_name"].lower())
        promoters_sorted = sorted(list(b_data["legal_promoter_names"]))
        localities_sorted = sorted(list(b_data["localities"]))
        builders_list.append({
            "builder_id": b_id,
            "builder_name": b_data["builder_name"],
            "is_featured_brand": b_data["is_featured_brand"],
            "project_count": len(projs),
            "legal_promoter_names": promoters_sorted[:10],
            "localities": localities_sorted[:10],
            "projects": projs,
        })

    # Sort builders: featured brands & multi-project builders first (by project_count DESC, then name ASC)
    builders_list.sort(
        key=lambda b: (
            0 if b["is_featured_brand"] else (1 if b["project_count"] > 1 else 2),
            -b["project_count"],
            b["builder_name"].lower(),
        )
    )

    print(f"[Builders] Total canonical builders generated: {len(builders_list)}")
    print("[Builders] Top 15 builders by project count:")
    for b in builders_list[:15]:
        print(f"  - {b['builder_name']} ({b['builder_id']}): {b['project_count']} projects")

    # Split builders_list into 3 chunks so each chunk is ~90 KB (well under 1 MiB limit)
    chunk_size = 250
    chunks = [
        builders_list[i : i + chunk_size]
        for i in range(0, len(builders_list), chunk_size)
    ]

    token = get_firebase_Auth_token()
    writes = []

    for c_idx, chunk in enumerate(chunks, start=1):
        chunk_doc_id = f"_catalog_chunk_{c_idx}"
        chunk_payload = {
            "chunk_id": chunk_doc_id,
            "chunk_index": c_idx,
            "total_chunks": len(chunks),
            "builders_count": len(chunk),
            "builders": chunk,
        }
        size_kb = round(len(json.dumps(chunk_payload).encode("utf-8")) / 1024, 1)
        print(f"[Builders] Prepared {chunk_doc_id}: {len(chunk)} builders ({size_kb} KB)")
        writes.append(make_firestore_write_op(f"builders/{chunk_doc_id}", chunk_payload))

    # Also write individual builder documents for the top 60 builders (all featured + multi-project builders)
    for b in builders_list[:60]:
        writes.append(make_firestore_write_op(f"builders/{b['builder_id']}", b))

    committed = 0
    while writes:
        batch = writes[:25]
        writes = writes[25:]
        committed += commit_firestore_writes(batch, token)
        print(f"[Builders] Committed {committed} Firestore writes...")

    print("[Builders] Successfully uploaded canonical builders catalog to Firestore!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
