import 'package:flutter/material.dart';

import '../core/app/app_state.dart';
import '../state/assessment_state.dart';

import '../widgets/dashboard/ai_insights_card.dart';
import '../widgets/dashboard/greeting_header.dart';
import '../widgets/dashboard/property_selector_card.dart';
import '../widgets/dashboard/quick_action_grid.dart';
import '../widgets/dashboard/recent_alerts_card.dart';
import '../widgets/hero_score_card.dart';

class HomeScreenV2 extends StatefulWidget {
  const HomeScreenV2({super.key});

  @override
  State<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends State<HomeScreenV2> {
  final AssessmentState assessmentState = AssessmentState.instance;

  @override
  void initState() {
    super.initState();
    assessmentState.addListener(_refresh);
  }

  @override
  void dispose() {
    assessmentState.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final property = AppState.instance.property.selectedProperty;

    if (property == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "No property selected.",
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    final latestResult = assessmentState.latestResult;

    final verified = property.compliance.verifiedCount;
    final pending = property.compliance.pendingCount;
    final issues = property.compliance.issueCount;

    final int score =
        latestResult?.overallScore.round() ??
        property.assessment.propertyHealthScore;

    final String status =
        latestResult?.grade ??
        property.assessment.grade;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GreetingHeader(
                userName: "Vinod",
              ),

              const SizedBox(height: 24),

              PropertySelectorCard(
                propertyName: property.name,
                location: property.address.city,
                onTap: () {},
              ),

              const SizedBox(height: 28),

              HeroScoreCard(
                score: score,
                status: status,
                verifiedCount: verified,
                pendingCount: pending,
                issueCount: issues,
                onPressed: () {
                  // Property Health Report screen
                },
              ),

              const SizedBox(height: 32),

              const QuickActionGrid(),

              const SizedBox(height: 32),

              const RecentAlertsCard(),

              const SizedBox(height: 32),

              const AIInsightsCard(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}