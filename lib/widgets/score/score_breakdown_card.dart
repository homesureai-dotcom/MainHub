import 'package:flutter/material.dart';

class ScoreBreakdownCard extends StatelessWidget {
  final String title;
  final int score;

  const ScoreBreakdownCard({
    super.key,
    required this.title,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          "$score",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}