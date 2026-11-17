import 'package:flutter/material.dart';

import '../../core/theme/homesure_tokens.dart';

enum StatusType {
  success,
  warning,
  danger,
  info,
}

class AppStatusChip extends StatelessWidget {
  final String label;
  final StatusType status;

  const AppStatusChip({
    super.key,
    required this.label,
    required this.status,
  });

  (Color fg, Color bg, Color border) get _colors {
    switch (status) {
      case StatusType.success:
        return (
          HomeSureColors.statusPositiveText,
          HomeSureColors.statusPositiveBg,
          HomeSureColors.statusPositiveBorder,
        );
      case StatusType.warning:
        return (
          HomeSureColors.statusWarningText,
          HomeSureColors.statusWarningBg,
          HomeSureColors.statusWarningBorder,
        );
      case StatusType.danger:
        return (
          HomeSureColors.statusCriticalText,
          HomeSureColors.statusCriticalBg,
          HomeSureColors.statusCriticalBorder,
        );
      case StatusType.info:
        return (
          HomeSureColors.champagneHighlight,
          HomeSureColors.midnightInteractive,
          HomeSureColors.champagneBronze,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (fg, bg, border) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
