# HomeSure AI — Existing UI/UX Audit & Interaction Friction Analysis

**Document Identifier:** `HOMESURE_UI_UX_AUDIT.md`  
**Audit Date:** November 9, 2026  
**Auditor:** Antigravity AI Engineering  
**Application Root:** `c:\Program Files\BlackMatter\Homesure`  

---

## 1. Overview of Visual & Interaction Design

HomeSure AI exhibits a clean, modern aesthetic rooted in **Material 3**, utilizing deep indigo brand tones, rounded cards (`BorderRadius.circular(20)`), subtle drop shadows, and clean vector typography. However, an in-depth audit of the user flow reveals substantial interaction friction, navigation dead-ends, contradictory visual metaphors, and legacy UI artifacts.

---

## 2. Granular UX Deficiencies & Friction Points

### A. Onboarding Fatigue (3 Consecutive Intro Screens)
* **Locations:**
  1. [`lib/screens/onboarding/splash_screen.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/onboarding/splash_screen.dart) (Mandatory 3-second timer).
  2. [`lib/screens/onboarding/welcome_screen.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/onboarding/welcome_screen.dart) (3-slide horizontal carousel).
  3. [`lib/screens/onboarding/how_it_works_screen.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/onboarding/how_it_works_screen.dart) (3-step static list).
* **Friction Analysis:** A user must traverse through three successive explanatory screens before ever encountering the authentication or property search input. This creates severe onboarding fatigue and high drop-off likelihood.

### B. Navigation Dead-Ends in the Main Navigation Shell
* **Location:** [`lib/screens/main_shell.dart#L25-L32`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/main_shell.dart#L25-L32)
* **Observation:** The primary bottom navigation bar presents 6 destinations. However, tapping the 3rd tab ("Health") and 4th tab ("AI") renders static placeholder screens:
  ```dart
  const _ComingSoonScreen(
    title: 'Property Health Record',
    icon: Icons.health_and_safety_outlined,
  ),
  const _ComingSoonScreen(
    title: 'AI Advisor',
    icon: Icons.smart_toy_outlined,
  )
  ```
* **Friction Analysis:** Placing permanent "Coming Soon" tabs in the root navigation bar severely undermines user trust and app perceived completeness, especially when full implementations for both features already exist in [`PropertyHealthRecordScreen`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/property_health_record_screen.dart) and [`SureBotScreen`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/assessment/surebot_screen.dart).

### C. The "Silent Click" Bug in Dashboard Timeline
* **Location:** [`lib/screens/home_screen_v2.dart#L188-L190`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/home_screen_v2.dart#L188-L190)
* **Code Reference:**
  ```dart
  void _openTimeline() {
    // Timeline screen is not implemented yet.
  }
  ```
* **Friction Analysis:** Tapping timeline actions on the home dashboard produces zero visual reaction, no feedback toast, and no navigation. To the user, the app appears frozen or broken.

### D. The Non-Functional Search Bar in City Selection
* **Location:** [`lib/screens/onboarding/city_selection_screen.dart#L87-L92`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/onboarding/city_selection_screen.dart#L87-L92)
* **Code Reference:**
  ```dart
  AppSearchField(
    hintText: 'Search city',
    onChanged: (value) {
      // Search functionality will be added later.
    },
  )
  ```
* **Friction Analysis:** The screen renders an interactive search text field, but entering text executes no filtering logic. The popular city grid below remains completely static.

### E. Conflicting UI Paradigms in the Assessment Flow
* **Location:** [`lib/screens/assessment/assessment_screen.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/screens/assessment/assessment_screen.dart)
* **Observation:** The assessment screen provides a segmented button to toggle between:
  1. *Classic View* ([`classic_category_accordion.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/widgets/assessment/classic_category_accordion.dart)): Uses standard expansion panels and traditional form fields.
  2. *Premium View* ([`premium_assessment_view.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/widgets/assessment/premium_assessment_view.dart)): Uses swipeable card stacks, custom category heatmap legends, and fluid motion.
* **Friction Analysis:** Offering users two completely different presentation paradigms for the same task introduces cognitive burden. It indicates an incomplete transition from an older UI design to a newer design.

### F. Terminological Inconsistency
* **Observation:** Across various screens and reports, the application inconsistently alternates between four different terms for the same metric:
  * *"Property Health Score"*
  * *"HomeSure Score"*
  * *"Property Health Index (PHI)"*
  * *"Health Score"*
* **Friction Analysis:** Users are left confused as to whether these are different sub-scores or the same master index.

### G. Hyper-Localised Terminology without Tooltips
* **Observation:** In the assessment questionnaire, terms such as `e-Khata`, `BESCOM`, `BWSSB`, `STP`, and `Fire NOC` are used as fundamental criteria.
* **Friction Analysis:** While applicable in Karnataka, users unfamiliar with Bengaluru municipal acronyms are given insufficient contextual help when evaluating properties in other states or when relocating.

### H. Accessibility & Color-Blindness Risks
* **Location:** [`lib/widgets/property_health/score_heatmap_legend.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/widgets/property_health/score_heatmap_legend.dart)
* **Observation:** Scoring statuses rely almost exclusively on green/orange/red chromatic shifts. Users with deuteranopia or protanopia cannot easily differentiate moderate compliance from critical legal risk without redundant iconography.
