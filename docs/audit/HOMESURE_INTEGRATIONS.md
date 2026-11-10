# HomeSure AI — Integrations & External Dependencies Audit

**Document Identifier:** `HOMESURE_INTEGRATIONS.md`  
**Audit Date:** November 9, 2026  
**Auditor:** Antigravity AI Engineering  
**Application Root:** `c:\Program Files\BlackMatter\Homesure`  

---

## 1. External Services, SDKs & Libraries Matrix

| Integration / Dependency | Declared Version | Purpose | Code Locations | Auth Requirements | Current Status |
| :--- | :---: | :--- | :--- | :--- | :---: |
| **Firebase Core** | `^5.0.0` | Bootstraps Firebase native plugins | `lib/main.dart#L34`, `lib/firebase_options.dart` | Google Services JSON configuration | **Active** |
| **Firebase Auth** | `^7.0.0` | User account lifecycle & tokens | `lib/features/auth/` | Client API key & project token | **Active** |
| **Cloud Firestore** | `^7.0.0` | Remote NoSQL database | `lib/core/assessment/`, `lib/features/` | Declarative Security Rules (RBAC) | **Active** |
| **Firebase Analytics** | `^13.0.0` | Telemetry & app open tracking | `lib/main.dart#L67` | Embedded in Google Services | **Active** |
| **Google Fonts** | `^6.3.3` | Inter font family styling | `lib/theme/app_theme.dart` | HTTP font fetch / local cache | **Active** |
| **Image Picker** | `^1.2.1` | Camera capture & photo gallery | `lib/core/evidence/image_picker_gateway.dart` | Camera & Photo permissions | **Active** |
| **File Picker** | `^13.1.0` | Native OS PDF/document selection | `lib/core/evidence/file_picker_gateway.dart` | Read Storage permissions | **Active** |
| **PDF** | `^3.11.3` | Vector document composition | `lib/features/report/pdf/` | None (pure Dart) | **Active** |
| **Printing** | `^5.14.2` | OS print spooler & share sheet | `lib/features/report/screens/` | Native OS print bridge | **Active** |
| **Lottie** | `^3.3.2` | Vector animation playback | `pubspec.yaml` | None (bundled JSON assets) | **Active** |
| **Flutter Animate** | `^4.5.2` | Declarative UI transition effects | `pubspec.yaml` | None (pure Dart) | **Active** |
| **Smooth Page Indicator**| `^1.2.1` | Carousel dot pagination | `lib/screens/onboarding/welcome_screen.dart` | None (pure Dart) | **Active** |
| **Percent Indicator** | `^4.2.3` | Circular score dial visualization | `lib/widgets/hero_score_card.dart` | None (pure Dart) | **Active** |
| **Google Gemini / AI** | *Absent* | Generative AI property reasoning | Declared in `docs/10_AI_Strategy.md` | API Key / Vertex AI | **Not Implemented** |
| **Payment Gateway** | *Absent* | Report purchase monetization | Declared in `docs/07_Business_Model.md` | Razorpay / Stripe credentials | **Not Implemented** |
| **Maps / Geolocation** | *Absent* | Map-based property boundary check | Declared in `docs/06_MVP_PRD.md` | Google Maps SDK API key | **Not Implemented** |
| **Cloud Messaging (FCM)**| *Absent* | Push notifications for alerts | Architecture diagrams | APNS / FCM server credentials | **Not Implemented** |

---

## 2. In-Depth Integration Evaluations

### A. Firebase Authentication & Cloud Firestore
* **Implementation:** The client app initializes against Firebase using configurations in [`lib/firebase_options.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/firebase_options.dart).
* **Data Exchanged:** Email strings, hashed credential tokens, profile documents, question answer arrays, and membership requests.
* **Limitations Identified:**
  * When `kUseFirebaseEmulators = true` ([`lib/main.dart#L22`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/main.dart#L22)), the app redirects traffic to `10.0.2.2:9099` (Android) or `127.0.0.1:9099` (Web/Desktop). If the local emulator suite is not running on the host machine, network connections fail silently or time out.

### B. Hardware & Document Pickers (`image_picker` & `file_picker`)
* **Implementation:** Wrapped behind abstract interfaces ([`ImagePickerGateway`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/core/evidence/image_picker_gateway.dart) and [`FilePickerGateway`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/core/evidence/file_picker_gateway.dart)) allowing mock injection during unit tests.
* **Limitations Identified:**
  * Files are retained purely on local temporary device storage (`Evidence.filePath`).
  * Cloud upload sync via `firebase_storage` is not implemented.

### C. Vector PDF Generation (`pdf` & `printing`)
* **Implementation:** Implemented in [`lib/features/report/pdf/property_report_pdf.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/features/report/pdf/property_report_pdf.dart).
* **Capabilities:** Renders vector tables, score badges, disclaimers, and metadata across clean multi-page A4 layouts. Dispatches directly to system printing daemons and Android share intents.
* **Status:** Verified and fully operational.

### D. Artificial Intelligence & SureBot (`docs/10_AI_Strategy.md` vs. Codebase)
* **Specification Expectation:** The technical architecture documents describe an LLM-driven conversational agent powered by Gemini to answer complex questions regarding property litigation, builder reliability, and title verification.
* **Codebase Reality:** No Gemini API or Vertex AI SDK dependencies exist in `pubspec.yaml`. The app currently runs [`PropertyHealthExplainer`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/features/surebot/services/property_health_explainer.dart), which uses deterministic conditional logic to return hardcoded strings in 6 languages.
