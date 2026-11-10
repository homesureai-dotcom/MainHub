# HomeSure AI — End-to-End User Journey Audit

**Document Identifier:** `HOMESURE_END_TO_END_USER_JOURNEY.md`  
**Audit Date:** November 9, 2026  
**Auditor:** Antigravity AI Engineering  
**Application Root:** `c:\Program Files\BlackMatter\Homesure`  

---

## 1. Journey Architecture & State Transitions

The user journey is orchestrated by [`AuthGate`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/features/auth/screens/auth_gate.dart). The state machine transitions according to two persistent variables:
1. **Firebase Authentication State (`User?`)**: Determines whether the user enters the signed-out sequence or the authenticated environment.
2. **Onboarding Completion (`users/{uid}/onboardingCompleted == true`)**: Determines whether an authenticated user is routed to location configuration or directly into the main shell.

```text
[App Launch]
     │
     ▼
[AuthGate] ──(Not Signed In)──► [SignedOutFlow Navigator]
     │                                ├── SplashScreen (3s timer)
     │                                ├── WelcomeScreen (Carousel)
     │                                ├── HowItWorksScreen (Walkthrough)
     │                                └── AuthScreen (Sign In / Register)
     │
     └──(Signed In)──► [Firestore Profile Check: onboardingCompleted?]
                             ├── False ──► [CitySelectionScreen]
                             └── True  ──► [MainShell]
                                              ├── Tab 0: HomeScreenV2
                                              ├── Tab 1: PropertySearchScreen
                                              ├── Tab 2: Health (Coming Soon)
                                              ├── Tab 3: AI Advisor (Coming Soon)
                                              ├── Tab 4: Residents Network
                                              └── Tab 5: Profile & Settings
```

---

## 2. Granular Screen-by-Screen Specifications

---

