# HomeSure AI — Existing Application Overview

**Document Identifier:** `HOMESURE_EXISTING_APP_OVERVIEW.md`  
**Audit Date:** November 9, 2026  
**Auditor:** Antigravity AI Engineering  
**Application Root:** `c:\Program Files\BlackMatter\Homesure`  
**Repository Branch:** `main` (commit `6db7592`: *"Prepare HomeSureAI for engineering collaboration"*)

---

## 1. Executive Purpose & Vision

HomeSure AI is a cross-platform mobile and web application built to serve as the **"Credit Score for Residential Properties"** in India. The application evaluates residential real estate—including apartments, villas, and gated communities—against statutory approvals, structural quality, utility connections, safety certifications, and documentation completeness.

Its core deliverable is the **Property Health Index™ (PHI™)** and a single, reproducible **Property Health Score (PHS)** on a 0 to 100 scale, accompanied by an executive PDF health report, prioritized risk-remediation action items, and multi-lingual AI explanations.

---

## 2. Intended User Personas

| Persona | Core Pain Points Addressed | Key Modules Used |
| :--- | :--- | :--- |
| **Prospective Home Buyers** | Uncertainty regarding RERA compliance, builder track record, occupancy certificates (OC), and title safety before purchasing. | Property Search, Property Health Record, PDF Report. |
| **Existing Apartment Owners** | Missing property tax documents, unapplied e-Khata, pending BESCOM/BWSSB meters, warranty tracking. | Dashboard Today's Priorities, Assessment Questionnaire, Evidence Vault. |
| **Resident Welfare Associations (RWAs)** | Corpus fund handovers, builder maintenance disputes, statutory AMC compliance, resident directories. | Residents Network (`NetworkHomeScreen`), Compliance Heatmap. |
| **Builders & Developers** | Credibility validation, statutory compliance proof, official buyer handover audits. | Property Submissions, Assessment Verification. |
| **Lenders & Financial Institutions** | Asset valuation risk assessment, legal due diligence. | Vector PDF Health Reports, Statutory Checklist. |

---

## 3. Core Modules & Capabilities

1. **Authentication & Profile Gate (`lib/features/auth/`)**:
   * Firebase Email/Password and Anonymous authentication.
   * Onboarding profile status validation via Cloud Firestore (`users/{uid}`).
2. **Onboarding & Location Personalization (`lib/screens/onboarding/`)**:
   * Multi-slide carousel value proposition.
   * Location selector (Bengaluru focus, secondary metro tiles).
3. **Property Catalogue & Submission Engine (`lib/features/property/`, `lib/features/property_submission/`)**:
   * Search interface supporting name, builder, locality, and RERA registration filtering.
   * Crowd-sourced unlisted property submission workflow writing to `property_submissions` collection in Firestore.
4. **Property Health Questionnaire & Evidence Capture (`lib/screens/assessment/`, `lib/core/evidence/`)**:
   * 33 statutory questions spanning 6 categories (`lib/data/phs_questions.dart`).
   * Dual rendering modes: Classic Accordion View and Premium Card Swipe View.
   * Composite evidence capture supporting Camera, Gallery, and PDF file selection.
5. **Property Intelligence Engine (`lib/core/engine/`)**:
   * Pure mathematical calculation engine (`WeightedPHScalculator`).
   * Evaluator registry, weighted category contributions, deterministic score derivation.
6. **Executive Dashboard V2 (`lib/screens/home_screen_v2.dart`)**:
   * Reactive state coordinator (`DashboardDataCoordinator`).
   * Hero score card, Today's Priorities, Pillar health heatmap, Evidence snapshot, and SureBot insights.
7. **Vector PDF Generation & Printing (`lib/features/report/`)**:
   * Professional multi-page report generator (`property_report_pdf.dart`).
   * High-fidelity vector rendering of score badges, risk assessments, missing document checklists, and disclaimers.
8. **SureBot AI Assistant (`lib/features/surebot/`)**:
   * Context-aware explanatory engine (`PropertyHealthExplainer`).
   * Multi-lingual translations for 6 Indian languages.
