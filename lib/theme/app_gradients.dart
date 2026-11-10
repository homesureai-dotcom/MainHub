import 'package:flutter/material.dart';

import '../core/theme/homesure_tokens.dart';

class AppGradients {
  AppGradients._();

  /// Main application gradient — Deep Navy to Muted Teal-Navy
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      HomeSureColors.primaryDarkNavy,
      HomeSureColors.primaryNavy,
      Color(0xFF1A3A5F),
    ],
  );

  /// Premium gradient used for report cover & executive hero cards
  static const LinearGradient premium = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      HomeSureColors.primaryDarkNavy,
      HomeSureColors.primaryNavy,
      HomeSureColors.accentTealDark,
    ],
  );

  /// Backward-compatible hero gradient
  static const LinearGradient hero = primary;

  static const LinearGradient success = LinearGradient(
    colors: [
      HomeSureColors.statusPositiveText,
      Color(0xFF1F9D63),
    ],
  );

  static const LinearGradient warning = LinearGradient(
    colors: [
      HomeSureColors.statusWarningText,
      Color(0xFFD98A16),
    ],
  );

  static const LinearGradient danger = LinearGradient(
    colors: [
      HomeSureColors.statusCriticalText,
      Color(0xFFD9534F),
    ],
  );
}
