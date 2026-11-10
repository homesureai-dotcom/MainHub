import 'package:flutter/material.dart';

import '../core/theme/homesure_tokens.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle display = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.8,
    color: HomeSureColors.textPrimary,
  );

  static const TextStyle h1 = HomeSureTypography.screenTitle;

  static const TextStyle h2 = HomeSureTypography.sectionTitle;

  static const TextStyle h3 = HomeSureTypography.cardTitle;

  static const TextStyle title = HomeSureTypography.cardTitle;

  static const TextStyle body = HomeSureTypography.bodyPrimary;

  static const TextStyle bodySmall = HomeSureTypography.bodySecondary;

  static const TextStyle caption = HomeSureTypography.caption;

  static const TextStyle label = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: HomeSureColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
