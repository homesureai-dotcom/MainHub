# HomeSure — Phase 2 UI & Architecture Audit

**Document Version:** 1.0  
**Phase:** Phase 2 — Complete Application UI/UX Redesign & Design System Implementation  
**Environment:** Flutter 3.41.4 / Dart 3.11.1 (`homesureai-51893`, Cloud Firestore `asia-south1`)  
**Target Platform:** Android (`emulator-5554`, `1080x2400`)

---

## 1. Executive Summary

HomeSure is a Bengaluru-first property intelligence platform positioned around the principle:
> *"Know the project you have chosen. Understand what is behind it."*

Phase 1 established the production Firestore backend (875 verified Bengaluru K-RERA projects, 680 canonical builders, regulatory documents, complaints, and unit hierarchy models) and implemented the Builder-First search and navigation pipeline (`Properties -> Builders -> Builder's Properties -> Property Details -> Assessment`).

However, the visual presentation across the application was assembled incrementally during early prototyping and Phase 1 data integration. This audit catalogs every screen, widget, navigation path, and styling dependency in the repository to ensure the Phase 2 redesign delivers a cohesive, fintech-grade property intelligence interface while preserving 100% of existing business logic, Firestore queries, state management, and the **883 passing automated tests**.

---

## 2. Screen & Navigation Inventory

| Destination / Screen | Source File | Current Role & State | Preserved Dependencies & Contracts |
| :--- | :--- | :--- | :--- |
| **Auth Gate & Sign-In** | `lib/features/auth/screens/auth_gate.dart`<br>`lib/features/auth/screens/sign_in_screen.dart` | Routes unauthenticated users to `SignInScreen` and authenticated users to `MainShell`. | `FirebaseAuth.instance.authStateChanges()`, `AppLocaleController.instance.loadSavedLanguage()`. |
| **Root Shell (`MainShell`)** | `lib/screens/main_shell.dart` | Root `IndexedStack` with bottom `NavigationBar` (`Home`, `Properties`, `Health`, `AI`, `Residents`, `Profile`). | Tab switching, `PropertyState.instance` listener for `Residents` tab (`NetworkHomeScreen`), language selector & sign-out in `Profile`. |
| **Tab 1: Home (`HomeScreenV2`)** | `lib/screens/home_screen_v2.dart` | Executive property intelligence dashboard. Renders onboarding/empty state when no property is selected, or full 6-pillar intelligence dashboard when a property is active. | `PropertyState`, `AssessmentState`, `DashboardAggregator`, `GreetingHeader`, `PropertySelectorCard`, `HeroScoreCard`, `AssessmentProgressCard`, `TodaysPrioritiesCard`, `PropertyHealthBreakdownCard`, `EvidenceSnapshotCard`, `QuickActionGrid`, `RecentAlertsCard`, `AIInsightsCard`. |
| **Tab 2: Properties (`PropertySearchScreen`)** | `lib/screens/onboarding/property_search_screen.dart` | Builder-first catalogue entry point (`680` canonical builders). Supports live debounced search (`180ms`) and unlisted property submission modal sheet (`Not listed?`). | `PropertyCatalogueGateway.fetchBuilders`, `PropertySubmissionGateway.submitProperty`, `BuilderCard`, `BuilderProjectsScreen`, `MyPropertyRequestsScreen`. |
| **Builder's Properties (`BuilderProjectsScreen`)** | `lib/screens/onboarding/builder_projects_screen.dart` | Displays all registered K-RERA projects under a selected canonical builder with in-builder search filtering. | `BuilderCatalogueEntry`, `PropertyCatalogueGateway.fetchProjectsForBuilder`, `PropertyCard`, `PropertyState.selectProperty`. |
| **Property Details (`PropertyDetailsScreen`)** | `lib/screens/property/property_details_screen.dart` | Project-level K-RERA intelligence workspace showing registration metadata, `summaryMetrics` with `ObservationState`, tower/unit hierarchy, buyer unit modal, portal tab status, regulatory documents, complaints, and `Start Assessment` CTA. | `PropertyCatalogueGateway.fetchProjectById`, `fetchProjectRegulatoryDetail`, `fetchProjectUnits`, `saveBuyerUnit`, `SureBotScreen` launch. |
| **Tab 3: Health (`MainShell` / `AssessmentScreen` / `PropertyHealthResultScreen`)** | `lib/screens/main_shell.dart`<br>`lib/screens/assessment/assessment_screen.dart`<br>`lib/screens/assessment/property_health_result_screen.dart` | 6-pillar Property Health Score (PHS) assessment & diagnostic engine (Legal & Statutory 25%, Financial & Title 20%, Builder Reliability 15%, Construction Quality 15%, Utilities & Approvals 15%, Safety & Compliance 10%). | `ScoreCalculator`, `PropertyHealthEngine`, `AssessmentState`, `QuestionEvidenceCoordinator`, `PropertyHealthResultScreen`. |
| **Tab 4: AI (`SureBotScreen`)** | `lib/screens/assessment/surebot_screen.dart` | Multilingual AI assessment guide and contextual property advisor (`en`, `kn`, `hi`, `te`, `ta`, `ml`). | `SureBotContext`, `AppLocaleController`, `UserProfileService`, `AssessmentScreen` navigation. |
| **Tab 5: Residents (`NetworkHomeScreen`)** | `lib/features/network/screens/network_home_screen.dart` | Community & resident association governance workspace tied to the currently selected property (`propertyId`). | `NetworkService`, `CommunityMembership`, `MembershipRequest`. |

