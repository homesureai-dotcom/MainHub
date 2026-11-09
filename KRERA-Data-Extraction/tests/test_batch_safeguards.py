"""
Unit Tests for Phase 2.1 Batch-Readiness Safeguards (`scripts/detail_batch_safeguards.py`)

Validates:
1. Duplicate-project protection (`deduplicate_catalogue_projects`).
2. Per-project checkpoints across `successful`, `partial`, `failed`, and `identity_unverified`.
3. Idempotent project extraction (repeated successful extraction does not increment attempts or duplicate rows, and is skipped on resume unless `force=True`).
4. Retryable failure policy (`failed` and `partial` are retryable up to `max_attempts`; `successful` and `identity_unverified` are non-retryable).
5. Per-project structured error logs (`detail_extraction_error_logs`).
6. Resume after interruption (`get_resumable_batch_queue`).
"""

from __future__ import annotations

from pathlib import Path

from scripts.detail_batch_safeguards import (
    DetailBatchCoordinator,
    classify_project_extraction_outcome,
    compute_canonical_project_key,
    deduplicate_catalogue_projects,
)
from scripts.discovery_engine import KRERADiscoveryEngine
from scripts.models import DetailExtractionStatus


def test_duplicate_project_protection_and_canonical_keys():
    """Verifies that duplicate catalogue rows (by registration number or ack number) are skipped."""
    records = [
        {
            "reg_no": "PRM/KA/RERA/1251/446/PR/171010/000003",
            "ack_no": "PR/KN/170729/000007",
            "project_name": "Godrej United",
            "page_number": 1,
            "row_order": 1,
        },
        {
            "reg_no": "prm/ka/rera/1251/446/pr/171010/000003",  # Duplicate registration number (case-insensitive)
            "ack_no": "PR/KN/170729/000007",
            "project_name": "Godrej United Duplicate",
            "page_number": 12,
            "row_order": 4,
        },
        {
            "reg_no": "",
            "ack_no": "PR/KN/180101/000555",
            "project_name": "Ack-Only Project",
            "page_number": 2,
            "row_order": 3,
        },
        {
            "reg_no": None,
            "ack_no": "PR/KN/180101/000555",  # Duplicate ack number
            "project_name": "Ack-Only Project Dup",
            "page_number": 9,
            "row_order": 8,
        },
    ]

    dedup = deduplicate_catalogue_projects(records)
    assert len(dedup.unique_records) == 2
    assert len(dedup.duplicate_records_skipped) == 2
    assert dedup.duplicate_records_skipped[0]["first_seen_page"] == 1
    assert dedup.duplicate_records_skipped[1]["first_seen_page"] == 2


