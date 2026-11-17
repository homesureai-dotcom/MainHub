import 'package:flutter/material.dart';

import '../../core/evidence/assessment_evidence_management_service.dart';
import '../../core/evidence/composite_evidence_capture_service.dart';
import '../../core/evidence/evidence.dart';
import '../../core/evidence/evidence_capture_coordinator.dart';
import '../../core/evidence/evidence_capture_service.dart';
import '../../core/evidence/evidence_requirement_catalog.dart';
import '../../core/evidence/evidence_requirement_resolver.dart';
import '../../core/evidence/evidence_type_mapper.dart';
import '../../core/evidence/evidence_validator.dart';
import '../../core/evidence/file_picker_evidence_capture_service.dart';
import '../../core/evidence/file_picker_gateway.dart';
import '../../core/evidence/image_picker_evidence_capture_service.dart';
import '../../core/evidence/image_picker_gateway.dart';
import '../../core/evidence/question_evidence_coordinator.dart';
import '../../core/evidence/video_capture_service.dart';
import '../../core/localization/app_locale_controller.dart';
import '../../core/phs/phs_answer.dart';
import '../../core/phs/phs_categories.dart';
import '../../core/phs/phs_question.dart';
import '../../core/theme/homesure_tokens.dart';
import '../../data/phs_questions.dart';
import '../../features/assessment/localization/assessment_translations.dart';
import '../../features/property/state/property_state.dart';
import '../../features/property_submission/services/property_submission_service.dart';
import '../../models/property_health/category_score.dart';
import '../../models/property_health/score_calculator.dart';
import '../../state/assessment_state.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/assessment/question_card.dart';
import '../onboarding/property_search_screen.dart';
import 'analyzing_screen.dart';

class AssessmentScreen extends StatefulWidget {
  final EvidenceCaptureService? evidenceCaptureService;
  final String? submissionId;
  final PropertySubmissionApprovalGateway? approvalGateway;
  final bool embeddedInTab;
  final VoidCallback? onSelectProperty;

  const AssessmentScreen({
    super.key,
    this.evidenceCaptureService,
    this.submissionId,
    this.approvalGateway,
    this.embeddedInTab = false,
    this.onSelectProperty,
  });

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final AssessmentState assessmentState = AssessmentState.instance;
  final PropertyState propertyState = PropertyState.instance;
  final ScoreCalculator _scoreCalculator = ScoreCalculator();
  final ScrollController _scrollController = ScrollController();

  late final QuestionEvidenceCoordinator _evidenceCoordinator;
  late final AssessmentEvidenceManagementService _evidenceManagementService;
  late final EvidenceCaptureCoordinator _evidenceCaptureCoordinator;

  PHSCategory _activeCategory = PHSCategory.legalOwnership;
  Map<String, List<Evidence>> _evidenceByQuestionId = {};
  final Set<String> _expandedEvidenceQuestionIds = {};

  bool _isAnswering = false;
  bool _approvalCheckComplete = true;
  bool _approvalDenied = false;
  bool _approvalCheckFailed = false;

  List<CategoryScore> get _categoryScores =>
      _scoreCalculator.calculate(assessmentState.answers);

  double get _overallScore =>
      _scoreCalculator.calculateOverallScore(_categoryScores);

  double get _assessmentCoverage =>
      _scoreCalculator.calculateAssessmentCoverage(assessmentState.answers);

