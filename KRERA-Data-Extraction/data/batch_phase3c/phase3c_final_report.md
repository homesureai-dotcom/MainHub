# HomeSure K-RERA — Phase 3C Final Extraction & Quality Assurance Report (250-Project Controlled Batch)

> **Single Source of Truth Notice:** Every count, distribution, and metric in this report is calculated directly from the persisted machine-readable JSON and SQLite artifacts in `data/batch_phase3c/` and `reports/`.

## Executive Summary & 22 Mandatory Metrics (Section 11.D)

| # | Metric / Requirement | Verified Value | Source Artifact |
|---:|---|---|---|
| 1 | **Selected project count** | `250` | `data/batch_phase3c/phase3c_manifest.json` |
| 2 | **Excluded historical / incomplete project count** | `125` historical (`25` Phase 3A + `100` Phase 3B) + `365` non-APPROVED/incomplete = `490` excluded | `data/batch_phase3c/phase3c_exclusion_report.json` |
| 3 | **Attempted project count** | `250` (`0` extracted in run, `250` resumed) | `reports/phase3c_batch_summary.json` |
| 4 | **Successful project count** | `250` | `reports/phase3c_batch_summary.json` |
| 5 | **Partial project count** | `0` | `reports/phase3c_batch_summary.json` |
| 6 | **Failed project count** | `0` | `reports/phase3c_batch_summary.json` |
| 7 | **Identity-unverified project count** | `0` (`250 / 250` verified) | `data/batch_phase3c/phase3c_identity_validation.json` |
| 8 | **Portal restrictions encountered** | `0` (`interrupted = False`) | `data/batch_phase3c/phase3c_error_log.json` |
| 9 | **Page-band distribution** | Early: `83`, Middle: `84`, Late: `83` | `data/batch_phase3c/phase3c_selection_report.json` |
| 10 | **Project-type distribution** | Residential/Group Housing: `120`, Plotted Development: `60`, Commercial: `35`, Mixed Development: `35` | `data/batch_phase3c/phase3c_selection_report.json` |
| 11 | **Registration-year distribution** | `10` distinct approval years (`2017`–`2026`), `246` distinct promoters | `data/batch_phase3c/phase3c_selection_report.json` |
| 12 | **Navigation schemas encountered** | `14` distinct visible tab schemas across `11` distinct tab types | `data/batch_phase3c/phase3c_coverage_report.json` |
| 13 | **Unlinked panes discovered & label sources** | `6` distinct unlinked pane signatures; label sources: `{'dom_comment_or_inner_heading': 1095}` (`UNLINKED_PANE_LABELS = {}`) | `data/batch_phase3c/phase3c_coverage_report.json` |
| 14 | **Total sections and fields extracted** | `9,822` sections, `36,829` fields, `64,286` table rows | `data/batch_phase3c/phase3c_coverage_report.json` |
| 15 | **Document observations vs links vs placeholders vs unavailable** | `28,112` total records (`24,887` unique observations, `24,887` downloadable links, `1,846` placeholders, `3,225` unavailable slots) | `data/batch_phase3c/phase3c_coverage_report.json` |
| 16 | **Normalization warnings and anomalies** | `13` validation warnings across `11` projects; `0` extraction errors | `data/batch_phase3c/phase3c_data_quality_report.json` |
| 17 | **Cross-section conflicts preserved** | `336` conflicts preserved across `250` projects (`0` silently resolved) | `data/batch_phase3c/phase3c_data_quality_report.json` |
| 18 | **PII exclusions and post-extraction PII scan results** | `6,739` PII items redacted during extraction; `500` files scanned post-extraction with **`0` PII leaks** | `data/batch_phase3c/phase3c_pii_audit.json` |
| 19 | **Automated live-DOM comparison results** | `250 / 250` projects passed; `2,261` fields checked, `2,261` retained samples (`2,261` stored objects), `0` mismatches | `data/batch_phase3c/phase3c_live_dom_comparisons.json` |
| 20 | **Human manual QA results (or pending status)** | `25` representative projects selected; status = `pending_human_review` (`human_review_performed = False`, `0` fabricated claims) | `data/batch_phase3c/phase3c_human_qa.json` |
| 21 | **Checkpoint status and retry queue** | Phase 3C SQLite: `{'pending': 0, 'successful': 250, 'partial': 0, 'failed': 0, 'identity_unverified': 0}`; Cumulative SQLite (`3A+3B+3C`): `375` projects (`{'pending': 0, 'successful': 375, 'partial': 0, 'failed': 0, 'identity_unverified': 0}`); Retry queue: `0` | `data/batch_phase3c/phase3c_checkpoints.sqlite` & `phase3c_retry_queue.json` |
| 22 | **Recommended readiness decision for Phase 3D** | **READY FOR PHASE 3D** (subject to optional human visual spot-check of the 25-project `phase3c_human_qa.json` packet) | Section 9 below |

