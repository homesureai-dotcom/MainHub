# HomeSure — Comprehensive QA Test Inventory & Regression Matrix

**Document Reference**: `docs/phase1/qa/HOMESURE_QA_TEST_INVENTORY.md`  
**Application**: HomeSure Mobile App (`com.example.homesure_ai`)  
**Target Environment**: Android 15 Emulator / Cloud Firestore (`homesureai-51893`)  
**Audit Date**: November 10, 2026  
**Total Test Cases Catalogued**: 42  

---

## 1. Test Inventory by Category

### Suite A: Application Launch & Navigation
| Test ID | Test Scenario | Execution Mode | Result | Regression Priority | Automation Script |
|---|---|---|---|---|---|
| **A01** | Cold launch from Android launcher | Emulator UI (ADB) | PASS | P0 (Smoke) | `run_qa_suite_a_b.py` |
| **A02** | User session restoration on launch | Emulator UI (ADB) | PASS | P1 (Functional) | `run_qa_suite_a_b.py` |
| **A03** | Navigation to Properties tab (Tab 2) | Emulator UI (ADB) | PASS | P0 (Smoke) | `run_qa_suite_a_b.py` |
| **A04** | Initial view shows Builder catalogue | Emulator UI (ADB) | PASS | P0 (Smoke) | `run_qa_suite_a_b.py` |
| **A05** | Bottom layout verification (absence of old 3 buttons) | Emulator UI (ADB) | PASS | P1 (UI) | `run_qa_suite_a_b.py` |
| **A06** | "Not listed?" button opens modal sheet | Emulator UI (ADB) | PASS | P2 (Functional) | `run_qa_suite_a_b.py` |
| **A07** | Dismissal of unlisted bottom sheet | Emulator UI (ADB) | PASS | P2 (Functional) | `run_qa_suite_a_b.py` |
| **A08** | Bottom tab switching and return to Properties | Emulator UI (ADB) | PASS | P1 (Navigation) | `run_qa_suite_a_b.py` |
| **A09** | Rapid repeated tab switching | Emulator UI (ADB) | PASS | P2 (Performance) | `run_qa_suite_a_b.py` |
| **A10** | Android back navigation from nested screens | Emulator UI (ADB) | PASS | P1 (Navigation) | `execute_e2e_journeys.py` |

### Suite B: Builder Catalogue & Search
| Test ID | Test Scenario | Execution Mode | Result | Regression Priority | Automation Script |
|---|---|---|---|---|---|
| **B01** | Full builder catalogue loading from Firestore | Emulator UI + REST | PASS | P0 (Data/Smoke) | `audit_firestore_data_integrity.py` |
| **B02-01** | Search builder by exact name: "Godrej" | Emulator UI (ADB) | PASS | P0 (Core Journey) | `run_all_qa_journeys.py` |
| **B02-02** | Search builder by exact name: "Prestige" | Emulator UI (ADB) | PASS | P0 (Core Journey) | `run_all_qa_journeys.py` |
| **B02-03** | Search builder by exact name: "Brigade" | Emulator UI (ADB) | PASS | P0 (Core Journey) | `run_all_qa_journeys.py` |
| **B02-04** | Search builder by exact name: "Shriram" | Emulator UI (ADB) | PASS | P1 (Functional) | `run_all_qa_journeys.py` |
| **B02-05** | Search builder by exact name: "Sattva" | Emulator UI (ADB) | PASS | P1 (Functional) | `run_all_qa_journeys.py` |
| **B02-06** | Search nonexistent builder: "NonexistentBuilderXYZ" | Emulator UI (ADB) | PASS | P1 (Functional) | `run_all_qa_journeys.py` |
| **B02-07** | Search with leading/trailing spaces: "  godrej  " | Emulator UI (ADB) | PASS | P2 (UX/Robustness) | `run_all_qa_journeys.py` |
| **B02-08** | Case-insensitive search: "PRESTIGE" | Emulator UI (ADB) | PASS | P2 (UX/Robustness) | `run_all_qa_journeys.py` |
| **B02-09** | Search field clearing and full catalogue restore | Emulator UI (ADB) | PASS | P1 (Functional) | `run_all_qa_journeys.py` |
| **B03** | Builder catalog consistency & SPV deduplication | Python Firestore Audit | PASS | P0 (Data Integrity) | `audit_firestore_data_integrity.py` |

