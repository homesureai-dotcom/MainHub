# HomeSure AI — Frontend Architecture Audit

**Document Identifier:** `HOMESURE_FRONTEND_ARCHITECTURE.md`  
**Audit Date:** November 9, 2026  
**Auditor:** Antigravity AI Engineering  
**Application Root:** `c:\Program Files\BlackMatter\Homesure`  

---

## 1. Technology Baseline & Versions

* **Framework:** Flutter 3.47.9 (Channel `stable`)
* **Language:** Dart 3.13.7
* **Design Specification:** Material 3 (`uses-material-design: true`, `ThemeData(useMaterial3: true)`)
* **Asset Pipelines:** Vector SVG (`flutter_svg: ^2.2.1`), Vector Fonts (`google_fonts: ^6.3.3` + bundled TTFs), Lottie animations (`lottie: ^3.3.2`), Staggered Animations (`flutter_animate: ^4.5.2`).

---

## 2. Directory & Component Organization

The codebase follows a hybrid **Feature-First + Core Domain** layout:

```text
lib/
├── core/                        # Pure domain logic & cross-cutting contracts
│   ├── app/                     # App-level constants & contracts
│   ├── assessment/              # Assessment session models & Firestore store
│   ├── engine/                  # Mathematical scoring engine & evaluators
│   ├── evidence/                # Evidence capture abstractions & catalogs
│   ├── localization/            # Language controllers & locale management
│   ├── phs/                     # Property Health Standard domain models
│   ├── rules/                   # Statutory rule evaluators
│   └── score/                   # Score result data structures
├── data/                        # Static datasets & legacy sample catalogs
├── enums/                       # Global enumeration types (ComplianceStatus, etc.)
├── features/                    # Encapsulated vertical business slices
│   ├── ai_intelligence/         # AI strategy stubs
│   ├── assessment/              # Assessment localization & domain helpers
│   ├── auth/                    # Authentication services, gates, and screens
│   ├── dashboard/               # Dashboard coordinators, models, and priority cards
│   ├── design_system/           # Engine playground and UI components
│   ├── network/                 # Resident community membership & directory
│   ├── property/                # Canonical property models, repository, and state
│   ├── property_submission/     # Unlisted property intake and approval gateways
│   ├── report/                  # Vector PDF generation, layout adapters, and viewer
│   └── surebot/                 # SureBot explainer engine and context builders
├── l10n/                        # Generated ARB localization delegates
├── models/                      # Legacy application data models
├── screens/                     # High-level screen orchestrations & page views
├── services/                    # Shared infrastructure services
├── state/                       # Core application state stores (AssessmentState)
├── theme/                       # Color palettes, gradients, typography, and themes
└── widgets/                     # Reusable design system widgets
```

---

## 3. Navigation Architecture

Navigation is organized across two hierarchical layers:

1. **Root Authentication Router (`AuthGate`)**:
   * Evaluates `FirebaseAuth.instance.authStateChanges()`.
   * Unauthenticated state renders [`SignedOutFlow`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/features/auth/screens/signed_out_flow.dart), which hosts an internal `Navigator` for onboarding slides, how-it-works, and login.
   * Authenticated state checks user profile data from Firestore (`onboardingCompleted`). If false, mounts `CitySelectionScreen()`. If true, mounts `MainShell()`.
2. **Main Application Shell (`MainShell`)**:
   * Manages a bottom `NavigationBar` with 6 tab destinations rendered inside an `IndexedStack` to preserve scroll positions:
     * Index 0: `HomeScreenV2` (Dashboard)
     * Index 1: `PropertySearchScreen` (Property Directory)
     * Index 2: `_ComingSoonScreen` ("Property Health Record")
     * Index 3: `_ComingSoonScreen` ("AI Advisor")
     * Index 4: `_NetworkDestination` (Residents Network)
     * Index 5: `_ProfileScreen` (Settings & Language)
3. **Modal & Hierarchical Navigation**:
   * Deep journeys (Assessment, Evidence Details, PDF Viewer, SureBot) push standard `MaterialPageRoute` transitions onto the root `Navigator`.

---

## 4. State Management Architecture