---

## 1. Cross-Phase Duplicate Exclusion & Sample Selection (Section 2)

- **Total Catalogue Rows Inspected (`data/raw_catalogue_Full_bengaluru_urban.json`):** `4,459`
- **Phase 3A Historical Projects Excluded:** `25`
- **Phase 3B Historical Projects Excluded:** `100`
- **Existing Successful SQLite Checkpoints Excluded:** `125`
- **Non-APPROVED or Incomplete Identifier Rows Placed in Manual-Review / Exclusion List:** `365`
- **Remaining Eligible `APPROVED` Candidate Pool:** `3,969`
- **Newly Selected Phase 3C Projects:** `250` (`0` overlap across `registration_number`, `acknowledgement_number`, `vpd_id`, and `canonical_project_key`)

### Page-Band & Project-Type Distribution (`250` Projects)

| Category | Target Quota | Actual Selected & Extracted |
|---|---:|---:|
| **Early (Pages 1–100)** | `83` | `83` |
| **Middle (Pages 101–300)** | `84` | `84` |
| **Late (Pages 301–446)** | `83` | `83` |
| **Residential/Group Housing** | `120` | `120` |
| **Plotted Development** | `60` | `60` |
| **Commercial** | `35` | `35` |
| **Mixed Development** | `35` | `35` |

### Approval-Year Distribution (`2017–2026`)

| Approval Year | Project Count |
|---|---:|
| `2017` | `44` |
| `2018` | `35` |
| `2019` | `17` |
| `2020` | `20` |
| `2021` | `15` |
| `2022` | `22` |
| `2023` | `21` |
| `2024` | `25` |
| `2025` | `23` |
| `2026` | `28` |

---

## 2. Internal 10 x 25 Sub-Batch Controlled Execution Summary (Section 12)

| Sub-Batch | Projects Range | Projects Count | Successful | Identity Unverified | Duplicates | Cross-Contamination | PII Files Scanned | PII Leaks | Validation |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---|
| `01/10` | `001–025` | `25` | `25` | `0` | `0` | `0` | `50` | `0` | `PASSED` |
| `02/10` | `026–050` | `25` | `25` | `0` | `0` | `0` | `50` | `0` | `PASSED` |
| `03/10` | `051–075` | `25` | `25` | `0` | `0` | `0` | `50` | `0` | `PASSED` |
| `04/10` | `076–100` | `25` | `25` | `0` | `0` | `0` | `50` | `0` | `PASSED` |
| `05/10` | `101–125` | `25` | `25` | `0` | `0` | `0` | `50` | `0` | `PASSED` |
| `06/10` | `126–150` | `25` | `25` | `0` | `0` | `0` | `50` | `0` | `PASSED` |
| `07/10` | `151–175` | `25` | `25` | `0` | `0` | `0` | `50` | `0` | `PASSED` |
| `08/10` | `176–200` | `25` | `25` | `0` | `0` | `0` | `50` | `0` | `PASSED` |
| `09/10` | `201–225` | `25` | `25` | `0` | `0` | `0` | `50` | `0` | `PASSED` |
| `10/10` | `226–250` | `25` | `25` | `0` | `0` | `0` | `50` | `0` | `PASSED` |

---

## 3. Dynamic Navigation Schemas & Unlinked DOM Panes (Sections 5 & 6)

### Observed Visible Navigation Schemas

