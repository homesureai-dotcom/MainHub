import 'package:flutter/material.dart';

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

  Color get color {
    switch (status) {
      case StatusType.success:
        return Colors.green;

      case StatusType.warning:
        return Colors.orange;

      case StatusType.danger:
        return Colors.red;

      case StatusType.info:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}