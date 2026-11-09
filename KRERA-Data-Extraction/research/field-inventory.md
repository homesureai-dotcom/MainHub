# Field Inventory & Data Schema — K-RERA Reconnaissance

This document defines the complete catalog of fields exposed on the K-RERA portal across both the search results grid and the individual project detail views.

---

## Status Legend

- `[VERIFIED]`: Field presence, label, and format confirmed directly from the portal DOM.
- `[UNVERIFIED]`: Field anticipated from standard RERA disclosures but not yet confirmed on K-RERA.
- `[ASSUMPTION]`: Assumed field format or mandatory status pending sample evaluation.
- `[BLOCKED]`: Field details inaccessible or masked.
- `[RESTRICTED / PII]`: Field contains personally identifiable information; **excluded from ingestion by Data Governance Policy**.

---

## Data Governance & Ingestion Policy

> [!IMPORTANT]
> **Strict PII Exclusion Rule**
> The HomeSure catalogue ingests only entity-level and project-level real estate data.
> - **EXCLUDED:** PAN Numbers, personal names/addresses/photos of Authorised Signatories and Project Members.
> - **INCLUDED:** Project attributes, company names, corporate registration IDs, corporate addresses, RERA numbers, sanction details, and completion metrics.

---

## 1. Search Results Grid Fields (Observed on `/projectViewDetails`)

| Field Name (UI Label) | Technical Key | Data Type | Example Value | Detail Link? | Status | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `S.No` | `s_no` | Integer / String | `1`, `2` | No | `[VERIFIED]` | Row index counter |
| `Acknowledgement No` | `ack_no` | String | *Application ID* | No | `[VERIFIED]` | Stable internal tracking ID |
| `Registration No` | `registration_no` | String | `PRM/KA/RERA/...` | No | `[VERIFIED]` | May be absent/custom string for rejected files |
| `View Project Details` | `view_details` | Action Link | `View` / Hyperlink | Yes | `[VERIFIED]` | Direct portal trigger to project disclosures |
| `Promoter Name` | `promoter_name` | String | *Developer Entity* | No | `[VERIFIED]` | Corporate / individual promoter |
| `Project Name` | `project_name` | String | `GODREJ UNITED` | No | `[VERIFIED]` | Registered project title |
| `Status` | `status` | String | `APPROVED`, `REJECTED` | No | `[VERIFIED]` | Lifecycle status; rejected records may show reason |
| `District` | `district` | String | `BENGALURU URBAN` | No | `[VERIFIED]` | Geographic administrative district |
| `Taluk` | `taluk` | String | *e.g., Bangalore East* | No | `[VERIFIED]` | Sub-district administrative unit |
| `Project Type` | `project_type` | String | *Residential / Mixed* | No | `[VERIFIED]` | Broad project classification |
| `Approved On` | `approved_on` | Date / String | *DD-MM-YYYY* | No | `[VERIFIED]` | Official date of RERA approval |
| Proposed Completion Date | `proposed_completion_date` | Date / String | *DD-MM-YYYY* | No | `[VERIFIED]` | Partially visible header in screenshot |

---

## 2. Project Registration Details Page Schema (Discovery-Driven Model)

> [!IMPORTANT]
> **Dynamic Discovery Principle**
> **Never assume that every K-RERA project has the same tabs, sections, fields, or documents.**
> The sections and field groups cataloged below represent structures observed across representative projects (such as `GODREJ UNITED`). They serve as a dictionary of known patterns, NOT a mandatory contract. The ingestion engine dynamically discovers whatever tabs and sections exist for a given project and assigns explicit observation states (`present_with_data`, `present_empty`, `not_present`, `not_applicable`, `not_available`, `extraction_failed`).

### Persistent Header Summary Fields (Observed Across All Project Detail Views)
| Field Name (UI Label) | Technical Key | Data Type | Nullable? | Example Value | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Project Name | `project_name` | String | No | `GODREJ UNITED` | `[VERIFIED]` |
| Acknowledgement Number | `ack_no` | String | No | *e.g., PR/KN/...* | `[VERIFIED]` |
| Registration Number | `registration_no` | String | No | *e.g., PRM/KA/RERA/...* | `[VERIFIED]` |

---

