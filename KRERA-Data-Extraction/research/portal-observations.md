# Portal Observations — K-RERA Reconnaissance

This document records direct observations of the user interface, navigation pathways, filtering mechanics, pagination behavior, and detail page layouts on the official [Karnataka RERA Portal](https://rera.karnataka.gov.in/).

> **Note on Methodology:** All observations below are derived strictly from direct user-supplied portal screenshots. They represent surface UI observations and do NOT constitute proof of the underlying backend API architecture, database integrity, or complete dataset.

---

## Status Legend

- `[VERIFIED]`: Directly observed and validated on the live portal via screenshot or primary portal UI evidence.
- `[UNVERIFIED]`: Mentioned in requirements or initial discussions, not yet independently checked.
- `[ASSUMPTION]`: An interpretation or hypothesis that still needs empirical validation.
- `[BLOCKED]`: Cannot currently be investigated (e.g., portal down, access denied).

---

## Investigation Checklist

### Section A: Portal Navigation
- [x] Identify the project application view page: **`/projectViewDetails`** `[VERIFIED]`
- [x] Record page heading/breadcrumb: **`Home / Project Applications`** `[VERIFIED]`
- [ ] Identify the top-level menu path leading to `/projectViewDetails` `[UNVERIFIED - Needs live check]`
- [ ] Identify all available status tabs (e.g., "Applications Applied For Registration", "Applications Approved", etc.) `[PARTIALLY OBSERVED]`
- [x] District filter / display confirmed: **`BENGALURU URBAN`** is present in record rows `[VERIFIED]`
- [ ] Determine how Bengaluru Urban filter is selected in the UI (`<select>`, AJAX, autocomplete) `[UNVERIFIED]`
- [ ] Record URL before and after applying filters `[UNVERIFIED]`

### Section B: Results and Pagination
- [x] Identify all visible table/grid columns in the results list `[VERIFIED]`
- [x] Record displayed result count for current view: **4,459 entries** (446 pages) `[VERIFIED - Tab context unresolved]`
- [x] Determine records per page: **10 records per page** on Page 1 `[VERIFIED]`
- [x] Inspect pagination controls: **First, Previous, numbered page links, Next, Last** `[VERIFIED]`
- [x] Test navigation to Page 2 and Last page `[VERIFIED]`
- [x] Check whether page navigation changes the browser URL: **Browser URL remains `/projectViewDetails` (no query params or hash)** `[VERIFIED]`
- [x] Compare records between pages: **Page 2 and Last page display different project names and Ack/Reg numbers compared with Page 1** `[VERIFIED]`
- [ ] Determine underlying pagination mechanism: **Unknown (no assumption of AJAX, ASP.NET postback, or client-side slicing without network evidence)** `[UNVERIFIED]`
- [ ] Check whether filters persist across pagination links `[PENDING INVESTIGATION]`

### Section C: Project Detail Pages
- [x] Identify presence of project detail trigger: **"View Project Details"** column present in grid `[VERIFIED]`
- [x] Open representative project record from "View Project Details" link: **Opens "Project Registration Details" page (Tested on Godrej United)** `[VERIFIED]`
- [x] Identify top-level header fields: **Project Name, Acknowledgement Number, Registration Number** `[VERIFIED]`
- [x] Identify visible tabs on Project Registration Details: **7 tabs identified** `[VERIFIED]`
- [x] Document visible fields in Promoter Details tab `[VERIFIED]`
- [x] Inspect Project Details tab (7 major field groups documented) `[VERIFIED]`
- [ ] Inspect Uploaded Documents tab (categories & file access mechanism) `[PENDING INVESTIGATION]`
- [x] Inspect Quarterly Updates tab (Status: NO DATA OBSERVED ON THE PROJECT PAGE) `[VERIFIED]`
- [x] Inspect Completion Details tab (Dates, financials, unit counts, 14 document categories) `[VERIFIED]`
- [x] Inspect Complaints tab (3 dispute rows logged; allegations vs. findings distinction) `[VERIFIED]`
- [ ] Inspect Enquired Documents tab `[FUTURE SCOPE]`
- [ ] Determine if detail URL contains unique record identifier query parameter or if state is session-bound `[PENDING INVESTIGATION]`

### Section D: Browser Network Inspection
- [x] DevTools via in-page `F12`: **Blocked by in-page modal dialog** `[BLOCKED]`
- [ ] Authorised / passive alternative network inspection `[BLOCKED PENDING ALTERNATIVE]`

### Section E: Document Ingestion Feasibility (Separate Workstream)
- [x] Confirm individual document download functionality via browser: **Confirmed (Direct downloads to local drive observed)** `[VERIFIED]`
- [ ] Inspect Occupancy Certificate (Filename, format, size, category match, association) `[PENDING]`
- [ ] Inspect Commencement Certificate (Filename, format, size, category match, association) `[PENDING]`
- [ ] Inspect Approved Building Plan (Filename, format, size, category match, association) `[PENDING]`
- [ ] Determine link mechanism (Direct static URL vs. session-bound download handler) `[PENDING]`
- [ ] Determine stability of document identifiers across sessions `[PENDING]`
- [ ] Check for official/permitted bulk download mechanisms (Strict rule: No unauthorized bulk crawling) `[PENDING]`

---

## Observation Log

### [VERIFIED] Portal Route, Breadcrumb & District Scope (Screenshot Observation)
- **Date & Time:** 2026-11-04 23:25 IST
- **Portal Section:** Home / Project Applications
- **Target URL Path:** `/projectViewDetails` (Base: `https://rera.karnataka.gov.in/`)
- **District / Filters:** `BENGALURU URBAN` (Displayed in result grid rows)
- **Evidence Reference:** User-provided screenshots (Phase 1 reconnaissance)
- **Observation:**
  - Page breadcrumb is rendered as `Home / Project Applications`.
  - The URL path hosting the table is `/projectViewDetails`.
  - Result records explicitly display `BENGALURU URBAN` in the **District** column.
- **Confidence:** High (Direct UI evidence)
- **Open Questions:**
  - What exact top-level menu hierarchy navigates to `/projectViewDetails`?

---

### [VERIFIED] Results Grid Columns & Schema (Screenshot Observation)
- **Date & Time:** 2026-11-04 23:25 IST
- **Portal Section:** Home / Project Applications (`/projectViewDetails`)
- **District / Filters:** Bengaluru Urban
- **Evidence Reference:** User-provided screenshots
- **Observation:**
  The result table displays the following columns in order:
  1. `S.No` (Row sequence index)
  2. `Acknowledgement No` (Unique application / ack identifier)
  3. `Registration No` (Official RERA registration string or blank/pending for non-approved)
  4. `View Project Details` (Action link/button to access project disclosures)
  5. `Promoter Name` (Entity or developer entity name)
  6. `Project Name` (Marketed or registered name of the project)
  7. `Status` (Application lifecycle state)
  8. `District` (District name, e.g., BENGALURU URBAN)
  9. `Taluk` (Sub-district division)
  10. `Project Type` (e.g., Residential, Commercial, Plotted)
  11. `Approved On` (Approval timestamp/date)
  12. Proposed Completion Date (Partially visible trailing column in the screenshot)
- **Confidence:** High (Direct UI evidence)
- **Open Questions:**
  - What is the exact header text for the partially visible completion date column?
  - Does "View Project Details" initiate an HTTP GET, POST form submit, or JavaScript popup?

---

### [VERIFIED] Result Counts & Pagination Structure (Screenshot Observation)
- **Date & Time:** 2026-11-04 23:25 IST
- **Portal Section:** Home / Project Applications (`/projectViewDetails`)
- **District / Filters:** Bengaluru Urban view
- **Evidence Reference:** User-provided screenshots
- **Observation:**
  - **Total Result Count:** 4,459 entries displayed.
  - **Page Sizing:** 10 records per page.
  - **Total Pages:** 446 pages ($445 \times 10 + 9 = 4,459$).
  - **Pagination Controls:** Full control bar featuring `First`, `Previous`, numbered page links, `Next`, and `Last`.
- **Confidence:** High for visible UI count; context between tabs remains an open question (see below).
- **Open Questions:**
  - See Unresolved Observations section regarding tab association.

---

### [VERIFIED] Sample Records, Status Values & Data Quality Observations (Screenshot Observation)
- **Date & Time:** 2026-11-04 23:25 IST
- **Portal Section:** Home / Project Applications (`/projectViewDetails`)
- **District / Filters:** Bengaluru Urban
- **Evidence Reference:** User-provided screenshots
- **Observation:**
  - **Representative Project Names Identified:**
    - `GODREJ UNITED`
    - `GODREJ AIR`
    - `SOBHA SILICON OASIS PHASE 1`
    - `UNIWORLD RESORTS`
    - `SKY LARK ROYAUME`
    - `CHARTERED HUMMINGBIRD`
    - `SKY ASTA`
    - `MAX 11`
    - `PRESTIGE BOULEVARD`
    - `PRESTIGE KEW GARDENS`
  - **Observed Status Values:**
    - `APPROVED`
    - `TRANSFERRED`
    - `REJECTED`
  - **Data Quality / Exception Note:**
    - One rejected record displays a descriptive rejection remark directly in place of standard registration details:
      > *"YOUR FILE IS REJECTED AS THERE ARE NO DETAILS."*
- **Confidence:** High (Direct UI evidence)
- **Open Questions:**
  - How are rejection reasons structured in the backend schema (separate column, or overload of Registration No / Status column)?

### [BLOCKED] In-Page F12 Developer Tools Restriction
- **Date & Time:** 2026-11-04 23:30 IST
- **Portal Section:** Home / Project Applications (`/projectViewDetails`)
- **Trigger Action:** Pressing `F12` key on the portal.
- **Observed Behavior:**
  - An in-page white modal dialog appears immediately blocking direct interaction.
  - Modal text message: *"Due to security reason, This function has been disabled!!"*
  - The modal renders inside the webpage DOM itself, not as an OS or separate Chrome DevTools window.
- **Technical Analysis `[ASSUMPTION]`:**
  - Likely a client-side JavaScript keyboard event listener intercepting keycode 123 (`F12`).
  - Implementation details remain unverified.
- **Compliance Policy:**
  - In strict compliance with project technical restrictions ("Never defeat or bypass an access control, permission check..."), no attempt will be made to circumvent or suppress this restriction.
  - Direct Network tab logging via in-page F12 is marked as **BLOCKED** pending an authorised alternative.
- **Confidence:** High (Direct UI observation)
- **Open Questions:**
  - Does standard browser UI navigation (clicks, pagination links, anchor tags) suffice for full data access without DevTools?

---

### [VERIFIED] Pagination Experiment (Page 2 & Last Navigation)
- **Date & Time:** 2026-11-04 23:33 IST
- **Portal Section:** Home / Project Applications (`/projectViewDetails`)
- **Trigger Action:** Clicking pagination controls (Page "2", "Last").
- **Observed Behavior:**
  - **Record Differentiation:** Page 2 displays distinctly different project names and acknowledgement / registration numbers compared with Page 1.
  - **Terminal Pagination:** The "Last" pagination control successfully navigates and displays different, terminal records.
  - **URL Behavior:** The browser URL remains strictly `/projectViewDetails` during all pagination interactions (no query parameters e.g., `?page=2`, nor hash `#page2`).
  - **Page Size:** First page displays 10 records.
  - **Total Count Displayed:** Constant at 4,459 entries.
- **Technical Assessment `[UNVERIFIED - NO ASSUMPTION]`:**
  - The underlying transport mechanism for pagination remains **unknown**.
  - **Rule:** Do NOT assume AJAX, ASP.NET postback, full page reload with hidden form states, or client-side dataset slicing without concrete network proof.
- **Confidence:** High (Observed UI behavior)
- **Open Questions:**
  - How are pagination requests initiated at the DOM layer (JavaScript click handlers, `href="javascript:..."`, or form submit)?

---

### [VERIFIED] Project Registration Details Page Layout (Godrej United)
- **Date & Time:** 2026-11-04 23:34 IST
- **Portal Section:** Project Registration Details (via "View Project Details" link on `GODREJ UNITED`)
- **Target URL Path:** To be checked (whether URL path updates or stays on `/projectViewDetails`)
- **Observed Header Summary Fields:**
  - **Project Name:** Explicitly displayed at the top.
  - **Acknowledgement Number:** Explicitly displayed.
  - **Registration Number:** Explicitly displayed.
- **Visible Tab Architecture (7 Distinct Tabs):**
  1. `Promoter Details` (Default active view)
  2. `Project Details`
  3. `Uploaded Documents`
  4. `Enquired Documents`
  5. `Complaints`
  6. `Quarterly Updates`
  7. `Completion Details`
- **Confidence:** High (Direct user verification)
- **Open Questions:**
  - Does clicking through tabs change the URL or load tab contents asynchronously?

---

### [VERIFIED] Promoter Details Tab Schema & PII Observations
- **Date & Time:** 2026-11-04 23:34 IST
- **Portal Section:** Project Registration Details > Promoter Details (`GODREJ UNITED`)
- **Observed Sections and Fields:**
  - `Promoter Type` (e.g., Company, Individual, Partnership)
  - `Promoter/Company Name`
  - `PAN Number` (Permanent Account Number)
  - `Address` (Registered office address)
  - `District`
  - `State/UT`
  - `PIN Code`
  - `Company Registration Number`
  - `Company Registration Certificate link` (Document link/attachment)
  - `Authorised Signatory Details`
  - `Project Member Details`
  - `Project Land Owner Details`
  - `RERA Registration Details with other States/UTs`
  - `Previous Project Details` (Restricted to the last 5 years only)
- **PII & Privacy Findings:**
  - The **Authorised Signatory Details** and **Project Member Details** sections include personal names, residential/contact addresses, and photograph/document links.
- **Confidence:** High (Direct UI verification)

---

## Data Governance & Privacy Boundary (Mandatory Policy)

> [!IMPORTANT]
> **Strict PII Exclusion for HomeSure Project Catalogue**
> In accordance with HomeSure data governance and privacy best practices:
> - **DO NOT collect, extract, or ingest:**
>   - PAN Numbers (promoter, signatory, or land owner).
>   - Personal residential addresses of authorised signatories or project members.
>   - Photographs or identity document scans of individuals.
>   - Any other personally identifiable information (PII) unless an explicit, legally vetted and approved business requirement is established.
> - **Allowed Scope (Catalogue Ingestion):**
>   - Official Project and Promoter entity names.
>   - Corporate Registration Number and corporate office address.
>   - RERA Registration Numbers and Acknowledgement Numbers.
>   - Geographic / project location attributes (District, Taluk, Project Address, PIN code).
>   - Project specifications, timelines, status, and regulatory filings.

---

### [VERIFIED] Project Details Tab Schema & Field Groups (Godrej United)
- **Date & Time:** 2026-11-04 23:36 IST
- **Portal Section:** Project Registration Details > Project Details (`GODREJ UNITED`)
- **Status:** `[VERIFIED]` (Observed portal data transcription; not independently verified legal facts)
- **Observed Field Groups & Values:**
  1. **Registration History:**
     - Registration / Extension Type
     - Start Date: `15-06-2017`
     - Original Proposed Completion Date: `31-05-2021`
     - Covid Extension: `31-05-2021` to `28-02-2022`
     - Certificate / Order link
  2. **Project Identity:**
     - Project Name, Description, Project Type, Project Status
     - Project Start and Proposed Completion Dates
  3. **Land and Project Costs:**
     - Total Land Area
     - Covered Area
     - Open Area
     - Estimated Construction Cost
     - Land Cost
     - Total Project Cost
  4. **Location Details:**
     - Project Address
     - District & Taluk
     - Geographic Boundary Coordinates (Latitude / Longitude bounding box)
     - Sanctioning / Approving Authority
  5. **Development and Inventory:**
     - Garage & Parking counts / areas
     - Inventory Type
     - Inventory Count (Observed: 51 units of 1 BHK)
     - Carpet Area
     - Exclusive Balcony / Verandah Area
     - Exclusive Terrace Area
  6. **External Development Infrastructure:**
     - Road system
     - Water supply
     - Sewage and drainage
     - Electricity
     - Solid waste management
     - Firefighting facilities
     - Drinking water provisions
     - Emergency evacuation
     - Renewable energy installations
  7. **Project Professionals:**
     - Architect
     - Structural Engineer
     - Contractor
     - Entity / organisation details and professional registration identifiers
- **Governance Constraint:** Unnecessary personal addresses and individual PII of professionals must NOT be collected in the initial catalogue.
- **Confidence:** High (Direct portal observation)

---

### [VERIFIED] Quarterly Updates Tab — Absence of Records (Godrej United)
- **Date & Time:** 2026-11-04 23:36 IST
- **Portal Section:** Project Registration Details > Quarterly Updates (`GODREJ UNITED`)
- **Observed Status:** **NO DATA OBSERVED ON THE PROJECT PAGE**
- **Analysis Rule:**
  - Do NOT infer or assume that the promoter never submitted quarterly updates.
  - The absence of data may reflect portal display errors, legacy project migration anomalies, or backend schema decoupling.
- **Confidence:** High (UI display status verified)

---

### [VERIFIED] Completion Details Tab — Execution & Financial Metrics (Godrej United)
- **Date & Time:** 2026-11-04 23:36 IST
- **Portal Section:** Project Registration Details > Completion Details (`GODREJ UNITED`)
- **Observed Milestone & Operational Values:**
  - **Completion Application Date:** `06-05-2022`
  - **Project Start Date:** `15-06-2017`
  - **Project End Date:** `28-02-2022`
  - **Completion Extension Field:** `NO` *(Note: conflicts with Covid extension under Project Details; see Exception List)*
  - **Occupancy Certificate Received:** `YES`
  - **Occupancy Certificate Date:** `09-02-2022`
  - **Total Apartments Sanctioned:** `512`
  - **Apartments Sold:** `512`
  - **Apartments Unsold:** `0`
  - **Completed Within Stipulated Period:** `YES`
  - **Inventory / Specification Changed:** `NO`
  - **As-Built Drawing Approved:** `YES`
- **Observed Financial Disclosures:**
  - **Total Project Cost:** `INR 5,200,000,000` (₹520 Crores)
  - **Amount Collected from Buyers:** `INR 4,788,191,565` (~₹478.8 Crores)
  - **Loan Raised:** `NO`
  - **Amount Spent on Project:** `INR 4,660,153,660` (~₹466.0 Crores)
  - **Balance with Promoter:** `INR 128,037,906` (~₹12.8 Crores)
- **Document Completion Evidence Categories (14 Observed Categories):**
  1. Stability Certificate
  2. Road-cutting Permission
  3. Fire NOC (Final)
  4. Occupancy Certificate (OC)
  5. KSPCB Consent (Pollution Control Board)
  6. Electrical / Lift-related Clearance Certificates
  7. Power Sanction (BESCOM / equivalent)
  8. Water and Sanitary Board Approval (BWSSB)
  9. External Infrastructure Completion
  10. Common Amenities and Association Handover
  11. Undivided Land Share (UDS) Handover
  12. Architect Completion Certificate
  13. CA Completion Certificate (Financials)
  14. Promoter Affidavit & Completion Photographs
- **Confidence:** High (Observed portal data)

---

### [VERIFIED] Complaints Tab — Dispute Allegations & Legal Caution (Godrej United)
- **Date & Time:** 2026-11-04 23:36 IST
- **Portal Section:** Project Registration Details > Complaints (`GODREJ UNITED`)
- **Observed Complaint Records:**
  1. **Filing Date: 10-10-2021**
     - *Subject / Allegation:* Compensation for flat damage.
     - *Status / Disposal:* Disposed by Authority Bench 4.
  2. **Filing Date: 06-02-2024**
     - *Subject / Allegation:* Misrepresentation, concealment of facts, and quality deficiency at handover.
     - *Status / Disposal:* Disposed by Adjudicating Officer.
  3. **Filing Date: 16-02-2026**
     - *Subject / Allegation:* Common amenities not delivered as committed and defective delivery.
     - *Status / Disposal:* Posted for orders.
- **Mandatory Risk & Legal Standard:**
  > [!WARNING]
  > **Complaint subjects are unilateral allegations, not established findings of fault.**
  > Do NOT compute, infer, or assign property risk scores or negative compliance ratings without retrieving and reading the final certified orders and outcomes.

---

## Data-Quality Exception Register

The reconnaissance has uncovered 5 explicit data anomalies that must be handled as edge cases in the data pipeline:

1. **Extension Contradiction:**
   - *Conflict:* Project Details records a Covid extension ending `28-02-2022`, but Completion Details explicitly states `NO` in the completion extension field.
   - *Requirement:* Pipeline reconciliation logic must compare both fields and flag discrepant extension states.
2. **Document Filename Anomalies:**
   - *Issue:* Certain attached document filenames appear to reference unrelated projects or generic internal file paths.
   - *Requirement:* Actual document headers and text must be verified; do not rely purely on filename strings for metadata.
3. **Geographic Coordinate Formatting:**
   - *Issue:* One transcribed west-coordinate value appears anomalous/inconsistent with standard Bengaluru coordinates ($12^\circ\text{N}, 77^\circ\text{E}$).
   - *Requirement:* Source verification and spatial bounds checking ($77.4^\circ - 77.8^\circ\text{E}$, $12.8^\circ - 13.2^\circ\text{N}$) needed before ingesting coordinates.
4. **Unit Inventory Divergence:**
   - *Issue:* Development details show `51 units` of `1 BHK`, whereas Completion Details show `512 apartments`.
   - *Requirement:* Determine whether the inventory table contains multiple paginated rows or multi-type rows (2 BHK, 3 BHK) that require complete tabular extraction.
5. **Missing Progress Records:**
   - *Issue:* Quarterly Updates tab displays no information (`NO DATA OBSERVED ON THE PROJECT PAGE`).
   - *Requirement:* Handlers must treat QPR tables as optional/nullable without breaking project ingestion.

---

## Architecture Evolution: Discovery-Driven Ingestion Engine

> [!IMPORTANT]
> **Fundamental Architectural Principle**
> **Never assume that every K-RERA project has the same tabs, sections, fields, or documents.**
> Portal structures are project-dependent. Some projects contain Completion Details; others do not. Some Completion Details contain financials; others only document dates. Some tabs are empty. The fixed 7-tab assumption is explicitly replaced with a dynamic, discovery-driven engine.

### Discovery Workflow
$$\text{Project Discovery} \longrightarrow \text{Project Detail Page} \longrightarrow \text{Tab Discovery} \longrightarrow \text{Section Discovery} \longrightarrow \text{Field Discovery} \longrightarrow \text{Extraction} \longrightarrow \text{Validation} \longrightarrow \text{Persistence}$$

### Explicit Missing-Data Semantics
To eliminate ambiguity, six observation states are enforced at tab, section, and field levels:
1. `present_with_data`: Element present with populated records.
2. `present_empty`: Element exists in DOM but contains no records (never inferred as failure).
3. `not_present`: Element absent in project view (never synthesized with dummy placeholders).
4. `not_applicable`: Element legally or structurally irrelevant for this project.
5. `not_available`: Element masked or withheld by portal permissions.
6. `extraction_failed`: Element discovered but parsing or network transfer failed (never recorded as empty).

### Coverage & Observability Contract
Every project maintains a `ProjectExtractionCoverage` record tracking:
- Discovered tabs vs. processed vs. present_empty vs. not_present vs. extraction_failed.
- Total sections, fields, and documents discovered.
- Coverage ratio measured strictly against **actually discovered** structures.
- Direct answers to the 5 observability questions (What was found? Which tabs available? Which empty/absent? What failed? What % captured?).

---

## Architecture Implications: Multi-Domain Data Model

To support auditable, resilient extraction without coupling loosely related regulatory disclosures into a brittle single schema, the target pipeline must implement **5 decoupled data domains**:

```text
[ K-RERA Source ]
       │
       ├── 1. Project Registry Domain
       │      (Ack No, Reg No, Project Name, Promoter Name, District, Taluk, Status)
       │
       ├── 2. Registration & Development Domain
       │      (Land Area, Costs, Sanctions, Coordinates, Inventory Breakdown, External Infra)
       │
       ├── 3. Regulatory Documents Domain
       │      (Certificate Links, Sanction Plans, NOCs, Filename Hashes, Storage URIs)
       │
       ├── 4. Complaints & Disputes Domain
       │      (Filing Dates, Allegation Text, Disposal Status, Bench/Officer, Order Links)
       │
       └── 5. Completion & Financial Disclosures Domain
              (OC Received/Date, Apartments Sold/Unsold, Costs, Buyer Collections, Spends)
```

### Ingestion Audit Contract (Every Field)
Every extracted attribute across all domains must preserve:
- `source_url`: Originating page or view
- `retrieval_timestamp`: ISO 8601 UTC timestamp of crawl
- `raw_value`: Unaltered text exactly as rendered in the DOM
- `normalized_value`: Strongly typed value (e.g., Integer, Decimal, ISO Date)
- `verification_state`: `[VERIFIED]`, `[DISCREPANCY_FLAGGED]`, or `[NULL_RECORDED]`

### [VERIFIED] Individual Document Download Functionality & UI Structure
- **Date & Time:** 2026-11-04 23:44 IST
- **Portal Section:** Project Registration Details (All document-enabled tabs)
- **Status:** `[VERIFIED]` (Direct user testing on local machine)
- **Observed UI Structure:**
  - The **Document Category** is presented as an explicit, labelled attribute on the project registration page.
  - A clickable PDF link/icon is rendered directly beside that labelled attribute.
  - **Observed Attribute-to-Link Pairs:**
    - `Occupancy Certificate` → Linked PDF
    - `Commencement Certificate` → Linked PDF
    - `Approved Building / Layout Plan` → Linked PDF
    - `Fire NOC` → Linked PDF
  - Clicking any of these links immediately downloads the associated binary file to the user's local disk.
- **Critical File Naming Observation:**
  - The actual downloaded PDF filenames vary widely across projects and promoters (often reflecting arbitrary promoter-side scan names or internal codes).
  - **The filename is NOT the authoritative document classification.**
- **Critical Data Governance Constraint:**
  - **Zero PII Acquisition:** PAN Card PDFs, personal identity cards, and personal photographs must **NOT** be downloaded or retained in any environment.
- **Confidence:** High (Direct local machine verification)

---

## Workstream: Document Ingestion Feasibility (Decoupled from Catalogue Pipeline)

> [!NOTE]
> **Pipeline Separation Architecture**
> Document ingestion is managed as an independent, downstream workstream. The core HomeSure project catalogue pipeline will extract tabular project metadata first. Document extraction will be scoped, throttled, and audited separately.

### Architecture Decision: Classification & Lineage Model
- **Primary Classification Principle:** Use the portal's explicit **Document Category** as the primary canonical classification key, NOT the underlying filename.
- **Hierarchical Entity Relationship:**
  $$\text{Project} \longrightarrow \text{Document Category} \longrightarrow \text{Source Download Link} \longrightarrow \text{Downloaded File}$$
- **Required Metadata Schema (Per Downloaded Document):**
  1. `project_id`: Internal unique project identifier
  2. `registration_number`: Official K-RERA registration number
  3. `document_category`: Portal UI label (e.g., `Occupancy Certificate`, `Approved Building Plan`)
  4. `original_filename`: Raw filename as delivered by the server / saved by the browser
  5. `source_document_url`: Full download URI / handler path
  6. `file_type`: Extension / MIME type (e.g., `.pdf`, `application/pdf`)
  7. `downloaded_at`: ISO 8601 UTC timestamp of retrieval
  8. `verification_status`: Content validation state (`VERIFIED`, `FLAGGED_MISMATCH`, `PENDING_REVIEW`)
  9. `storage_path`: Internal storage URI (object store / local vault path)

### Strict Document Classification & Validation Rules
- **No Filename-Based Classification:** Never classify or route documents based solely on regex matching of raw filenames.
- **Content Match Verification Required:** Never assume file contents match the displayed portal category without validation.
- **Mismatch Discrepancy Flagging:** If document text or headers contradict the portal's stated category (e.g., a file labeled *Occupancy Certificate* actually contains a *Commencement Certificate* or *Bank Statement*), the file must be tagged as `FLAGGED_MISMATCH` and routed to a queue for manual human review.
- **Preservation of Raw Provenance:** Always preserve the original filename, raw download URL, and raw metadata headers.

### Pilot Sample Investigation (Non-Sensitive Documents Only)
To assess format consistency, file naming stability, and content fidelity without bulk requests, investigate the following 3 non-sensitive regulatory documents for `GODREJ UNITED`:
1. **Occupancy Certificate (OC)**
2. **Commencement Certificate (CC)**
3. **Approved Building / Sanction Plan**

#### Audit Matrix for Sample Documents
| Evaluation Dimension | Parameter / Question | Observation (`GODREJ UNITED` Pilot) |
| :--- | :--- | :--- |
| **Document Category** | Displayed label in UI | *e.g., Occupancy Certificate* |
| **Original Filename** | Raw filename saved by browser | *Record full filename and extension* |
| **File Format & MIME** | File extension and content type | *PDF, JPEG, etc.* |
| **File Size** | Disk size in KB / MB | *Determine payload footprint* |
| **Download Behaviour** | Inline tab view vs. browser download prompt | *Record browser reaction* |
| **Content Match Verification** | Does actual text match category label? | *Check for mislabeled/placeholder uploads* |
| **Project Association** | Does document reference the target project? | *Check for cross-project filename mismatches* |

### Open Technical Architecture Questions (Document Pipeline)
- [ ] **Direct URL vs. Handler:** Are document links static public URLs (e.g., `https://.../uploads/.../plan.pdf`) or routed through an application download handler (e.g., `downloadFile.do?docId=...`)?
- [ ] **Session Binding:** Can a document link be fetched by an external HTTP client without an active browser session cookie?
- [ ] **Identifier Stability:** Are document identifiers persistent and immutable over time, or dynamic per user session?
- [ ] **Repeatability:** Can permitted downloads be repeated reliably across different time windows?
- [ ] **Permitted Bulk Mechanism:** Does K-RERA expose an authorized bulk export or archive endpoint? *(Assumption: No; manual or throttled single-file fetches only).*
- **Strict Compliance Rule:** Zero automated bulk downloading or parallel flood requests. All sample checks must remain manual and minimal during Phase 1.

---

## Important Unresolved Observations & Hypotheses
- **Issue:** The first screenshot visually highlights the **"Applications Applied For Registration"** tab. It is therefore not yet confirmed whether the 4,459 entries represent:
  - Total applications applied for registration in Bengaluru Urban, OR
  - An unfiltered aggregate across multiple statuses, OR
  - The "Applications Approved" view.
- **Action Required:** Interactively click and confirm the active tab state and check if the result count changes when clicking **"Applications Approved"**.

### 2. [UNRESOLVED] Total Statewide vs. District Counts (8,992 vs 4,459)
- **Issue:** The **"Applications Approved"** tab label displays a count badge of **8,992** in the screenshot header.
- **Rule:** Do NOT treat **8,992** as the Bengaluru Urban approved count.
  - Hypothesis: 8,992 may represent total statewide approved projects across all Karnataka districts, or an unfiltered baseline metric.
- **Action Required:** Compare counts before and after district selection.

### 3. [UNRESOLVED] Count Divergence Tracking (4,459 vs ~4,445)
- **Issue:** A count discrepancy exists between reconnaissance checkpoints:
  - **Source A (Project Requirements Meeting, prior date):** Approx. **4,445** entries noted.
  - **Source B (Reconnaissance Screenshot, 2026-11-04):** Exactly **4,459** entries visible (+14 records).
- **Hypothesis:** K-RERA portal is continuously updated with new registrations/decisions, or the earlier meeting observation had slightly different filter parameters applied.
- **Action Required:** Maintain an audit log of total counts with timestamp, active tab, and applied district filters.

### 4. [UNRESOLVED] Verification Plan: Explicit Tab & District Re-query
- **Next Direct Step:** Perform a controlled query on the portal:
  1. Explicitly select tab **"Applications Approved"**.
  2. Explicitly select District **"Bengaluru Urban"**.
  3. Record the resulting total entry count, page count, and verify whether `REJECTED` or `TRANSFERRED` records still appear or if the view restricts purely to `APPROVED`.

---

## Findings Summary Matrix

| Feature / Question | Screenshot Observation | Status | Evidence / Confidence |
| :--- | :--- | :--- | :--- |
| **Portal Path** | `/projectViewDetails` | `[VERIFIED]` | High (Screenshot breadcrumb & URL) |
| **Breadcrumb** | `Home / Project Applications` | `[VERIFIED]` | High |
| **District Field Value** | `BENGALURU URBAN` | `[VERIFIED]` | High (Multiple rows) |
| **Displayed Record Count** | 4,459 entries (446 pages) | `[VERIFIED]` | High (Exact UI string, tab context pending) |
| **Page Size** | 10 records / page | `[VERIFIED]` | High |
| **Pagination Elements** | First, Previous, Page Numbers, Next, Last | `[VERIFIED]` | High |
| **Status Values Seen** | `APPROVED`, `TRANSFERRED`, `REJECTED` | `[VERIFIED]` | High (Rejection reason text observed) |
| **Tab Label Badge** | Applications Approved: 8,992 | `[VERIFIED]` | High (Statewide indicator, not Bengaluru Urban) |
| **Active Tab Context** | "Applications Applied For Registration" highlighted | `[UNRESOLVED]` | Low/Medium — Needs explicit confirmation |
| **Count Delta** | 4,459 (Nov 2026) vs ~4,445 (prior meeting) | `[UNRESOLVED]` | Under audit tracking |
| **Detail Action Mechanism**| "View Project Details" link | `[VERIFIED]` | High (Mechanism: GET/POST unverified) |
| **In-Page DevTools (F12)** | Blocked with modal dialog | `[BLOCKED]` | High (Observed in-page modal: "Due to security reason...") |
| **Pagination URL Change** | URL remains `/projectViewDetails` | `[VERIFIED]` | High (No query params or hash on page 2 / Last) |
| **Page Data Refresh** | Distinct records loaded per page | `[VERIFIED]` | High (Page 2 & Last load distinct project records) |
| **Pagination Transport Mechanism** | Unknown (do not assume AJAX/postback) | `[UNVERIFIED]` | Pending non-intrusive network evidence |
| **Detail Page Sections** | 7 tabs (Promoter, Project, Docs, Complaints, QPRs, etc.) | `[VERIFIED]` | High (Observed on Godrej United detail view) |
| **Promoter PII Exposure** | PAN, Signatory/Member names, personal addresses, photos | `[VERIFIED]` | High (Strictly excluded by Data Governance policy) |
| **Project Details Tab Schema** | 7 field groups (history, identity, land/cost, location, inventory, infra, pros) | `[VERIFIED]` | High (Direct portal observation) |
| **Quarterly Updates Status** | NO DATA OBSERVED ON THE PROJECT PAGE | `[VERIFIED]` | High (No inference on promoter filing behavior) |
| **Completion Disclosures** | Detailed metrics, ₹520Cr cost, ₹478.8Cr buyer funds, OC YES | `[VERIFIED]` | High (Direct portal observation) |
| **Completion Documents** | 14 document categories identified | `[VERIFIED]` | High (Direct portal observation) |
| **Complaints Disclosures** | 3 dispute rows observed (disposed / pending orders) | `[VERIFIED]` | High (Allegations only; no risk score inference) |
| **Extension Data Conflict** | Covid extension vs. Completion Details extension NO | `[VERIFIED]` | High (Flagged in Data-Quality Exception Register) |
| **Document Downloads** | Client-initiated downloads to local drive verified | `[VERIFIED]` | High (Observed on individual document links) |
| **Document Ingestion Strategy** | Decoupled downstream workstream; zero bulk downloads | `[PLANNED]` | High (Pilot restricted to OC, CC, Sanction Plan) |
| **Document Classification Model** | UI Category is primary key; filenames vary and are non-authoritative | `[VERIFIED / ARCH-DECISION]` | High (Mismatch flagged for manual review) |