---

## 3. Visual & UX Deficiencies Identified in Current Implementation

1. **Fragmented Color Palette & Generic Material Defaults**:
   - Current screens mix bright royal blue (`#2563EB`), purple M3 surface tints (`ColorScheme.fromSeed` default), slate grays (`#0F172A`, `#64748B`), and high-saturation orange/red/green accents.
   - `NavigationBar` in `MainShell` uses Material 3's default lavender/purple indicator pill (visible in emulator screenshots), clashing with the blue cards and dark navy headers.
2. **Excessive Card Padding & Low Information Density**:
   - `AppCard` defaults to `24px` (`AppSpacing.lg`) padding and `24px` border radius with heavy drop shadows (`blurRadius: 18–28`).
   - `PropertyCard` uses oversized `64x64` icon containers, `22px` padding, and verbose helper copy (`"Select this project to view its details and start an assessment"`), limiting mobile viewports to ~2.5 cards on screen.
3. **Unstructured Long-Scroll in `PropertyDetailsScreen`**:
   - `PropertyDetailsScreen` stacks all K-RERA metrics, unit hierarchy, tab observations, documents, complaints, and assessment status in a single undifferentiated vertical list without section navigation pills or an at-a-glance intelligence summary grid.
   - `ObservationState` values (`present_with_data`, `present_empty`, `not_present`, `not_applicable`, `not_available`, `extraction_failed`) are rendered as plain italic gray text rather than semantic, audit-grade status badges.
4. **Placeholder Tabs in `MainShell` & Android Back Button Exit (`QA-ISSUE-002`)**:
   - In `MainShell`, tapping the `Health` or `AI` bottom navigation tabs renders a static `_ComingSoonScreen` instead of surfacing an active Property Health Intelligence overview or `SureBotScreen` workspace.
   - Pressing the Android hardware Back button while on Tabs 1–4 exits the application immediately because `MainShell` lacks a root `PopScope` handler to return to Tab 0 (`Home`).
5. **Unused Imports & Analyzer Warnings (`QA-ISSUE-003`)**:
   - `flutter analyze` reported 31 info/warning items across `lib/` and `test/`, alongside temporary QA Python scripts in the workspace root that must be cleaned up.

---

## 4. Preservation & Test Compatibility Strategy

To ensure zero regressions across the **883 existing unit and widget tests**:
1. **Preserve Widget Class Names & Constructors**: `GreetingHeader`, `PropertySelectorCard`, `HeroScoreCard`, `AssessmentProgressCard`, `TodaysPrioritiesCard`, `PropertyHealthBreakdownCard`, `EvidenceSnapshotCard`, `QuickActionGrid`, `QuickActionCard`, `RecentAlertsCard`, `AIInsightsCard`, `BuilderCard`, `PropertyCard`, `AppCard`, `AppButton`, and `AppSearchField` retain their exact public APIs.
2. **Preserve Semantic Copy & Test Finders**: All key strings asserted by widget tests (e.g., `'Let’s get your property started'`, `'Find a Property'`, `'Not Assessed'`, `'Assessment in progress'`, `'Continue Assessment'`, `'Builders in the catalogue'`, `'Not listed?'`, `"My project isn't listed"`, `'Select a Property'`, `'Not yet assessed by HomeSureAI'`, `'Start Assessment'`, `'Specify Apartment / Unit to Evaluate'`) are preserved verbatim while upgrading their surrounding visual hierarchy, typography, badges, and layout structure.
3. **Centralized Token Architecture**: Both the new `lib/core/theme/` design system package and legacy `lib/theme/` classes (`AppColors`, `AppTheme`, `AppTextStyles`, `AppGradients`, `AppSpacing`, `AppRadius`, `AppShadows`) are unified around the Phase 2 Deep Navy (`#172B4D`) & Muted Teal (`#168C83`) design tokens.
