import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle display = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.bold,
    height: 1.15,
    letterSpacing: -1,
    color: Color(0xFF0F172A),
  );

  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Color(0xFF0F172A),
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Color(0xFF0F172A),
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: Color(0xFF0F172A),
  );

  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1E293B),
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: Color(0xFF334155),
    height: 1.6,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    color: Color(0xFF64748B),
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: Color(0xFF94A3B8),
    letterSpacing: .5,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Color(0xFF475569),
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
}