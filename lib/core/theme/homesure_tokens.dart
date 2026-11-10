import 'package:flutter/material.dart';

import '../../features/property/models/krera_project_models.dart';

/// Canonical HomeSure Phase 2 Design Tokens.
///
/// Implements the institutional, fintech-grade palette, typography, spacing,
/// radius, and elevation tokens for the Bengaluru property intelligence platform.
class HomeSureColors {
  HomeSureColors._();

  // Primary & Brand Accents
  static const Color primaryNavy = Color(0xFF172B4D);
  static const Color primaryDarkNavy = Color(0xFF10213A);
  static const Color primaryNavyTint = Color(0xFFECF0F6);

  static const Color accentTeal = Color(0xFF168C83);
  static const Color accentTealDark = Color(0xFF116E67);
  static const Color accentTealTint = Color(0xFFE6F4F2);
  static const Color accentTealBorder = Color(0xFFB5DFD9);

  // Backgrounds & Surfaces
  static const Color backgroundWarm = Color(0xFFF7F8FA);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF1F4F9);
  static const Color surfaceElevated = Color(0xFFFAFBFC);

  // Typography Colors
  static const Color textPrimary = Color(0xFF17212F);
  static const Color textSecondary = Color(0xFF687386);
  static const Color textMuted = Color(0xFF8C96A6);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // Borders & Dividers
  static const Color borderDivider = Color(0xFFE7EAF0);
  static const Color borderStrong = Color(0xFFD2D8E3);

  // Semantic Status — Positive / Verified
  static const Color statusPositiveText = Color(0xFF16794B);
  static const Color statusPositiveBg = Color(0xFFEAF6F0);
  static const Color statusPositiveBorder = Color(0xFFBFE5D1);

  // Semantic Status — Warning / Attention
  static const Color statusWarningText = Color(0xFFB86E00);
  static const Color statusWarningBg = Color(0xFFFFF6E5);
  static const Color statusWarningBorder = Color(0xFFF5D9A6);

  // Semantic Status — Critical / Risk
  static const Color statusCriticalText = Color(0xFFC43B3B);
  static const Color statusCriticalBg = Color(0xFFFDF0F0);
  static const Color statusCriticalBorder = Color(0xFFF3C2C2);

  // Semantic Status — Neutral / Info
  static const Color statusNeutralText = Color(0xFF42526E);
  static const Color statusNeutralBg = Color(0xFFF1F4F9);
  static const Color statusNeutralBorder = Color(0xFFD8E0EC);

  // Disabled
  static const Color disabledText = Color(0xFF9AA4B2);
  static const Color disabledBg = Color(0xFFEEF1F6);
}

class HomeSureSpacing {
  HomeSureSpacing._();

  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

class HomeSureRadius {
  HomeSureRadius._();

  static const double xs = 6.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double pill = 999.0;
}

class HomeSureShadows {
  HomeSureShadows._();

  static const List<BoxShadow> cardSubtle = [
    BoxShadow(
      color: Color(0x0710213A),
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
  ];

  static const List<BoxShadow> cardElevated = [
    BoxShadow(
      color: Color(0x0D10213A),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];
}

class HomeSureTypography {
  HomeSureTypography._();

  static const TextStyle screenTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.4,
    color: HomeSureColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.2,
    color: HomeSureColors.textPrimary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w700,
    height: 1.35,
    letterSpacing: -0.1,
    color: HomeSureColors.textPrimary,
  );

  static const TextStyle bodyPrimary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: HomeSureColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: HomeSureColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: HomeSureColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    height: 1.35,
    letterSpacing: 0.15,
    color: HomeSureColors.textSecondary,
  );

  static const TextStyle eyebrow = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.8,
    color: HomeSureColors.textSecondary,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.2,
  );
}

/// Visual tokens for each of the 6 canonical K-RERA `ObservationState` values.
class ObservationStateVisual {
  final String label;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;

  const ObservationStateVisual({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
  });

  static ObservationStateVisual of(ObservationState state) {
    switch (state) {
      case ObservationState.presentWithData:
        return const ObservationStateVisual(
          label: 'Available in K-RERA',
          textColor: HomeSureColors.statusPositiveText,
          backgroundColor: HomeSureColors.statusPositiveBg,
          borderColor: HomeSureColors.statusPositiveBorder,
          icon: Icons.verified_outlined,
        );
      case ObservationState.presentEmpty:
        return const ObservationStateVisual(
          label: 'Published Empty in K-RERA',
          textColor: HomeSureColors.statusWarningText,
          backgroundColor: HomeSureColors.statusWarningBg,
          borderColor: HomeSureColors.statusWarningBorder,
          icon: Icons.info_outline_rounded,
        );
      case ObservationState.notPresent:
        return const ObservationStateVisual(
          label: 'Not Shown on K-RERA',
          textColor: HomeSureColors.statusNeutralText,
          backgroundColor: HomeSureColors.statusNeutralBg,
          borderColor: HomeSureColors.statusNeutralBorder,
          icon: Icons.remove_circle_outline,
        );
      case ObservationState.notApplicable:
        return const ObservationStateVisual(
          label: 'Not Applicable',
          textColor: HomeSureColors.textSecondary,
          backgroundColor: HomeSureColors.surfaceSubtle,
          borderColor: HomeSureColors.borderDivider,
          icon: Icons.block_flipped,
        );
      case ObservationState.notAvailable:
        return const ObservationStateVisual(
          label: 'Not Available',
          textColor: HomeSureColors.textSecondary,
          backgroundColor: HomeSureColors.surfaceSubtle,
          borderColor: HomeSureColors.borderDivider,
          icon: Icons.help_outline_rounded,
        );
      case ObservationState.extractionFailed:
        return const ObservationStateVisual(
          label: 'Verification Needed',
          textColor: HomeSureColors.statusCriticalText,
          backgroundColor: HomeSureColors.statusCriticalBg,
          borderColor: HomeSureColors.statusCriticalBorder,
          icon: Icons.warning_amber_rounded,
        );
    }
  }
}
