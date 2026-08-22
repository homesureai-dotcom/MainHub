import 'package:flutter/material.dart';

import '../../core/assessment/assessment_result.dart';
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
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
                color: Colors.green,
              ),

              const SizedBox(height: 16),

              const Text(
                "Assessment Complete",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Your Property Health Report is Ready",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                "We've evaluated your property across Legal, Construction, Utilities, Safety, Community and Documentation.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 36),

              const Text(
                "PROPERTY HEALTH INDEX™",
                style: TextStyle(
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Based on ${result.categoryResults.length} assessment categories",
                style: const TextStyle(
                  color: Colors.grey,
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

              const SizedBox(height: 30),

              Card(
                elevation: 0,
                color: Colors.green.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [

                      const Icon(
                        Icons.auto_awesome,
                        color: Colors.green,
                        size: 34,
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        "Great News!",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        result.summary,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          height: 1.6,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
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