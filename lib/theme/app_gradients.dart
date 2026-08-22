import 'package:flutter/material.dart';

class AppGradients {
  AppGradients._();

  /// Main application gradient
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F172A),
      Color(0xFF2563EB),
    ],
  );

  /// Premium gradient used for report cover
  static const LinearGradient premium = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F172A),
      Color(0xFF1E3A8A),
      Color(0xFF2563EB),
    ],
  );

  /// Backward-compatible hero gradient
  ///
  /// Existing widgets (Splash Screen, Hero Card,
  /// Property Hero Card) can continue using
  /// AppGradients.hero without any changes.
  static const LinearGradient hero = primary;

  static const LinearGradient success = LinearGradient(
    colors: [
      Color(0xFF16A34A),
      Color(0xFF22C55E),
    ],
  );

  static const LinearGradient warning = LinearGradient(
    colors: [
      Color(0xFFF59E0B),
      Color(0xFFFBBF24),
    ],
  );

  static const LinearGradient danger = LinearGradient(
    colors: [
      Color(0xFFDC2626),
      Color(0xFFEF4444),
    ],
  );
}