### Tab 1: Promoter Details

| Field / Section Name | Technical Key | Data Type | Governance Classification | Status | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `Promoter Type` | `promoter_type` | String | Standard Ingestion | `[VERIFIED]` | e.g., Company, Individual, Partnership |
| `Promoter/Company Name` | `promoter_name` | String | Standard Ingestion | `[VERIFIED]` | Entity name |
| `PAN Number` | `pan_no` | String | **`[RESTRICTED / PII]`** | `[VERIFIED]` | **DO NOT INGEST** |
| `Address` | `promoter_address` | String | Standard Ingestion | `[VERIFIED]` | Registered corporate office address |
| `District` | `promoter_district` | String | Standard Ingestion | `[VERIFIED]` | Corporate location district |
| `State/UT` | `promoter_state` | String | Standard Ingestion | `[VERIFIED]` | Corporate location state |
| `PIN Code` | `promoter_pincode` | String | Standard Ingestion | `[VERIFIED]` | Postal code |
| `Company Registration Number` | `company_reg_no` | String | Standard Ingestion | `[VERIFIED]` | CIN / ROC registration number |
| `Company Registration Certificate`| `company_reg_cert_url` | Document Link | Standard Ingestion | `[VERIFIED]` | Link to corporate certificate |
| `Authorised Signatory Details` | `signatory_details` | Object / List | **`[RESTRICTED / PII]`** | `[VERIFIED]` | Contains personal names, addresses, photos (**DO NOT INGEST**) |
| `Project Member Details` | `member_details` | Object / List | **`[RESTRICTED / PII]`** | `[VERIFIED]` | Contains personal names, addresses, photos (**DO NOT INGEST**) |
| `Project Land Owner Details` | `land_owner_details` | Object / List | Controlled Review | `[VERIFIED]` | Land owner entity / individual list |
| `RERA Registration Details with other States/UTs` | `other_state_rera_regs` | List | Standard Ingestion | `[VERIFIED]` | Prior state regulatory registrations |
| `Previous Project Details` | `prev_projects_5yr` | List | Standard Ingestion | `[VERIFIED]` | Track record (last 5 years only) |

---

---

### Tab 2: Project Details

#### Group 1: Registration History
| Field / Label | Technical Key | Data Type | Example Value | Status |
| :--- | :--- | :--- | :--- | :--- |
| Registration / Extension Type | `registration_type` | String | `Original` / `Covid Extension` | `[VERIFIED]` |
| Start Date | `original_start_date` | Date / String | `15-06-2017` | `[VERIFIED]` |
| Original Proposed Completion Date | `original_completion_date` | Date / String | `31-05-2021` | `[VERIFIED]` |
| Extension Start Date | `extension_start_date` | Date / String | `31-05-2021` | `[VERIFIED]` |
| Extension End Date | `extension_end_date` | Date / String | `28-02-2022` | `[VERIFIED]` |
| Extension Certificate / Order | `extension_order_url` | Document Link | Link / PDF | `[VERIFIED]` |

#### Group 2: Project Identity
| Field / Label | Technical Key | Data Type | Example Value | Status |
| :--- | :--- | :--- | :--- | :--- |
| Project Name | `project_name` | String | `GODREJ UNITED` | `[VERIFIED]` |
| Project Description | `project_description` | Text | Residential complex... | `[VERIFIED]` |
| Project Type | `project_type` | String | `Residential` | `[VERIFIED]` |
| Project Status | `project_status` | String | `Approved` | `[VERIFIED]` |

#### Group 3: Land and Project Costs
| Field / Label | Technical Key | Data Type | Example Value | Status |
| :--- | :--- | :--- | :--- | :--- |
| Total Land Area | `total_land_area_sqm` | Decimal / String | *e.g., in Sq.M* | `[VERIFIED]` |
| Covered Area | `covered_area_sqm` | Decimal / String | - | `[VERIFIED]` |
| Open Area | `open_area_sqm` | Decimal / String | - | `[VERIFIED]` |
| Estimated Construction Cost | `estimated_construction_cost` | Numeric / Decimal | - | `[VERIFIED]` |
| Land Cost | `land_cost` | Numeric / Decimal | - | `[VERIFIED]` |
| Total Project Cost | `total_project_cost` | Numeric / Decimal | `5,200,000,000` | `[VERIFIED]` |

