import 'package:flutter/material.dart';

import 'homesure_tokens.dart';

class HomeSureTheme {
  HomeSureTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: HomeSureColors.primaryNavy,
      brightness: Brightness.light,
      primary: HomeSureColors.primaryNavy,
      onPrimary: Colors.white,
      secondary: HomeSureColors.accentTeal,
      onSecondary: Colors.white,
      surface: HomeSureColors.surfaceWhite,
      onSurface: HomeSureColors.textPrimary,
      onSurfaceVariant: HomeSureColors.textSecondary,
      outline: HomeSureColors.borderDivider,
      error: HomeSureColors.statusCriticalText,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: HomeSureColors.backgroundWarm,
      dividerColor: HomeSureColors.borderDivider,
      appBarTheme: const AppBarTheme(
        backgroundColor: HomeSureColors.surfaceWhite,
        foregroundColor: HomeSureColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: HomeSureColors.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: HomeSureColors.surfaceWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HomeSureRadius.lg),
          side: const BorderSide(color: HomeSureColors.borderDivider),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: HomeSureColors.surfaceWhite,
        surfaceTintColor: Colors.transparent,
        indicatorColor: HomeSureColors.primaryNavyTint,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: HomeSureColors.primaryNavy,
              size: 22,
            );
          }
          return const IconThemeData(
            color: HomeSureColors.textSecondary,
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: HomeSureColors.primaryNavy,
            );
          }
          return const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: HomeSureColors.textSecondary,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: HomeSureColors.primaryNavy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: HomeSureColors.disabledBg,
          disabledForegroundColor: HomeSureColors.disabledText,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HomeSureRadius.md),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HomeSureColors.primaryNavy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: HomeSureColors.disabledBg,
          disabledForegroundColor: HomeSureColors.disabledText,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HomeSureRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: HomeSureColors.primaryNavy,
          side: const BorderSide(color: HomeSureColors.borderStrong),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HomeSureRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: HomeSureColors.accentTeal,
          textStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HomeSureColors.surfaceWhite,
        hintStyle: const TextStyle(
          fontSize: 13.5,
          color: HomeSureColors.textMuted,
        ),
        labelStyle: const TextStyle(
          fontSize: 13.5,
          color: HomeSureColors.textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HomeSureRadius.md),
          borderSide: const BorderSide(color: HomeSureColors.borderDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HomeSureRadius.md),
          borderSide: const BorderSide(color: HomeSureColors.borderDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HomeSureRadius.md),
          borderSide: const BorderSide(
            color: HomeSureColors.primaryNavy,
            width: 1.4,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: HomeSureColors.surfaceWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HomeSureRadius.lg),
        ),
        titleTextStyle: HomeSureTypography.sectionTitle,
      ),
      dividerTheme: const DividerThemeData(
        color: HomeSureColors.borderDivider,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        displaySmall: HomeSureTypography.screenTitle,
        headlineMedium: HomeSureTypography.screenTitle,
        headlineSmall: HomeSureTypography.sectionTitle,
        titleLarge: HomeSureTypography.cardTitle,
        titleMedium: HomeSureTypography.cardTitle,
        bodyLarge: HomeSureTypography.bodyPrimary,
        bodyMedium: HomeSureTypography.bodyPrimary,
        bodySmall: HomeSureTypography.bodySecondary,
        labelSmall: HomeSureTypography.caption,
      ),
    );
  }
}
