import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../features/auth/services/user_profile_service.dart';
import '../../features/surebot/models/surebot_language.dart';

/// Shared locale state for the entire HomeSureAI application.
///
/// All screens should read the active locale from this controller rather
/// than maintaining their own independent language preference.
class AppLocaleController {
  AppLocaleController._();

  static final AppLocaleController instance = AppLocaleController._();

  final ValueNotifier<Locale> locale = ValueNotifier<Locale>(
    const Locale('en'),
  );

  bool _disposed = false;

  String get languageCode => locale.value.languageCode;

  bool supportsLanguage(String code) => SureBotLanguage.fromCode(code) != null;

  /// Loads the signed-in user's saved language preference.
  ///
  /// If Firebase is not initialized or the preference cannot be loaded,
  /// the app safely retains its current language.
  Future<void> loadSavedLanguage() async {
    if (Firebase.apps.isEmpty) return;

    try {
      final code = await UserProfileService().getPreferredLanguage();
      if (!_disposed && supportsLanguage(code)) {
        locale.value = Locale(code);
      }
    } catch (_) {
      // Keep the current locale if profile loading fails.
    }
  }

  /// Changes the shared locale and persists it for a signed-in user.
  ///
  /// If saving fails, the previous locale is restored.
  Future<void> setLanguage(String code) async {
    if (!supportsLanguage(code)) {
      throw ArgumentError.value(code, 'code', 'Unsupported language.');
    }

    final previousLocale = locale.value;
    final nextLocale = Locale(code);

    if (previousLocale == nextLocale) return;

    locale.value = nextLocale;

    if (Firebase.apps.isEmpty) return;

    try {
      await UserProfileService().savePreferredLanguage(code);
    } catch (_) {
      if (!_disposed) {
        locale.value = previousLocale;
      }
      rethrow;
    }
  }

  void dispose() {
    _disposed = true;
    locale.dispose();
  }
}
