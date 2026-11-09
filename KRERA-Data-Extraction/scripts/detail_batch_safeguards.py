"""
HomeSure K-RERA Phase 2.1 — Batch-Readiness Safeguards Coordinator

Provides batch-execution safeguards for project-detail extraction without starting
bulk extraction:
1. Per-project checkpoints (`detail_extraction_checkpoints` SQLite table).
2. Idempotent project extraction (SHA-256 payload digest, safe upserts, and skipping
   already `successful` projects unless `force=True`).
3. Retryable failure classification (`failed` and `partial` extractions are retryable up to
   `max_attempts`; `successful` and `identity_unverified` are non-retryable).
4. Per-project structured error logs (`detail_extraction_error_logs` SQLite table).
5. Resume after interruption (`get_resumable_batch_queue`).
6. Duplicate-project protection (`deduplicate_catalogue_projects`).
7. Explicit distinction between `successful`, `partial`, `failed`, and `identity_unverified`
   extraction outcomes.
"""

from __future__ import annotations

import hashlib
import json
import sqlite3
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

from .models import DetailExtractionStatus, Project


@dataclass
class BatchCheckpointRecord:
    """Represents a persisted per-project extraction checkpoint."""

    project_key: str
    registration_number: Optional[str]
    acknowledgement_number: Optional[str]
    project_name: Optional[str]
    portal_detail_element_id: Optional[str]
    catalogue_page_number: Optional[int]
    catalogue_row_order: Optional[int]
    extraction_status: DetailExtractionStatus
    identity_verification_status: Optional[str]
    attempt_count: int
    is_retryable: bool
    payload_sha256: Optional[str]
    raw_output_path: Optional[str]
    normalized_output_path: Optional[str]
    last_error_message: Optional[str]
    updated_at_utc: str


@dataclass
class DeduplicationResult:
    """Summary of catalogue deduplication before batch execution."""

    unique_records: List[Dict[str, Any]] = field(default_factory=list)
    duplicate_records_skipped: List[Dict[str, Any]] = field(default_factory=list)


def compute_canonical_project_key(record: Dict[str, Any]) -> str:
    """Computes a deterministic canonical key for duplicate-project protection.

    Priority:
    1. Normalized Registration Number (if non-empty)
    2. Normalized Acknowledgement Number (if non-empty)
    3. Catalogue `record_key` / `record_unique_key`
    """
    reg = (
        record.get("reg_no")
        or record.get("registration_number")
        or record.get("REGISTRATION NO")
        or ""
    ).strip()
    if reg:
        return f"REG::{reg.upper()}"

    ack = (
        record.get("ack_no")
        or record.get("acknowledgement_number")
        or record.get("ACKNOWLEDGEMENT NO")
        or ""
    ).strip()
    if ack:
        return f"ACK::{ack.upper()}"

    rk = (
        record.get("record_key")
        or record.get("record_unique_key")
        or record.get("vpd_id")
        or ""
    ).strip()
    if rk:
        return f"KEY::{rk}"

    raise ValueError(f"Cannot compute canonical project key for record without identifiers: {record}")


def deduplicate_catalogue_projects(records: List[Dict[str, Any]]) -> DeduplicationResult:
    """Filters duplicate catalogue rows so the same project is never extracted twice in a batch."""
    seen_keys: Dict[str, Dict[str, Any]] = {}
    result = DeduplicationResult()

    for rec in records:
        key = compute_canonical_project_key(rec)
        if key in seen_keys:
            result.duplicate_records_skipped.append(
                {
                    "project_key": key,
                    "duplicate_record": rec,
                    "first_seen_page": seen_keys[key].get("page_number"),
                    "first_seen_row": seen_keys[key].get("row_order"),
                }
            )
            continue
        seen_keys[key] = rec
        result.unique_records.append(rec)

    return result


