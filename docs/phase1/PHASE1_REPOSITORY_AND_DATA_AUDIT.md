# HomeSure Phase 1 — Repository and Data-Source Audit (`PHASE1_REPOSITORY_AND_DATA_AUDIT.md`)

**Date:** 2026-11-10  
**Repository:** `https://github.com/vinocj-oss/homesure-ai.git` (`main` @ `6db7592`)  
**Workspace:** `c:\Program Files\BlackMatter\Homesure`  
**Firebase Project:** `homesureai-51893` (`asia-south1`, `FIRESTORE_NATIVE`, `STANDARD`)

---

## 1. Executive Summary & Blocking Clarification

### ⚠️ Blocking Clarification Required Before Executing Production Import (Stage 1 Gate)
Per Stage 1 requirements:
> *"Inspect the eight selected projects individually and identify their actual data coverage and structural variations. If the eight projects are not explicitly identifiable through an existing manifest, configuration, or documented selection, do not select eight projects yourself. Report this as a blocking clarification."*

An exhaustive inspection of `KRERA-Data-Extraction/` (`data/k_rera_extraction.sqlite`, `data/pilot/`, `data/batch_phase3a/`, `data/batch_phase3b/`, `data/batch_phase3c/`, `data/batch_phase3d/`, and `scripts/`) confirms that **no manifest, configuration, or documented selection explicitly defines "eight selected central projects."**

Specifically:
1. **Context of "8-center" / "Eight selected central projects"**: In the prior conversation turn, the request to *"Start the mapping process and import the 8-center project catalog here in the app"* was a voice-to-text transcription of **"875 project catalog"** (referring to the **875 verified projects** in `detail_extraction_checkpoints`).
2. **Actual Manifests Present in `KRERA-Data-Extraction/data/`**:
   - **Total Verified Projects in SQLite (`detail_extraction_checkpoints`)**: **875 projects** (25 in Phase 3A + 100 in Phase 3B + 250 in Phase 3C + 500 in Phase 3D).
   - **Phase 2 Pilot (`data/pilot/`)**: **5 projects** (`Godrej United`, `Godrej Air`, `PRESTIGE BOULEVARD`, `ecopolis Block-2`, `HASIRU VISTHARA`).
   - **Phase 3A Stratified Manifest (`data/batch_phase3a/phase3a_selected_25_manifest.json`)**: **25 projects**, stratified inside `scripts/phase3a_batch_extractor.py` into:
     - *Early Catalogue Page Stratum*: 9 projects
     - *Middle ("Central") Catalogue Page Stratum*: **8 projects** (`ecopolis Block-2`, `PRESTIGE BOULEVARD`, `SNN Raj Etternia`, `HASIRU VISTHARA`, `TOTAL ENVIRONMENT LEARNING TO FLY`, `SALARPURIA SATTVA EAST CREST`, `Salarpuria Sattva Magnus`, `DS-MAX SKYCITY`)
     - *Late Catalogue Page Stratum*: 8 projects
   - **First 8 Projects by Extraction Order (`rowid 1..8` in `detail_extraction_checkpoints`)**: `Godrej United`, `Godrej Air`, `Polaris`, `vajram tiara`, `Chartered Hummingbird`, `ARATT GRAND TOWN`, `ecopolis Block-2`, `PRESTIGE BOULEVARD`.

**Action Required from Product / Engineering Lead:**
Before executing the Firestore import in Stage 4, please confirm whether we should:
- **Option A**: Import **all 875 verified projects** from `k_rera_extraction.sqlite` (if "eight selected central projects" originated from the "8-center" / "875" voice-to-text transcription), **OR**
- **Option B**: Import an initial **8-project cohort** first (either the 8 Middle-Stratum projects from Phase 3A, the first 8 projects in `detail_extraction_checkpoints`, or a specific list of 8 RERA registration numbers you provide) and support `--all-selected` / `--all-verified` in the importer.

---

## 2. Existing Flutter Application Architecture

