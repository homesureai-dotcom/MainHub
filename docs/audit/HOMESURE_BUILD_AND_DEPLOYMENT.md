# HomeSure AI — Build, Deployment & Runtime Audit

**Document Identifier:** `HOMESURE_BUILD_AND_DEPLOYMENT.md`  
**Audit Date:** November 9, 2026  
**Auditor:** Antigravity AI Engineering  
**Application Root:** `c:\Program Files\BlackMatter\Homesure`  

---

## 1. Build System & Toolchain Specification

* **Flutter Version:** 3.47.9 (Channel `stable`)
* **Dart Version:** 3.13.7
* **Android Gradle Plugin (AGP):** 8.6+ via Kotlin DSL (`android/build.gradle.kts`, `android/app/build.gradle.kts`)
* **Gradle Wrapper:** Gradle 8.10.2 / 9.1.0 (`android/gradle/wrapper/gradle-wrapper.properties`)
* **Java Development Kit (JDK):** OpenJDK 21.0.3 (bundled in Android Studio) / JVM 17 target compatibility.
* **Android SDK Target:** Compile SDK: 35/36; Target SDK: 35 (Android 15); Min SDK: 21 (Android 5.0).
* **Native Tooling:** Android NDK `r28c`, CMake 3.22.1.

---

## 2. Compilation & Packaging Pipelines

### A. Android APK Build Pipeline
1. **Command:** `flutter build apk --debug` or `flutter build apk --release`.
2. **Output Artifact:** [`build/app/outputs/flutter-apk/app-debug.apk`](file:///c:/Program%20Files/BlackMatter/Homesure/build/app/outputs/flutter-apk/app-debug.apk).
3. **Identity & Package Details:**
   * **Namespace:** `com.example.homesure_ai`
   * **Application ID:** `com.example.homesure_ai` ([`android/app/build.gradle.kts#L20`](file:///c:/Program%20Files/BlackMatter/Homesure/android/app/build.gradle.kts#L20))
   * **Version Code:** `1` (derived from `pubspec.yaml: 1.0.0+1`)
   * **Version Name:** `1.0.0`
4. **Signing Configuration Audit:**
   * In [`android/app/build.gradle.kts#L33`](file:///c:/Program%20Files/BlackMatter/Homesure/android/app/build.gradle.kts#L33), release builds explicitly sign with the debug keystore:
     ```kotlin
     buildTypes {
         release {
             signingConfig = signingConfigs.getByName("debug")
         }
     }
     ```
   * **Risk Assessment:** The application currently lacks an official production release keystore configuration.

### B. Web Build Pipeline
* **Command:** `flutter build web`
* **Output Artifact:** `build/web/`
* **Configuration:** Web rewrites and single-page routing configured in [`firebase.json#L24-L39`](file:///c:/Program%20Files/BlackMatter/Homesure/firebase.json#L24-L39).

### C. Desktop Windows Build Pipeline
* **Command:** `flutter build windows`
* **Output Artifact:** `build/windows/x64/runner/Release/homesure_ai.exe`
* **Prerequisites:** Requires Windows Developer Mode symlink support or elevated execution permissions.

---

## 3. Environment & Runtime Configuration

The application runtime is governed by two boolean constants in [`lib/main.dart`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/main.dart):

```dart
/// Set to true only when intentionally testing against
/// local Firebase Authentication and Firestore Emulators.
const bool kUseFirebaseEmulators = true;

/// Toggle this to true whenever you want to test
/// the Property Intelligence Engine.
const bool kDeveloperMode = false;
```

### Runtime Behaviors:
1. **`kUseFirebaseEmulators = true`**:
   * Directs auth traffic to `host:9099` and Firestore traffic to `host:8180`.
   * On Android emulators, `host = 10.0.2.2`. On Desktop/Web, `host = 127.0.0.1`.
   * **Critical Note:** Release builds throw a fatal runtime exception if this flag is enabled:
     ```dart
     if (kReleaseMode) {
       throw StateError('Firebase Emulators must not be enabled in a release build.');
     }
     ```
2. **`kDeveloperMode = true`**:
   * Bypasses the authentication gate and mounts [`EnginePlaygroundScreen`](file:///c:/Program%20Files/BlackMatter/Homesure/lib/features/design_system/screens/engine_playground_screen.dart) as the application root.

---

## 4. Permissions & Device Manifest Audit

* **Main Manifest:** [`android/app/src/main/AndroidManifest.xml`](file:///c:/Program%20Files/BlackMatter/Homesure/android/app/src/main/AndroidManifest.xml)
* **Debug Manifest:** [`android/app/src/debug/AndroidManifest.xml`](file:///c:/Program%20Files/BlackMatter/Homesure/android/app/src/debug/AndroidManifest.xml)

### Critical Manifest Finding:
1. `<uses-permission android:name="android.permission.INTERNET"/>` and `android:usesCleartextTraffic="true"` are declared **only** in `android/app/src/debug/AndroidManifest.xml`.
2. The main production manifest (`src/main/AndroidManifest.xml`) does **not** declare the `INTERNET` permission.
3. While debug builds inherit the debug manifest, a clean release build could strip the internet permission, preventing all Firebase communication on physical devices.

---

## 5. Backend & Database Deployment Commands

Deployment of the serverless backend is managed via the Firebase CLI:

```powershell
# 1. Deploy Firestore Security Rules & Composite Indexes
firebase deploy --only firestore:rules,firestore:indexes

# 2. Deploy Web Single Page Application to Firebase Hosting
firebase deploy --only hosting

# 3. Deploy Cloud Functions (Node.js / TypeScript)
firebase deploy --only functions
```

---

## 6. Known Build & Compilation Warnings

1. **Deprecated Kotlin Gradle Plugin (KGP):**
   * The build process issues explicit deprecation warnings regarding Firebase plugins:
     ```text
     WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP):
     firebase_analytics, firebase_auth, firebase_core.
     Future versions of Flutter will fail to build if your app uses plugins that apply KGP.
     Migrate to Built-in Kotlin.
     ```
2. **Java Compiler Obsolete Target Options:**
   * Build generates javac warnings: `warning: [options] source value 8 is obsolete and will be removed in a future release`.
3. **Android SDK Whitespace Conflict:**
   * Default path `C:\Users\Shubham Kumar\AppData\Local\Android\Sdk` contains spaces, breaking NDK build tools. Resolved via directory junction at `C:\Android\Sdk`.
