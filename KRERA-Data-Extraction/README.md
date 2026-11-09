# K-RERA Data Extraction Pipeline

Reliable, auditable Karnataka Real Estate Regulatory Authority (K-RERA) project catalogue for HomeSure.

---

## 1. Project Objective

Build an automated, resilient, and fully auditable data ingestion pipeline that extracts, parses, validates, and stores official K-RERA project records into the HomeSure property database. The goal is complete visibility into registered real estate projects, promoter entities, approvals, statutory timelines, and regulatory filings.

## 2. Current Phase: Phase 1 — Portal Reconnaissance & Architecture

- Map the official portal layout and DOM structure.
- Document pagination, district filters, and record lifecycles.
- Establish the discovery-driven ingestion architecture and data contracts.
- Validate extraction behavior across heterogeneous project structures.

> **Crucial Rule:** We do NOT implement mass crawlers or hammer government servers during Phase 1. All findings must be systematically documented and verified with primary portal evidence.

## 3. Scope Boundaries & Scope Control

This architectural update maintains strict scope discipline to ensure the Bengaluru Urban pilot is delivered successfully without distraction:

- **State / Territory:** Karnataka, India.
- **Initial Pilot District:** **Bengaluru Urban**
- **Follow-up District:** Bengaluru Rural (post pilot verification)
- **Target Section:** **Applications Approved** (under project/application search)
- **Scope Prioritization:**
  1. Bengaluru Urban catalogue extraction & deduplication.
  2. Stable project identification.
  3. Dynamic tab and section discovery.
  4. Project-level extraction coverage and validation.
  5. Decoupled document feasibility pilot (sample OC, CC, Sanction Plan).
  6. Additional district rollout after pilot validation.
- **Strictly Out of Scope:** Bulk downloading of all PDFs, OCR processing, statewide crawls, database mass-loaders.

## 4. Fundamental Architectural Principle

> [!IMPORTANT]
> **Never assume that every K-RERA project has the same tabs, sections, fields or documents.**

