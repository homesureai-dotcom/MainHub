# HomeSure K-RERA — Phase 3D Final Extraction & Quality Assurance Report (500-Project Controlled Batch)

> **Single Source of Truth Notice:** Every count, distribution, and metric in this report is computed programmatically from persisted JSON and SQLite artifacts in `data/batch_phase3d/` and `reports/`. Zero LLM calls were used during extraction or aggregation.

## Executive Summary & 27 Mandatory Metrics (Section 15)

| # | Metric / Requirement | Verified Value | Source Artifact |
|---:|---|---|---|
| 1 | **Selected manifest count** | `500` (SHA-256: `be0f0a3c9f21c976...`) | `data/batch_phase3d/phase3d_manifest.json` |
| 2 | **Projects attempted** | `500` (`500` extracted in run, `0` resumed) | `reports/phase3d_batch_summary.json` |
| 3 | **Successful extractions** | `500` | `reports/phase3d_batch_summary.json` |
| 4 | **Partial extractions** | `0` | `reports/phase3d_batch_summary.json` |
| 5 | **Failed extractions** | `0` | `reports/phase3d_batch_summary.json` |
| 6 | **Identity-unverified projects** | `0` (`500 / 500` verified) | `data/batch_phase3d/phase3d_identity_validation.json` |
| 7 | **Skipped projects (idempotent resume)** | `0` | `reports/phase3d_batch_summary.json` |
| 8 | **Duplicate exclusions** | `375` historical (`25` Phase 3A + `100` Phase 3B + `250` Phase 3C) + `0` within-batch duplicates | `data/batch_phase3d/phase3d_exclusion_report.json` |
| 9 | **Catalogue reconciliation** | `4,459` total: `3,719` eligible unprocessed (pre-3D), `375` already processed (`3A–3C`), `365` non-APPROVED | `data/batch_phase3d/phase3d_catalogue_reconciliation.json` |
| 10 | **Remaining eligible inventory (pre-Phase 3D)** | `3,719` eligible `APPROVED` projects | `data/batch_phase3d/phase3d_remaining_eligible_inventory.json` |
| 11 | **Page-band distribution** | Early: `166`, Middle: `168`, Late: `166` | `data/batch_phase3d/phase3d_selection_report.json` |
| 12 | **Project-type distribution** | Residential/Group Housing: `313`, Plotted Development: `120`, Mixed Development: `47`, Commercial: `20` | `data/batch_phase3d/phase3d_selection_report.json` |
| 13 | **Promoter diversity** | `496` distinct promoters across `500` projects | `data/batch_phase3d/phase3d_selection_report.json` |
| 14 | **Approval-year distribution** | `10` distinct approval years (`2017`–`2026`) | `data/batch_phase3d/phase3d_selection_report.json` |
| 15 | **Navigation schemas** | `13` distinct visible tab schemas across `11` distinct tab types | `data/batch_phase3d/phase3d_coverage_report.json` |
| 16 | **Sections and fields extracted** | `20,483` sections, `72,113` fields, `146,903` table rows | `data/batch_phase3d/phase3d_coverage_report.json` |
| 17 | **Unlinked panes** | `6` distinct signatures (`490` projects with data); label sources: `{'dom_comment_or_inner_heading': 2198}` | `data/batch_phase3d/phase3d_coverage_report.json` |
| 18 | **Document accounting (reconciled)** | `50880 (unique) + 0 (duplicates) + 6404 (unavailable) = 57284 (total visible records)`; downloadable links: `50,880`; placeholder anomaly tags (subset of linked/unavail, not additive): `3,646`; unlinked-pane docs: `2,200` | `data/batch_phase3d/phase3d_document_reconciliation.json` |
| 19 | **PII exclusions and scan results** | `13,570` PII items redacted; `1000` files scanned post-extraction with **`0` PII leaks** | `data/batch_phase3d/phase3d_pii_audit.json` |
| 20 | **Automated comparison coverage** | `496 / 500` passed; `8,776` fields compared (`12.17%` of extracted; `8,693` exact, `79` whitespace-only, `4` semantic mismatches) | `data/batch_phase3d/phase3d_live_dom_comparisons.json` |
| 21 | **Human QA results** | `25` projects reviewed against captured DOM + persisted files (`review_method = previously_captured_dom_and_persisted_extraction_files_review`, `live_portal_human_browsing_performed = False`) | `data/batch_phase3d/phase3d_human_qa.json` |
| 22 | **Raw/normalized integrity** | `100%` tab/pane parity (`3728` tabs, `2198` unlinked panes), `0` fabricated items, `687` conflicts preserved | `data/batch_phase3d/phase3d_raw_normalized_integrity.json` |
| 23 | **Checkpoint and retry statistics** | Phase 3D SQLite: `{'pending': 0, 'successful': 500, 'partial': 0, 'failed': 0, 'identity_unverified': 0}`; retry queue count: `0` | `data/batch_phase3d/phase3d_checkpoints.sqlite` & `phase3d_retry_queue.json` |
| 24 | **Portal interruptions** | `0` (`interrupted = False`) | `data/batch_phase3d/phase3d_error_log.json` |
| 25 | **Known limitations** | No document binary downloads in Phase 3D; Early & Late Commercial strata had `0` remaining projects (`59/59` already extracted in 3A–3C or Middle); live-DOM comparison is a bounded spot-check (`20` KV pairs/project max). | Section 6 below |
| 26 | **Cumulative Phase 3A–3D totals** | **`875`** unique successful projects (`25` Phase 3A + `100` Phase 3B + `250` Phase 3C + `500` Phase 3D) | `data/k_rera_extraction.sqlite` |
| 27 | **Remaining eligible project count (post-Phase 3D)** | **`3,219`** remaining eligible `APPROVED` projects in Bengaluru Urban (`4,094 - 875`) | `data/batch_phase3d/phase3d_catalogue_reconciliation.json` |

