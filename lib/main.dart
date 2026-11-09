
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/assessment/assessment_session_store.dart';
import 'core/localization/app_locale_controller.dart';
import 'features/auth/screens/auth_gate.dart';
import 'features/design_system/screens/engine_playground_screen.dart';
import 'firebase_options.dart';
import 'l10n/generated/app_localizations.dart';
import 'state/assessment_state.dart';
import 'theme/app_theme.dart';

/// Set to true only when intentionally testing against
/// local Firebase Authentication and Firestore Emulators.
///
/// Keep false for normal and production builds.
const bool kUseFirebaseEmulators = true;

/// Toggle this to true whenever you want to test
/// the Property Intelligence Engine.
///
/// false = Normal HomeSure App
/// true  = Engine Playground
const bool kDeveloperMode = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kUseFirebaseEmulators) {
    if (kReleaseMode) {
      throw StateError(
        'Firebase Emulators must not be enabled in a release build.',
      );
    }

    // Android emulator reaches the host Mac through 10.0.2.2.
    // Web and desktop running on the Mac can use 127.0.0.1.
    final host = defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : '127.0.0.1';

    // Connect Firebase Authentication to the local emulator.
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);

    // Connect Cloud Firestore to the local emulator.
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8180);
  }

  // Enable per-user Firestore assessment session persistence.
  AssessmentState.instance.configurePersistence(
    AssessmentSessionStore(),
  );

  // Restore the signed-in user's saved language when available.
  // Failure to load a preference leaves the app in English.
  await AppLocaleController.instance.loadSavedLanguage();

  await FirebaseAnalytics.instance.logAppOpen();

  runApp(const HomeSureAIApp());
}

class HomeSureAIApp extends StatelessWidget {
  const HomeSureAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeController = AppLocaleController.instance;

    return ValueListenableBuilder<Locale>(
      valueListenable: localeController.locale,
      builder: (context, locale, child) {
        return MaterialApp(
          title: 'HomeSure AI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: kDeveloperMode
              ? const EnginePlaygroundScreen()
              : const AuthGate(),
        );
      },
    );
  }
}
