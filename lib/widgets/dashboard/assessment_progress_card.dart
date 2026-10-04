import 'package:flutter/material.dart';

class AssessmentProgressCard extends StatelessWidget {
  final int completedQuestions;
  final int totalQuestions;
  final double completionPercentage;
  final int completedCategories;
  final int totalCategories;

  const AssessmentProgressCard({
    super.key,
    required this.completedQuestions,
    required this.totalQuestions,
    required this.completionPercentage,
    required this.completedCategories,
    required this.totalCategories,
  });

  @override
  Widget build(BuildContext context) {
    final hasStarted = completedQuestions > 0;
    final progress = completionPercentage.clamp(0.0, 100.0) / 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: Color(0xFF2563EB),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Assessment Progress',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (!hasStarted) ...[
            const Text(
              'Your property health assessment has not started yet.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$completedQuestions',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 4,
                    bottom: 4,
                  ),
                  child: Text(
                    'of $totalQuestions questions',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${completionPercentage.round()}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: const Color(0xFFE2E8F0),
              ),
            ),

            const SizedBox(height: 14),

            Text(
              '$completedCategories of $totalCategories categories started',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }
}