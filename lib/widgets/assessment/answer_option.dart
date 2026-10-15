import 'package:flutter/material.dart';

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
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: selected ? 0.20 : 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: selected ? color.withValues(alpha: 0.95) : null,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: selected
                  ? Icon(
                      Icons.check_circle,
                      key: const ValueKey<String>('selected'),
                      color: color,
                      size: 22,
                    )
                  : const Icon(
                      Icons.arrow_forward_ios,
                      key: ValueKey<String>('unselected'),
                      size: 16,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
