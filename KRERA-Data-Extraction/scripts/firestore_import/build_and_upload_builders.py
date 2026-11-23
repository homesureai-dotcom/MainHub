#!/usr/bin/env python3
"""
HomeSure Phase 4 — Canonical Builders Catalogue Builder & Uploader (`/builders`)

Reads all live `/projects` documents directly from Cloud Firestore (100% consistent
source of truth), resolves canonical builder identities & search aliases via
`name_normalization.py`, dynamically chunks `/builders/_catalog_chunk_1..N` under
a strict 650 KB size budget, publishes `/builders/_catalog_meta`, and cleans up
stale excess chunk docs if chunk count shrinks.
"""

from __future__ import annotations

import argparse
import datetime
import json
import sys
from pathlib import Path
from typing import Any, Dict, List

WORKSPACE_ROOT = Path(__file__).resolve().parents[3]
EXTRACTION_ROOT = WORKSPACE_ROOT / "KRERA-Data-Extraction"
SCRIPTS_ROOT = EXTRACTION_ROOT / "scripts"
if str(SCRIPTS_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_ROOT))

from geography import normalize_taluk
from name_normalization import build_project_normalization, resolve_builder_identity
from import_projects import (
    SCHEMA_VERSION,
    commit_firestore_writes,
    get_firebase_Auth_token,
    list_firestore_collection_docs,
    make_firestore_delete_op,
    make_firestore_write_op,
)

MAX_CHUNK_BYTES = 650_000
MAX_BUILDERS_PER_CHUNK = 200


def build_builders_catalog_from_projects(
    projects: List[Dict[str, Any]],
) -> List[Dict[str, Any]]:
    """Group canonical `/projects` records into sorted `BuilderCatalogueEntry` dicts."""
    builders_map: Dict[str, Dict[str, Any]] = {}

    for p in projects:
        p_id = (p.get("project_id") or p.get("_doc_id") or "").strip()
        reg_no = (p.get("registration_number") or "").strip()
        p_name = (p.get("officialProjectName") or p.get("project_name") or "").strip()
        prom_name = (p.get("officialBuilderName") or p.get("promoter_name") or "").strip()
        if not p_id:
            continue

        binfo = resolve_builder_identity(p_name, prom_name, reg_no)
        pnorm = build_project_normalization(
            project_name=p_name,
            promoter_name=prom_name,
            registration_number=reg_no,
            canonical_project_id=p_id,
            source_record_id=p.get("sourceRecordId") or p.get("internal_id") or p_id,
        )
        b_id = binfo["builder_id"]

        if b_id not in builders_map:
            builders_map[b_id] = {
                "builder_id": b_id,
                "builder_name": binfo["canonical_builder_name"],
                "normalized_builder_name": binfo["normalized_builder_name"],
                "is_featured_brand": binfo["is_featured_brand"],
                "builder_aliases": set(binfo["builder_aliases"]),
                "legal_promoter_names": set(),
                "localities": set(),
                "projects": [],
                "seen_reg_nos": set(),
            }

        entry = builders_map[b_id]
        # Avoid double counting if duplicate IDs were passed
        dedup_token = reg_no.upper() if reg_no else p_id
        if dedup_token in entry["seen_reg_nos"]:
            continue
        entry["seen_reg_nos"].add(dedup_token)

        entry["builder_aliases"].update(binfo["builder_aliases"])
        if prom_name:
            entry["legal_promoter_names"].add(prom_name)

        raw_taluk = (p.get("taluk") or "").strip()
        norm_taluk = (p.get("normalizedTaluk") or normalize_taluk(raw_taluk) or raw_taluk).strip()
        if norm_taluk:
            entry["localities"].add(norm_taluk)

        counts = p.get("counts") or {}
        prov = p.get("provenance") or {}
        metrics = p.get("summary_metrics") or {}
        total_units_val = 0
        if isinstance(counts, dict) and counts.get("total_units"):
            try:
                total_units_val = int(counts["total_units"])
            except (TypeError, ValueError):
                total_units_val = 0
        elif isinstance(metrics, dict) and isinstance(metrics.get("total_units_inventories"), dict):
            raw_u = metrics["total_units_inventories"].get("value")
            try:
                total_units_val = int(str(raw_u).strip()) if raw_u is not None else 0
            except (TypeError, ValueError):
                total_units_val = 0

        towers_sum = p.get("towers_summary") or []
        data_tier = prov.get("data_tier") or (
            "deep_extracted" if (counts.get("total_fields") or 0) > 0 else "catalogue_summary"
        )

        # Keep aliases compact inside catalog chunks
        proj_aliases = p.get("projectAliases") or pnorm["projectAliases"]

        entry["projects"].append({
            "project_id": p_id,
            "project_name": p_name,
            "official_project_name": pnorm["officialProjectName"],
            "normalized_project_name": pnorm["normalizedProjectName"],
            "project_aliases": proj_aliases[:10],
            "promoter_name": prom_name,
            "district": (p.get("district") or "Bengaluru Urban").strip(),
            "taluk": raw_taluk or norm_taluk,
            "normalized_taluk": norm_taluk,
            "city": (p.get("city") or "Bengaluru").strip(),
            "registration_number": reg_no,
            "acknowledgement_number": (p.get("acknowledgement_number") or "").strip(),
            "project_type": (p.get("project_type") or "").strip(),
            "regulatory_status": (p.get("regulatory_status") or "APPROVED").strip(),
            "approved_on": (p.get("approved_on_iso") or p.get("approved_on_raw") or "").strip(),
            "proposed_completion_date": (
                p.get("proposed_completion_date_iso") or p.get("proposed_completion_date_raw") or ""
            ).strip(),
            "project_start_date": (p.get("project_start_date_iso") or "").strip(),
            "total_units": total_units_val,
            "total_towers": len(towers_sum) if isinstance(towers_sum, list) else 0,
            "total_documents": counts.get("total_documents") or 0,
            "total_complaints": counts.get("total_complaints") or 0,
            "data_tier": data_tier,
        })

    builders_list: List[Dict[str, Any]] = []
    for b_id, b_data in builders_map.items():
        projs = sorted(b_data["projects"], key=lambda x: x["project_name"].lower())
        promoters_sorted = sorted(b_data["legal_promoter_names"])
        localities_sorted = sorted(b_data["localities"])
        aliases_sorted = sorted(b_data["builder_aliases"])[:25]
        builders_list.append({
            "builder_id": b_id,
            "builder_name": b_data["builder_name"],
            "normalized_builder_name": b_data["normalized_builder_name"],
            "builder_aliases": aliases_sorted,
            "is_featured_brand": b_data["is_featured_brand"],
            "project_count": len(projs),
            "legal_promoter_names": promoters_sorted[:15],
            "localities": localities_sorted[:10],
            "project_ids": [x["project_id"] for x in projs],
            "projects": projs,
        })

    builders_list.sort(
        key=lambda b: (
            0 if b["is_featured_brand"] else (1 if b["project_count"] > 1 else 2),
            -b["project_count"],
            b["builder_name"].lower(),
        )
    )
    return builders_list