#### Group 4: Location & Jurisdiction
| Field / Label | Technical Key | Data Type | Example Value | Status |
| :--- | :--- | :--- | :--- | :--- |
| Project Address | `project_address` | String | *Whitefield Main Rd...* | `[VERIFIED]` |
| District | `district` | String | `BENGALURU URBAN` | `[VERIFIED]` |
| Taluk | `taluk` | String | `Bangalore East` | `[VERIFIED]` |
| Geographic Boundary Coordinates | `geo_coordinates` | Object / Bounding Box | North/South/East/West coords | `[VERIFIED]` |
| Approving Authority | `approving_authority` | String | `BBMP` / `BDA` | `[VERIFIED]` |

#### Group 5: Development and Inventory
| Field / Label | Technical Key | Data Type | Example Value | Status |
| :--- | :--- | :--- | :--- | :--- |
| Garage / Parking Counts & Areas | `parking_inventory` | Object | Open / Covered counts & sq.m | `[VERIFIED]` |
| Inventory Type | `inventory_type` | String | `1 BHK`, `2 BHK` | `[VERIFIED]` |
| Inventory Count | `inventory_count` | Integer | `51` (check for multi-row) | `[VERIFIED]` |
| Carpet Area | `carpet_area_sqm` | Decimal | Sq.M | `[VERIFIED]` |
| Exclusive Balcony / Verandah Area | `balcony_area_sqm` | Decimal | Sq.M | `[VERIFIED]` |
| Exclusive Terrace Area | `terrace_area_sqm` | Decimal | Sq.M | `[VERIFIED]` |

#### Group 6: External Development Infrastructure
| Infrastructure Item | Technical Key | Data Type | Governance Classification | Status |
| :--- | :--- | :--- | :--- | :--- |
| Road system | `infra_roads` | String / Status | Standard Ingestion | `[VERIFIED]` |
| Water supply | `infra_water_supply` | String / Status | Standard Ingestion | `[VERIFIED]` |
| Sewage and drainage | `infra_sewage_drainage` | String / Status | Standard Ingestion | `[VERIFIED]` |
| Electricity | `infra_electricity` | String / Status | Standard Ingestion | `[VERIFIED]` |
| Solid waste management | `infra_solid_waste` | String / Status | Standard Ingestion | `[VERIFIED]` |
| Firefighting provisions | `infra_firefighting` | String / Status | Standard Ingestion | `[VERIFIED]` |
| Drinking water facilities | `infra_drinking_water` | String / Status | Standard Ingestion | `[VERIFIED]` |
| Emergency evacuation | `infra_evacuation` | String / Status | Standard Ingestion | `[VERIFIED]` |
| Renewable energy | `infra_renewable_energy` | String / Status | Standard Ingestion | `[VERIFIED]` |

#### Group 7: Project Professionals (Organisation-Level Only)
| Role / Entity | Technical Key | Data Type | Governance Classification | Status |
| :--- | :--- | :--- | :--- | :--- |
| Architect Entity / Reg ID | `architect_org_details` | Object | Organisation only | `[VERIFIED]` |
| Structural Engineer Entity | `structural_engineer_org` | Object | Organisation only | `[VERIFIED]` |
| Contractor Entity | `contractor_org` | Object | Organisation only | `[VERIFIED]` |
| *Personal residential addresses / personal IDs* | - | - | **`[RESTRICTED / PII]`** | **EXCLUDED** |

---

### Tab 3: Uploaded Documents
*Document categories and file access links pending direct inspection.*

---

### Tab 4: Enquired Documents
*Pending future scope.*

---

### Tab 5: Complaints (Disputes & Litigation Allegations)
> [!WARNING]
> Allegations only. Do NOT assign automated risk scores without inspecting certified orders.

| Field / Label | Technical Key | Data Type | Example Value | Status |
| :--- | :--- | :--- | :--- | :--- |
| Complaint Filing Date | `complaint_date` | Date / String | `10-10-2021`, `06-02-2024`, `16-02-2026` | `[VERIFIED]` |
| Allegation / Subject | `allegation_subject` | Text | Misrepresentation, common amenities... | `[VERIFIED]` |
| Disposal / Status | `complaint_status` | String | Disposed / Posted for orders | `[VERIFIED]` |
| Adjudicating Forum | `adjudicating_forum` | String | Authority Bench 4 / Adjudicating Officer | `[VERIFIED]` |

