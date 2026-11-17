import 'package:flutter/material.dart';

import 'homesure_tokens.dart';

class HomeSureTheme {
  HomeSureTheme._();

  static ThemeData get light => dark;

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: HomeSureColors.champagneGold,
      brightness: Brightness.dark,
      primary: HomeSureColors.champagneGold,
      onPrimary: HomeSureColors.midnightCard,
      secondary: HomeSureColors.champagneHighlight,
      onSecondary: HomeSureColors.midnightCard,
      surface: HomeSureColors.midnightCard,
      onSurface: HomeSureColors.champagneInk,
      onSurfaceVariant: HomeSureColors.slateMuted,
      outline: HomeSureColors.borderSlate,
      error: HomeSureColors.statusCriticalText,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: HomeSureColors.midnightBg,
      canvasColor: HomeSureColors.midnightBg,
      dividerColor: HomeSureColors.borderSlate,
      appBarTheme: const AppBarTheme(
        backgroundColor: HomeSureColors.midnightHeader,
        foregroundColor: HomeSureColors.champagneInk,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: HomeSureColors.champagneInk,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: HomeSureColors.midnightCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HomeSureRadius.lg),
          side: const BorderSide(color: HomeSureColors.borderSlate),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: HomeSureColors.midnightBottomNav,
        surfaceTintColor: Colors.transparent,
        indicatorColor: HomeSureColors.midnightSelected,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: HomeSureColors.champagneHighlight,
              size: 22,
            );
          }
          return const IconThemeData(
            color: HomeSureColors.slateMuted,
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: HomeSureColors.champagneHighlight,
            );
          }
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: HomeSureColors.slateMuted,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: HomeSureColors.champagneGold,
          foregroundColor: HomeSureColors.midnightCard,
          disabledBackgroundColor: HomeSureColors.disabledBg,
          disabledForegroundColor: HomeSureColors.disabledText,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HomeSureRadius.md),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HomeSureColors.champagneGold,
          foregroundColor: HomeSureColors.midnightCard,
          disabledBackgroundColor: HomeSureColors.disabledBg,
          disabledForegroundColor: HomeSureColors.disabledText,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HomeSureRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: HomeSureColors.midnightInteractive,
          foregroundColor: HomeSureColors.champagneHighlight,
          side: const BorderSide(color: HomeSureColors.champagneBronze),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HomeSureRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: HomeSureColors.champagneHighlight,
          textStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HomeSureColors.midnightCard,
        hintStyle: const TextStyle(
          fontSize: 13.5,
          color: HomeSureColors.slatePlaceholder,
        ),
        labelStyle: const TextStyle(
          fontSize: 13.5,
          color: HomeSureColors.slateMuted,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HomeSureRadius.md),
          borderSide: const BorderSide(color: HomeSureColors.borderInput),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HomeSureRadius.md),
          borderSide: const BorderSide(color: HomeSureColors.borderInput),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HomeSureRadius.md),
          borderSide: const BorderSide(
            color: HomeSureColors.champagneGold,
            width: 1.5,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: HomeSureColors.midnightCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HomeSureRadius.lg),
          side: const BorderSide(color: HomeSureColors.borderSlate),
        ),
        titleTextStyle: HomeSureTypography.sectionTitle,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: HomeSureColors.midnightCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(color: HomeSureColors.borderSlate),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: HomeSureColors.midnightInteractive,
        selectedColor: HomeSureColors.midnightSelected,
        labelStyle: const TextStyle(
          color: HomeSureColors.champagneInk,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: HomeSureColors.borderSlate),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HomeSureRadius.pill),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: HomeSureColors.midnightInteractive,
        contentTextStyle: const TextStyle(
          color: HomeSureColors.champagneInk,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HomeSureRadius.md),
          side: const BorderSide(color: HomeSureColors.champagneGold),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: HomeSureColors.borderSlate,
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
