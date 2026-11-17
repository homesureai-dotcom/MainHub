import 'package:flutter/material.dart';

import '../../core/assessment/assessment_result.dart';
import '../../core/theme/homesure_tokens.dart';
import '../../state/assessment_state.dart';

import '../../widgets/common/app_button.dart';
import '../../widgets/score/score_badge.dart';
import '../../widgets/score/score_breakdown_card.dart';
import '../../widgets/score/score_circle.dart';

import '../../features/report/screens/property_health_report_screen.dart';

import '../home_screen_v2.dart';
import '../../core/phs/phs_categories.dart';

class ScoreRevealScreen extends StatelessWidget {
  const ScoreRevealScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AssessmentResult? result =
        AssessmentState.instance.latestResult;

    if (result == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "No assessment result found.",
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: HomeSureColors.midnightBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 10),
              const Icon(
                Icons.verified_rounded,
                size: 64,
                color: HomeSureColors.statusPositiveText,
              ),
              const SizedBox(height: 16),
              const Text(
                'Assessment Complete',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: HomeSureColors.champagneInk,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your Property Health Report is Ready',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: HomeSureColors.champagneHighlight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "We've evaluated your property across Legal, Construction, Utilities, Safety, Community and Documentation.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.55,
                  color: HomeSureColors.slateMuted,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'PROPERTY HEALTH INDEX™',
                style: TextStyle(
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: HomeSureColors.champagneHighlight,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Based on ${result.categoryResults.length} assessment categories',
                style: const TextStyle(
                  color: HomeSureColors.slateMuted,
                ),
              ),
              const SizedBox(height: 24),
              ScoreCircle(
                score: result.overallScore.round(),
              ),
              const SizedBox(height: 24),
              ScoreBadge(
                score: result.overallScore.round(),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: HomeSureColors.midnightCard,
                  borderRadius: BorderRadius.circular(HomeSureRadius.lg),
                  border: Border.all(color: HomeSureColors.champagneBronze),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: HomeSureColors.champagneHighlight,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Great News!',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: HomeSureColors.champagneInk,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      result.summary,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        height: 1.55,
                        fontSize: 15,
                        color: HomeSureColors.slateDetailBody,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Category Breakdown",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              const SizedBox(height: 16),

              ...result.categoryResults.map(
                (category) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ScoreBreakdownCard(
                    title: category.category.displayName,
                    score: category.percentage.round(),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: "View Full Property Health Report",
                  icon: Icons.description,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const PropertyHealthReportScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: "Go to Dashboard",
                  icon: Icons.dashboard,
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const HomeScreenV2(),
                      ),
                      (route) => false,
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}