### Screen 1: Splash Screen
* **File & Route:** [`lib/screens/onboarding/splash_screen.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/onboarding/splash_screen.dart) — Internal route: `/` inside `SignedOutFlow`.
* **Purpose:** Brand impression and initial frame presentation while runtime assets bootstrap.
* **UI Components & Layout:** Full-height container styled with `AppGradients.hero` (linear blue), semi-transparent rounded icon container (shield icon), application title *"HomeSure AI"*, subtitle *"Property Health & Intelligence"*, and circular progress indicator.
* **Actions Available:** None (automatic 3-second non-blocking `Timer`).
* **Input Fields & Validation:** None.
* **Backend / API Interactions:** Triggers no APIs directly.
* **Data Displayed:** Static branding strings.
* **Navigation Destination:** Replaces route with `WelcomeScreen()`.
* **Current Implementation Status:** **Fully implemented**.

---

### Screen 2: Welcome Carousel
* **File & Route:** [`lib/screens/onboarding/welcome_screen.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/onboarding/welcome_screen.dart) — Route: `/welcome`.
* **Purpose:** Educate users on the core value proposition of Property Health Index (PHI).
* **UI Components & Layout:** SafeArea column containing a top "Skip" text button, an expanded `PageView.builder` reading from `onboardingPages` ([`lib/data/onboarding_data.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/data/onboarding_data.dart)), a `SmoothPageIndicator` (worm style, blue color), and a bottom primary action button (`AppButton`).
* **Actions Available:**
  * Swipe horizontally between 3 slides.
  * Tap "Skip" to bypass to `HowItWorksScreen`.
  * Tap "Next" on slides 1-2 to advance carousel.
  * Tap "Get Started" on slide 3 to navigate to `HowItWorksScreen`.
* **Input Fields & Validation:** None.
* **Backend / API Interactions:** None.
* **Data Displayed:** Titles, descriptions, and icon identifiers from `onboardingPages`.
* **Navigation Destination:** `HowItWorksScreen()`.
* **Current Implementation Status:** **Fully implemented**.

---

### Screen 3: How It Works
* **File & Route:** [`lib/screens/onboarding/how_it_works_screen.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/onboarding/how_it_works_screen.dart) — Route: `/how-it-works`.
* **Purpose:** Outline the 3-step operational loop of the application.
* **UI Components & Layout:** Scaffold with simple `AppBar`, padded body, title text *"How HomeSure AI Works"*, three numbered `ListTile` cards (1. Search your apartment, 2. Answer a few questions, 3. Receive your HomeSure Score), and a pinned bottom `FilledButton` ("Continue").
* **Actions Available:** Tap "Continue" or tap top back button.
* **Input Fields & Validation:** None.
* **Backend / API Interactions:** None.
* **Data Displayed:** Static descriptive instructional steps.
* **Navigation Destination:** `AuthScreen()`.
* **Current Implementation Status:** **Fully implemented**.

---

### Screen 4: Authentication Screen
* **File & Route:** [`lib/features/auth/screens/auth_screen.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/features/auth/screens/auth_screen.dart) — Route: `/sign-in`.
* **Purpose:** User registration, credential authentication, and password recovery.
* **UI Components & Layout:** Scrollable form container with application logo, mode title ("Sign In" / "Create Account"), Email text field with email icon, Password text field with toggleable eye visibility icon, "Forgot Password?" text button, primary submit button with loading indicator, and toggle link ("Don't have an account? Sign Up").
* **Actions Available:**
  * Toggle between Sign In mode and Registration mode.
  * Toggle password obfuscation.
  * Tap "Forgot Password?" to trigger password reset modal/email.
  * Submit form via "Sign In" / "Register".
* **Input Fields & Validation:**
  * `Email`: Required; regex-validated format (`RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')`).
  * `Password`: Required; minimum 6 characters.
* **Backend / API Interactions:**
  * `FirebaseAuth.instance.signInWithEmailAndPassword(email, password)`
  * `FirebaseAuth.instance.createUserWithEmailAndPassword(email, password)`
  * `FirebaseAuth.instance.sendPasswordResetEmail(email)`
* **Data Displayed:** Form labels, validation error banners, and SnackBar alerts.
* **Navigation Destination:** On success, `AuthGate` detects `authStateChanges()` stream update and remounts.
* **Current Implementation Status:** **Fully implemented**.

---

### Screen 5: City Selection Screen
* **File & Route:** [`lib/screens/onboarding/city_selection_screen.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/onboarding/city_selection_screen.dart).
* **Purpose:** Location personalization to anchor municipal and statutory rules (e.g., BESCOM, BWSSB, e-Khata in Bengaluru).
* **UI Components & Layout:** Wrapped in `OnboardingScaffold`, search field header, horizontal/grid list of `CityCard` widgets with city images/icons and name badges, error display banner, and pinned bottom `AppButton` ("Continue").
* **Actions Available:**
  * Select a city tile (highlights with border and selection indicator).
  * Type in search bar (placeholder; does not filter yet).
  * Tap "Continue" to save selection.
* **Input Fields & Validation:** `selectedIndex != null` required before button activates.
* **Backend / API Interactions:**
  * Calls `UserProfileService.saveSelectedCity(city, state)`.
  * Writes `{ city: 'Bengaluru', state: 'Karnataka', onboardingCompleted: true, updatedAt: serverTimestamp() }` to Firestore document `users/{uid}`.
  * Increments `authGateRefreshNotifier.value++` to signal `AuthGate`.
* **Data Displayed:** City catalog loaded from [`lib/data/cities.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/data/cities.dart) (Bengaluru, Mumbai, Pune, Hyderabad, Chennai, Delhi NCR).
* **Navigation Destination:** Rebuilt into `MainShell()`.
* **Current Implementation Status:** **Fully implemented** (search bar filtering is pending).

---

### Screen 6: Main Dashboard (Home Tab)
* **File & Route:** [`lib/screens/home_screen_v2.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/home_screen_v2.dart) (rendered inside `MainShell` tab index 0).
* **Purpose:** Central operational hub displaying active property health, action priorities, and progress.
* **UI Components & Layout:** Scrollable dashboard composed of discrete cards:
  1. `GreetingHeader`: Displays personalized greeting ("Hello, [Name]") and date.
  2. `PropertySelectorCard`: Current property title, locality, and "Change Property" pill.
  3. `HeroScoreCard`: Large circular PHS dial (0-100) or "Start Assessment" prompt.
  4. `_buildAssessmentResumeCard`: Visual progress bar when assessment is partially completed.
  5. `TodaysPrioritiesCard`: Top actionable compliance risks with estimated minutes.
  6. `PropertyHealthBreakdownCard`: Visual progress bars for all 6 PHS pillars.
  7. `EvidenceSnapshotCard`: Counts of verified, pending, and missing documents.
  8. `AiInsightsCard`: Actionable summary advice attributed to SureBot.
* **Actions Available:**
  * Tap "Change Property" -> navigates to `PropertySearchScreen`.
  * Tap Hero Score Card / "Start Assessment" -> navigates to `AssessmentScreen`.
  * Tap "Resume Assessment" -> resumes in-progress `AssessmentScreen`.
  * Tap any Priority card -> navigates to `PriorityDetailScreen`.
  * Tap Evidence snapshot -> navigates to `EvidenceDetailsScreen`.
  * Tap "Ask SureBot" -> navigates to `SureBotScreen`.
  * Tap Pillar item -> opens category breakdown.
* **Input Fields & Validation:** None directly.
* **Backend / API Interactions:**
  * Coordinates data via `DashboardDataCoordinator`.
  * Restores active assessment sessions from Firestore `users/{uid}/assessment_sessions/{assessmentId}`.
  * Queries Firestore `property_submissions/{id}` to verify submission validity.
* **Data Displayed:** Derived from `PropertyState` and `AssessmentState`.
* **Navigation Destinations:** Listed in actions above.
* **Current Implementation Status:** **Fully implemented**.

---

### Screen 7: Property Search & Selection Screen
* **File & Route:** [`lib/screens/onboarding/property_search_screen.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/onboarding/property_search_screen.dart) (accessible via navigation tab 1 or dashboard selector).
* **Purpose:** Browse verified projects or request inclusion of unlisted developments.
* **UI Components & Layout:** Top `AppSearchField`, filtered ListView of `PropertyCard` items, and a prominent banner for unlisted projects: *"Can't find your property? Submit Request"*.
* **Actions Available:**
  * Live filter search input (matches name, builder, locality, city, RERA number).
  * Tap property card to select.
  * Tap "View Details" to open `PropertyDetailsScreen`.
  * Tap "Submit Request" to open `_PropertyFormDialog`.
  * Tap "View My Requests" to open `MyPropertyRequestsScreen`.
* **Input Fields & Validation:** Live search text box; dialog requires Property Name, Locality, and City.
* **Backend / API Interactions:**
  * Unlisted submissions write to Firestore collection `property_submissions` with status `pending_review`.
* **Data Displayed:** Currently displays 2 hardcoded sample properties from [`lib/data/properties.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/data/properties.dart).
* **Navigation Destinations:** `PropertyDetailsScreen`, `MyPropertyRequestsScreen`.
* **Current Implementation Status:** **Partially implemented** (UI and submission work; search dataset is mock/hardcoded).

---

### Screen 8: Property Health Assessment Questionnaire
* **File & Route:** [`lib/screens/assessment/assessment_screen.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/assessment/assessment_screen.dart).
* **Purpose:** Administer the 33-question Property Health Standard evaluation.
* **UI Components & Layout:**
  * Top Category tabs with progress ticks.
  * Switcher toggle: **Classic View** (Accordion list) vs. **Premium View** (Swipeable cards with animated heatmap).
  * `QuestionCard`: Question title, legal/statutory rationale ("Why this matters"), radio answer options (*Yes*, *No*, *In Progress*, *Not Applicable*).
  * Evidence status pill and "Add Evidence" button.
  * Bottom navigation: "Save & Exit", "Previous", and "Next / Complete".
* **Actions Available:**
  * Select answer for question (updates `AssessmentState` and persists to Firestore).
  * Toggle between Classic and Premium views.
  * Tap "Add Evidence" -> opens modal bottom sheet (`EvidenceActionSheet`) with Camera, Gallery, and File options.
  * Tap "Save & Exit" -> writes session snapshot to Firestore and returns to Dashboard.
  * Tap "Complete Assessment" on final question -> launches `AnalyzingScreen`.
* **Input Fields & Validation:** Radio selection; optional photo or PDF attachments.
* **Backend / API Interactions:** Writes continuous updates to Firestore path `users/{uid}/assessment_sessions/{assessmentId}`.
* **Data Displayed:** 33 questions from [`lib/data/phs_questions.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/data/phs_questions.dart).
* **Navigation Destinations:** `AnalyzingScreen`, `EvidenceActionSheet`.
* **Current Implementation Status:** **Fully implemented**.

---

### Screen 9: Analyzing Screen
* **File & Route:** [`lib/screens/assessment/analyzing_screen.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/assessment/analyzing_screen.dart).
* **Purpose:** Transition screen running the mathematical PHS evaluation while displaying animated verification progress.
* **UI Components & Layout:** Central animated pulsing orb/icon, animated checklist sequence (`AnalyzingStep`: *"Evaluating statutory compliance...", "Calculating pillar weights...", "Synthesizing evidence score..."*).
* **Actions Available:** None (automatic progression after animation concludes).
* **Input Fields & Validation:** None.
* **Backend / API Interactions:** Invokes `WeightedPHScalculator` in-memory; persists final score state.
* **Data Displayed:** Step-by-step progress checklist.
* **Navigation Destination:** Replaces route with `PropertyHealthResultScreen`.
* **Current Implementation Status:** **Fully implemented**.

---

### Screen 10: Property Health Result Screen
* **File & Route:** [`lib/screens/assessment/property_health_result_screen.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/assessment/property_health_result_screen.dart).
* **Purpose:** Reveal the final Property Health Score, statutory risk profile, and document audit.
* **UI Components & Layout:**
  * Top circular score dial with color-coded band (Green: 80-100, Orange: 50-79, Red: 0-49).
  * Rating badge ("Excellent", "Moderate Risk", "Critical Attention Needed").
  * 6-pillar breakdown accordion with contribution weights.
  * Missing documents warning tile.
  * Bottom action cluster: "Download PDF Report", "View Report", "Ask SureBot", and "Back to Dashboard".
* **Actions Available:**
  * Tap "Download PDF Report" -> triggers vector PDF generation and system print/share sheet.
  * Tap "View Report" -> opens in-app report viewer (`PropertyHealthReportScreen`).
  * Tap "Ask SureBot" -> opens `SureBotScreen` seeded with score context.
* **Input Fields & Validation:** None.
* **Backend / API Interactions:** Reads computed `PropertyHealthResult`.
* **Data Displayed:** Comprehensive computed scores and risk statements.
* **Navigation Destinations:** `PropertyHealthReportScreen`, `SureBotScreen`, `HomeScreenV2`.
* **Current Implementation Status:** **Fully implemented**.

---

### Screen 11: In-App PDF Health Report & Print Viewer
* **File & Route:** [`lib/features/report/screens/property_health_report_screen.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/features/report/screens/property_health_report_screen.dart).
* **Purpose:** Preview and export the formal multi-page Property Health Report.
* **UI Components & Layout:** Vector PDF preview container with page navigation, zoom controls, and floating action button for system printing/export.
* **Actions Available:** Export PDF, share file, trigger wireless printer.
* **Input Fields & Validation:** None.
* **Backend / API Interactions:** Native device print spooler integration via `printing` package.
* **Data Displayed:** Vector layout generated by [`PropertyReportPdf`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/features/report/pdf/property_report_pdf.dart).
* **Navigation Destination:** Pop back to Result screen.
* **Current Implementation Status:** **Fully implemented**.

---

### Screen 12: SureBot Conversational AI Screen
* **File & Route:** [`lib/screens/assessment/surebot_screen.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/assessment/surebot_screen.dart).
* **Purpose:** Provide grounded, multi-lingual guidance explaining the property health score and next steps.
* **UI Components & Layout:** Top SureBot avatar with localized greeting, quick-prompt pill buttons ("Why is my score what it is?", "What should I address first?", "Which documents need attention?"), conversational bubble list, and language switcher.
* **Actions Available:**
  * Tap prompt pills to trigger explanations.
  * Switch language (English, Kannada, Hindi, Telugu, Tamil, Malayalam).
  * Tap "Start Assessment" if launched prior to assessment.
* **Input Fields & Validation:** Selection of prompt pills.
* **Backend / API Interactions:**
  * Reads/writes user language preference via `UserProfileService.savePreferredLanguage()`.
  * Generates responses via deterministic engine `PropertyHealthExplainer`.
* **Data Displayed:** Multi-lingual translated explanations.
* **Navigation Destinations:** Pop back or advance to `AssessmentScreen`.
* **Current Implementation Status:** **Fully implemented** (rule-based deterministic copy; live Gemini API integration is not yet connected).

---

### Screen 13: Residents Welfare Network (Residents Tab)
* **File & Route:** [`lib/features/network/screens/network_home_screen.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/features/network/screens/network_home_screen.dart) (MainShell tab index 4).
* **Purpose:** Facilitate resident community membership and RWA coordination.
* **UI Components & Layout:** Active property banner, membership status badge ("Not a member", "Pending approval", "Verified Member"), join request form dialog, association announcements feed, and resident contact directory.
* **Actions Available:**
  * Submit membership request (role: Owner, Tenant, Family Member) with personal note.
  * View pending approval status.
* **Input Fields & Validation:** Dropdown relationship selector; optional message string (max 300 chars).
* **Backend / API Interactions:**
  * Firestore collection: `properties/{propertyId}/community/main/membership_requests/{uid}`.
  * Reads membership record from `properties/{propertyId}/community/main/members/{uid}`.
* **Data Displayed:** Community details and member lists.
* **Navigation Destination:** None (embedded tab).
* **Current Implementation Status:** **Partially implemented** (request submission is fully wired; member directory feeds rely on mock collections).

---

### Screen 14: Profile & Settings Screen
* **File & Route:** [`lib/screens/main_shell.dart#L280-L418`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/main_shell.dart#L280-L418) (MainShell tab index 5).
* **Purpose:** User account management, language selection, and session termination.
* **UI Components & Layout:** User avatar with display name and email, Language selector card with native language scripts, App version footer (`1.0.0+1`), and Red "Sign Out" action button.
* **Actions Available:**
  * Select language from modal dropdown (instantly updates app locale via `AppLocaleController`).
  * Tap "Sign Out" (prompts confirmation, terminates Firebase session, and resets `AuthGate`).
* **Input Fields & Validation:** Language selection.
* **Backend / API Interactions:** `FirebaseAuth.instance.signOut()`; Firestore user profile language sync.
* **Data Displayed:** User email, display name, and active locale.
* **Navigation Destination:** Replaces entire tree with `SignedOutFlow()`.
* **Current Implementation Status:** **Fully implemented**.

---

### Screen 15: Developer Mode: Engine Playground Screen
* **File & Route:** [`lib/features/design_system/screens/engine_playground_screen.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/features/design_system/screens/engine_playground_screen.dart).
* **Purpose:** Internal QA testing harness to stress-test scoring math, category weights, and rule variations without completing the UI questionnaire.
* **UI Components & Layout:** Sliders for each of the 6 category scores (0-100), real-time calculated weighted PHS display, and rule trigger debugger.
* **Actions Available:** Slide category scores; toggle test rules.
* **Input Fields & Validation:** Sliders clamped between 0 and 100.
* **Backend / API Interactions:** In-memory execution of `WeightedPHScalculator`.
* **Data Displayed:** Real-time numerical calculations.
* **Activation:** Triggered when `kDeveloperMode = true` in [`lib/main.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/main.dart#L29).
* **Current Implementation Status:** **Fully implemented** (internal engineering tool).
