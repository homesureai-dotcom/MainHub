import 'package:flutter/material.dart';

import '../core/theme/homesure_tokens.dart';

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> small = HomeSureShadows.cardSubtle;

  static const List<BoxShadow> medium = HomeSureShadows.cardElevated;

  static const List<BoxShadow> large = [
    BoxShadow(
      color: Color(0x1410213A),
      blurRadius: 22,
      offset: Offset(0, 10),
    ),
  ];
}