| Visible Navigation Tab Schema | Projects Count |
|---|---:|
| `Promoter Details | Land Details | Project Details | Bank Details | Uploaded Documents | Enquired Documents | Complaints | Quarterly Updates` | `81` |
| `Promoter Details | Project Details | Uploaded Documents | Enquired Documents | Complaints | Quarterly Updates` | `59` |
| `Promoter Details | Project Details | Uploaded Documents | Enquired Documents | Complaints | Quarterly Updates | Completion Details` | `43` |
| `Promoter Details | Land Details | Project Details | Bank Details | Uploaded Documents | Enquired Documents | Complaints | Quarterly Updates | Completion Details` | `20` |
| `Promoter Details | Project Details | Uploaded Documents | Enquired Documents | Complaints | Project Extension Details | Quarterly Updates | Completion Details` | `17` |
| `Promoter Details | Project Details | Uploaded Documents | Enquired Documents | Complaints | Project Extension Details | Quarterly Updates` | `17` |
| `Promoter Details | Land Details | Project Details | Bank Details | Uploaded Documents | Enquired Documents | Complaints | Project Extension Details | Quarterly Updates` | `3` |
| `Promoter Details | Project Details | Uploaded Documents | Enquired Documents | Complaints | Modification of Plan Details | Project Extension Details | Quarterly Updates | Completion Details` | `2` |
| `Promoter Details | Project Details | Uploaded Documents | Enquired Documents | Complaints | Modification of Plan Details | Quarterly Updates | Completion Details` | `2` |
| `Promoter Details | Land Details | Project Details | Bank Details | Uploaded Documents | Enquired Documents | Complaints | Modification of Plan Details | Quarterly Updates` | `2` |
| `Promoter Details | Land Details | Project Details | Bank Details | Uploaded Documents | Enquired Documents | Complaints | Modification of Plan Details | Quarterly Updates | Completion Details` | `1` |
| `Promoter Details | Project Details | Uploaded Documents | Enquired Documents | Complaints | Modification of Plan Details | Project Extension Details | Quarterly Updates` | `1` |
| `Promoter Details | Project Details | Uploaded Documents | Enquired Documents | Complaints | Modification of Plan Details | Quarterly Updates` | `1` |
| `Promoter Details | Land Details | Project Details | Bank Details | Uploaded Documents | Enquired Documents | Complaints | Modification of Plan Details | Project Extension Details | Quarterly Updates` | `1` |

### Visible Tab Discovery vs. Data Presence

| Visible Tab Label | Discovered In Projects | `present_with_data` | `present_empty` |
|---|---:|---:|---:|
| `Promoter Details` | `250` | `250` | `0` |
| `Project Details` | `250` | `250` | `0` |
| `Uploaded Documents` | `250` | `248` | `2` |
| `Enquired Documents` | `250` | `146` | `104` |
| `Complaints` | `250` | `95` | `155` |
| `Quarterly Updates` | `250` | `77` | `173` |
| `Land Details` | `108` | `108` | `0` |
| `Bank Details` | `108` | `107` | `1` |
| `Completion Details` | `85` | `84` | `1` |
| `Project Extension Details` | `41` | `40` | `1` |
| `Modification of Plan Details` | `10` | `9` | `1` |

### Unlinked DOM Panes (`UNLINKED_PANE_LABELS = {}` — DOM Comment / Inner Heading / Generic Fallback)

| Unlinked Pane Signature (`#id (resolved_label)`) | Discovered Count | `present_with_data` |
|---|---:|---:|
| `#postReg (Project Details)` | `245` | `237` |
| `#modPlan (Modification of Plan Details)` | `239` | `4` |
| `#extPlan (Project Extension Details)` | `208` | `5` |
| `#completion (Completion Details)` | `158` | `14` |
| `#menu5 (Appeal / FNH Details)` | `138` | `15` |
| `#menu3 (Cost Details)` | `107` | `107` |

---

## 4. Extraction Status vs. Coverage Quality Metrics (Section 9)

- **Execution Status Breakdown:**
  - `successful`: `250`
  - `partial`: `0`
  - `failed`: `0`
  - `identity_unverified`: `0`
- **Independent Coverage Quality Summary:**
  - Projects with 100% of discovered visible tabs parsed: `250 / 250`
  - Projects with failed tabs: `0`
  - Projects with zero extracted fields: `0`
  - Projects with populated unlinked DOM panes captured: `237`
  - Projects with validation warnings preserved: `11` (`13` total warnings)
  - Projects with cross-section conflicts preserved: `250` (`336` total conflicts)

---

## 5. PII Protection & Adversarial Scanner Audit (Section 8)