def chunk_builders_by_size(
    builders_list: List[Dict[str, Any]],
    max_chunk_bytes: int = MAX_CHUNK_BYTES,
    max_builders_per_chunk: int = MAX_BUILDERS_PER_CHUNK,
) -> List[List[Dict[str, Any]]]:
    """Pack builders into chunks guaranteed to fit safely within Firestore's 1 MiB limit."""
    chunks: List[List[Dict[str, Any]]] = []
    current_chunk: List[Dict[str, Any]] = []
    current_bytes = 512  # envelope overhead

    for b in builders_list:
        b_bytes = len(json.dumps(b, ensure_ascii=False).encode("utf-8")) + 4
        if current_chunk and (
            len(current_chunk) >= max_builders_per_chunk
            or (current_bytes + b_bytes) > max_chunk_bytes
        ):
            chunks.append(current_chunk)
            current_chunk = []
            current_bytes = 512
        current_chunk.append(b)
        current_bytes += b_bytes

    if current_chunk:
        chunks.append(current_chunk)
    return chunks


def main() -> int:
    parser = argparse.ArgumentParser(description="HomeSure Canonical Builders Catalogue Uploader")
    parser.add_argument("--dry-run", action="store_true", help="Compute chunks and verify counts without writing to Firestore")
    args = parser.parse_args()

    token = get_firebase_Auth_token()
    print("[Builders] Fetching live `/projects` documents from Cloud Firestore...")
    mask_fields = [
        "project_id",
        "project_name",
        "officialProjectName",
        "normalizedProjectName",
        "projectAliases",
        "promoter_name",
        "officialBuilderName",
        "district",
        "taluk",
        "normalizedTaluk",
        "city",
        "registration_number",
        "acknowledgement_number",
        "project_type",
        "regulatory_status",
        "approved_on_raw",
        "approved_on_iso",
        "proposed_completion_date_raw",
        "proposed_completion_date_iso",
        "project_start_date_iso",
        "counts",
        "towers_summary",
        "summary_metrics",
        "provenance",
    ]
    all_projects = list_firestore_collection_docs("projects", token, mask_fields=mask_fields)
    print(f"[Builders] Loaded {len(all_projects)} live projects from Firestore `/projects`.")

    builders_list = build_builders_catalog_from_projects(all_projects)
    total_projs_grouped = sum(b["project_count"] for b in builders_list)
    deep_cnt = sum(
        1 for b in builders_list for p in b["projects"] if p.get("data_tier") == "deep_extracted"
    )
    cat_cnt = total_projs_grouped - deep_cnt

    print(f"[Builders] Total canonical builders: {len(builders_list)} | Total projects grouped: {total_projs_grouped}")
    print(f"[Builders] Breakdown: deep_extracted={deep_cnt}, catalogue_summary={cat_cnt}")
    print("[Builders] Top 15 builders:")
    for b in builders_list[:15]:
        print(f"  - {b['builder_name']} ({b['builder_id']}): {b['project_count']} projects | legal={b['legal_promoter_names'][:3]}")

    # Explicitly log Sobha & Assetz verification
    for target_id in ("builder_sobha_limited", "builder_assetz_group", "builder_sobha_rani", "builder_pride_group"):
        found = next((b for b in builders_list if b["builder_id"] == target_id), None)
        if found:
            print(f"  [Verify {target_id}]: count={found['project_count']}, sample={[p['project_name'] for p in found['projects'][:5]]}")

    chunks = chunk_builders_by_size(builders_list)
    chunk_ids = [f"_catalog_chunk_{i}" for i in range(1, len(chunks) + 1)]
    now_iso = datetime.datetime.now(datetime.timezone.utc).isoformat()

    meta_payload = {
        "meta_id": "_catalog_meta",
        "schema_version": SCHEMA_VERSION,
        "total_chunks": len(chunks),
        "chunk_ids": chunk_ids,
        "total_builders": len(builders_list),
        "total_projects": total_projs_grouped,
        "deep_extracted_projects": deep_cnt,
        "catalogue_summary_projects": cat_cnt,
        "updated_at": now_iso,
    }

    writes: List[Dict[str, Any]] = [make_firestore_write_op("builders/_catalog_meta", meta_payload)]
    chunk_stats = []

    for c_idx, chunk in enumerate(chunks, start=1):
        chunk_doc_id = f"_catalog_chunk_{c_idx}"
        chunk_payload = {
            "chunk_id": chunk_doc_id,
            "chunk_index": c_idx,
            "total_chunks": len(chunks),
            "builders_count": len(chunk),
            "builders": chunk,
        }
        size_kb = round(len(json.dumps(chunk_payload, ensure_ascii=False).encode("utf-8")) / 1024, 1)
        chunk_stats.append({"chunk_id": chunk_doc_id, "builders_count": len(chunk), "size_kb": size_kb})
        print(f"[Builders] Prepared {chunk_doc_id}: {len(chunk)} builders ({size_kb} KB)")
        if size_kb >= 900:
            raise RuntimeError(f"Chunk {chunk_doc_id} exceeded safety cap ({size_kb} KB >= 900 KB)")
        writes.append(make_firestore_write_op(f"builders/{chunk_doc_id}", chunk_payload))

    # Write individual builder documents for top 100 featured & multi-project builders
    for b in builders_list[:100]:
        writes.append(make_firestore_write_op(f"builders/{b['builder_id']}", b))

    # Clean up any stale excess _catalog_chunk_k docs (e.g. if chunk count previously exceeded len(chunks))
    existing_builder_docs = list_firestore_collection_docs("builders", token, mask_fields=["chunk_id"])
    stale_chunks = []
    for doc in existing_builder_docs:
        doc_id = doc["_doc_id"]
        if doc_id.startswith("_catalog_chunk_") and doc_id not in chunk_ids:
            stale_chunks.append(doc_id)
            writes.append(make_firestore_delete_op(f"builders/{doc_id}"))

    report_out = {
        "mode": "dry_run" if args.dry_run else "live_upload",
        "timestamp": now_iso,
        "meta": meta_payload,
        "chunks": chunk_stats,
        "stale_chunks_deleted": stale_chunks,
        "top_25_builders": [
            {k: b[k] for k in ("builder_id", "builder_name", "project_count", "is_featured_brand", "localities")}
            for b in builders_list[:25]
        ],
    }
    report_path = EXTRACTION_ROOT / "data" / "builders_upload_report.json"
    report_path.write_text(json.dumps(report_out, indent=2), encoding="utf-8")

    if args.dry_run:
        print(f"[Builders] DRY-RUN complete. {len(writes)} ops prepared. Report saved to {report_path}")
        return 0

    committed = 0
    while writes:
        batch = writes[:20]
        writes = writes[20:]
        committed += commit_firestore_writes(batch, token)
        print(f"[Builders] Committed {committed} Firestore writes...")

    print(f"[Builders] Successfully uploaded {len(builders_list)} builders across {len(chunks)} chunks! Report: {report_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