The application avoids heavy third-party state libraries (such as Bloc or Riverpod) in favor of lightweight, native Flutter reactive primitives:

| State Store | Mechanism | Scope | Primary Responsibility |
| :--- | :--- | :--- | :--- |
| **`AssessmentState`** | `ChangeNotifier` (Singleton) | Global | Holds active assessment session, question index, user answers, and evidence references. Syncs with Firestore. |
| **`PropertyState`** | `ChangeNotifier` (Singleton) | Global | Holds active property profile, selected apartment, and recent property list. |
| **`AppLocaleController`** | `ValueNotifier<Locale>` (Singleton) | Global | Reactive locale management driving `MaterialApp` rebuilds upon language change. |
| **`authGateRefreshNotifier`** | `ValueNotifier<int>` | Global | Signals `AuthGate` to re-fetch Firestore profile when onboarding completes. |
| **Screen State** | `StatefulWidget` (`setState`) | Local | Transient form inputs, carousel animations, and loading spinners. |

---

## 5. Styling, Theming & Design System

* **Theme Definitions:** Contained in [`lib/theme/app_theme.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/theme/app_theme.dart).
* **Color Palette (`AppColors`):**
  * Primary: Deep Indigo / Navy (`#0F172A`, `#1E293B`, `#2563EB`)
  * Health Indicators: Green (`#16A34A`), Amber/Orange (`#D97706`), Red (`#DC2626`)
  * Neutral Background: Slate / Off-White (`#F8FAFC`, `#FFFFFF`)
* **Typography:** Integrates `GoogleFonts.inter` with localized system fallback. Asset TTF fonts are bundled in `assets/fonts/` for regional South Asian scripts (Kannada, Devanagari, Telugu, Tamil, Malayalam).
* **Core Reusable Components:**
  * [`AppButton`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/widgets/common/app_button.dart): Standardized filled/outline action button with loading states.
  * [`AppSearchField`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/widgets/common/app_search_field.dart): Search input with prefix search icon and clear button.
  * [`OnboardingScaffold`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/widgets/common/onboarding_scaffold.dart): Pinned bottom-button onboarding layout wrapper.
  * [`HeroScoreCard`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/widgets/hero_score_card.dart): Circular score gauge with gradient fills.

---

## 6. Form Handling & Validations

Forms leverage standard `Form` and `TextEditingController` patterns:
* **Authentication Forms (`AuthScreen`):**
  * Email validation: `RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')`.
  * Password validation: Minimum length check (`value.length >= 6`).
* **Property Submission Forms (`_PropertyFormDialog`):**
  * Required fields: Property Name (max 200 chars), Locality (max 200 chars), City (max 100 chars).
  * Optional fields: Builder Name, RERA Registration Number.
* **Network Membership Requests:**
  * Dropdown selector restricting relationship to `['owner', 'tenant', 'familyMember']`.
  * Optional message bounded to 300 characters.

---

## 7. Architectural Inconsistencies & Duplications

1. **Dual Property Domain Models:**
   * Model A: [`lib/models/property.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/models/property.dart) (Legacy model used in onboarding catalogue).
   * Model B: [`lib/features/property/models/property.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/features/property/models/property.dart) (Canonical feature model used by `PropertyState` and the dashboard).
   * Bridged via [`PropertyAdapter`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/features/property/models/property_adapter.dart), introducing maintenance overhead.
2. **Dual Questionnaire Datasets:**
   * Prototype: [`lib/data/assessment_questions.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/data/assessment_questions.dart) (4 legacy questions).
   * Production: [`lib/data/phs_questions.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/data/phs_questions.dart) (33 comprehensive PHS questions).
3. **Deceptive File Naming:**
   * [`lib/screens/home_screen.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/home_screen.dart) does not contain a home screen; it is a 1-line re-export of `network_home_screen.dart`.
   * The actual home screen is [`lib/screens/home_screen_v2.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/home_screen_v2.dart).
4. **Main Navigation Disconnects:**
   * Bottom navigation tabs for "Property Health Record" and "AI Advisor" display static *Coming Soon* placeholders, despite functional implementations existing in [`PropertyHealthRecordScreen`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/property_health_record_screen.dart) and [`SureBotScreen`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/assessment/surebot_screen.dart).
