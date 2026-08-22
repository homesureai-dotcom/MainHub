import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    scaffoldBackgroundColor: AppColors.background,

    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: Colors.white,
    ),

    // ---------- Typography ----------
    textTheme: GoogleFonts.manropeTextTheme(),

    // ---------- AppBar ----------
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      titleTextStyle: GoogleFonts.manrope(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    ),

    // ---------- Cards ----------
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppSpacing.cardRadius,
        ),
      ),
    ),

    // ---------- Buttons ----------
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppSpacing.buttonRadius,
          ),
        ),
        textStyle: GoogleFonts.manrope(
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    // ---------- Filled Buttons ----------
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppSpacing.buttonRadius,
          ),
        ),
        textStyle: GoogleFonts.manrope(
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    // ---------- Inputs ----------
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: AppColors.border,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
      ),
    ),

    dividerTheme: const DividerThemeData(
      thickness: 1,
      space: 32,
    ),
  );
}