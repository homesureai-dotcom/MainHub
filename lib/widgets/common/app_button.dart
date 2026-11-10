import 'package:flutter/material.dart';

import '../../core/theme/homesure_tokens.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool enabled;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: icon != null ? Icon(icon, size: 19) : const SizedBox.shrink(),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: HomeSureColors.primaryNavy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: HomeSureColors.disabledBg,
          disabledForegroundColor: HomeSureColors.disabledText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HomeSureRadius.md),
          ),
        ),
      ),
    );
  }
}