- **Total PII Exclusions Recorded During Extraction:** `6,739`
- **Post-Extraction Adversarial Scanner Files Checked:** `500` (`250` raw + `250` normalized JSONs)
- **Post-Extraction PII Leaks Detected:** **`0`**
- **PII Redactions by Category:**
  - `Excluded personal photograph <img> in table column 'Column_2' of section 'Project Photographs'.`: `1,069`
  - `Excluded personal photograph <img> in table column 'Column_4' of section 'Project Photographs'.`: `1,068`
  - `Excluded individual residential address 'Present Address' in section 'Project Land Owner / Co-promoter Details'.`: `580`
  - `Excluded individual personal address 'Communication Address' inside individual section 'Project Land Owner / Co-promoter Details'.`: `580`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='PAN').`: `568`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='PAN Card').`: `398`
  - `Excluded individual personal address 'Address' inside individual section 'Partner Details'.`: `179`
  - `Excluded personal photograph field/link in 'Partner Details' (label='Photo').`: `179`
  - `Excluded individual personal address 'Address' inside individual section 'Project Member Details'.`: `148`
  - `Excluded personal photograph field/link in 'Project Member Details' (label='Photograph').`: `148`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='PAN Number').`: `142`
  - `Excluded individual personal address 'Address' inside individual section 'Authorized Signatory Detail'.`: `134`
  - `Excluded personal photograph field/link in 'Authorized Signatory Detail' (label='Photograph').`: `134`
  - `Excluded individual personal address 'Address' inside individual section 'Director Details'.`: `132`
  - `Excluded personal photograph field/link in 'Director Details' (label='Photo').`: `132`
  - `Excluded personal photograph <img> in table column 'Document' of section 'Project Photo'.`: `129`
  - `Excluded individual residential address 'Present Address' in section 'Authorized Signatory Details'.`: `108`
  - `Excluded individual residential address 'Permanent Address' in section 'Authorized Signatory Details'.`: `108`
  - `Excluded personal photograph <img> tag in section 'Authorized Signatory Details'.`: `108`
  - `Excluded personal photograph <img> in table column 'Column_6' of section 'Status of Common Areas To be Relinquished to local Authority /Planning Authority'.`: `105`
  - `Excluded personal photograph <img> in table column 'Document' of section 'Project Photo*'.`: `84`
  - `Excluded individual residential address 'Present Address' in section 'Project Land Owner Details'.`: `83`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='Self Attested PAN Card*').`: `64`
  - `Excluded individual residential address 'Present Address' in section 'Chief Executive Officer / Managing Director Details'.`: `41`
  - `Excluded individual residential address 'Permanent Address' in section 'Chief Executive Officer / Managing Director Details'.`: `41`
  - `Excluded personal photograph <img> tag in section 'Chief Executive Officer / Managing Director Details'.`: `41`
  - `Excluded personal photograph <img> in table column 'Photo' of section 'Project Head Details'.`: `41`
  - `Excluded identity document or filename containing PAN/Aadhaar/ID pattern (label='Address Proof').`: `17`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Borewell Photo').`: `11`
  - `Excluded personal photograph field/link in 'Promoter Details' (label='Photograph').`: `8`
  - `Excluded personal photograph <img> in table column 'Photo' of section 'Project Agents'.`: `7`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Ambiant Photo').`: `4`
  - `Excluded individual personal address 'Address' inside individual section 'Promoter Details'.`: `3`
  - `Excluded individual personal address 'Address' inside individual section 'Previous Project Details (Last 5 years only)'.`: `3`
  - `Excluded identity document or filename containing PAN/Aadhaar/ID pattern (label='Board Resolution for Authorized Signatory/Certificate of Authorization').`: `3`
  - `Excluded identity document or filename containing PAN/Aadhaar/ID pattern (label='Document').`: `3`
  - `Excluded identity document or filename containing PAN/Aadhaar/ID pattern (label='ENGINEER KYC').`: `3`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Project development details recent photo').`: `3`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='BOREWELL PHOTO').`: `2`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='PAN CARD').`: `2`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='Self Attested PAN').`: `2`
  - `Excluded value matching Indian PAN pattern in field 'GSTIN'.`: `2`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='CA Aadhaar').`: `2`
  - `Excluded identity document or filename containing PAN/Aadhaar/ID pattern (label='GST Certificate').`: `2`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Borewell Photograph 1').`: `2`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Borewell Photograph 2').`: `2`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='PHOTO').`: `2`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='FIRM PAN CARD').`: `2`
  - `Excluded value matching Indian PAN pattern in field 'Income Tax Return Acknowledgement [2015 - 2016]'.`: `1`
  - `Excluded value matching Indian PAN pattern in field 'Company Registration No.'.`: `1`
  - `Excluded identity document or filename containing PAN/Aadhaar/ID pattern (label='ENGINEER AADTHAAR').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='4.8-Project-Photo').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='Self attested PAN card copy').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='Firm PAN Copy').`: `1`
  - `Excluded value matching Indian PAN pattern in field 'Income Tax Return Acknowledgement [2023 - 2024]'.`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='2- KYC Engineer Aadhar B Ramesh.pdf').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Photo').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='PAN CARD ATTESTED BY PARTNER').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='Self attested Pan Card Copy').`: `1`
  - `Excluded identity document or filename containing PAN/Aadhaar/ID pattern (label='NOC').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='PAN CARD OF SBR GROUP & Managing Partner Mr. T. Venugopal').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='Self Attested PAN Card').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='Pan Card').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='SELF ATTESTED PAN NO.').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='Self Attested pan Card').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='Pan card attested').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Project Co-ordinate Photo').`: `1`
  - `Excluded document filename containing embedded email or mobile number (label='WebSite Link 1').`: `1`
  - `Excluded identity document or filename containing PAN/Aadhaar/ID pattern (label='DP').`: `1`
  - `Excluded personal photograph filename in 'Authorized Signatory Details' (label='Board Resolution for Authorized Signatory/Certificate of Authorization').`: `1`
  - `Excluded value matching Aadhaar number pattern in field 'Longitude'.`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='CA'S AADHAR').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='CA'S PAN CARD').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='PROJECT ENGINEER'S AADHAR').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='PAN Card Self Attested').`: `1`
  - `Excluded value matching Indian PAN pattern in field 'Registration Number'.`: `1`
  - `Excluded identity document or filename containing PAN/Aadhaar/ID pattern (label='Registration Certificate').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Hissa Photo Copy').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='PAN Card - Self Attested').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='PAN CARD SELF ATTESTED').`: `1`
  - `Excluded identity document or filename containing PAN/Aadhaar/ID pattern (label='Certificate').`: `1`
  - `Excluded identity document or filename containing PAN/Aadhaar/ID pattern (label='Self Attested Pancard').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='Annexure 66-PAN-Shriram Upscale.pdf').`: `1`
  - `Excluded value matching Aadhaar number pattern in field 'Auditors Report 2019-20 -2020-21 - 2021-22 with CA UDIN'.`: `1`
  - `Excluded value matching Aadhaar number pattern in field 'Balance sheet 2019-20 -2020-21 - 2021-22'.`: `1`
  - `Excluded value matching Aadhaar number pattern in field 'Profit Loss statements 2019-20 -2020-21 - 2021-22'.`: `1`
  - `Excluded value matching Aadhaar number pattern in field 'Cash flow statement 2019-20 -2020-21 - 2021-22'.`: `1`
  - `Excluded identity document or filename containing PAN/Aadhaar/ID pattern (label='Chartered accountant KYC').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='Firm's PAN with the seal and signature of the Partner').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='Self attested PAN card.').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Source of Water Photo').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='gnanavel aadhar card').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Photograph 1').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Photograph 2').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Photograph 3').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Photograph 4').`: `1`
  - `Excluded identity document or filename containing PAN/Aadhaar/ID pattern (label='CA KYC').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='Architects Aadhar').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='Engineer Aadhar').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='PAN Self Attested').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='PAN copy self attested').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='1 Firm PAN Card').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='2 Project Engineer Aadhaar Card').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Existing borewell photo').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='CA Self-Attested Aadhar Card').`: `1`
  - `Excluded personal photograph filename in 'Enquired Documents' (label='Partner's photos and KYC.').`: `1`
  - `Excluded identity document or filename containing PAN/Aadhaar/ID pattern (label='CA self attested KYC documents').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='18 Engineer Aadhaar').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='Arch AADHAR (1)').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Borewell photo 1').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Borewell photo 2').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='CA Aadhar Signed').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='Mahesh PAN').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Photo 1').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Photo 2').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Photo 3').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Photo 4').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Photo 5').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='1 RP Aadhaar').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='2 RP Pan').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='3 SS Aadhaar').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='4 SS Pan').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='5 BHK Aadhaar').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='6 BHK Pan').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='7 CA Aadhaar KYC').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='3 CA - Aadhar Card').`: `1`
  - `Excluded document filename containing embedded email or mobile number (label='Promoter Website').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='CHARTERED ACCOUNTANT AADHAR').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Borewell Photograph 3').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Borewell Photograph 4').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='pan card ADPL attested.pdf').`: `1`
  - `Excluded identity document or filename containing PAN/Aadhaar/ID pattern (label='CA - KYC Details').`: `1`
  - `Excluded value matching Indian PAN pattern in field 'DIN Number'.`: `1`
  - `Excluded identity document or filename containing PAN/Aadhaar/ID pattern (label='CHARTERED ACCOUNTANT KYC').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='MADHUSUDHAN PHOTO').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='COMPANY PAN CARD').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='Arc Aadhaar Card.pdf').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='KYC Engineer Aadhar').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='II of 6 Aadhar Chartered Engineer').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='SELF ATTESTED FIRM PAN CARD').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='BOREWEL PHOTO').`: `1`
  - `Excluded identity document or filename containing PAN/Aadhaar/ID pattern (label='Organization Structure').`: `1`
  - `Excluded identity document or filename containing PAN/Aadhaar/ID pattern (label='Project Specifications').`: `1`
  - `Excluded identity document or filename containing PAN/Aadhaar/ID pattern (label='Proforma of Agreement for Sale').`: `1`
  - `Excluded identity document or filename containing PAN/Aadhaar/ID pattern (label='Proforma of Allotment Letter').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='11Project Land Photo 1').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='BOREWELL photo').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='PHOTO of site').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Google photo').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='FIRM PAN CARD SELF ATTESTED').`: `1`
  - `Excluded value matching Indian PAN pattern in field 'profit and loss account and balance sheet'.`: `1`
  - `Excluded value matching Indian PAN pattern in field 'ITS STATMENT'.`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='4 Aadhaar-praveen-NEW-MASK').`: `1`
  - `Excluded PAN/Aadhaar/ID identifier or document under PII policy (label='9 Land Owner Aadhaar and PAN').`: `1`
  - `Excluded value matching Indian PAN pattern in field 'Designation'.`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Project Recent Photograph 2').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Project Recent Photograph 3').`: `1`
  - `Excluded personal photograph field/link in 'Enquired Documents' (label='Borewell GPS Photo').`: `1`