def test_checkpoints_idempotency_retries_error_logs_and_resume(tmp_path: Path):
    """Tests all 4 extraction states, idempotency, retry exhaustion, error logs, and resume queue."""
    db_path = tmp_path / "batch_safeguards_test.sqlite"
    coord = DetailBatchCoordinator(sqlite_path=db_path, max_attempts=3)
    engine = KRERADiscoveryEngine(require_identity_verification=True)

    rec_success = {
        "REGISTRATION NO": "PRM/KA/RERA/1251/446/PR/171010/000001",
        "ACKNOWLEDGEMENT NO": "PR/KN/170729/000001",
        "PROJECT NAME": "Project One",
        "vpd_id": "10",
        "page_number": 1,
        "row_order": 1,
    }
    rec_partial = {
        "REGISTRATION NO": "PRM/KA/RERA/1251/446/PR/171010/000002",
        "ACKNOWLEDGEMENT NO": "PR/KN/170729/000002",
        "PROJECT NAME": "Project Two",
        "vpd_id": "20",
        "page_number": 1,
        "row_order": 2,
    }
    rec_failed = {
        "REGISTRATION NO": "PRM/KA/RERA/1251/446/PR/171010/000003",
        "ACKNOWLEDGEMENT NO": "PR/KN/170729/000003",
        "PROJECT NAME": "Project Three",
        "vpd_id": "30",
        "page_number": 1,
        "row_order": 3,
    }
    rec_unverified = {
        "REGISTRATION NO": "PRM/KA/RERA/1251/446/PR/171010/000004",
        "ACKNOWLEDGEMENT NO": "PR/KN/170729/000004",
        "PROJECT NAME": "Project Four",
        "vpd_id": "40",
        "page_number": 1,
        "row_order": 4,
    }

    # 1. Process rec_success -> SUCCESSFUL
    p1 = engine.create_project(rec_success)
    p1 = engine.process_project_details(
        p1,
        {
            "modal_identity": {
                "project_name": "Project One",
                "acknowledgement_number": "PR/KN/170729/000001",
                "registration_number": "PRM/KA/RERA/1251/446/PR/171010/000001",
            },
            "tabs": [
                {
                    "label": "Project Details",
                    "sections": [{"label": "Info", "fields": {"Type": "Residential"}}],
                }
            ],
        },
    )
    cp1 = coord.record_project_outcome(rec_success, p1, "raw/p1.json", "norm/p1.json")
    assert cp1.extraction_status == DetailExtractionStatus.SUCCESSFUL
    assert cp1.is_retryable is False
    assert cp1.attempt_count == 1

    # Idempotency check: re-recording identical successful project does not increment attempt_count
    cp1_again = coord.record_project_outcome(rec_success, p1, "raw/p1.json", "norm/p1.json")
    assert cp1_again.attempt_count == 1
    assert cp1_again.payload_sha256 == cp1.payload_sha256
    assert coord.should_extract_project(rec_success) == (False, "already_successful")
    assert coord.should_extract_project(rec_success, force=True) == (True, "forced_reextraction")

    # 2. Process rec_partial -> PARTIAL (1 tab succeeds, 1 tab fails)
    p2 = engine.create_project(rec_partial)
    p2 = engine.process_project_details(
        p2,
        {
            "modal_identity": {
                "project_name": "Project Two",
                "acknowledgement_number": "PR/KN/170729/000002",
                "registration_number": "PRM/KA/RERA/1251/446/PR/171010/000002",
            },
            "tabs": [
                {
                    "label": "Promoter Details",
                    "sections": [{"label": "Info", "fields": {"Promoter": "ABC Builders"}}],
                },
                {
                    "label": "Project Details",
                    "simulate_failure": True,
                    "error_message": "DOM parse timeout in Project Details",
                },
            ],
        },
    )
    cp2 = coord.record_project_outcome(rec_partial, p2)
    assert cp2.extraction_status == DetailExtractionStatus.PARTIAL
    assert cp2.is_retryable is True
    assert cp2.attempt_count == 1
    assert coord.should_extract_project(rec_partial) == (True, "retryable_failure")

    # 3. Process rec_failed -> FAILED (transport/browser timeout across 3 attempts until max_attempts exhausted)
    cp3_a1 = coord.record_transport_or_browser_failure(
        rec_failed,
        error_stage="modal_wait",
        error_type="TimeoutError",
        error_message="Timed out waiting for #result ul.nav-tabs",
    )
    assert cp3_a1.extraction_status == DetailExtractionStatus.FAILED
    assert cp3_a1.attempt_count == 1
    assert cp3_a1.is_retryable is True

    # Resume queue after interruption should include ONLY rec_partial (retryable) and rec_failed (retryable) and rec_unverified (pending)
    queue_mid, _, skip_mid = coord.get_resumable_batch_queue(
        [rec_success, rec_partial, rec_failed, rec_unverified]
    )
    assert [r["PROJECT NAME"] for r in queue_mid] == ["Project Two", "Project Three", "Project Four"]
    assert skip_mid["already_successful"] == 1

    # Exhaust attempts 2 and 3 for rec_failed
    coord.record_transport_or_browser_failure(
        rec_failed, "modal_wait", "TimeoutError", "Timeout attempt 2"
    )
    cp3_a3 = coord.record_transport_or_browser_failure(
        rec_failed, "modal_wait", "TimeoutError", "Timeout attempt 3"
    )
    assert cp3_a3.attempt_count == 3
    assert cp3_a3.is_retryable is False
    assert coord.should_extract_project(rec_failed) == (False, "max_attempts_exhausted")

    # 4. Process rec_unverified -> IDENTITY_UNVERIFIED (registration number mismatch -> non-retryable)
    p4 = engine.create_project(rec_unverified)
    p4 = engine.process_project_details(
        p4,
        {
            "modal_identity": {
                "project_name": "Project Four",
                "acknowledgement_number": "PR/KN/170729/000004",
                "registration_number": "PRM/KA/RERA/1251/446/PR/171010/999999",  # Mismatch!
            },
            "tabs": [
                {
                    "label": "Project Details",
                    "sections": [{"label": "Info", "fields": {"Type": "Commercial"}}],
                }
            ],
        },
    )
    status4, retry4 = classify_project_extraction_outcome(p4)
    assert status4 == DetailExtractionStatus.IDENTITY_UNVERIFIED
    assert retry4 is False

    cp4 = coord.record_project_outcome(rec_unverified, p4)
    assert cp4.extraction_status == DetailExtractionStatus.IDENTITY_UNVERIFIED
    assert cp4.is_retryable is False
    assert coord.should_extract_project(rec_unverified) == (False, "blocked_identity_unverified")

    # Check status counts and per-project error logs
    counts = coord.get_status_counts()
    assert counts["successful"] == 1
    assert counts["partial"] == 1
    assert counts["failed"] == 1
    assert counts["identity_unverified"] == 1

    failed_logs = coord.get_error_logs(compute_canonical_project_key(rec_failed))
    assert len(failed_logs) == 3
    assert failed_logs[-1]["attempt_number"] == 3
    assert failed_logs[-1]["is_retryable"] == 0
