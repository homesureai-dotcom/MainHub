# HomeSure AI — Complete Feature & Module Inventory

**Document Identifier:** `HOMESURE_FEATURE_INVENTORY.md`  
**Audit Date:** November 9, 2026  
**Auditor:** Antigravity AI Engineering  
**Application Root:** `c:\Program Files\BlackMatter\Homesure`  

---

## 1. Classification Methodology

Every module and capability in the codebase is categorized into one of six operational tiers:
1. **Fully implemented**: Code is written, tested, connected to persistence/services, and operational.
2. **Partially implemented**: Core functionality exists but is missing critical capabilities or edge cases.
3. **UI only / mock data**: Visual interface is complete, but data is static, hardcoded, or disconnected from backends.
4. **Backend only**: Backend code, Firestore rules, or data pipelines exist without a corresponding frontend UI.
5. **Planned but not implemented**: Declared in specifications or navigation tabs, but code is a stub or placeholder.
6. **Broken or inaccessible**: Code exists in repository but cannot be reached or fails at runtime.

---

## 2. Comprehensive Feature Matrix

| Feature / Capability | Classification | Primary Code References | Operational Behavior & Dependencies |
| :--- | :---: | :--- | :--- |
| **Email/Password Authentication** | **Fully implemented** | `lib/features/auth/services/auth_service.dart`, `lib/features/auth/screens/auth_screen.dart` | Handles user registration, email validation, authentication, and Firebase state listening. Depends on Firebase Auth. |
| **Password Reset** | **Fully implemented** | `lib/features/auth/screens/auth_screen.dart#L79` | Sends official Firebase Auth password recovery emails to registered addresses. |
| **Onboarding Walkthrough** | **Fully implemented** | `lib/screens/onboarding/welcome_screen.dart`, `lib/data/onboarding_data.dart` | 3-step carousel with smooth page indicator and skip logic. Zero backend dependencies. |
| **City Selection Onboarding** | **Partially implemented** | `lib/screens/onboarding/city_selection_screen.dart`, `lib/features/auth/services/user_profile_service.dart` | Saves user's chosen city and unlocks `onboardingCompleted` in Firestore. However, the search text field has no filter logic implemented. |
| **Mathematical PHS Engine** | **Fully implemented** | `lib/core/engine/weighted_phs_calculator.dart`, `lib/core/engine/engine.dart` | Zero-UI mathematical calculation of 6 pillars: Legal (25%), Quality (25%), Utilities (15%), Safety (15%), Community (10%), Docs (10%). 100% test-backed. |
| **Assessment Questionnaire** | **Fully implemented** | `lib/screens/assessment/assessment_screen.dart`, `lib/data/phs_questions.dart` | Administers 33 standardized questions across all 6 statutory pillars. Fully handles answer state, scoring metadata, and answer validations. |
| **Dual Assessment Views** | **Fully implemented** | `lib/widgets/assessment/classic_category_accordion.dart`, `lib/widgets/assessment/premium_assessment_view.dart` | Allows users to toggle between standard category accordion and premium card-swiping view with interactive category heatmap. |
| **Multi-Source Evidence Capture** | **Fully implemented** | `lib/core/evidence/composite_evidence_capture_service.dart`, `lib/core/evidence/` | Seamlessly integrates hardware Camera, Photo Gallery (`image_picker`), and Document PDF picker (`file_picker`) with evidence status validation. |
| **Firestore Session Persistence** | **Fully implemented** | `lib/core/assessment/assessment_session_store.dart`, `lib/state/assessment_state.dart` | Continuously persists in-progress question responses under `users/{uid}/assessment_sessions/{id}` to prevent progress loss. |
| **Executive Dashboard (V2)** | **Fully implemented** | `lib/screens/home_screen_v2.dart`, `lib/features/dashboard/coordinators/dashboard_data_coordinator.dart` | Reactive dashboard coordinating score cards, active session resumes, Today's Priorities, pillar health heatmaps, and evidence tallies. |
| **Vector PDF Report Exporter** | **Fully implemented** | `lib/features/report/pdf/property_report_pdf.dart`, `lib/features/report/screens/property_health_report_screen.dart` | Renders multi-page executive vector PDF reports with score dials, pillar breakdowns, missing document warnings, and system print integration. |
| **SureBot Explainer (Rule-Based)** | **Fully implemented** | `lib/features/surebot/services/property_health_explainer.dart`, `lib/screens/assessment/surebot_screen.dart` | Context-aware, deterministic copy explaining scores and recommendations in 6 Indian languages. |
| **SureBot Live LLM / Gemini** | **Planned but not implemented** | `docs/10_AI_Strategy.md` | Architecture envisions generative AI reasoning via Gemini. Code currently uses deterministic rule-based explainer. |
| **App Localization (6 Languages)** | **Fully implemented** | `lib/l10n/`, `lib/core/localization/app_locale_controller.dart`, `assets/fonts/` | Full multi-language support (English, Kannada, Hindi, Telugu, Tamil, Malayalam) with embedded Unicode TrueType font assets. |
| **Property Search (Frontend)** | **UI only / mock data** | `lib/screens/onboarding/property_search_screen.dart`, `lib/data/properties.dart` | Search UI supports filtering by builder, locality, and RERA number, but dataset is restricted to 2 hardcoded sample properties. |
| **Unlisted Property Submission** | **Fully implemented** | `lib/features/property_submission/services/property_submission_service.dart` | Allows users to submit unlisted apartments to Firestore collection `property_submissions`. Enforces strict validation rules. |
| **My Property Requests Viewer** | **Fully implemented** | `lib/screens/onboarding/my_property_requests_screen.dart` | Live Firestore stream (`watchMySubmissions()`) displaying approval statuses (`pending_review`, `approved`, `rejected`). |
| **K-RERA Data Pipeline** | **Backend only** | `KRERA-Data-Extraction/` | Fully functional Python ingestion pipeline with 875 official Karnataka RERA projects extracted into `k_rera_extraction.sqlite`. Not yet mapped into Flutter. |
| **Residents Welfare Network** | **Partially implemented** | `lib/features/network/screens/network_home_screen.dart`, `lib/features/network/services/network_service.dart` | Membership join requests write to Firestore. Announcements and member directory currently rely on stubbed data. |
| **Health Tab in MainShell** | **Planned but not implemented** | `lib/screens/main_shell.dart#L25` | Main navigation shell displays a static `_ComingSoonScreen` placeholder, despite `PropertyHealthRecordScreen` existing in the repository. |
| **AI Advisor Tab in MainShell** | **Planned but not implemented** | `lib/screens/main_shell.dart#L29` | Main navigation shell displays a static `_ComingSoonScreen` placeholder, despite `SureBotScreen` being fully functional when launched from dashboard. |
| **Project Timeline Feature** | **Planned but not implemented** | `lib/screens/home_screen_v2.dart#L188` | Empty method stub (`void _openTimeline() {}`) with no destination screen. |
| **Cloud Functions Backend** | **Planned but not implemented** | `functions/src/index.ts` | Default TypeScript starter boilerplate; no server-side trigger functions, background workers, or admin APIs implemented. |
| **Engine Playground Testing** | **Fully implemented** | `lib/features/design_system/screens/engine_playground_screen.dart` | Dedicated testing screen allowing manual simulation of category scores and rule outcomes. Gated behind `kDeveloperMode = true`. |

