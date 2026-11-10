import 'package:flutter/material.dart';

import '../core/theme/homesure_components.dart';
import '../core/theme/homesure_tokens.dart';
import '../data/phs_questions.dart';
import '../features/dashboard/coordinators/dashboard_data_coordinator.dart';
import '../features/dashboard/models/dashboard_data.dart';
import '../features/dashboard/models/dashboard_priority.dart';
import '../features/property/state/property_state.dart';
import '../features/property_submission/services/property_submission_service.dart';
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
import 'onboarding/property_search_screen.dart';

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
  bool _dashboardSessionRestoreAttempted = false;

  Future<void> _restoreDashboardSessionIfNeeded() async {
    if (_dashboardSessionRestoreAttempted) return;
    _dashboardSessionRestoreAttempted = true;

    if (assessmentState.hasActiveSession) return;

    try {
      final candidate = await assessmentState.loadLatestInProgressCandidate();

      if (!mounted || candidate == null) return;

      final submissionId = candidate.submissionId?.trim();
      if (submissionId != null && submissionId.isNotEmpty) {
        final approved = await PropertySubmissionService().isSubmissionApproved(
          submissionId,
        );

        if (!mounted || !approved) return;
      }

      await assessmentState.restoreInProgress(
        propertyId: candidate.propertyId,
        submissionId: candidate.submissionId,
      );
    } catch (error) {
      debugPrint('HOMESURE_DASHBOARD_RESTORE_ERROR: $error');
    }
  }

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
    await _restoreDashboardSessionIfNeeded();

    if (!mounted) return;

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
        builder: (_) => EvidenceDetailsScreen(summary: summary),
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
        builder: (_) => SureBotScreen(sureBotContext: sureBotContext),
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

  void _findProperty() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const PropertySearchScreen()),
    );
  }

  void _continueAssessment() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            AssessmentScreen(submissionId: assessmentState.submissionId),
      ),
    );
  }

  void _openPriorityDetail(DashboardPriority priority) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PriorityDetailScreen(priority: priority),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HomeSureColors.surfaceWhite,
        borderRadius: BorderRadius.circular(HomeSureRadius.lg),
        border: Border.all(color: HomeSureColors.accentTealBorder),
        boxShadow: HomeSureShadows.cardSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: HomeSureColors.accentTealTint,
                  borderRadius: BorderRadius.circular(HomeSureRadius.sm),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: HomeSureColors.accentTealDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assessment in progress',
                      style: HomeSureTypography.cardTitle,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Continue your Property Health Assessment',
                      style: HomeSureTypography.bodySecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$answeredQuestions of $totalQuestions questions',
                style: HomeSureTypography.bodyMedium,
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: HomeSureColors.accentTealDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(HomeSureRadius.pill),
            child: LinearProgressIndicator(
              value: completionPercentage,
              minHeight: 7,
              backgroundColor: HomeSureColors.surfaceSubtle,
              valueColor: const AlwaysStoppedAnimation<Color>(
                HomeSureColors.accentTeal,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            remainingQuestions > 0
                ? '$remainingQuestions '
                      '${remainingQuestions == 1 ? 'question' : 'questions'} remaining'
                : 'Assessment ready to complete',
            style: HomeSureTypography.caption,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _continueAssessment,
              icon: const Icon(Icons.arrow_forward, size: 18),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final data = _dashboardData;

    if (data == null) {
      return Scaffold(
        backgroundColor: HomeSureColors.backgroundWarm,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: HomeSureColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(HomeSureRadius.xl),
                      border: Border.all(color: HomeSureColors.borderDivider),
                      boxShadow: HomeSureShadows.cardSubtle,
                    ),
                    child: Column(
                      children: [
                        const HomeSureStatusBadge(
                          label: 'Bengaluru Property Due Diligence',
                          tone: HomeSureBadgeTone.teal,
                          icon: Icons.verified_user_outlined,
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: HomeSureColors.primaryNavyTint,
                            borderRadius: BorderRadius.circular(
                              HomeSureRadius.lg,
                            ),
                          ),
                          child: const Icon(
                            Icons.apartment_rounded,
                            size: 30,
                            color: HomeSureColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Let’s get your property started',
                          textAlign: TextAlign.center,
                          style: HomeSureTypography.screenTitle,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Know the project you have chosen. Understand what is behind it using official K-RERA disclosures and structured buyer evaluation.',
                          textAlign: TextAlign.center,
                          style: HomeSureTypography.bodySecondary,
                        ),
                        const SizedBox(height: 18),
                        const Row(
                          children: [
                            Expanded(
                              child: HomeSureMetricTile(
                                label: 'Canonical Builders',
                                value: '680',
                                sublabel: 'Bengaluru Registry',
                                icon: Icons.domain_rounded,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: HomeSureMetricTile(
                                label: 'K-RERA Projects',
                                value: '875',
                                sublabel: 'Official Records',
                                icon: Icons.fact_check_outlined,
                                accentColor: HomeSureColors.accentTealDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _findProperty,
                            icon: const Icon(Icons.search_rounded, size: 19),
                            label: const Text('Find a Property'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (assessmentState.hasActiveSession) ...[
                    const SizedBox(height: 16),
                    _buildAssessmentResumeCard(),
                    const SizedBox(height: 16),
                    AssessmentProgressCard(
                      completedQuestions: assessmentState
                          .assessmentProgress
                          .answeredQuestions,
                      totalQuestions:
                          assessmentState.assessmentProgress.totalQuestions,
                      completionPercentage: assessmentState
                          .assessmentProgress
                          .completionPercentage
                          .toDouble(),
                      completedCategories: assessmentState
                          .assessmentProgress
                          .completedCategoryCount,
                      totalCategories: assessmentState
                          .assessmentProgress
                          .totalCategoryCount,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    final property = data.property;
    final score = data.healthScore?.round();
    final status = data.healthGrade;

    return Scaffold(
      backgroundColor: HomeSureColors.backgroundWarm,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GreetingHeader(userName: 'Vinod'),
              const SizedBox(height: 18),
              PropertySelectorCard(
                propertyName: property.name,
                location: property.address.city,
                onTap: _findProperty,
              ),
              const SizedBox(height: 18),
              HeroScoreCard(
                score: score,
                status: status ?? 'Not Assessed',
                verifiedCount: property.compliance.verifiedCount,
                pendingCount: property.compliance.pendingCount,
                issueCount: property.compliance.issueCount,
                onPressed: _openCompliance,
              ),
              const SizedBox(height: 18),
              TodaysPrioritiesCard(
                data: data,
                onPriorityTap: _openPriorityDetail,
              ),
              const SizedBox(height: 18),
              _buildAssessmentResumeCard(),
              if (assessmentState.hasActiveSession) const SizedBox(height: 18),
              AssessmentProgressCard(
                completedQuestions: data.evaluatedQuestionCount,
                totalQuestions: data.totalQuestionCount,
                completionPercentage: data.questionCompletionPercentage,
                completedCategories: data.evaluatedCategoryCount,
                totalCategories: data.totalCategoryCount,
              ),
              if (data.healthResult != null) ...[
                const SizedBox(height: 18),
                PropertyHealthBreakdownCard(result: data.healthResult!),
              ],
              const SizedBox(height: 18),
              EvidenceSnapshotCard(
                data: data,
                onViewDetails: _openEvidenceDetails,
              ),
              const SizedBox(height: 22),
              QuickActionGrid(
                onAiAdvisor: _openAiAdvisor,
                onDocuments: _openDocuments,
                onCompliance: _openCompliance,
                onTimeline: _openTimeline,
              ),
              const SizedBox(height: 22),
              const RecentAlertsCard(),
              const SizedBox(height: 22),
              AIInsightsCard(data: data),
            ],
          ),
        ),
      ),
    );
  }
}
