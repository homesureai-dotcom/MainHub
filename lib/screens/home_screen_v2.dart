import 'package:flutter/material.dart';

import '../data/phs_questions.dart';
import '../features/dashboard/coordinators/dashboard_data_coordinator.dart';
import '../features/dashboard/models/dashboard_data.dart';
import '../features/dashboard/models/dashboard_priority.dart';
import '../features/property/state/property_state.dart';
import '../features/surebot/builders/surebot_context_builder.dart';
import '../screens/assessment/assessment_screen.dart';
import '../screens/assessment/evidence_details_screen.dart';
import '../screens/assessment/property_health_result_screen.dart';
import '../screens/assessment/surebot_screen.dart';
import '../screens/dashboard/priority_detail_screen.dart';
import '../state/assessment_state.dart';

import '../widgets/dashboard/ai_insights_card.dart';
import '../widgets/dashboard/assessment_progress_card.dart';
import '../widgets/dashboard/evidence_snapshot_card.dart';
import '../widgets/dashboard/greeting_header.dart';
import '../widgets/dashboard/property_health_breakdown_card.dart';
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
  final PropertyState propertyState = PropertyState.instance;

  final AssessmentState assessmentState = AssessmentState.instance;

  final SureBotContextBuilder _sureBotContextBuilder =
      const SureBotContextBuilder();

  late final DashboardDataCoordinator _dashboardCoordinator;

  DashboardData? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _dashboardCoordinator = DashboardDataCoordinator(
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
    if (!mounted) {
      return;
    }

    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final data = await _dashboardCoordinator.build();

    if (!mounted) {
      return;
    }

    setState(() {
      _dashboardData = data;
      _isLoading = false;
    });
  }

  void _openEvidenceDetails() {
    final summary = _dashboardData?.evidenceSummary;

    if (summary == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EvidenceDetailsScreen(
          summary: summary,
        ),
      ),
    );
  }

  void _openAiAdvisor() {
    final data = _dashboardData;

    if (data == null) {
      return;
    }

    final DashboardPriority? currentPriority = data.priorities.isEmpty
        ? null
        : data.priorities.first;

    final sureBotContext = _sureBotContextBuilder.build(
      data,
      currentPriority: currentPriority,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SureBotScreen(
          sureBotContext: sureBotContext,
        ),
      ),
    );
  }

  void _openDocuments() {
    _openEvidenceDetails();
  }

  void _openCompliance() {
    final data = _dashboardData;
    final result = data?.healthResult;

    if (result == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PropertyHealthResultScreen(
          result: result,
          evidenceSummary: data?.evidenceSummary,
        ),
      ),
    );
  }

  void _openTimeline() {
    // Timeline screen is not implemented yet.
  }

  void _continueAssessment() {
    Navigator.of(
      context,
    ).push(
      MaterialPageRoute<void>(
        builder: (_) => const AssessmentScreen(),
      ),
    );
  }

  void _openPriorityDetail(DashboardPriority priority) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PriorityDetailScreen(
          priority: priority,
        ),
      ),
    );
  }

  Widget _buildAssessmentResumeCard() {
    final session = assessmentState.session;

    if (session == null || !assessmentState.hasActiveSession) {
      return const SizedBox.shrink();
    }

    final totalQuestions = phsQuestions.length;

    final answeredQuestions = assessmentState.answeredQuestionCount;

    final remainingQuestions = totalQuestions > answeredQuestions
        ? totalQuestions - answeredQuestions
        : 0;

    final completionPercentage = totalQuestions > 0
        ? (answeredQuestions / totalQuestions).clamp(0.0, 1.0)
        : 0.0;

    final percentage = (completionPercentage * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDBEAFE),
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assessment in progress',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Continue your Property Health Assessment',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$answeredQuestions of $totalQuestions questions',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: completionPercentage,
              minHeight: 9,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            remainingQuestions > 0
                ? '$remainingQuestions '
                      '${remainingQuestions == 1 ? 'question' : 'questions'} remaining'
                : 'Assessment ready to complete',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _continueAssessment,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continue Assessment'),
            ),
          ),
        ],
      ),
    );
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

    final score = data.healthScore?.round();

    final status = data.healthGrade;

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
                userName: 'Vinod',
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
                status: status ?? 'Not Assessed',
                verifiedCount: property.compliance.verifiedCount,
                pendingCount: property.compliance.pendingCount,
                issueCount: property.compliance.issueCount,
                onPressed: _openCompliance,
              ),
              if (data.healthResult != null) ...[
                const SizedBox(height: 24),
                PropertyHealthBreakdownCard(
                  result: data.healthResult!,
                ),
              ],
              const SizedBox(height: 24),
              _buildAssessmentResumeCard(),
              if (assessmentState.hasActiveSession)
                const SizedBox(height: 24),
              AssessmentProgressCard(
                completedQuestions: data.evaluatedQuestionCount,
                totalQuestions: data.totalQuestionCount,
                completionPercentage:
                    data.questionCompletionPercentage,
                completedCategories:
                    data.evaluatedCategoryCount,
                totalCategories:
                    data.totalCategoryCount,
              ),
              const SizedBox(height: 24),
              TodaysPrioritiesCard(
                data: data,
                onPriorityTap: _openPriorityDetail,
              ),
              const SizedBox(height: 24),
              EvidenceSnapshotCard(
                data: data,
                onViewDetails: _openEvidenceDetails,
              ),
              const SizedBox(height: 32),
              QuickActionGrid(
                onAiAdvisor: _openAiAdvisor,
                onDocuments: _openDocuments,
                onCompliance: _openCompliance,
                onTimeline: _openTimeline,
              ),
              const SizedBox(height: 32),
              const RecentAlertsCard(),
              const SizedBox(height: 32),
              AIInsightsCard(
                data: data,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