---

## 6. Automated Live-DOM Comparison vs. Human Manual QA (Section 10)

1. **Automated Live-DOM Verification (`data/batch_phase3c/phase3c_live_dom_comparisons.json`):**
   - Verification mode: `automated_live_dom_comparison` (`human_manual_inspection_performed = False`)
   - Projects compared: `250` (`250` passed)
   - Total live-DOM fields checked (`total_live_dom_fields_checked_count`): `2,261`
   - Total retained field samples (`retained_field_samples_count`): `2,261`
   - Actual stored field sample objects (`len(retained_field_samples)`): `2,261`
   - Field mismatches: `0`
2. **Human Manual QA Sample (`data/batch_phase3c/phase3c_human_qa.json`):**
   - Sample size: `25` projects across Early/Middle/Late bands and all 4 project types
   - Status: `pending_human_review` (`human_review_performed = False`; no human inspection was fabricated)

---

## 7. Cumulative Progress Across Phases 3A, 3B, and 3C

| Phase | Target Projects | Checkpointed `successful` | Cumulative `successful` in `data/k_rera_extraction.sqlite` |
|---|---:|---:|---:|
| **Phase 3A** | `25` | `25` | `25` |
| **Phase 3B** | `100` | `100` | `125` |
| **Phase 3C** | `250` | `250` | `375` |

## 8. Readiness Decision for Phase 3D

- **Recommendation:** **PROCEED TO PHASE 3D** when ready.
- **Rationale:** All 250 Phase 3C projects completed with `100%` strict identity verification, `0` portal restrictions/CAPTCHAs, `0` cross-phase duplicates, `0` PII leaks across all 500 output files, and `100%` automated live-DOM field/tab alignment across all 10 controlled sub-batches.