### Suite C: Builder-to-Property Navigation
| Test ID | Test Scenario | Execution Mode | Result | Regression Priority | Automation Script |
|---|---|---|---|---|---|
| **C01** | Open Godrej Properties -> verify 9 projects | Emulator UI (ADB) | PASS | P0 (Core Journey) | `execute_e2e_journeys.py` |
| **C02** | Open Prestige Group -> verify 13 projects | Emulator UI (ADB) | PASS | P0 (Core Journey) | `execute_e2e_journeys.py` |
| **C03** | Open Brigade Group -> verify 15 projects | Emulator UI (ADB) | PASS | P0 (Core Journey) | `execute_e2e_journeys.py` |
| **C04** | In-builder project filtering ("United" under Godrej) | Emulator UI (ADB) | PASS | P1 (Functional) | `execute_e2e_journeys.py` |
| **C05** | In-builder project filtering ("Boulevard" under Prestige)| Emulator UI (ADB) | PASS | P1 (Functional) | `execute_e2e_journeys.py` |

### Suite D: Property Selection & Details
| Test ID | Test Scenario | Execution Mode | Result | Regression Priority | Automation Script |
|---|---|---|---|---|---|
| **D01** | Open Godrej United details | Emulator UI (ADB) | PASS | P0 (Core Journey) | `execute_e2e_journeys.py` |
| **D02** | Open Boulevard at Godrej Woodscapes details | Emulator UI (ADB) | PASS | P1 (Functional) | `execute_e2e_journeys.py` |
| **D03** | Open PRESTIGE BOULEVARD details | Emulator UI (ADB) | PASS | P0 (Core Journey) | `execute_e2e_journeys.py` |
| **D04** | Open Brigade project details | Emulator UI (ADB) | PASS | P1 (Functional) | `execute_e2e_journeys.py` |
| **D05** | Verify absence of stale property state on switch | Emulator UI (ADB) | PASS | P1 (State Integrity) | `execute_e2e_journeys.py` |

### Suite E & F: Regulatory Sections & Documents
| Test ID | Test Scenario | Execution Mode | Result | Regression Priority | Automation Script |
|---|---|---|---|---|---|
| **E01** | Display of 24 key regulatory sections in bundle | Emulator UI (ADB) | PASS | P0 (Core Regulatory) | `inspect_project_details_bundle.py` |
| **E02** | Observation state badges (present_with_data / empty) | Emulator UI (ADB) | PASS | P1 (Compliance) | `inspect_project_details_bundle.py` |
| **F01** | Display of regulatory documents (91 docs for Godrej) | Emulator UI (ADB) | PASS | P0 (Core Regulatory) | `inspect_project_details_bundle.py` |
| **F02** | Document row interaction & download link trigger | Manual / Code Audit | PARTIAL | P2 (Enhancement) | Visual inspection |

### Suite G: Complaints Inspection
| Test ID | Test Scenario | Execution Mode | Result | Regression Priority | Automation Script |
|---|---|---|---|---|---|
| **G01** | Display of official complaints (6 on Godrej United) | Emulator UI (ADB) | PASS | P0 (Legal/Trust) | `inspect_project_details_bundle.py` |
| **G02** | Display of high complaint volume (77 on Prestige Blvd)| Emulator UI (ADB) | PASS | P1 (Performance/Data)| `inspect_project_details_bundle.py` |
| **G03** | Display of zero-complaint project (MALHAR PATTERNS) | Emulator UI (ADB) | PASS | P1 (Edge Case) | `inspect_project_details_bundle.py` |

### Suite H, I, J, K, L: Non-Functional, Security & Automated Tests
| Test ID | Test Scenario | Execution Mode | Result | Regression Priority | Automation Script |
|---|---|---|---|---|---|
| **H01** | Plotted developments without towers (KNS Infrastructure) | Emulator UI (ADB) | PASS | P1 (Data Variant) | `run_targeted_journeys.py` |
| **I01** | Firestore full-dataset mapping audit (875 projects) | Python REST Audit | PASS | P0 (Data Integrity) | `audit_firestore_data_integrity.py` |
| **J01** | Initial catalogue fetch performance (<1.5s) | Benchmark | PASS | P1 (SLA/Performance) | Network profiler |
| **K01** | Firestore security rules write denial on `/projects` | Python REST | PASS | P0 (Security) | `audit_firestore_data_integrity.py` |
| **K02** | Firestore security rules write denial on `/builders` | Python REST | PASS | P0 (Security) | `audit_firestore_data_integrity.py` |
| **K03** | Public read-only access to `/projects/{id}` | Python REST | PASS | P0 (Security) | `audit_firestore_data_integrity.py` |
| **L01** | Flutter unit & widget test execution (883 tests) | `flutter test` | PASS | P0 (CI Gate) | `flutter test` |
| **L02** | Flutter static analysis verification | `flutter analyze` | PASS | P0 (CI Gate) | `flutter analyze` |

