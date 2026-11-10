import 'package:flutter/material.dart';

import '../core/theme/homesure_tokens.dart';

class AppColors {
  AppColors._();

  // Primary Brand Colors — Deep Navy & Muted Teal
  static const Color primary = HomeSureColors.primaryNavy;
  static const Color primaryDark = HomeSureColors.primaryDarkNavy;
  static const Color primaryLight = HomeSureColors.primaryNavyTint;
  static const Color secondary = HomeSureColors.accentTeal;
  static const Color accent = HomeSureColors.accentTeal;

  // Backgrounds & Surfaces
  static const Color background = HomeSureColors.backgroundWarm;
  static const Color surface = HomeSureColors.surfaceWhite;
  static const Color card = HomeSureColors.surfaceWhite;
  static const Color surfaceSubtle = HomeSureColors.surfaceSubtle;

  // Text Colors
  static const Color textPrimary = HomeSureColors.textPrimary;
  static const Color textSecondary = HomeSureColors.textSecondary;
  static const Color textMuted = HomeSureColors.textMuted;

  // Status Colors
  static const Color success = HomeSureColors.statusPositiveText;
  static const Color warning = HomeSureColors.statusWarningText;
  static const Color danger = HomeSureColors.statusCriticalText;
  static const Color info = HomeSureColors.accentTeal;

  // Borders
  static const Color border = HomeSureColors.borderDivider;
}