---

### Tab 6: Quarterly Updates
- **Observed State:** `NO DATA OBSERVED ON THE PROJECT PAGE` `[VERIFIED]`
- **Ingestion Rule:** Field must be nullable; no inference of promoter non-compliance.

---

### Tab 7: Completion Details

| Field / Label | Technical Key | Data Type | Observed Value (`GODREJ UNITED`) | Status |
| :--- | :--- | :--- | :--- | :--- |
| Completion Application Date | `completion_application_date` | Date | `06-05-2022` | `[VERIFIED]` |
| Project Start Date | `project_start_date` | Date | `15-06-2017` | `[VERIFIED]` |
| Project End Date | `project_end_date` | Date | `28-02-2022` | `[VERIFIED]` |
| Completion Extension Granted | `completion_extension_flag` | Boolean / String | `NO` (Flagged in exceptions) | `[VERIFIED]` |
| Occupancy Certificate Received | `oc_received_flag` | Boolean / String | `YES` | `[VERIFIED]` |
| Occupancy Certificate Date | `oc_date` | Date | `09-02-2022` | `[VERIFIED]` |
| Total Apartments Sanctioned | `total_apartments` | Integer | `512` | `[VERIFIED]` |
| Apartments Sold | `apartments_sold` | Integer | `512` | `[VERIFIED]` |
| Apartments Unsold | `apartments_unsold` | Integer | `0` | `[VERIFIED]` |
| Completed Within Stipulated Period | `completed_on_time_flag` | Boolean / String | `YES` | `[VERIFIED]` |
| Inventory / Specification Changed | `inventory_changed_flag` | Boolean / String | `NO` | `[VERIFIED]` |
| As-Built Drawing Approved | `as_built_drawing_approved` | Boolean / String | `YES` | `[VERIFIED]` |
| Total Project Cost | `total_project_cost` | Decimal | `INR 5,200,000,000` | `[VERIFIED]` |
| Amount Collected from Buyers | `buyer_collection_amount` | Decimal | `INR 4,788,191,565` | `[VERIFIED]` |
| Loan Raised | `loan_raised_flag` | Boolean / String | `NO` | `[VERIFIED]` |
| Amount Spent on Project | `amount_spent` | Decimal | `INR 4,660,153,660` | `[VERIFIED]` |
| Balance with Promoter | `promoter_balance` | Decimal | `INR 128,037,906` | `[VERIFIED]` |

---

## 3. Completion Document Categories (Observed on Tab 7)

| Document Category | Technical Key | File Type | Classification | Status |
| :--- | :--- | :--- | :--- | :--- |
| 1. Stability Certificate | `doc_stability_cert` | PDF | Statutory Structural Clearance | `[VERIFIED]` |
| 2. Road-cutting Permission | `doc_road_cutting_perm` | PDF | Municipal Permission | `[VERIFIED]` |
| 3. Final Fire NOC | `doc_fire_noc` | PDF | Fire Department Clearance | `[VERIFIED]` |
| 4. Occupancy Certificate (OC) | `doc_occupancy_cert` | PDF | Critical Handover Document | `[VERIFIED]` |
| 5. KSPCB Consent | `doc_kspcb_consent` | PDF | Environmental / Pollution Clearance | `[VERIFIED]` |
| 6. Electrical / Lift Clearance | `doc_electrical_lift_cert`| PDF | Electrical Inspectorate Clearance | `[VERIFIED]` |
| 7. Power Sanction | `doc_power_sanction` | PDF | Utility Power Sanction (BESCOM) | `[VERIFIED]` |
| 8. Water & Sanitary Approval | `doc_water_sanitary_board`| PDF | Utility Water/Sewerage Approval (BWSSB) | `[VERIFIED]` |
| 9. External Infrastructure Completion | `doc_infra_completion` | PDF | Site Works Certification | `[VERIFIED]` |
| 10. Common Amenities & Handover | `doc_amenities_handover` | PDF | Resident Association Handover | `[VERIFIED]` |
| 11. Undivided Land Share Handover | `doc_uds_handover` | PDF | Land Ownership Transfer | `[VERIFIED]` |
| 12. Architect Completion Certificate | `doc_architect_completion`| PDF | Form 4 / Technical Completion | `[VERIFIED]` |
| 13. CA Completion Certificate | `doc_ca_completion` | PDF | Financial Audit Certification | `[VERIFIED]` |
| 14. Promoter Affidavit & Photographs | `doc_affidavit_photos` | PDF / JPG | Legal Affirmation & Site Evidence | `[VERIFIED]` |

