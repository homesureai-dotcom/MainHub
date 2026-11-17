import 'package:flutter/material.dart';

import '../../features/property/models/krera_project_models.dart';

/// Canonical HomeSure Design Tokens — Midnight Slate & Champagne Dark (Palette A).
///
/// Extracted directly from `HomeSureAI_Mobile_Midnight_Slate_Champagne_Dark_PaletteA_Fixed.html`.
class HomeSureColors {
  HomeSureColors._();

  // Midnight Slate & Champagne Dark Core Palette (Reference HTML)
  static const Color midnightBg = Color(0xFF091923);
  static const Color midnightHeader = Color(0xFA081722);
  static const Color midnightBottomNav = Color(0xFC081722);
  static const Color midnightNavy = Color(0xFF0F2437);
  static const Color midnightCard = Color(0xFF102532);
  static const Color midnightDetail = Color(0xFF152B3A);
  static const Color midnightInteractive = Color(0xFF1B3443);
  static const Color midnightSand = Color(0xFF243746);
  static const Color midnightSelected = Color(0xFF243B4C);
  static const Color midnightChoiceSelected = Color(0xFF34495A);

  static const Color champagneGold = Color(0xFFC9A47E);
  static const Color champagneHighlight = Color(0xFFE7C9A8);
  static const Color champagneBronze = Color(0xFF8A6847);

  static const Color champagneInk = Color(0xFFF4EBDD);
  static const Color slateMuted = Color(0xFFB9C3C8);
  static const Color slateDetailBody = Color(0xFFC7D0D4);
  static const Color slatePlaceholder = Color(0xFFAEBBC2);

  static const Color borderSlate = Color(0xFF344957);
  static const Color borderInput = Color(0xFF425968);

  static const Color heroMidSlate = Color(0xFF1B3448);
  static const Color heroWarmBronze = Color(0xFF80684F);

  // Semantic aliases mapped across existing components
  static const Color primaryNavy = champagneGold;
  static const Color primaryDarkNavy = midnightNavy;
  static const Color primaryNavyTint = midnightSelected;

  static const Color accentTeal = champagneGold;
  static const Color accentTealDark = champagneHighlight;
  static const Color accentTealTint = midnightSelected;
  static const Color accentTealBorder = champagneBronze;

  // Backgrounds & Surfaces
  static const Color backgroundWarm = midnightBg;
  static const Color surfaceWhite = midnightCard;
  static const Color surfaceSubtle = midnightDetail;
  static const Color surfaceElevated = midnightInteractive;

  // Typography Colors
  static const Color textPrimary = champagneInk;
  static const Color textSecondary = slateMuted;
  static const Color textMuted = slatePlaceholder;
  static const Color textOnDark = champagneInk;

  // Borders & Dividers
  static const Color borderDivider = borderSlate;
  static const Color borderStrong = borderInput;

  // Semantic Status — Positive / Verified
  static const Color statusPositiveText = Color(0xFF6EE7B7);
  static const Color statusPositiveBg = Color(0xFF112E2A);
  static const Color statusPositiveBorder = Color(0xFF235D4E);

  // Semantic Status — Warning / Attention
  static const Color statusWarningText = champagneHighlight;
  static const Color statusWarningBg = midnightSand;
  static const Color statusWarningBorder = champagneBronze;

  // Semantic Status — Critical / Risk
  static const Color statusCriticalText = Color(0xFFFCA5A5);
  static const Color statusCriticalBg = Color(0xFF311B22);
  static const Color statusCriticalBorder = Color(0xFF7F2D36);

  // Semantic Status — Neutral / Info
  static const Color statusNeutralText = slateMuted;
  static const Color statusNeutralBg = midnightDetail;
  static const Color statusNeutralBorder = borderSlate;

  // Disabled
  static const Color disabledText = Color(0xFF64748B);
  static const Color disabledBg = midnightInteractive;
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
  static const double sm = 10.0;
  static const double md = 12.0;
  static const double lg = 17.0;
  static const double xl = 18.0;
  static const double pill = 999.0;
}

class HomeSureShadows {
  HomeSureShadows._();

  static const List<BoxShadow> cardSubtle = [
    BoxShadow(
      color: Color(0x38000000),
      blurRadius: 16,
      offset: Offset(0, 5),
    ),
  ];

  static const List<BoxShadow> cardElevated = [
    BoxShadow(
      color: Color(0x47000000),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}

class HomeSureTypography {
  HomeSureTypography._();

  static const TextStyle screenTitle = TextStyle(
    fontSize: 23,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.3,
    color: HomeSureColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.15,
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
    height: 1.45,
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
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: 0.7,
    color: HomeSureColors.champagneHighlight,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
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