---

## 3. Detailed Feature Behavioral Analysis

### A. The Core Scoring Loop
1. The user begins at [`AssessmentScreen`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/assessment/assessment_screen.dart).
2. Each of the 33 questions from [`lib/data/phs_questions.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/data/phs_questions.dart) carries:
   * A parent category (`PHSCategory`).
   * A question weight (`questionWeight`).
   * Scoring impacts per response option (*Yes*, *No*, *In Progress*, *Not Applicable*).
   * Minimum required evidence classification (`EvidenceType`).
3. Answering a question updates `AssessmentState` and triggers an async write to Firestore via `AssessmentSessionStore`.
4. When the user completes question 33, `AnalyzingScreen` invokes `WeightedPHScalculator.calculate()`.
5. Category scores are derived from normalized answer weights, multiplied by statutory pillar weights, and summed into a final score between 0.0 and 100.0.

### B. The Evidence Pipeline
1. Evidence capture is abstracted through [`EvidenceCaptureService`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/core/evidence/evidence_capture_service.dart).
2. Tapping "Add Evidence" opens [`EvidenceActionSheet`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/widgets/assessment/evidence_action_sheet.dart).
3. The user can capture photos using the device camera, select images from their photo library, or select PDF files using the system file picker.
4. Uploaded evidence is validated against requirement catalogs (`EvidenceRequirementCatalog`) and classified as verified, pending, or missing.
5. Document statuses are integrated into the final PDF report.

### C. Property Submission Workflow
1. When a user searches for an apartment not present in the catalog, they tap "Submit Request".
2. The dialog collects:
   * `name`: Property name (required, 1-200 chars).
   * `builder`: Builder/promoter name (optional, max 200 chars).
   * `locality`: Locality/area (required, 1-200 chars).
   * `city`: City name (required, 1-100 chars).
   * `reraNumber`: RERA registration number (optional, max 100 chars).
3. Submissions write to Firestore `property_submissions/{submissionId}` with `status = "pending_review"` and `createdAt = request.time`.
4. Security rules enforce that users can only read their own submissions (`resource.data.submittedBy == request.auth.uid`) and cannot mutate them once created.
