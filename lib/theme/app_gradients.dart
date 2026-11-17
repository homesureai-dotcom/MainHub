import 'package:flutter/material.dart';

import '../core/theme/homesure_tokens.dart';

class AppGradients {
  AppGradients._();

  /// Reference HTML hero gradient:
  /// `linear-gradient(135deg,#0F2437 0%,#1B3448 65%,#80684F 100%)`
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.65, 1.0],
    colors: [
      HomeSureColors.midnightNavy,
      HomeSureColors.heroMidSlate,
      HomeSureColors.heroWarmBronze,
    ],
  );

  /// Premium gradient used for report cover & executive hero cards
  static const LinearGradient premium = primary;

  /// Backward-compatible hero gradient
  static const LinearGradient hero = primary;

  /// Champagne progress fill gradient (`linear-gradient(90deg,#C9A47E,#E7C9A8)`)
  static const LinearGradient progressChampagne = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      HomeSureColors.champagneGold,
      HomeSureColors.champagneHighlight,
    ],
  );

  static const LinearGradient success = LinearGradient(
    colors: [
      Color(0xFF15803D),
      Color(0xFF34D399),
    ],
  );

  static const LinearGradient warning = LinearGradient(
    colors: [
      HomeSureColors.champagneBronze,
      HomeSureColors.champagneHighlight,
    ],
  );

  static const LinearGradient danger = LinearGradient(
    colors: [
      Color(0xFFB91C1C),
      Color(0xFFFCA5A5),
    ],
  );
}
