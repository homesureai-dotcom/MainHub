import 'package:flutter/material.dart';

import '../features/dashboard/coordinators/dashboard_data_coordinator.dart';
import '../features/dashboard/models/dashboard_data.dart';
import '../features/property/state/property_state.dart';
import '../screens/assessment/evidence_details_screen.dart';
import '../screens/assessment/property_health_result_screen.dart';
import '../screens/assessment/surebot_screen.dart';
import '../state/assessment_state.dart';

import '../widgets/dashboard/ai_insights_card.dart';
import '../widgets/dashboard/assessment_progress_card.dart';
import '../widgets/dashboard/evidence_snapshot_card.dart';
import '../widgets/dashboard/greeting_header.dart';
import '../widgets/dashboard/property_selector_card.dart';
import '../widgets/dashboard/quick_action_grid.dart';
import '../widgets/dashboard/recent_alerts_card.dart';
import '../widgets/dashboard/todays_priorities_card.dart';
import '../widgets/hero_score_card.dart';

class HomeScreenV2 extends StatefulWidget {
  const HomeScreenV2({super.key});

  @override
  State<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends State<HomeScreenV2> {
  final PropertyState propertyState =
      PropertyState.instance;

  final AssessmentState assessmentState =
      AssessmentState.instance;

  late final DashboardDataCoordinator
      _dashboardCoordinator;

  DashboardData? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _dashboardCoordinator =
        DashboardDataCoordinator(
      propertyState: propertyState,
      assessmentState: assessmentState,
    );

    propertyState.addListener(_refresh);
    assessmentState.addListener(_refresh);

    _loadDashboardData();
  }

  @override
  void dispose() {
    propertyState.removeListener(_refresh);
    assessmentState.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;

    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final data =
        await _dashboardCoordinator.build();

    if (!mounted) return;

    setState(() {
      _dashboardData = data;
      _isLoading = false;
    });
  }

  void _openEvidenceDetails() {
    final summary =
        _dashboardData?.evidenceSummary;

    if (summary == null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            EvidenceDetailsScreen(
          summary: summary,
        ),
      ),
    );
  }

  void _openAiAdvisor() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const SureBotScreen(),
      ),
    );
  }

  void _openDocuments() {
    _openEvidenceDetails();
  }

  void _openCompliance() {
    final data = _dashboardData;
    final result = data?.healthResult;

    if (result == null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PropertyHealthResultScreen(
          result: result,
          evidenceSummary:
              data?.evidenceSummary,
        ),
      ),
    );
  }

  void _openTimeline() {
    // Timeline screen is not implemented yet.
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final data = _dashboardData;

    if (data == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No property selected.',
            style: TextStyle(
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    final property = data.property;
    final score =
        data.healthScore?.round();
    final status =
        data.healthGrade;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            32,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const GreetingHeader(
                userName: 'Vinod',
              ),
              const SizedBox(height: 24),
              PropertySelectorCard(
                propertyName:
                    property.name,
                location:
                    property.address.city,
                onTap: () {},
              ),
              const SizedBox(height: 28),
              HeroScoreCard(
                score: score,
                status:
                    status ?? 'Not Assessed',
                verifiedCount:
                    property.compliance
                        .verifiedCount,
                pendingCount:
                    property.compliance
                        .pendingCount,
                issueCount:
                    property.compliance
                        .issueCount,
                onPressed: () {},
              ),
              const SizedBox(height: 24),
              AssessmentProgressCard(
                completedQuestions:
                    data.evaluatedQuestionCount,
                totalQuestions:
                    data.totalQuestionCount,
                completionPercentage:
                    data.questionCompletionPercentage,
                completedCategories:
                    data.evaluatedCategoryCount,
                totalCategories:
                    data.totalCategoryCount,
              ),
              const SizedBox(height: 24),
              EvidenceSnapshotCard(
                data: data,
                onViewDetails:
                    _openEvidenceDetails,
              ),
              const SizedBox(height: 24),
              TodaysPrioritiesCard(
                data: data,
              ),
              const SizedBox(height: 32),
              QuickActionGrid(
                onAiAdvisor:
                    _openAiAdvisor,
                onDocuments:
                    _openDocuments,
                onCompliance:
                    _openCompliance,
                onTimeline:
                    _openTimeline,
              ),
              const SizedBox(height: 32),
              const RecentAlertsCard(),
              const SizedBox(height: 32),
              AIInsightsCard(
                data: data,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}