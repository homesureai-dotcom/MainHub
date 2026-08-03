import 'package:flutter/material.dart';

class AppGradients {
  AppGradients._();

  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F172A), // Navy
      Color(0xFF2563EB), // HomeSure Blue
    ],
  );

  static const LinearGradient success = LinearGradient(
    colors: [
      Color(0xFF10B981),
      Color(0xFF059669),
    ],
  );

  static const LinearGradient warning = LinearGradient(
    colors: [
      Color(0xFFF59E0B),
      Color(0xFFD97706),
    ],
  );
}