### 2.1 Framework & Build Configuration
- **Framework**: Flutter `3.47.9` (channel `stable`), Dart `3.13.7` (`sdk: ^3.10.7` in [`pubspec.yaml`](file:///c:/Program%20Files/BlackMatter/Homesure/pubspec.yaml)).
- **Application ID / Package**: `com.homesure.homesure` (`version: 1.0.0+1`).
- **Architecture Pattern**: Hybrid transitioning from a flat legacy MVP structure (`lib/models/`, `lib/screens/`, `lib/services/`, `lib/data/`) to a feature-first modular architecture (`lib/features/property/`, `lib/features/assessment/`, `lib/features/dashboard/`, `lib/features/report/`, `lib/features/workspace/`) coordinated via `provider` (`MultiProvider` in [`lib/main.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/main.dart#L36-L78)).

### 2.2 Relevant File Paths
| Area | File Path | Role |
|---|---|---|
| App Entry & DI | [`lib/main.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/main.dart) | Initializes Firebase, configures `MultiProvider`, sets `kUseFirebaseEmulators = true` |
| Firebase Options | [`lib/firebase_options.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/firebase_options.dart) | Generated FlutterFire config for `homesureai-51893` |
| Legacy Property Model | [`lib/models/property.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/models/property.dart) | 12-field UI model (`id`, `name`, `builder`, `location`, `priceRange`, `configs`, `possessionDate`, `reraId`, `imageUrl`, `highlights`, `totalUnits`, `areaSize`) |
| Feature Property Model | [`lib/features/property/models/property.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/features/property/models/property.dart) | 6-field feature model (`id`, `name`, `builder`, `location`, `reraId`, `metadata`) |
| Property Adapter | [`lib/features/property/models/property_adapter.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/features/property/models/property_adapter.dart) | Bridges `legacy.Property` <-> `feature.Property` via `metadata` map |
| Hardcoded Property Catalogue | [`lib/data/properties.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/data/properties.dart) | Defines 2 hardcoded mock properties (`Casagrand Aquene`, `Prestige Lakeside Habitat`) |
| Property Repository | [`lib/features/property/services/property_repository.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/features/property/services/property_repository.dart) | Currently ignores Firestore for catalogue reads; returns `mockProperties` after a 300ms delay; writes unverified custom properties to `property_submissions` |
| Property State | [`lib/features/property/state/property_state.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/features/property/state/property_state.dart) | `ChangeNotifier` holding `availableProperties` and `selectedProperty` |
| Property Search Screen | [`lib/screens/onboarding/property_search_screen.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/onboarding/property_search_screen.dart) | Imports `mockProperties` directly from `lib/data/properties.dart` and filters in-memory |
| Property Details Screen | [`lib/screens/property/property_details_screen.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/property/property_details_screen.dart) | Renders `legacy.Property` summary + hardcoded mock strings (`"6.5 Acres"`, `"540 Units"`, `"72%"` open space, `"85/100"` trust score, `"Clear Title"`, `"OC Status: Pending"`) |
| Property Card Widget | [`lib/widgets/property_card.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/widgets/property_card.dart) | Renders a `legacy.Property` card in `PropertySearchScreen` |
| Firestore Rules | [`firestore.rules`](file:///c:/Program%20Files/BlackMatter/Homesure/firestore.rules) | Currently only defines rules for `/users/{userId}` and `/property_submissions/{submissionId}` |
| Firestore Indexes | [`firestore.indexes.json`](file:///c:/Program%20Files/BlackMatter/Homesure/firestore.indexes.json) | Currently empty (`{"indexes": [], "fieldOverrides": []}`) |

---

## 3. Existing Property Models & Duplicate Models

HomeSure currently suffers from split-brain property modeling across two classes:

### 3.1 `legacy.Property` ([`lib/models/property.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/models/property.dart))
```dart
class Property {
  final String id;
  final String name;
  final String builder;
  final String location;
  final String priceRange;
  final List<String> configs;
  final String possessionDate;
  final String reraId;
  final String imageUrl;
  final List<String> highlights;
  final int totalUnits;
  final String areaSize;
}
```
- **Consumers**: [`PropertySearchScreen`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/onboarding/property_search_screen.dart), [`PropertyDetailsScreen`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/property/property_details_screen.dart), [`PropertyCard`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/widgets/property_card.dart), [`PropertyHeroCard`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/widgets/dashboard/property_hero_card.dart), [`UnifiedMainScreen`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/main/unified_main_screen.dart).
- **Limitations**:
  - Has **no** `fromJson` / `toJson` / `fromFirestore` serialization methods.
  - Assumes marketing/listing fields (`priceRange`, `configs`, `imageUrl`, `highlights`) are always non-null strings/lists, whereas K-RERA regulatory records do not provide marketing prices or hero stock photos.
  - Has no representation for K-RERA tabs, sections, observation states (`present_with_data`, `present_empty`, `not_present`, etc.), regulatory documents, complaints, or `Project -> Phase -> Tower -> Unit` hierarchy.

### 3.2 `feature.Property` ([`lib/features/property/models/property.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/features/property/models/property.dart))
```dart
class Property {
  final String id;
  final String name;
  final String builder;
  final String location;
  final String reraId;
  final Map<String, dynamic> metadata;
}
```
- **Consumers**: [`PropertyRepository`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/features/property/services/property_repository.dart), [`PropertyState`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/features/property/state/property_state.dart), [`DashboardDataCoordinator`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/features/dashboard/services/dashboard_data_coordinator.dart).
- **Limitations**: Stashes extra fields loosely into an untyped `metadata` map via [`PropertyAdapter`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/features/property/models/property_adapter.dart).

---

## 4. Existing Property Repository, Search Screen & Details Screen

### 4.1 `PropertyRepository` ([`lib/features/property/services/property_repository.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/features/property/services/property_repository.dart))
- `getAvailableProperties()` simulates network latency (`Future.delayed(const Duration(milliseconds: 300))`) and returns `legacy_data.mockProperties.map(PropertyAdapter.fromLegacy).toList()`.
- `getPropertyById(String id)` calls `getAvailableProperties()` and looks up `id` in memory.
- `submitCustomProperty(...)` writes user-entered unverified projects to `/property_submissions` in Firestore.

### 4.2 `PropertySearchScreen` ([`lib/screens/onboarding/property_search_screen.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/onboarding/property_search_screen.dart))
- Bypasses `PropertyState` and `PropertyRepository` completely on load! Line 6 imports `../../data/properties.dart` directly and initializes `_filteredProperties = mockProperties`.
- Filters `_filteredProperties` synchronously in memory across `name`, `builder`, `location`, and `reraId`.
- When a user taps a `PropertyCard`, it navigates directly to `PropertyDetailsScreen(property: property)`.

### 4.3 `PropertyDetailsScreen` ([`lib/screens/property/property_details_screen.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/property/property_details_screen.dart))
- Displays `property.name`, `property.builder`, `property.location`, `property.reraId`, `property.possessionDate`, `property.configs`, and `property.priceRange`.
- **Hardcoded Mock Values Inside Widget Code**:
  - Line 117: `"85/100"` ("Prelim Trust Score")
  - Line 218: `"6.5 Acres"` ("Total Area" — ignores `property.areaSize`!)
  - Line 219: `"540 Units"` ("Total Units" — ignores `property.totalUnits`!)
  - Line 221: `"72%"` ("Open Space")
  - Lines 234–253: Hardcoded `"RERA Registered"`, `"Clear Title"` (`"Verified"`), `"OC Status"` (`"Pending"`).

---

## 5. Existing Firebase & Firestore Configuration

### 5.1 Firebase Project & Database
- **Project ID**: `homesureai-51893` (Project Number `192920993152`).
- **Firestore Database**: `(default)` in `asia-south1` (Mumbai), `FIRESTORE_NATIVE`, `STANDARD` edition.
- **Current Live Collections**:
  1. `users/{uid}` (with subcollections `assessments`, `workspace`, `documents`)
  2. `property_submissions/{submissionId}` (11 existing documents)
  - *Note*: There is currently no `projects` or `properties` collection in live Firestore.

### 5.2 Emulator Flag in `lib/main.dart`
- Line 22 of [`lib/main.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/main.dart#L22) hardcodes:
  ```dart
  const bool kUseFirebaseEmulators = true;
  ```
- When running in `kDebugMode`, this routes Firebase Auth (`9099`) and Cloud Firestore (`8180`) to `10.0.2.2` (Android) / `localhost` instead of the live `homesureai-51893` Cloud Firestore instance. To connect the app to the live Firestore catalogue by default (while still supporting emulators via `--dart-define=USE_FIREBASE_EMULATORS=true`), this constant should default to `bool.fromEnvironment('USE_FIREBASE_EMULATORS', defaultValue: false)`.

### 5.3 Existing `firestore.rules` & `firestore.indexes.json`
- [`firestore.rules`](file:///c:/Program%20Files/BlackMatter/Homesure/firestore.rules) currently blocks all access outside `/users/{userId}/**` and `/property_submissions/{submissionId}` via a catch-all `match /{document=**} { allow read, write: if false; }`.
- [`firestore.indexes.json`](file:///c:/Program%20Files/BlackMatter/Homesure/firestore.indexes.json) is empty (`{"indexes": [], "fieldOverrides": []}`).

---

## 6. SQLite Extraction Database & Normalized Output Audit

### 6.1 Database Location & Table Inventory
- **File Path**: `c:\Program Files\BlackMatter\Homesure\KRERA-Data-Extraction\data\k_rera_extraction.sqlite`
- **Tables & Row Counts**:

| Table Name | Row Count | Purpose |
|---|---:|---|
| `extraction_runs` | 4 | Tracks catalogue crawl runs (`run_id`, `district_filter`, `status`, `total_rows_extracted`) |
| `extracted_pages` | 446 | Checkpoints DataTables pagination pages (`page_number`, `row_count`, `first_reg_no`, `last_reg_no`) |
| `raw_search_rows` | 4,459 | Complete Bengaluru Urban K-RERA project catalogue search rows (`project_key`, `registration_number`, `acknowledgement_number`, `project_name`, `promoter_name`, `district`, `taluk`, `project_type`, `status`, `approved_on`, `proposed_completion_date`, `raw_cells_json`, `action_attrs_json`) |
| `detail_extraction_checkpoints` | **875** | Tracks deep portal detail extraction for 875 Bengaluru projects (`project_key`, `registration_number`, `acknowledgement_number`, `project_name`, `extraction_status`, `raw_html_path`, `raw_json_path`, `normalized_json_path`, `tabs_found_count`, `tabs_extracted_count`, `documents_found_count`, `identity_verification_status`, `retry_count`, `updated_at`) |
| `detail_extraction_error_logs` | 48 | Historical retry/timeout error log entries during batch scraping |

All **875 rows** in `detail_extraction_checkpoints` have:
- `extraction_status = 'successful'`
- `identity_verification_status = 'verified'`
- Valid normalized JSON files on disk (`KRERA-Data-Extraction/data/batch_phase3{a,b,c,d}/normalized/*.json`).

### 6.2 Normalized JSON Structure (`KRERA-Data-Extraction/scripts/models.py`)
Each normalized project JSON file conforms to `models.Project`:
- **Identity & Catalogue Metadata**:
  - `internal_id`: Deterministic key (`REG::<registration_number>`)
  - `registration_number`: Official K-RERA registration number (e.g., `PRM/KA/RERA/1251/446/PR/171010/000003`)
  - `acknowledgement_number`: K-RERA acknowledgement number (e.g., `PR/KN/170729/000003`)
  - `project_name`, `promoter_name`, `district` (`Bengaluru Urban`), `taluk`, `project_type`, `status`, `approved_on`, `proposed_completion_date`
  - `catalogue_source_info`: `{ page_number, row_index, raw_row_text }`
  - `identity_verification`: `{ is_verified, status, matched_fields, mismatched_fields, notes }`
- **`ObservationState` Enum**:
  1. `present_with_data`
  2. `present_empty`
  3. `not_present`
  4. `not_applicable`
  5. `not_available`
  6. `extraction_failed`
- **Dynamic Tabs (`tabs: Dict[str, ProjectTabObservation]`)**:
  Across the 875 extracted projects, 11 distinct visible tab labels appear with the following frequency and observation states:
  - `Promoter Details`: 875 (`present_with_data`: 875)
  - `Project Details`: 875 (`present_with_data`: 875)
  - `Uploaded Documents`: 875 (`present_with_data`: 873, `present_empty`: 2)
  - `Enquired Documents`: 875 (`present_with_data`: 491, `present_empty`: 384)
  - `Complaints`: 875 (`present_with_data`: 350, `present_empty`: 525) — **7,973 total complaint records** across 350 projects
  - `Quarterly Updates`: 875 (`present_with_data`: 260, `present_empty`: 615)
  - `Land Details`: 369 (`present_with_data`: 369)
  - `Bank Details`: 369 (`present_with_data`: 366, `present_empty`: 3)
  - `Completion Details`: 344 (`present_with_data`: 343, `present_empty`: 1)
  - `Project Extension Details`: 138 (`present_with_data`: 137, `present_empty`: 1)
  - `Modification of Plan Details`: 39 (`present_with_data`: 38, `present_empty`: 1)
- **Unlinked DOM Panes (`unlinked_dom_panes: Dict[str, ProjectTabObservation]`)**:
  K-RERA's server-rendered HTML frequently includes hidden Bootstrap tab panes (`#postReg`, `#modPlan`, `#extPlan`, `#completion`, `#menu3`, `#menu5`) that are not linked in the visible navigation bar. For example, `#postReg` is `present_with_data` in 846 projects.
- **Sections, Fields, Tables & Documents**:
  Each `ProjectTabObservation` contains `sections: List[SectionObservation]`, where each section has:
  - `section_name`, `observation_state`
  - `fields: Dict[str, FieldObservation]` (`raw_label`, `normalized_key`, `value`, `observation_state`, `source_section`, `source_tab`, `provenance`)
  - `tables: List[Dict[str, Any]]` (used for Complaints, Quarterly Updates, Development Work / Inventory tables, Noc lists, etc.)
  - `documents: List[DocumentArtifact]` (`document_type`, `label`, `observation_state`, `file_url`, `file_name`, `source_tab`, `source_section`)
- **PII Exclusions & Cross-Section Conflicts**:
  - `pii_exclusions`: Explicit log of excluded personal identifiers (e.g., PAN, Aadhaar, personal mobile/email).
  - `cross_section_conflicts`: Explicit log of discrepancies between catalogue headers and inner tab fields (e.g., project status or completion date mismatches).

### 6.3 Inspection of Eight Representative Projects (First 8 in `detail_extraction_checkpoints`)
To illustrate structural variations across real extracted projects:

| # | Project Name | Registration Number | Promoter | Taluk | Type | Visible Tabs (`present_with_data` / total) | Sections | Fields | Docs | Complaints State |
|---:|---|---|---|---|---|---:|---:|---:|---:|---|
| 1 | **Godrej United** | `PRM/KA/RERA/1251/446/PR/171010/000003` | United Oxygen Company Pvt Ltd | Bengaluru East | Residential/Group Housing | 5 / 7 | 24 | 177 | 88 | `present_with_data` |
| 2 | **Godrej Air** | `PRM/KA/RERA/1251/446/PR/170819/000006` | Godrej Housing Projects LLP | Bengaluru East | Residential/Group Housing | 5 / 7 | 24 | 164 | 89 | `present_with_data` |
| 3 | **Polaris** | `PRM/KA/RERA/1251/446/PR/171015/000268` | Citrus Properties Pvt Ltd | Bengaluru East | Plotted Development | 4 / 7 | 20 | 150 | 70 | `present_empty` |
| 4 | **vajram tiara** | `PRM/KA/RERA/1251/309/PR/170913/000144` | vajram estates private limited | Bengaluru North | Residential/Group Housing | 5 / 7 | 18 | 133 | 69 | `present_with_data` |
| 5 | **Chartered Hummingbird** | `PRM/KA/RERA/1251/310/PR/170824/000049` | Chartered Housing Pvt Ltd | Bengaluru South | Residential/Group Housing | 5 / 7 | 22 | 157 | 70 | `present_with_data` |
| 6 | **ARATT GRAND TOWN** | `PRM/KA/RERA/1251/308/PR/171222/000932` | ARATT GRAND TOWN | Anekal | Plotted Development | 5 / 7 | 16 | 122 | 70 | `present_with_data` |
| 7 | **ecopolis Block-2** | `PRM/KA/RERA/1251/309/PR/171014/000662` | hinduja realty ventures limited | Bengaluru North | Commercial | 3 / 6 | 20 | 146 | 66 | `present_empty` |
| 8 | **PRESTIGE BOULEVARD** | `PRM/KA/RERA/1251/446/PR/170824/000057` | Prestige Estates Projects Limited | Bengaluru East | Residential/Group Housing | 5 / 7 | 21 | 178 | 69 | `present_with_data` |

And the **8 Middle ("Central") Stratum Projects** in `phase3a_selected_25_manifest.json` (`index 9..16`):
1. `ecopolis Block-2` (`PRM/KA/RERA/1251/309/PR/171014/000662`) — Commercial, Bengaluru North
2. `PRESTIGE BOULEVARD` (`PRM/KA/RERA/1251/446/PR/170824/000057`) — Residential/Group Housing, Bengaluru East
3. `SNN Raj Etternia` (`PRM/KA/RERA/1251/446/PR/170902/000083`) — Residential/Group Housing, Bengaluru East
4. `HASIRU VISTHARA` (`PRM/KA/RERA/1251/308/PR/180504/001616`) — Plotted Development, Anekal
5. `TOTAL ENVIRONMENT LEARNING TO FLY` (`PRM/KA/RERA/1251/310/PR/171014/000450`) — Residential/Group Housing, Bengaluru South
6. `SALARPURIA SATTVA EAST CREST` (`PRM/KA/RERA/1251/446/PR/171014/000548`) — Residential/Group Housing, Bengaluru East
7. `Salarpuria Sattva Magnus` (`PRM/KA/RERA/1251/310/PR/170905/000143`) — Residential/Group Housing, Bengaluru South
8. `DS-MAX SKYCITY` (`PRM/KA/RERA/1251/309/PR/180131/001126`) — Residential/Group Housing, Bengaluru North

---

## 7. Data Inconsistencies, Risks & Implementation Dependencies

1. **Firestore 1 MiB Document Size Limit vs. Deep K-RERA Payloads**:
   - Some large K-RERA projects contain 100+ documents, dozens of quarterly update tables, and 50+ complaints. Storing the entire raw `tabs` and `unlinked_dom_panes` tree inside a single root `projects/{projectId}` document risks approaching Firestore's 1 MiB limit and would make search list queries slow and expensive.
   - **Mitigation**: Split the Firestore data model into:
     - Lightweight root document `projects/{projectId}` containing identity, normalized search fields, summary metrics, tab observation state summary, and provenance.
     - Subcollections for heavy/variable-cardinality records:
       - `projects/{projectId}/regulatory_tabs/{tabKey}` (full sections, fields, and tables per tab/pane)
       - `projects/{projectId}/documents/{docId}` (all regulatory document metadata & URLs)
       - `projects/{projectId}/complaints/{complaintId}` (individual complaint records)
       - `projects/{projectId}/phases/{phaseId}`, `towers/{towerId}`, `units/{unitId}` (unit-level hierarchy foundation).
2. **Inconsistent Date & Casing Formats in K-RERA**:
   - Dates appear as `DD/MM/YYYY` (`10/10/2017`), `DD-MM-YYYY`, or ISO timestamps, and project/promoter names vary between UPPERCASE, Title Case, and lowercase (`vajram tiara`).
   - **Mitigation**: Preserve exact `raw_*` strings from K-RERA alongside normalized lowercase search fields (`project_name_lower`, `promoter_name_lower`, `registration_number_normalized`, `search_tokens`) and parsed ISO-8601 dates where valid.
3. **Document Table Column Headers in K-RERA**:
   - In K-RERA's HTML tables, some multi-column Yes/No checklist rows produce generic labels like `Column_6 (YES)` when parsed generically, while actual downloadable file rows carry descriptive labels (`Relinquishment Deed`, `Advocate Search Report`, `Form-4 Certificate`). Both must be preserved accurately with their `source_section` and `file_url` status.