---

## 4. Document Ingestion Feasibility Workstream (Architecture & Schema)

*Note: Document ingestion is decoupled from the primary project catalogue pipeline. Zero bulk downloads.*

### Architecture Decision: Category-First Lineage
- **Primary Classification:** The official K-RERA **Document Category** displayed beside the download link is the canonical classification key.
- **Filename Non-Authoritativeness:** Actual PDF filenames vary arbitrarily across projects and cannot be used as the authoritative classifier.
- **Relational Model:**
  $$\text{Project} \longrightarrow \text{Document Category} \longrightarrow \text{Source Download Link} \longrightarrow \text{Downloaded File}$$

### Recommended Document Metadata Contract
Every document record ingested into the document store must capture:

| Attribute Name | Data Type | Nullable? | Description / Extraction Source |
| :--- | :--- | :--- | :--- |
| `project_id` | String / UUID | No | HomeSure internal unique project identifier |
| `registration_number` | String | No | Official K-RERA project registration number |
| `document_category` | String | No | Canonical portal UI label (e.g., `Occupancy Certificate`) |
| `original_filename` | String | No | Raw filename delivered by server or saved by browser |
| `source_document_url` | String | No | Full download URL or handler link from DOM |
| `file_type` | String | No | MIME type / file extension (e.g., `application/pdf`, `.pdf`) |
| `downloaded_at` | Timestamp (UTC)| No | ISO 8601 timestamp of retrieval |
| `verification_status` | Enum | No | `VERIFIED`, `FLAGGED_MISMATCH`, `PENDING_REVIEW` |
| `storage_path` | String | No | Internal URI in secure object vault / blob storage |

### Validation & Discrepancy Policy
- **Preserve Provenance:** Original filename and source URL must always be retained in storage metadata.
- **Never Classify Solely by Filename:** Regex matching on raw filenames is strictly disallowed for routing.
- **Content Match Requirement:** Do not assume file contents match the displayed category without parsing/validation.
- **Discrepancy Flagging:** If document text or headers contradict the portal category (e.g., file labeled *Occupancy Certificate* actually contains a *Commencement Certificate* or *Bank Statement*), the file must be tagged as `FLAGGED_MISMATCH` and routed to manual human review.

---

### Priority Pilot Target Documents (Non-Sensitive Only)
| Document Target | Statutory Significance | Target Section / Tab | Download Verification Status |
| :--- | :--- | :--- | :--- |
| **Occupancy Certificate (OC)** | Proof of physical completion & handover clearance | Completion Details (Tab 7) / Uploaded Docs | `[PENDING EVALUATION]` |
| **Commencement Certificate (CC)** | Proof of municipal start approval & zoning | Uploaded Documents (Tab 3) | `[PENDING EVALUATION]` |
| **Approved Building / Sanction Plan** | Architectural specification & layout legality | Uploaded Documents (Tab 3) | `[PENDING EVALUATION]` |

### Per-Document Evaluation Contract (Pilot Phase)
Each downloaded pilot document must record:
1. `doc_category`: UI label in the portal
2. `original_filename`: Raw filename as saved by browser
3. `file_format`: Extension / MIME type (e.g. PDF)
4. `file_size_bytes`: File size on disk
5. `download_behaviour`: Direct browser download vs. in-page PDF viewer
6. `content_match_flag`: Binary indicator whether text in document matches its label
7. `project_match_flag`: Binary indicator whether document header matches target project registration
8. `governance_status`: `[APPROVED - NON_SENSITIVE]` vs `[RESTRICTED - PII / EXCLUDED]`
