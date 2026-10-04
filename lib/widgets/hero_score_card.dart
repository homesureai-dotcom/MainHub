import 'package:flutter/material.dart';

import '../theme/app_gradients.dart';
import 'common/health_score_indicator.dart';

class HeroScoreCard extends StatelessWidget {
  final int? score;
  final String status;
  final int verifiedCount;
  final int pendingCount;
  final int issueCount;
  final VoidCallback? onPressed;

  const HeroScoreCard({
    super.key,
    required this.score,
    required this.status,
    required this.verifiedCount,
    required this.pendingCount,
    required this.issueCount,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final hasScore = score != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROPERTY HEALTH SCORE',
            style: TextStyle(
              color: Colors.white70,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 24),

          Center(
            child: hasScore
                ? HealthScoreIndicator(
                    score: score!,
                    status: status,
                  )
                : const _NotAssessedState(),
          ),

          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: _StatusCard(
                  icon: Icons.check_circle,
                  color: Colors.greenAccent,
                  value: verifiedCount,
                  label: 'Verified',
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _StatusCard(
                  icon: Icons.schedule,
                  color: Colors.orangeAccent,
                  value: pendingCount,
                  label: 'Pending',
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _StatusCard(
                  icon: Icons.error_outline,
                  color: Colors.redAccent,
                  value: issueCount,
                  label: 'Issues',
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xff0F172A),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: onPressed,
              icon: const Icon(Icons.description_outlined),
              label: Text(
                hasScore
                    ? 'View Property Health Report'
                    : 'Start Property Health Assessment',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotAssessedState extends StatelessWidget {
  const _NotAssessedState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: .08),
        border: Border.all(
          color: Colors.white.withValues(alpha: .25),
          width: 2,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            color: Colors.white70,
            size: 42,
          ),
          SizedBox(height: 12),
          Text(
            'Not Assessed',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Complete your assessment',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String label;

  const _StatusCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 22,
          ),

          const SizedBox(height: 8),

          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}