def classify_project_extraction_outcome(project: Project) -> Tuple[DetailExtractionStatus, bool]:
    """Classifies a processed `Project` into one of the 4 terminal/intermediate states and whether it is retryable.

    Returns `(status, is_retryable_by_nature)`:
    - `IDENTITY_UNVERIFIED`: Identity mismatch or incomplete identity -> non-retryable without manual review (`False`).
    - `SUCCESSFUL`: Identity verified, >=1 visible tab discovered, 0 failed tabs, 0 coverage errors -> non-retryable (`False`).
    - `PARTIAL`: Identity verified, >=1 tab extracted with data/empty, but >=1 tab or section failed -> retryable (`True`).
    - `FAILED`: 0 tabs discovered or all tabs failed -> retryable (`True`).
    """
    if project.identity_verification is not None and not project.identity_verification.is_verified:
        return DetailExtractionStatus.IDENTITY_UNVERIFIED, False

    if project.extraction_status == DetailExtractionStatus.IDENTITY_UNVERIFIED:
        return DetailExtractionStatus.IDENTITY_UNVERIFIED, False

    cov = project.coverage
    if cov.total_tabs_discovered == 0:
        return DetailExtractionStatus.FAILED, True

    if cov.tabs_extraction_failed or cov.errors:
        successful_tabs_count = len(cov.tabs_processed) + len(cov.tabs_present_empty)
        if successful_tabs_count > 0:
            return DetailExtractionStatus.PARTIAL, True
        return DetailExtractionStatus.FAILED, True

    return DetailExtractionStatus.SUCCESSFUL, False