9. **Residents Welfare Network (`lib/features/network/`)**:
   * Community membership management, pending join requests, and association updates.
10. **Localization (`lib/l10n/`, `lib/core/localization/`)**:
    * Full localization across English, Kannada, Hindi, Telugu, Tamil, and Malayalam.
    * Bundled Unicode TrueType font assets for South Asian scripts.

---

## 4. Current Technology Stack

| Layer | Technology | Details |
| :--- | :--- | :--- |
| **Language & SDK** | Dart 3.13.7 / Flutter 3.47.9 | SDK constraint: `sdk: ^3.12.2`, `flutter: ">=3.44.0"` |
| **Mobile Architecture** | Android (Kotlin DSL / Gradle 8.10.2 / AGP 8.6+) | Target SDK 35/36, JVM 17, Java 21 toolchain |
| **Desktop Architecture** | Windows (MSVC 2022 C++ runner) | Visual Studio Build Tools 2022 17.12.3 |
| **Web Architecture** | HTML5 / CanvasKit / WebAssembly | Built for Chrome / Edge deployment |
| **Backend / BaaS** | Firebase Cloud Services | Project ID: `homesureai-51893` |
| **Database (Remote)** | Cloud Firestore (Enterprise rules version 2) | Declarative security with RBAC and owner scoping |
| **Database (Local Ingestion)** | SQLite 3 | `k_rera_extraction.sqlite` (875 projects catalogued) |
| **Cloud Compute** | Firebase Cloud Functions (v2 HTTPS / Firestore) | Node.js / TypeScript 5.3 (`functions/`) |
| **UI Design System** | Material 3 + Custom Tokens | Google Fonts (`google_fonts: ^6.3.3`), SVG, Lottie, Shaders |
| **PDF Generation** | `pdf: ^3.11.3` & `printing: ^5.14.2` | Vector document generation |
| **Hardware Access** | `image_picker: ^1.2.1` & `file_picker: ^13.1.0` | Camera and multi-format document picker |

---

## 5. Software Architectural Pattern

The application implements a **Feature-First Domain-Driven Architecture** with strict decoupling rules:
- **Zero UI-Engine Coupling:** UI widgets never compute scores or modify assessment math.
- **Single Source of Truth:** `AssessmentState` and `WeightedPHScalculator` drive all score projections.
- **Layered Responsibilities:**
  1. `lib/core/`: Reusable, platform-agnostic business logic (Scoring, Evidence interfaces, Localization).
  2. `lib/features/`: Self-contained business domains containing their own models, services, controllers, and feature widgets.
  3. `lib/screens/`: High-level view compositions and orchestrations.
  4. `lib/widgets/`: Atomic and composite UI components.
  5. `lib/state/`: Reactive application stores (`ChangeNotifier`).

---

## 6. Supported Platforms & Build Variants

1. **Android**: Fully supported (`build/app/outputs/flutter-apk/app-debug.apk`).
   * Package Name: `com.example.homesure_ai`
   * Min SDK: Flutter default (API 21 / Android 5.0)
   * Target SDK: API 35 (Android 15)
   * NDK Version: `r28c` (installed)
2. **Web**: Enabled (`flutter build web`).
3. **Windows Desktop**: Enabled (`flutter build windows`).
4. **iOS / macOS / Linux**: Platform scaffolding present in repository; requires host operating system to build.

---

## 7. Version & Configuration Metadata

* **Application Name:** `homesure_ai`
* **Version String:** `1.0.0+1` (`pubspec.yaml` line 5)
* **Active Environment Toggle:** `kUseFirebaseEmulators = true` ([`lib/main.dart#L22`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/main.dart#L22))
* **Active Developer Mode:** `kDeveloperMode = false` ([`lib/main.dart#L29`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/main.dart#L29))
* **Default Firebase Target:** `homesureai-51893` ([`.firebaserc#L3`](file:///c:/Program%20Files/BlackMatter/Homesure/.firebaserc#L3))