---

## 2. Evidence Mapping

All execution screenshots are stored in `docs/phase1/qa/evidence/`:

| Screenshot File | Associated Test IDs | Description |
|---|---|---|
| `01_initial_state.png` | A01 | Android device running app |
| `A01_app_running_home.png` | A01, A02 | App home screen with active user session |
| `A03_properties_screen_loaded.png` | A03, A04, A05 | Properties screen with builder catalogue & compact layout |
| `A06_not_listed_bottom_sheet.png` | A06 | "Not listed?" bottom modal sheet |
| `A07_bottom_sheet_closed.png` | A07 | Screen after dismissing bottom sheet |
| `A08_navigated_away_to_home.png` | A08 | Home tab active |
| `A08_navigated_back_to_properties.png` | A08 | Properties tab restored |
| `B01_builder_catalogue_scrolled.png` | B01, J01 | Scrolled view of canonical builder list |
| `B02_01_search_godrej.png` | B02-01 | Filtered result for "Godrej" (Godrej Properties, 9 projects) |
| `B02_02_search_prestige.png` | B02-02 | Filtered result for "Prestige" (Prestige Group, 13 projects) |
| `B02_03_search_brigade.png` | B02-03 | Filtered result for "Brigade" (Brigade Group, 15 projects) |
| `B02_04_search_shriram.png` | B02-04 | Filtered result for "Shriram" (Shriram Properties, 10 projects) |
| `B02_05_search_sattva.png` | B02-05 | Filtered result for "Sattva" (Sattva Group, 7 projects) |
| `B02_06_search_nonexistent.png` | B02-06 | Empty state for "NonexistentBuilderXYZ" |
| `B02_07_search_spaces_godrej.png` | B02-07 | Trimmed search result for "  godrej  " |
| `B02_08_search_uppercase_prestige.png` | B02-08 | Case-insensitive result for "PRESTIGE" |
| `B02_09_catalogue_restored_680.png` | B02-09, B03 | Full catalogue restored with "680 Builders" badge |
| `J1_01_godrej_projects_screen.png` | C01 | Godrej Properties page with 9 registered projects |
| `J1_02_woodscapes_details_top.png` | D02 | Boulevard at Godrej Woodscapes details |
| `J1_04_godrej_search_united.png` | C04 | In-builder search for "United" |
| `J1_05_godrej_united_details_top.png` | D01 | Godrej United details (RERA registration, promoter) |
| `J1_06_godrej_united_details_mid.png` | E01, E02 | Godrej United regulatory sections and observation states |
| `J1_07_godrej_united_details_complaints.png` | F01, G01 | Godrej United 91 documents & 6 official complaints |
| `J1_08_returned_to_properties.png` | A10, C01 | Clean back navigation to Properties catalogue |
| `J2_01_prestige_projects_screen.png` | C02 | Prestige Group page with 13 registered projects |
| `J2_02_prestige_search_boulevard.png` | C05 | In-builder search for "Boulevard" under Prestige |
| `J2_03_prestige_boulevard_details_top.png` | D03 | PRESTIGE BOULEVARD top details |
| `J2_04_prestige_boulevard_complaints_77.png` | G02 | PRESTIGE BOULEVARD 77 complaints and 72 documents |
| `J3_01_brigade_projects_screen.png` | C03 | Brigade Group page with 15 registered projects |
| `J3_02_brigade_projects_scrolled.png` | C03 | Scrolled view of Brigade projects |
| `J6_01_empty_search_verified.png` | B02-06 | Verified empty search layout with "My project isn't listed" |
| `J6_02_catalogue_recovered_verified.png`| B02-09 | Verified 680 builders restored |

---

## 3. Future Regression Testing Requirements for CI/CD

1. **Pre-Commit / Pre-PR Gate**:
   - `flutter analyze` (Zero compilation errors, zero warnings in production code).
   - `flutter test` (All 883 unit & widget tests must pass).
2. **Post-Import Data Integrity Gate**:
   - `python KRERA-Data-Extraction/scripts/firestore_import/build_and_upload_builders.py` validation.
   - `python audit_firestore_data_integrity.py` ensuring all imported projects map to exactly one canonical builder with zero duplicates.
3. **Smoke UI Automation Gate**:
   - Headless or emulator UI run of `run_all_qa_journeys.py` on release candidate APK builds.
