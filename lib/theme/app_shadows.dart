import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> small = [
    BoxShadow(
      color: Color(0x11000000),
      blurRadius: 8,
      offset: Offset(0, 3),
    ),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x16000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> large = [
    BoxShadow(
      color: Color(0x22000000),
      blurRadius: 28,
      offset: Offset(0, 14),
    ),
  ];
}