The K-RERA portal's structure is project-dependent:
- Different projects expose completely different sets of tabs (e.g., some have *Completion Details*, others do not).
- Identically named tabs may contain differing sections, tables, or document sets (e.g., one project's *Completion Details* has detailed financials; another contains only a document checklist with dates).
- Some tabs exist in the DOM but are empty (`present_empty`).
- Uploaded document categories and filenames vary unpredictably across projects.

**These variations are inherent characteristics of the portal, not exceptions to be hardcoded around.**

---

## 5. Discovery-Driven Ingestion Engine & Workflow

The pipeline completely replaces fixed-tab sequences with an open, discovery-driven workflow:

$$\text{Project Discovery} \longrightarrow \text{Project Detail Page} \longrightarrow \text{Tab Discovery} \longrightarrow \text{Section Discovery} \longrightarrow \text{Field Discovery} \longrightarrow \text{Extraction} \longrightarrow \text{Validation} \longrightarrow \text{Persistence}$$

### Step A: Project Discovery
- Identify projects from the K-RERA search catalogue (`/projectViewDetails`).
- Preserve official identifiers (`registration_no`, `acknowledgement_no`) and catalogue metadata.
- Maintain a stable, deterministic internal project ID (`KRERA_<reg_no>` or `KRERA_ACK_<ack_no>`).

### Step B: Dynamic Tab Discovery
- On opening a project detail view, dynamically detect all tabs or navigable sections actually exposed.
- Record their visible labels and DOM identifiers.
- Do not mandate any specific tab to exist.
- **Never fail an entire project extraction because a tab is absent.**

### Step C: Dynamic Section and Field Discovery
For every discovered tab:
- Inspect visible sections, tables, key-value pairs, and document links.
- Extract the structures actually presented without imposing a rigid schema.
- Support repeated fields, nested sections, tabular matrices, and document collections.
- Preserve original portal labels verbatim.

### Step D: Extraction, Validation, and Persistence
- Store extracted information against the project and its corresponding tab/section.
- Preserve raw string values alongside normalized types wherever transformation is reliable.
- Record source tab, section, and extraction timestamp for full traceability.
- Isolate tab-level failures so remaining tabs succeed.

---

## 6. Missing-Data & Coverage Semantics

To eliminate ambiguity, the ingestion pipeline enforces 6 explicit states across tabs, sections, and fields:

| State Code | Semantic Definition | Ingestion Rule |
| :--- | :--- | :--- |
| `present_with_data` | Element is present in the DOM and contains populated values | Process, normalize, and persist |
| `present_empty` | Element exists in the DOM but contains no records | Record as empty; **never infer non-compliance or failure** |
| `not_present` | Element was not rendered in the project's detail view | Omit without failure; **never manufacture placeholder records** |
| `not_applicable` | Element is legally or structurally irrelevant for this project type | Flagged based on project classification |
| `not_available` | Element is withheld or masked by portal permissions | Flagged for audit |
| `extraction_failed` | Element was discovered but parsing or network transfer failed | **Never record as empty**; log error and compute coverage drop |

---

## 7. Raw Preservation & Anomaly Handling

- **Raw Value Retention:** Always preserve the raw string rendered in the DOM (`raw_value`) alongside `normalized_value`.
- **No Silent Coercion:** Anomalous or malformed values must never be silently converted into valid types.
  - *Example:* A document approval date displayed as `01-01-0001` or `00-00-0000` is retained as raw `01-01-0001` and flagged with `ANOMALY_MALFORMED_PLACEHOLDER_DATE`.
- **Category-First Documents:** Document categories displayed in the UI are canonical; raw filenames are non-authoritative.
- **Unresolved Conflict Logging:** When different sections contradict each other (e.g., Covid extension date vs. Completion extension flag), both values are preserved and flagged in the Data-Quality Exception Register for manual review.

---

## 8. Extraction Observability & Coverage Metrics

For every project, the engine compiles a `ProjectExtractionCoverage` record to answer 5 fundamental questions:

1. **What information did we find for this project?** (Discovered tabs, captured sections, fields, documents).
2. **Which tabs were actually available?** (Complete list of visible tabs).
3. **Which sections were empty or absent?** (`present_empty` vs. `not_present` breakdown).
4. **What failed to extract?** (Explicit list of `extraction_failed` tabs with errors).
5. **How much of the available portal information was captured?** (Coverage ratio measured strictly against **actually discovered** structures, not a rigid expected tab list).

---

## 9. Conceptual Data Model

Implemented in Python (`scripts/models.py`) with Pydantic v2:

```text
[ Project ]
  ├── internal_id
  ├── registration_number
  ├── acknowledgement_number
  ├── project_name, promoter_name, district, status
  ├── catalogue_source_info
  ├── coverage: ProjectExtractionCoverage
  └── tabs: Dict[str, ProjectTabObservation]
        ├── tab_label, tab_identifier, observation_state
        └── sections: List[SectionObservation]
              ├── section_label, section_type, observation_state
              ├── fields: List[FieldObservation]
              │     ├── field_label, raw_value, normalized_value, anomaly_flags
              ├── table_rows: List[Dict[str, Any]]
              └── documents: List[DocumentObservation]
                    ├── document_category, displayed_filename, source_url
                    └── approval_date_raw, anomaly_flags, file_metadata
```

---

## 10. Technical Restrictions & Data Governance

- **No Security Bypasses:** Do not bypass CAPTCHA, authentication, rate limits, or anti-bot protections.
- **Respect In-Page Controls:** The portal blocks in-page `F12` with a security modal; we do NOT circumvent or suppress this.
- **Mandatory PII Exclusion:**
  - **Strictly EXCLUDE:** PAN Numbers, personal addresses, identity cards, and photographs of signatories and members.
  - **Include:** Corporate names, registration numbers, project specifications, locations, and statutory filings.
- **No Aggressive Requests:** Sequential, rate-limited requests only. Never hammer government servers.
- **Decoupled Document Workstream:** Document ingestion is isolated from tabular catalogue extraction. Zero bulk downloading.

---

## 11. Project Structure & Codebase

```text
KRERA-Data-Extraction/
├── research/
│   ├── portal-observations.md    # Reconnaissance findings & exception registers
│   ├── network-analysis.md       # DevTools status ([BLOCKED]) & protocol notes
│   ├── field-inventory.md        # Dynamic schema & document evaluation contracts
│   └── screenshots/              # Evidence screenshots
├── scripts/
│   ├── __init__.py
│   ├── models.py                 # Dynamic discovery data model & coverage metrics
│   └── discovery_engine.py       # Discovery-driven ingestion engine
├── tests/
│   ├── test_dynamic_discovery.py # Pytest suite covering all 6 heterogeneous scenarios
│   └── .gitkeep
├── data/
│   ├── raw/
│   └── processed/
├── logs/
├── .gitignore
└── README.md
```

---

## 12. Milestones & Implementation Roadmap

- [x] **Milestone 1:** Project initialization and research structure setup.
- [x] **Milestone 2:** Results grid audit (`/projectViewDetails`), pagination testing, and field cataloging.
- [x] **Milestone 3 (Blocked):** In-page DevTools network audit (`[BLOCKED]` due to in-page security modal).
- [x] **Milestone 4:** Dynamic discovery architecture design, data modeling, and engine implementation.
- [x] **Milestone 5:** Comprehensive test suite for heterogeneous project structures (8/8 tests passing).
- [ ] **Milestone 6:** Document Ingestion Feasibility Pilot (OC, CC, Sanction Plan non-sensitive sample audit).
- [ ] **Milestone 7:** Bengaluru Urban catalogue extraction POC using the discovery engine.
- [ ] **Milestone 8:** Expansion to Bengaluru Rural post pilot validation.
