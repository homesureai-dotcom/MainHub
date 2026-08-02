import 'package:flutter/material.dart';

class ComplianceItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const ComplianceItem({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: color,
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}