class DetailBatchCoordinator:
    """Manages SQLite checkpoints, idempotency, retry policy, and per-project error logs."""

    def __init__(self, sqlite_path: Path, max_attempts: int = 3):
        self.sqlite_path = Path(sqlite_path)
        self.max_attempts = max_attempts
        self._init_schema()

    def _connect(self) -> sqlite3.Connection:
        conn = sqlite3.connect(str(self.sqlite_path))
        conn.row_factory = sqlite3.Row
        return conn

    def _init_schema(self) -> None:
        self.sqlite_path.parent.mkdir(parents=True, exist_ok=True)
        with self._connect() as conn:
            conn.executescript(
                """
                CREATE TABLE IF NOT EXISTS detail_extraction_checkpoints (
                    project_key TEXT PRIMARY KEY,
                    registration_number TEXT,
                    acknowledgement_number TEXT,
                    project_name TEXT,
                    portal_detail_element_id TEXT,
                    catalogue_page_number INTEGER,
                    catalogue_row_order INTEGER,
                    extraction_status TEXT NOT NULL,
                    identity_verification_status TEXT,
                    attempt_count INTEGER NOT NULL DEFAULT 0,
                    is_retryable INTEGER NOT NULL DEFAULT 1,
                    payload_sha256 TEXT,
                    raw_output_path TEXT,
                    normalized_output_path TEXT,
                    last_error_message TEXT,
                    updated_at_utc TEXT NOT NULL
                );

                CREATE TABLE IF NOT EXISTS detail_extraction_error_logs (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    project_key TEXT NOT NULL,
                    registration_number TEXT,
                    acknowledgement_number TEXT,
                    attempt_number INTEGER NOT NULL,
                    error_stage TEXT NOT NULL,
                    error_type TEXT NOT NULL,
                    error_message TEXT NOT NULL,
                    is_retryable INTEGER NOT NULL,
                    logged_at_utc TEXT NOT NULL
                );

                CREATE INDEX IF NOT EXISTS idx_detail_checkpoints_status
                    ON detail_extraction_checkpoints(extraction_status, is_retryable);

                CREATE INDEX IF NOT EXISTS idx_detail_error_logs_key
                    ON detail_extraction_error_logs(project_key);
                """
            )

    def get_checkpoint(self, project_key: str) -> Optional[BatchCheckpointRecord]:
        """Retrieves the current checkpoint for `project_key`, if any."""
        with self._connect() as conn:
            row = conn.execute(
                "SELECT * FROM detail_extraction_checkpoints WHERE project_key = ?",
                (project_key,),
            ).fetchone()
            if not row:
                return None
            return BatchCheckpointRecord(
                project_key=row["project_key"],
                registration_number=row["registration_number"],
                acknowledgement_number=row["acknowledgement_number"],
                project_name=row["project_name"],
                portal_detail_element_id=row["portal_detail_element_id"],
                catalogue_page_number=row["catalogue_page_number"],
                catalogue_row_order=row["catalogue_row_order"],
                extraction_status=DetailExtractionStatus(row["extraction_status"]),
                identity_verification_status=row["identity_verification_status"],
                attempt_count=int(row["attempt_count"]),
                is_retryable=bool(row["is_retryable"]),
                payload_sha256=row["payload_sha256"],
                raw_output_path=row["raw_output_path"],
                normalized_output_path=row["normalized_output_path"],
                last_error_message=row["last_error_message"],
                updated_at_utc=row["updated_at_utc"],
            )

    def should_extract_project(self, record: Dict[str, Any], force: bool = False) -> Tuple[bool, str]:
        """Determines whether a project should be extracted in the current run.

        - If `force=True`, always returns `(True, "forced_reextraction")`.
        - If no checkpoint exists or status is `pending`, returns `(True, "pending_initial_extraction")`.
        - If status is `successful`, returns `(False, "already_successful")`.
        - If status is `identity_unverified`, returns `(False, "blocked_identity_unverified")`.
        - If status is `failed` or `partial`:
          - Returns `(True, "retryable_failure")` if `is_retryable` and `attempt_count < max_attempts`.
          - Returns `(False, "max_attempts_exhausted")` otherwise.
        """
        if force:
            return True, "forced_reextraction"

        key = compute_canonical_project_key(record)
        cp = self.get_checkpoint(key)
        if cp is None or cp.extraction_status == DetailExtractionStatus.PENDING:
            return True, "pending_initial_extraction"

        if cp.extraction_status == DetailExtractionStatus.SUCCESSFUL:
            return False, "already_successful"

        if cp.extraction_status == DetailExtractionStatus.IDENTITY_UNVERIFIED:
            return False, "blocked_identity_unverified"

        if cp.is_retryable and cp.attempt_count < self.max_attempts:
            return True, "retryable_failure"

        return False, "max_attempts_exhausted"

    def record_project_outcome(
        self,
        record: Dict[str, Any],
        project: Project,
        raw_output_path: Optional[str] = None,
        normalized_output_path: Optional[str] = None,
    ) -> BatchCheckpointRecord:
        """Idempotently records the extraction checkpoint and any errors for a processed `Project`."""
        key = compute_canonical_project_key(record)
        existing = self.get_checkpoint(key)

        status, retryable_by_nature = classify_project_extraction_outcome(project)
        project.extraction_status = status

        # Compute deterministic SHA-256 digest of normalized tabs + identity verification
        digest_payload = {
            "registration_number": project.registration_number,
            "acknowledgement_number": project.acknowledgement_number,
            "extraction_status": status.value,
            "tabs": {k: v.model_dump(mode="json") for k, v in project.tabs.items()},
        }
        payload_sha256 = hashlib.sha256(
            json.dumps(digest_payload, sort_keys=True, default=str).encode("utf-8")
        ).hexdigest()

        # Idempotency check: if already successful with the exact same payload hash, preserve attempt_count
        if (
            existing is not None
            and existing.extraction_status == DetailExtractionStatus.SUCCESSFUL
            and status == DetailExtractionStatus.SUCCESSFUL
            and existing.payload_sha256 == payload_sha256
        ):
            attempt_count = existing.attempt_count
        else:
            attempt_count = (existing.attempt_count if existing else 0) + 1

        is_retryable = bool(retryable_by_nature and attempt_count < self.max_attempts)
        now_utc = datetime.now(timezone.utc).isoformat()
        iv_status = (
            project.identity_verification.verification_status
            if project.identity_verification
            else None
        )
        last_error = "; ".join(project.coverage.errors) if project.coverage.errors else None

        with self._connect() as conn:
            conn.execute(
                """
                INSERT INTO detail_extraction_checkpoints (
                    project_key,
                    registration_number,
                    acknowledgement_number,
                    project_name,
                    portal_detail_element_id,
                    catalogue_page_number,
                    catalogue_row_order,
                    extraction_status,
                    identity_verification_status,
                    attempt_count,
                    is_retryable,
                    payload_sha256,
                    raw_output_path,
                    normalized_output_path,
                    last_error_message,
                    updated_at_utc
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(project_key) DO UPDATE SET
                    registration_number = excluded.registration_number,
                    acknowledgement_number = excluded.acknowledgement_number,
                    project_name = excluded.project_name,
                    portal_detail_element_id = excluded.portal_detail_element_id,
                    catalogue_page_number = excluded.catalogue_page_number,
                    catalogue_row_order = excluded.catalogue_row_order,
                    extraction_status = excluded.extraction_status,
                    identity_verification_status = excluded.identity_verification_status,
                    attempt_count = excluded.attempt_count,
                    is_retryable = excluded.is_retryable,
                    payload_sha256 = excluded.payload_sha256,
                    raw_output_path = excluded.raw_output_path,
                    normalized_output_path = excluded.normalized_output_path,
                    last_error_message = excluded.last_error_message,
                    updated_at_utc = excluded.updated_at_utc
                """,
                (
                    key,
                    project.registration_number,
                    project.acknowledgement_number,
                    project.project_name,
                    str(record.get("vpd_id")) if record.get("vpd_id") is not None else None,
                    record.get("page_number"),
                    record.get("row_order"),
                    status.value,
                    iv_status,
                    attempt_count,
                    1 if is_retryable else 0,
                    payload_sha256,
                    raw_output_path,
                    normalized_output_path,
                    last_error,
                    now_utc,
                ),
            )

            # Log per-project errors if status is not SUCCESSFUL
            if status != DetailExtractionStatus.SUCCESSFUL:
                err_stage = (
                    "identity_verification"
                    if status == DetailExtractionStatus.IDENTITY_UNVERIFIED
                    else "tab_or_section_parsing"
                )
                for err_msg in project.coverage.errors or [f"Project ended in status '{status.value}'"]:
                    conn.execute(
                        """
                        INSERT INTO detail_extraction_error_logs (
                            project_key,
                            registration_number,
                            acknowledgement_number,
                            attempt_number,
                            error_stage,
                            error_type,
                            error_message,
                            is_retryable,
                            logged_at_utc
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """,
                        (
                            key,
                            project.registration_number,
                            project.acknowledgement_number,
                            attempt_count,
                            err_stage,
                            status.value,
                            err_msg,
                            1 if is_retryable else 0,
                            now_utc,
                        ),
                    )

        return self.get_checkpoint(key)  # type: ignore[return-value]

    def record_transport_or_browser_failure(
        self,
        record: Dict[str, Any],
        error_stage: str,
        error_type: str,
        error_message: str,
        retryable: bool = True,
    ) -> BatchCheckpointRecord:
        """Records a browser/modal timeout or transport exception before a `Project` model can be built."""
        key = compute_canonical_project_key(record)
        existing = self.get_checkpoint(key)
        attempt_count = (existing.attempt_count if existing else 0) + 1
        is_retryable = bool(retryable and attempt_count < self.max_attempts)
        now_utc = datetime.now(timezone.utc).isoformat()

        reg = record.get("reg_no") or record.get("registration_number") or record.get("REGISTRATION NO")
        ack = record.get("ack_no") or record.get("acknowledgement_number") or record.get("ACKNOWLEDGEMENT NO")
        pname = record.get("project_name") or record.get("PROJECT NAME")

        with self._connect() as conn:
            conn.execute(
                """
                INSERT INTO detail_extraction_checkpoints (
                    project_key,
                    registration_number,
                    acknowledgement_number,
                    project_name,
                    portal_detail_element_id,
                    catalogue_page_number,
                    catalogue_row_order,
                    extraction_status,
                    identity_verification_status,
                    attempt_count,
                    is_retryable,
                    payload_sha256,
                    raw_output_path,
                    normalized_output_path,
                    last_error_message,
                    updated_at_utc
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(project_key) DO UPDATE SET
                    extraction_status = excluded.extraction_status,
                    attempt_count = excluded.attempt_count,
                    is_retryable = excluded.is_retryable,
                    last_error_message = excluded.last_error_message,
                    updated_at_utc = excluded.updated_at_utc
                """,
                (
                    key,
                    reg,
                    ack,
                    pname,
                    str(record.get("vpd_id")) if record.get("vpd_id") is not None else None,
                    record.get("page_number"),
                    record.get("row_order"),
                    DetailExtractionStatus.FAILED.value,
                    None,
                    attempt_count,
                    1 if is_retryable else 0,
                    None,
                    None,
                    None,
                    error_message,
                    now_utc,
                ),
            )
            conn.execute(
                """
                INSERT INTO detail_extraction_error_logs (
                    project_key,
                    registration_number,
                    acknowledgement_number,
                    attempt_number,
                    error_stage,
                    error_type,
                    error_message,
                    is_retryable,
                    logged_at_utc
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    key,
                    reg,
                    ack,
                    attempt_count,
                    error_stage,
                    error_type,
                    error_message,
                    1 if is_retryable else 0,
                    now_utc,
                ),
            )

        return self.get_checkpoint(key)  # type: ignore[return-value]

    def get_resumable_batch_queue(
        self,
        catalogue_records: List[Dict[str, Any]],
        force: bool = False,
    ) -> Tuple[List[Dict[str, Any]], DeduplicationResult, Dict[str, int]]:
        """Builds an ordered, deduplicated queue of projects that need initial extraction or retry after interruption."""
        dedup = deduplicate_catalogue_projects(catalogue_records)
        queue: List[Dict[str, Any]] = []
        skip_reasons: Dict[str, int] = {
            "duplicate_catalogue_records": len(dedup.duplicate_records_skipped),
        }

        for rec in dedup.unique_records:
            should_run, reason = self.should_extract_project(rec, force=force)
            if should_run:
                queue.append(rec)
            else:
                skip_reasons[reason] = skip_reasons.get(reason, 0) + 1

        return queue, dedup, skip_reasons

    def get_error_logs(self, project_key: Optional[str] = None) -> List[Dict[str, Any]]:
        """Returns structured error logs, optionally filtered by `project_key`."""
        with self._connect() as conn:
            if project_key:
                rows = conn.execute(
                    "SELECT * FROM detail_extraction_error_logs WHERE project_key = ? ORDER BY id ASC",
                    (project_key,),
                ).fetchall()
            else:
                rows = conn.execute(
                    "SELECT * FROM detail_extraction_error_logs ORDER BY id ASC"
                ).fetchall()
            return [dict(r) for r in rows]

    def get_status_counts(self) -> Dict[str, int]:
        """Returns counts of checkpoints grouped by `extraction_status`."""
        counts = {s.value: 0 for s in DetailExtractionStatus}
        with self._connect() as conn:
            rows = conn.execute(
                """
                SELECT extraction_status, COUNT(*) AS cnt
                FROM detail_extraction_checkpoints
                GROUP BY extraction_status
                """
            ).fetchall()
            for r in rows:
                counts[r["extraction_status"]] = int(r["cnt"])
        return counts