---

## 1. Catalogue Reconciliation & Stratified 500-Project Selection (Sections 4 & 5)

| Band | Residential/Group Housing | Plotted Development | Mixed Development | Commercial | Total Selected |
|---|---:|---:|---:|---:|---:|
| **Early (Pages 1–100)** | `126` | `25` | `15` | `0` *(all 30 extracted in 3A–3C)* | `166` |
| **Middle (Pages 101–300)** | `84` | `40` | `24` | `20` | `168` |
| **Late (Pages 301–446)** | `103` | `55` | `8` | `0` *(all 29 extracted in 3A–3C)* | `166` |
| **Total** | **`313`** | **`120`** | **`47`** | **`20`** | **`500`** |

### Approval-Year Distribution (`2017–2026`)

| Approval Year | Project Count |
|---|---:|
| `2017` | `110` |
| `2018` | `66` |
| `2019` | `39` |
| `2020` | `35` |
| `2021` | `30` |
| `2022` | `42` |
| `2023` | `39` |
| `2024` | `40` |
| `2025` | `51` |
| `2026` | `48` |

---

## 2. Internal 20 x 25 Sub-Batch Controlled Execution Summary (Section 11)

| Sub-Batch | Projects Range | Projects Count | Successful | Identity Unverified | Duplicates | Cross-Contamination | Doc Accounting OK | PII Files Scanned | PII Leaks | Validation |
|---:|---|---:|---:|---:|---:|---:|---|---|---:|---|
| `01/20` | `001–025` | `25` | `25` | `0` | `0` | `0` | `True` | `50` | `0` | `PASSED` |
| `02/20` | `026–050` | `25` | `25` | `0` | `0` | `0` | `True` | `50` | `0` | `PASSED` |
| `03/20` | `051–075` | `25` | `25` | `0` | `0` | `0` | `True` | `50` | `0` | `PASSED` |
| `04/20` | `076–100` | `25` | `25` | `0` | `0` | `0` | `True` | `50` | `0` | `PASSED` |
| `05/20` | `101–125` | `25` | `25` | `0` | `0` | `0` | `True` | `50` | `0` | `PASSED` |
| `06/20` | `126–150` | `25` | `25` | `0` | `0` | `0` | `True` | `50` | `0` | `PASSED` |
| `07/20` | `151–175` | `25` | `25` | `0` | `0` | `0` | `True` | `50` | `0` | `PASSED` |
| `08/20` | `176–200` | `25` | `25` | `0` | `0` | `0` | `True` | `50` | `0` | `PASSED` |
| `09/20` | `201–225` | `25` | `25` | `0` | `0` | `0` | `True` | `50` | `0` | `PASSED` |
| `10/20` | `226–250` | `25` | `25` | `0` | `0` | `0` | `True` | `50` | `0` | `PASSED` |
| `11/20` | `251–275` | `25` | `25` | `0` | `0` | `0` | `True` | `50` | `0` | `PASSED` |
| `12/20` | `276–300` | `25` | `25` | `0` | `0` | `0` | `True` | `50` | `0` | `PASSED` |
| `13/20` | `301–325` | `25` | `25` | `0` | `0` | `0` | `True` | `50` | `0` | `PASSED` |
| `14/20` | `326–350` | `25` | `25` | `0` | `0` | `0` | `True` | `50` | `0` | `PASSED` |
| `15/20` | `351–375` | `25` | `25` | `0` | `0` | `0` | `True` | `50` | `0` | `PASSED` |
| `16/20` | `376–400` | `25` | `25` | `0` | `0` | `0` | `True` | `50` | `0` | `PASSED` |
| `17/20` | `401–425` | `25` | `25` | `0` | `0` | `0` | `True` | `50` | `0` | `PASSED` |
| `18/20` | `426–450` | `25` | `25` | `0` | `0` | `0` | `True` | `50` | `0` | `PASSED` |
| `19/20` | `451–475` | `25` | `25` | `0` | `0` | `0` | `True` | `50` | `0` | `PASSED` |
| `20/20` | `476–500` | `25` | `25` | `0` | `0` | `0` | `True` | `50` | `0` | `PASSED` |

---

## 3. Reconciled Document Accounting (Section 8)

- **Partition Equation:** `50880 (unique) + 0 (duplicates) + 6404 (unavailable) = 57284 (total visible records)`
- **Visible Tabs Total Document Records:** `57,284`
- **Unique Linked Document Observations:** `50,880`
- **Downloadable Document Links:** `50,880`
- **Duplicate Document Observations:** `0`
- **Unavailable Document Slots (`not_available` / `not_applicable`):** `6,404`
- **Placeholder Filename Anomaly Tags (Subset Overlap, Not Additive):** `3,646` (`3,646` inside linked observations, `0` inside unavailable slots)
- **Unlinked DOM Panes Documents (Tracked Separately):** `2,200` records (`2,091` links)

---

## 4. Cumulative Progress Across Phases 3A, 3B, 3C, and 3D

| Phase | Target Projects | Unique Successful Projects | Cumulative Unique Successful Projects | Remaining Eligible `APPROVED` Pool |
|---|---:|---:|---:|---:|
| **Phase 3A** | `25` | `25` | `25` | `4,069` |
| **Phase 3B** | `100` | `100` | `125` | `3,969` |
| **Phase 3C** | `250` | `250` | `375` | `3,719` |
| **Phase 3D** | `500` | `500` | **`875`** | **`3,219`** |

