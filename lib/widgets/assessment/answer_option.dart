import 'package:flutter/material.dart';

import '../../core/theme/homesure_tokens.dart';

class AnswerOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback? onTap;
  final bool selected;

  const AnswerOption({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(HomeSureRadius.lg),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? HomeSureColors.midnightChoiceSelected
              : HomeSureColors.midnightInteractive,
          borderRadius: BorderRadius.circular(HomeSureRadius.lg),
          border: Border.all(
            color: selected
                ? HomeSureColors.champagneGold
                : HomeSureColors.borderSlate,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: selected ? 0.24 : 0.14),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? HomeSureColors.champagneHighlight
                      : HomeSureColors.champagneInk,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: selected
                  ? const Icon(
                      Icons.check_circle,
                      key: ValueKey<String>('selected'),
                      color: HomeSureColors.champagneGold,
                      size: 22,
                    )
                  : const Icon(
                      Icons.arrow_forward_ios,
                      key: ValueKey<String>('unselected'),
                      size: 16,
                      color: HomeSureColors.slateMuted,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
