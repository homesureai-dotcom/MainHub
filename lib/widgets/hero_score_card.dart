import 'package:flutter/material.dart';

import '../core/theme/homesure_tokens.dart';
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.circular(HomeSureRadius.xl),
        boxShadow: HomeSureShadows.cardElevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PROPERTY HEALTH SCORE',
                style: TextStyle(
                  color: Color(0xFFB8C7DC),
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(HomeSureRadius.pill),
                ),
                child: Text(
                  hasScore ? status : 'Due Diligence Pending',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: hasScore
                ? HealthScoreIndicator(
                    score: score!,
                    status: status,
                  )
                : const _NotAssessedState(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatusCard(
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF4ADE80),
                  value: verifiedCount,
                  label: 'Verified',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatusCard(
                  icon: Icons.schedule_rounded,
                  color: const Color(0xFFFBBF24),
                  value: pendingCount,
                  label: 'Pending',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatusCard(
                  icon: Icons.error_outline_rounded,
                  color: const Color(0xFFF87171),
                  value: issueCount,
                  label: 'Issues',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: HomeSureColors.primaryNavy,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(HomeSureRadius.md),
                ),
              ),
              onPressed: onPressed,
              icon: const Icon(Icons.description_outlined, size: 19),
              label: Text(
                hasScore
                    ? 'View Property Health Report'
                    : 'Start Property Health Assessment',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
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
      width: 164,
      height: 164,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.07),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.5,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shield_outlined,
            color: Color(0xFF8CE0D8),
            size: 36,
          ),
          SizedBox(height: 10),
          Text(
            'Not Assessed',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              'Complete your assessment',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFB8C7DC),
                fontSize: 11.5,
              ),
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
        vertical: 11,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(HomeSureRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 19,
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB8C7DC),
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
