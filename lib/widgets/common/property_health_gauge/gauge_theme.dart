import 'package:flutter/material.dart';

class GaugeTheme {
  const GaugeTheme._();

  static const double strokeWidth = 16;

  static const double startAngle = 135;

  static const double sweepAngle = 270;

  static const Color background =
      Color(0xFFE8EEF8);

  static const Color healthy =
      Color(0xFF22C55E);

  static const Color good =
      Color(0xFF84CC16);

  static const Color attention =
      Color(0xFFF59E0B);

  static const Color risk =
      Color(0xFFEA580C);

  static const Color critical =
      Color(0xFFDC2626);

  static const Duration animationDuration =
      Duration(milliseconds: 1200);
}