  List<PHSQuestion> _questionsForCategory(PHSCategory category) {
    return phsQuestions
        .where((question) => question.category == category)
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();

    _seedInitialExpandedQuestion(_activeCategory);
    assessmentState.addListener(_onAssessmentStateChanged);
    propertyState.addListener(_onPropertyStateChanged);
    _initializeEvidenceCoordinator();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final id = widget.submissionId?.trim();
      if (id == null || id.isEmpty) {
        _initializeAssessment();
      } else {
        _verifySubmissionApproval(id);
      }
    });
  }

  void _seedInitialExpandedQuestion(PHSCategory category) {
    final questions = _questionsForCategory(category);
    if (questions.isNotEmpty) {
      _expandedEvidenceQuestionIds
        ..clear()
        ..add(questions.first.id);
    }
  }

  void _onAssessmentStateChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onPropertyStateChanged() {
    if (!mounted) return;
    setState(() {});
    if (propertyState.selectedProperty != null) {
      _loadPillarEvidence();
    }
  }

  @override
  void dispose() {
    assessmentState.removeListener(_onAssessmentStateChanged);
    propertyState.removeListener(_onPropertyStateChanged);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _verifySubmissionApproval(String submissionId) async {
    if (mounted) {
      setState(() {
        _approvalCheckComplete = false;
        _approvalDenied = false;
        _approvalCheckFailed = false;
      });
    }

    try {
      final checker = widget.approvalGateway ?? PropertySubmissionService();
      final approved = await checker.isSubmissionApproved(submissionId);

      if (!mounted) return;

      setState(() {
        _approvalCheckComplete = true;
        _approvalDenied = !approved;
        _approvalCheckFailed = false;
      });

      if (approved) {
        await _initializeAssessment();
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _approvalCheckComplete = true;
        _approvalDenied = true;
        _approvalCheckFailed = true;
      });
    }
  }

  void _ensureActiveSession() {
    if (assessmentState.hasActiveSession) {
      return;
    }

    final submissionId = widget.submissionId?.trim();
    assessmentState.startAssessment(
      propertyId: propertyState.selectedProperty?.id,
      submissionId:
          submissionId == null || submissionId.isEmpty ? null : submissionId,
    );
  }

  Future<void> _initializeAssessment() async {
    final propertyId = propertyState.selectedProperty?.id;
    final submissionId = widget.submissionId?.trim();

    try {
      final restored = await assessmentState.restoreInProgress(
        propertyId: propertyId,
        submissionId: submissionId == null || submissionId.isEmpty
            ? null
            : submissionId,
      );

      if (!mounted) return;

      if (!restored && !widget.embeddedInTab) {
        _ensureActiveSession();
      }

      _restoreCurrentPillar();
      await _loadPillarEvidence();
    } catch (error, stackTrace) {
      debugPrint('HOMESURE_ASSESSMENT_RESTORE_ERROR: $error');
      debugPrintStack(
        label: 'HOMESURE_ASSESSMENT_RESTORE_STACK',
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not restore saved progress. Check the debug log for details.',
          ),
        ),
      );
    }
  }

  void _restoreCurrentPillar() {
    if (phsQuestions.isEmpty) {
      return;
    }

    final savedQuestionId = assessmentState.currentQuestionId;
    var restoredIndex = savedQuestionId == null
        ? -1
        : phsQuestions.indexWhere((q) => q.id == savedQuestionId);

    if (restoredIndex < 0) {
      final answers = assessmentState.answers;
      if (answers.isEmpty) {
        restoredIndex = 0;
      } else {
        final answeredIds = answers.map((a) => a.questionId).toSet();
        restoredIndex = phsQuestions.indexWhere(
          (q) => !answeredIds.contains(q.id),
        );
        if (restoredIndex < 0) {
          restoredIndex = phsQuestions.length - 1;
        }
      }
    }

    final restoredQuestion = phsQuestions[restoredIndex];

    setState(() {
      _activeCategory = restoredQuestion.category;
      _seedInitialExpandedQuestion(_activeCategory);
      _isAnswering = false;
    });

    if (assessmentState.currentQuestionId != restoredQuestion.id) {
      assessmentState.updateCurrentQuestion(restoredQuestion.id);
    }
  }

  PHSResponse? _savedResponseForQuestion(String questionId) {
    for (final answer in assessmentState.answers) {
      if (answer.questionId == questionId) {
        return answer.response;
      }
    }
    return null;
  }

  void _initializeEvidenceCoordinator() {
    const typeMapper = EvidenceTypeMapper();
    const resolver = EvidenceRequirementResolver(typeMapper: typeMapper);
    const catalog = EvidenceRequirementCatalog(resolver: resolver);
    final validator = EvidenceValidator();

    _evidenceCoordinator = QuestionEvidenceCoordinator(
      repository: assessmentState.evidenceRepository,
      validator: validator,
    );

    _evidenceManagementService = AssessmentEvidenceManagementService(
      repository: assessmentState.evidenceRepository,
    );

    final captureService =
        widget.evidenceCaptureService ??
        CompositeEvidenceCaptureService(
          documentCaptureService: FilePickerEvidenceCaptureService(
            filePicker: const PlatformFilePickerGateway(),
          ),
          photographCaptureService: ImagePickerEvidenceCaptureService(
            imagePicker: PlatformImagePickerGateway(),
          ),
          videoCaptureService: VideoCaptureService(
            imagePicker: PlatformImagePickerGateway(),
          ),
        );

    _evidenceCaptureCoordinator = EvidenceCaptureCoordinator(
      captureService: captureService,
      repository: assessmentState.evidenceRepository,
    );

    if (phsQuestions.isNotEmpty) {
      catalog.getForQuestion(phsQuestions.first);
    }
  }

  Future<void> _loadPillarEvidence() async {
    final questions = _questionsForCategory(_activeCategory);
    final nextMap = <String, List<Evidence>>{};

    for (final q in questions) {
      nextMap[q.id] = await _evidenceCoordinator.loadEvidence(q.id);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _evidenceByQuestionId = nextMap;
    });
  }

  Future<void> handleEvidenceTypeSelectedForQuestion(
    PHSQuestion question,
    EvidenceType type,
  ) async {
    _ensureActiveSession();
    _expandedEvidenceQuestionIds.add(question.id);

    if (type == EvidenceType.document ||
        type == EvidenceType.photograph ||
        type == EvidenceType.video) {
      await _captureEvidenceForQuestion(question, type);
      return;
    }

    await _createPendingEvidenceForQuestion(question, type);
  }

  Future<void> _captureEvidenceForQuestion(
    PHSQuestion question,
    EvidenceType type,
  ) async {
    final label = switch (type) {
      EvidenceType.document => 'Document',
      EvidenceType.photograph => 'Photograph',
      EvidenceType.video => 'Video',
      EvidenceType.manual => 'Manual Entry',
    };

    final request = switch (type) {
      EvidenceType.document => const EvidenceCaptureRequest.document(),
      EvidenceType.photograph => const EvidenceCaptureRequest.photograph(),
      EvidenceType.video => const EvidenceCaptureRequest.video(),
      EvidenceType.manual => const EvidenceCaptureRequest.manual(),
    };

    try {
      final evidence = await _evidenceCaptureCoordinator.captureEvidence(
        id: 'EVIDENCE_${DateTime.now().microsecondsSinceEpoch}',
        questionId: question.id,
        type: type,
        name: '$label evidence',
        request: request,
        source: EvidenceSource.userUpload,
        addedAt: DateTime.now(),
      );

      if (evidence == null) {
        return;
      }

      await _loadPillarEvidence();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label evidence added successfully.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } on UnsupportedError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? '$label capture is unavailable.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _createPendingEvidenceForQuestion(
    PHSQuestion question,
    EvidenceType type,
  ) async {
    final label = switch (type) {
      EvidenceType.document => 'Document',
      EvidenceType.photograph => 'Photograph',
      EvidenceType.video => 'Video',
      EvidenceType.manual => 'Manual Entry',
    };

    final evidence = Evidence(
      id: 'EVIDENCE_${DateTime.now().microsecondsSinceEpoch}',
      questionId: question.id,
      type: type,
      name: '$label evidence pending capture',
      description:
          'Evidence entry created from the assessment evidence action.',
      status: EvidenceStatus.notProvided,
      source: EvidenceSource.userEntry,
      addedAt: DateTime.now(),
    );

    await _evidenceCoordinator.addEvidence(evidence);
    await _loadPillarEvidence();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label evidence entry added. Capture can be completed here.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleEvidenceStatusChange(Evidence updatedEvidence) async {
    try {
      await _evidenceManagementService.updateEvidence(updatedEvidence);
      await _loadPillarEvidence();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evidence status updated.'),
          duration: Duration(seconds: 2),
        ),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleEvidenceDelete(Evidence evidence) async {
    try {
      final deleted = await _evidenceManagementService.deleteEvidence(
        evidence.id,
      );

      if (!deleted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evidence could not be found.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      await _loadPillarEvidence();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evidence deleted.'),
          duration: Duration(seconds: 2),
        ),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _selectPillar(PHSCategory category, {bool scrollToTop = false}) {
    final questions = _questionsForCategory(category);
    setState(() {
      _activeCategory = category;
      _seedInitialExpandedQuestion(category);
      _isAnswering = false;
    });

    if (questions.isNotEmpty) {
      assessmentState.updateCurrentQuestion(questions.first.id);
    }
    _loadPillarEvidence();

    if (scrollToTop && _scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _goToNextPillar() {
    const categories = PHSCategory.values;
    final currentIndex = categories.indexOf(_activeCategory);
    final nextCategory = categories[(currentIndex + 1) % categories.length];
    _selectPillar(nextCategory, scrollToTop: true);
  }

  void _toggleEvidenceExpanded(String questionId) {
    setState(() {
      if (!_expandedEvidenceQuestionIds.add(questionId)) {
        _expandedEvidenceQuestionIds.remove(questionId);
      }
    });
  }

  void _saveAnswerForQuestion(PHSQuestion question, PHSResponse response) {
    _ensureActiveSession();

    assessmentState.saveAnswer(
      PHSAnswer(questionId: question.id, response: response),
      currentQuestionId: question.id,
    );

    if (!mounted) return;

    setState(() {
      if (response == PHSResponse.yes) {
        _expandedEvidenceQuestionIds.add(question.id);
      }
      _isAnswering = false;
    });
  }

  void _clearAnswer(PHSQuestion question) {
    assessmentState.clearAnswer(
      question.id,
      currentQuestionId: question.id,
    );
    if (!mounted) return;
    setState(() {
      _isAnswering = false;
    });
  }

  void _completeAssessment() {
    _ensureActiveSession();
    final pillarQuestions = _questionsForCategory(_activeCategory);
    if (pillarQuestions.isNotEmpty) {
      assessmentState.updateCurrentQuestion(pillarQuestions.last.id);
    }
    assessmentState.completeAssessment();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AnalyzingScreen()),
    );
  }

  Future<void> _saveAndExit() async {
    if (_isAnswering) return;

    final pillarQuestions = _questionsForCategory(_activeCategory);
    if (assessmentState.currentQuestionId == null && pillarQuestions.isNotEmpty) {
      assessmentState.updateCurrentQuestion(pillarQuestions.first.id);
    }

    assessmentState.saveAndExit();

    try {
      await assessmentState.flushPersistence();

      if (!mounted) return;

      if (assessmentState.persistenceError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save your progress. Please check your connection and try again.',
            ),
          ),
        );
        return;
      }

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your progress. Please try again.'),
        ),
      );
    }
  }

  Widget _buildGradientProgressBar(double ratio) {
    final clamped = ratio.clamp(0.0, 1.0);
    return Container(
      height: 7,
      decoration: BoxDecoration(
        color: HomeSureColors.midnightSelected,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: clamped,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [
                  HomeSureColors.champagneGold,
                  HomeSureColors.champagneHighlight,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHealthPhiBanner(int liveScore, bool hasScore) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: HomeSureColors.champagneGold.withAlpha(87),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PROPERTY HEALTH INDEX',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: HomeSureColors.slateMuted,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$liveScore',
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: HomeSureColors.champagneInk,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Text(
                    '/100',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: HomeSureColors.champagneHighlight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hasScore
                      ? 'Based on your assessment responses'
                      : 'Select a response to calculate PHI',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: HomeSureColors.champagneHighlight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarStrip() {
    final translations = AssessmentTranslations(
      AppLocaleController.instance.languageCode,
    );
    final progress = assessmentState.assessmentProgress;

    return SizedBox(
      height: 106,
      child: SingleChildScrollView(
        key: const ValueKey<String>('assessment-pillars-strip'),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < PHSCategory.values.length; index++) ...[
              if (index > 0) const SizedBox(width: 8),
              Builder(
                builder: (context) {
                  final category = PHSCategory.values[index];
                  final isSelected = category == _activeCategory;
                  final catProgress = progress.progressFor(category);
                  final answered = catProgress?.answeredQuestions ?? 0;
                  final total = catProgress?.totalQuestions ?? 0;
                  final fraction = total == 0 ? 0.0 : answered / total;

                  return InkWell(
                    key: ValueKey<String>('assessment-pillar-${category.name}'),
                    borderRadius: BorderRadius.circular(14),
                    onTap: _isAnswering ? null : () => _selectPillar(category),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 158,
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? HomeSureColors.midnightSelected
                            : HomeSureColors.midnightCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? HomeSureColors.champagneGold
                              : HomeSureColors.borderSlate,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            translations.categoryName(category),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: HomeSureColors.champagneInk,
                              height: 1.2,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$answered/$total answered',
                            style: const TextStyle(
                              fontSize: 11,
                              color: HomeSureColors.slateMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildGradientProgressBar(fraction),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivePillarCard(List<PHSQuestion> pillarQuestions) {
    final translations = AssessmentTranslations(
      AppLocaleController.instance.languageCode,
    );
    final progress = assessmentState.assessmentProgress;
    final catProgress = progress.progressFor(_activeCategory);
    final answered = catProgress?.answeredQuestions ?? 0;
    final total = pillarQuestions.length;
    final ratio = total == 0 ? 0.0 : answered / total;

    CategoryScore? pillarScore;
    for (final s in _categoryScores) {
      if (s.category == _activeCategory) {
        pillarScore = s;
        break;
      }
    }
    final scoreValue =
        pillarScore != null && pillarScore.maxScore > 0
            ? pillarScore.score.round()
            : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HomeSureColors.midnightCard,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: HomeSureColors.borderSlate),
        boxShadow: HomeSureShadows.cardSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ACTIVE ASSESSMENT PILLAR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: HomeSureColors.slateMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            translations.categoryName(_activeCategory),
            key: const ValueKey<String>('active-pillar-title'),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: HomeSureColors.champagneInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _activeCategory.description,
            style: const TextStyle(
              fontSize: 12,
              color: HomeSureColors.slateMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$answered of $total answered',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: HomeSureColors.champagneInk,
                ),
              ),
              Text(
                '$scoreValue / 100',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: HomeSureColors.champagneHighlight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          _buildGradientProgressBar(ratio),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final submissionId = widget.submissionId?.trim();
    final isSubmittedProperty = submissionId != null && submissionId.isNotEmpty;

    if (isSubmittedProperty && !_approvalCheckComplete) {
      return Scaffold(
        appBar: AppBar(title: const Text('Property Assessment')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Verifying property approval...'),
            ],
          ),
        ),
      );
    }

    if (isSubmittedProperty && _approvalDenied) {
      final message = _approvalCheckFailed
          ? 'We could not verify this property’s approval. '
              'Please check your connection and try again later.'
          : 'This property has not been approved for assessment yet. '
              'Please check My Property Requests for its status.';

      return Scaffold(
        appBar: AppBar(title: const Text('Property Assessment')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 16),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    final hasPropertyContext =
        propertyState.selectedProperty != null || isSubmittedProperty;
    if (widget.embeddedInTab && !hasPropertyContext) {
      return Scaffold(
        backgroundColor: HomeSureColors.midnightBg,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Property Assessment'),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 104),
              child: Container(
                key: const ValueKey<String>('assessment-no-property-selected'),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: HomeSureColors.midnightCard,
                  borderRadius: BorderRadius.circular(HomeSureRadius.lg),
                  border: Border.all(color: HomeSureColors.borderSlate),
                  boxShadow: HomeSureShadows.cardSubtle,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: HomeSureColors.midnightInteractive,
                        borderRadius: BorderRadius.circular(HomeSureRadius.md),
                        border: Border.all(
                          color: HomeSureColors.champagneBronze,
                        ),
                      ),
                      child: const Icon(
                        Icons.apartment_rounded,
                        size: 28,
                        color: HomeSureColors.champagneHighlight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select a Property First',
                      style: HomeSureTypography.sectionTitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please select a property from the catalogue so you can start your Property Health Assessment and view the assessment questions.',
                      textAlign: TextAlign.center,
                      style: HomeSureTypography.bodySecondary,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const ValueKey<String>(
                          'assessment-select-property-btn',
                        ),
                        onPressed: widget.onSelectProperty ??
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const PropertySearchScreen(),
                                ),
                              );
                            },
                        icon: const Icon(Icons.search_rounded, size: 18),
                        label: const Text('Select a Property'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final hasScore = _assessmentCoverage > 0;
    final liveScore = hasScore ? _overallScore.round() : 0;
    final pillarQuestions = _questionsForCategory(_activeCategory);
    final isLastPillar = _activeCategory == PHSCategory.values.last;
    final showCompleteButton =
        isLastPillar || assessmentState.answeredQuestionCount > 0;

    return Scaffold(
      backgroundColor: HomeSureColors.midnightBg,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embeddedInTab,
        title: const Text(
          'Property Assessment',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (!widget.embeddedInTab)
            TextButton(
              onPressed: _isAnswering ? null : _saveAndExit,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Save & Exit'),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                key: const ValueKey<String>('assessment-phi-top-right'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: HomeSureColors.midnightCard,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: HomeSureColors.champagneGold,
                    width: 1.4,
                  ),
                ),
                child: Text(
                  '$liveScore out of 100',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: HomeSureColors.champagneHighlight,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            widget.embeddedInTab ? 104 : 28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHealthPhiBanner(liveScore, hasScore),
              const SizedBox(height: 12),
              const Text(
                'Select a pillar and answer each question.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: HomeSureColors.slateMuted,
                ),
              ),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Assessment pillars',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: HomeSureColors.champagneHighlight,
                    ),
                  ),
                  Text(
                    'Swipe right to explore →',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: HomeSureColors.champagneHighlight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildPillarStrip(),
              const SizedBox(height: 12),
              _buildActivePillarCard(pillarQuestions),
              const SizedBox(height: 12),
              for (var i = 0; i < pillarQuestions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: QuestionCard(
                    key: ValueKey<String>(
                      'assessment-qcard-${pillarQuestions[i].id}',
                    ),
                    question: pillarQuestions[i],
                    questionNumber: i + 1,
                    totalPillarQuestions: pillarQuestions.length,
                    selectedResponse: _savedResponseForQuestion(
                      pillarQuestions[i].id,
                    ),
                    onResponseSelected: _isAnswering
                        ? null
                        : (response) => _saveAnswerForQuestion(
                              pillarQuestions[i],
                              response,
                            ),
                    onClearResponse: () => _clearAnswer(pillarQuestions[i]),
                    collapsibleEvidence: true,
                    evidenceExpanded: _expandedEvidenceQuestionIds.contains(
                      pillarQuestions[i].id,
                    ),
                    onToggleEvidenceExpanded: () =>
                        _toggleEvidenceExpanded(pillarQuestions[i].id),
                    suppliedEvidence:
                        _evidenceByQuestionId[pillarQuestions[i].id] ??
                            const [],
                    onEvidenceTypeSelected: (type) =>
                        handleEvidenceTypeSelectedForQuestion(
                          pillarQuestions[i],
                          type,
                        ),
                    onEvidenceStatusChange: _handleEvidenceStatusChange,
                    onEvidenceDelete: _handleEvidenceDelete,
                  ),
                ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey<String>('assessment-next-pillar-btn'),
                  onPressed: _isAnswering ? null : _goToNextPillar,
                  child: const Text('Next pillar →'),
                ),
              ),
              if (showCompleteButton) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const ValueKey<String>('assessment-complete-btn'),
                    onPressed: _isAnswering ? null : _completeAssessment,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Complete assessment'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
