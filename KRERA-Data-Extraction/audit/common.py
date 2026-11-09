"""Shared read-only helpers for the Phase 3C independent audit.

Every function here only READS persisted artifacts. Nothing in this package writes to
data/batch_phase3a, data/batch_phase3b, data/batch_phase3c or the SQLite databases.
Audit outputs are written only to reports/ (new files).
"""
from __future__ import annotations

import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Iterator, List, Tuple

ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

P3C = ROOT / "data" / "batch_phase3c"
P3C_RAW = P3C / "raw"
P3C_NORM = P3C / "normalized"
REPORTS = ROOT / "reports"
SQLITE_CUM = ROOT / "data" / "k_rera_extraction.sqlite"
SQLITE_P3C = P3C / "phase3c_checkpoints.sqlite"
P3A_MANIFEST = ROOT / "data" / "batch_phase3a" / "phase3a_selected_25_manifest.json"
P3B_MANIFEST = ROOT / "data" / "batch_phase3b" / "phase3b_selected_100_manifest.json"
P3C_MANIFEST = P3C / "phase3c_manifest.json"


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def jload(path: Path) -> Any:
    return json.loads(Path(path).read_text(encoding="utf-8"))


def jdump(path: Path, obj: Any) -> None:
    path = Path(path)
    if path.exists():
        raise FileExistsError(f"Refusing to overwrite existing file: {path}")
    path.write_text(json.dumps(obj, indent=2, ensure_ascii=False, default=str), encoding="utf-8")


def sha256_file(path: Path) -> str:
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def manifest_projects() -> List[Dict[str, Any]]:
    return jload(P3C_MANIFEST)["selected_projects"]


def project_files(proj: Dict[str, Any]) -> Tuple[Path, Path]:
    prefix = proj["file_prefix"]
    return P3C_RAW / f"{prefix}_raw.json", P3C_NORM / f"{prefix}_normalized.json"


def iter_sections(sections: List[Dict[str, Any]], path: Tuple[str, ...] = ()) -> Iterator[Tuple[Dict[str, Any], Tuple[str, ...]]]:
    for sec in sections or []:
        p = path + (sec.get("section_label", ""),)
        yield sec, p
        yield from iter_sections(sec.get("subsections") or [], p)


def iter_norm_sections(norm: Dict[str, Any], scope: str = "all") -> Iterator[Tuple[str, str, Dict[str, Any], Tuple[str, ...]]]:
    """Yields (container, tab_label, section, path). container is 'tab' or 'unlinked'."""
    if scope in ("all", "tabs"):
        for tab in (norm.get("tabs") or {}).values():
            for sec, p in iter_sections(tab.get("sections") or []):
                yield "tab", tab.get("tab_label", ""), sec, p
            subs = tab.get("sub_tabs") or []
            subs = list(subs.values()) if isinstance(subs, dict) else subs
            for st in subs:
                if not isinstance(st, dict):
                    continue
                for sec, p in iter_sections(st.get("sections") or []):
                    yield "tab", tab.get("tab_label", ""), sec, p
    if scope in ("all", "unlinked"):
        for key, pane in (norm.get("unlinked_dom_panes") or {}).items():
            for sec, p in iter_sections(pane.get("sections") or []):
                yield "unlinked", f"{key}|{pane.get('tab_label','')}", sec, p


def has_real_link(doc: Dict[str, Any]) -> bool:
    """Same definition as KRERADiscoveryEngine._compute_document_coverage_metrics (re-implemented independently)."""
    su = doc.get("source_url")
    return bool(doc.get("document_identifier") or (su and not su.endswith("DOC_ID=")))
