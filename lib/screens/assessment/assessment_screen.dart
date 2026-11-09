import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

import '../../widgets/assessment/classic_category_accordion.dart';

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

import '../../core/phs/phs_answer.dart';

import '../../core/phs/phs_categories.dart';

import '../../core/phs/phs_category_question_resolver.dart';

import '../../core/phs/phs_question_progress.dart';

import '../../core/phs/phs_question_progress_resolver.dart';

import '../../data/phs_questions.dart';

import '../../core/phs/phs_question.dart';

import '../../features/property/state/property_state.dart';

import '../../features/property_submission/services/property_submission_service.dart';

import '../../models/property_health/category_score.dart';

import '../../models/property_health/score_calculator.dart';

import '../../state/assessment_state.dart';

import '../../widgets/assessment/assessment_progress.dart';

import '../../widgets/assessment/current_question_progress.dart';

import '../../widgets/assessment/premium_assessment_view.dart';

import '../../widgets/assessment/question_card.dart';

import '../../widgets/property_health/score_heatmap_legend.dart';

import 'analyzing_screen.dart';

class AssessmentScreen extends StatefulWidget {
  final EvidenceCaptureService? evidenceCaptureService;

  final String? submissionId;

  final PropertySubmissionApprovalGateway? approvalGateway;

  const AssessmentScreen({
    super.key,

    this.evidenceCaptureService,

    this.submissionId,

    this.approvalGateway,
  });

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  int currentQuestion = 0;
  late final PageController _questionPageController = PageController();

  final AssessmentState assessmentState = AssessmentState.instance;

  final PropertyState propertyState = PropertyState.instance;

  final PHSCategoryQuestionResolver _categoryQuestionResolver =
      const PHSCategoryQuestionResolver();

  final PHSQuestionProgressResolver _questionProgressResolver =
      const PHSQuestionProgressResolver();

  final ScoreCalculator _scoreCalculator = ScoreCalculator();

  late final QuestionEvidenceCoordinator _evidenceCoordinator;

  late final AssessmentEvidenceManagementService _evidenceManagementService;

  late final EvidenceCaptureCoordinator _evidenceCaptureCoordinator;

  List<Evidence> _currentQuestionEvidence = const [];

  PHSResponse? _selectedResponse;

  bool _isAnswering = false;

  bool _premiumView = false;

  // Catalogue properties retain the existing flow. Submitted properties// must pass a fresh approval check before an assessment can start.*

  bool _approvalCheckComplete = true;

  bool _approvalDenied = false;

  bool _approvalCheckFailed = false;

  PHSCategory? _selectedPremiumCategory;

  PHSQuestionProgress? get _currentQuestionProgress =>
      _questionProgressResolver.resolve(
        questionId: phsQuestions[currentQuestion].id,

        questions: phsQuestions,

        answeredQuestionIds: assessmentState.answers
            .map((answer) => answer.questionId)
            .toSet(),
      );

  List<CategoryScore> get _categoryScores =>
      _scoreCalculator.calculate(assessmentState.answers);

  double get _overallScore =>
      _scoreCalculator.calculateOverallScore(_categoryScores);

  double get _assessmentCoverage =>
      _scoreCalculator.calculateAssessmentCoverage(assessmentState.answers);

  @override
  void initState() {
    super.initState();

    _initializeEvidenceCoordinator();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final id = widget.submissionId?.trim();

      if (id == null || id.isEmpty) {
        // Existing catalogue/dashboard assessment flow.*

        _initializeAssessment();
      } else {
        // Do not initialize the assessment until approval is confirmed.*

        _verifySubmissionApproval(id);
      }
    });
  }

  @override
  void dispose() {
    _questionPageController.dispose();
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
        _initializeAssessment();
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

      if (!restored) {
        assessmentState.startAssessment(
          propertyId: propertyId,

          submissionId: submissionId == null || submissionId.isEmpty
              ? null
              : submissionId,
        );
      }

      _restoreCurrentQuestion();

      _loadCurrentQuestionEvidence();
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

  void _restoreCurrentQuestion() {
    if (phsQuestions.isEmpty) {
      return;
    }

    final savedQuestionId = assessmentState.currentQuestionId;

    var restoredIndex = savedQuestionId == null
        ? -1
        : phsQuestions.indexWhere((question) => question.id == savedQuestionId);

    if (restoredIndex < 0) {
      final answers = assessmentState.answers;

      if (answers.isEmpty) {
        restoredIndex = 0;
      } else {
        final answeredQuestionIds = answers
            .map((answer) => answer.questionId)
            .toSet();

        restoredIndex = phsQuestions.indexWhere(
          (question) => !answeredQuestionIds.contains(question.id),
        );

        if (restoredIndex < 0) {
          restoredIndex = phsQuestions.length - 1;
        }
      }
    }

    setState(() {
      currentQuestion = restoredIndex;
      _selectedResponse = null;
      _isAnswering = false;
    });

    final restoredQuestionId = phsQuestions[restoredIndex].id;

    // Keep the persisted session aligned with the question shown on screen.
    if (assessmentState.currentQuestionId != restoredQuestionId) {
      assessmentState.updateCurrentQuestion(restoredQuestionId);
    }
  }

  PHSResponse? _savedResponseForQuestion(String questionId) {
    PHSResponse? response;

    for (final answer in assessmentState.answers) {
      if (answer.questionId == questionId) {
        response = answer.response;
      }
    }

    return response;
  }

  void _initializeEvidenceCoordinator() {
    final typeMapper = const EvidenceTypeMapper();

    final resolver = EvidenceRequirementResolver(typeMapper: typeMapper);

    final catalog = EvidenceRequirementCatalog(resolver: resolver);

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

    catalog.getForQuestion(phsQuestions[currentQuestion]);
  }

  Future<void> _loadCurrentQuestionEvidence() async {
    final question = phsQuestions[currentQuestion];

    final evidence = await _evidenceCoordinator.loadEvidence(question.id);

    if (!mounted) {
      return;
    }

    setState(() {
      _currentQuestionEvidence = evidence;
    });
  }

  Future<void> handleEvidenceTypeSelected(EvidenceType type) async {
    if (type == EvidenceType.document ||
        type == EvidenceType.photograph ||
        type == EvidenceType.video) {
      await _captureEvidence(type);

      return;
    }

    await _createPendingEvidence(type);
  }

  Future<void> _captureEvidence(EvidenceType type) async {
    final question = phsQuestions[currentQuestion];

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

      await _loadCurrentQuestionEvidence();

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
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? '$label capture is unavailable.'),

          duration: const Duration(seconds: 2),
        ),
      );
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),

          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _createPendingEvidence(EvidenceType type) async {
    final question = phsQuestions[currentQuestion];

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

    await _loadCurrentQuestionEvidence();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label evidence entry added. '
          'Capture can be completed here.',
        ),

        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleEvidenceStatusChange(Evidence updatedEvidence) async {
    try {
      await _evidenceManagementService.updateEvidence(updatedEvidence);

      await _loadCurrentQuestionEvidence();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evidence status updated.'),

          duration: Duration(seconds: 2),
        ),
      );
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }

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
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evidence could not be found.'),

            duration: Duration(seconds: 2),
          ),
        );

        return;
      }

      await _loadCurrentQuestionEvidence();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evidence deleted.'),

          duration: Duration(seconds: 2),
        ),
      );
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),

          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _moveCarouselTo(int index) {
    if (!_questionPageController.hasClients) return;
    _questionPageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
    );
  }

  void _openQuestion(PHSQuestion question) {
    if (_isAnswering) return;

    final questionIndex = phsQuestions.indexWhere(
      (candidate) => candidate.id == question.id,
    );

    if (questionIndex < 0) return;

    setState(() {
      currentQuestion = questionIndex;

      _selectedResponse = null;

      _isAnswering = false;

      _currentQuestionEvidence = const [];

      _selectedPremiumCategory = question.category;
    });

    assessmentState.updateCurrentQuestion(question.id);
    _moveCarouselTo(questionIndex);
    _loadCurrentQuestionEvidence();
  }

  void _openCategory(PHSCategory category) {
    final question = _categoryQuestionResolver.resolve(
      category: category,

      questions: phsQuestions,

      answers: assessmentState.answers,
    );

    if (question == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'There are no questions available for '
            '${category.displayName}.',
          ),

          duration: const Duration(seconds: 2),
        ),
      );

      return;
    }

    final questionIndex = phsQuestions.indexWhere(
      (candidate) => candidate.id == question.id,
    );

    if (questionIndex < 0) {
      return;
    }

    setState(() {
      currentQuestion = questionIndex;

      _selectedResponse = null;

      _isAnswering = false;

      _currentQuestionEvidence = const [];

      _selectedPremiumCategory = category;
    });

    assessmentState.updateCurrentQuestion(question.id);
    _moveCarouselTo(questionIndex);
    _loadCurrentQuestionEvidence();

    if (!_premiumView) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        final message =
            assessmentState.answers.any(
              (answer) => answer.questionId == question.id,
            )
            ? 'Opening ${category.displayName}.'
            : 'Continuing ${category.displayName}.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),

            duration: const Duration(seconds: 1),
          ),
        );
      });
    }
  }

  void _toggleView(bool premium) {
    setState(() {
      _premiumView = premium;

      if (premium) {
        _selectedPremiumCategory ??= phsQuestions[currentQuestion].category;
      }
    });
  }

  void saveAnswer(PHSResponse response) {
    final question = phsQuestions[currentQuestion];

    // Save or update the answer without moving to another question.
    assessmentState.saveAnswer(
      PHSAnswer(questionId: question.id, response: response),
      currentQuestionId: question.id,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedResponse = response;
      _isAnswering = false;
    });
  }

  void _goToNextQuestion() {
    if (currentQuestion >= phsQuestions.length - 1) {
      return;
    }

    final nextIndex = currentQuestion + 1;
    final nextQuestion = phsQuestions[nextIndex];

    setState(() {
      currentQuestion = nextIndex;
      _selectedResponse = null;
      _isAnswering = false;
      _currentQuestionEvidence = const [];
      if (_premiumView) {
        _selectedPremiumCategory = nextQuestion.category;
      }
    });

    assessmentState.updateCurrentQuestion(nextQuestion.id);
    _moveCarouselTo(nextIndex);
    _loadCurrentQuestionEvidence();
  }

  void _completeAssessment() {
    if (currentQuestion != phsQuestions.length - 1) {
      return;
    }

    assessmentState.updateCurrentQuestion(phsQuestions[currentQuestion].id);
    assessmentState.completeAssessment();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AnalyzingScreen()),
    );
  }

  Widget _buildQuestionNavigation() {
    final isFirstQuestion = currentQuestion == 0;
    final isLastQuestion = currentQuestion == phsQuestions.length - 1;

    return Row(
      children: [
        if (!isFirstQuestion)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _goToPreviousQuestion,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous Question'),
            ),
          )
        else
          const Spacer(),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: isLastQuestion ? _completeAssessment : _goToNextQuestion,
            icon: Icon(
              isLastQuestion ? Icons.check_circle_outline : Icons.arrow_forward,
            ),
            label: Text(
              isLastQuestion ? 'Complete assessment' : 'Next Question',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveAndExit() async {
    if (_isAnswering) return;

    assessmentState.updateCurrentQuestion(phsQuestions[currentQuestion].id);

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

  Widget _buildAnswerOptions(PHSResponse? selectedResponse) {
    final labels = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );

    Widget option({
      required String text,
      required PHSResponse response,
      required Color color,
    }) {
      final selected = selectedResponse == response;

      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isAnswering ? null : () => saveAnswer(response),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.10) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? color : Colors.grey.shade300,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: color,
                  size: 22,
                ),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? color : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        option(
          text: labels?.assessmentYes ?? 'Yes',
          response: PHSResponse.yes,
          color: Colors.green,
        ),
        const SizedBox(width: 8),
        option(
          text: labels?.assessmentNo ?? 'No',
          response: PHSResponse.no,
          color: Colors.red,
        ),
        const SizedBox(width: 8),
        option(
          text: labels?.assessmentNotSure ?? "I'm Not Sure",
          response: PHSResponse.unsure,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildQuestionContent({
    required PHSQuestion question,

    bool includeProgress = true,
  }) {
    final selectedResponse =
        _selectedResponse ?? _savedResponseForQuestion(question.id);

    final questionProgress = includeProgress
        ? _questionProgressResolver.resolve(
            questionId: question.id,

            questions: phsQuestions,

            answeredQuestionIds: assessmentState.answers
                .map((answer) => answer.questionId)
                .toSet(),
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        if (includeProgress && questionProgress != null) ...[
          CurrentQuestionProgress(progress: questionProgress),

          const SizedBox(height: 24),
        ],

        QuestionCard(
          question: question,

          suppliedEvidence: question.id == phsQuestions[currentQuestion].id
              ? _currentQuestionEvidence
              : const [],

          onEvidenceTypeSelected:
              question.id == phsQuestions[currentQuestion].id
              ? handleEvidenceTypeSelected
              : null,

          onEvidenceStatusChange:
              question.id == phsQuestions[currentQuestion].id
              ? _handleEvidenceStatusChange
              : null,

          onEvidenceDelete: question.id == phsQuestions[currentQuestion].id
              ? _handleEvidenceDelete
              : null,
        ),

        const SizedBox(height: 24),

        _buildAnswerOptions(selectedResponse),
      ],
    );
  }

  Widget _buildPremiumQuestion(PHSCategory category) {
    final question = phsQuestions[currentQuestion];

    if (question.category != category) {
      return const SizedBox.shrink();
    }

    return _buildQuestionContent(question: question, includeProgress: false);
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.all(4),

      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),

        borderRadius: BorderRadius.circular(12),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          _buildViewToggleOption(
            label: 'Classic',

            icon: Icons.view_agenda_outlined,

            selected: !_premiumView,

            onTap: () => _toggleView(false),
          ),

          _buildViewToggleOption(
            label: 'Premium',

            icon: Icons.auto_awesome_outlined,

            selected: _premiumView,

            onTap: () => _toggleView(true),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleOption({
    required String label,

    required IconData icon,

    required bool selected,

    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,

      borderRadius: BorderRadius.circular(9),

      child: InkWell(
        borderRadius: BorderRadius.circular(9),

        onTap: _isAnswering ? null : onTap,

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),

          child: Row(
            mainAxisSize: MainAxisSize.min,

            children: [
              Icon(
                icon,

                size: 16,

                color: selected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
              ),

              const SizedBox(width: 5),

              Text(
                label,

                style: TextStyle(
                  fontSize: 12,

                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,

                  color: selected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassicView() {
    final progress = assessmentState.assessmentProgress;
    final answeredIds = assessmentState.answers
        .map((answer) => answer.questionId)
        .toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AssessmentProgress(
                current: currentQuestion + 1,
                total: phsQuestions.length,
              ),
              const SizedBox(height: 5),
              Text(
                '${progress.answeredQuestions} of '
                '${progress.totalQuestions} questions answered',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 10),
              ClassicCategoryAccordion(
                questions: phsQuestions,
                progressFor: progress.progressFor,
                isAnswered: answeredIds.contains,
                currentQuestionId: phsQuestions[currentQuestion].id,
                onQuestionSelected: _openQuestion,
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            key: const PageStorageKey<String>('assessment-question-carousel'),
            controller: _questionPageController,
            itemCount: phsQuestions.length,
            onPageChanged: (index) {
              if (index == currentQuestion || !mounted) return;
              final question = phsQuestions[index];
              setState(() {
                currentQuestion = index;
                _selectedResponse = null;
                _isAnswering = false;
                _currentQuestionEvidence = const [];
                _selectedPremiumCategory = question.category;
              });
              assessmentState.updateCurrentQuestion(question.id);
              _loadCurrentQuestionEvidence();
            },
            itemBuilder: (context, index) {
              final question = phsQuestions[index];
              return SingleChildScrollView(
                key: PageStorageKey<String>(
                  'assessment-question-${question.id}',
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ScoreHeatmapLegend(
                      compact: true,
                      score: _assessmentCoverage > 0 ? _overallScore : null,
                    ),
                    const SizedBox(height: 10),
                    _buildQuestionContent(
                      question: question,
                      includeProgress: true,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: _buildQuestionNavigation(),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          'Choose how you want to explore your assessment.',

          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),

        const SizedBox(height: 16),

        _buildViewToggle(),

        const SizedBox(height: 20),
      ],
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

    final progress = assessmentState.assessmentProgress;

    return Scaffold(
      backgroundColor: _premiumView
          ? const Color(0xFFF1F5F9)
          : const Color(0xFFF8FAFC),

      appBar: AppBar(
        title: const Text('Property Assessment'),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),

            child: _buildViewToggle(),
          ),

          TextButton(
            onPressed: _isAnswering ? null : _saveAndExit,

            child: const Text('Save & Exit'),
          ),
        ],
      ),

      body: SafeArea(
        child: _premiumView
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPremiumHeader(),
                    PremiumAssessmentView(
                      progress: progress,
                      categoryScores: _categoryScores,
                      overallScore: _overallScore,
                      assessmentCoverage: _assessmentCoverage,
                      selectedCategory: _selectedPremiumCategory,
                      onCategoryTap: _openCategory,
                      questionBuilder: _buildPremiumQuestion,
                    ),
                    const SizedBox(height: 24),
                    _buildQuestionNavigation(),
                    const SizedBox(height: 20),
                  ],
                ),
              )
            : _buildClassicView(),
      ),
    );
  }

  void _goToPreviousQuestion() {
    if (currentQuestion <= 0) {
      return;
    }

    setState(() {
      currentQuestion--;

      _selectedResponse = null;

      _isAnswering = false;

      _currentQuestionEvidence = const [];

      if (_premiumView) {
        _selectedPremiumCategory = phsQuestions[currentQuestion].category;
      }
    });

    assessmentState.updateCurrentQuestion(phsQuestions[currentQuestion].id);
    _moveCarouselTo(currentQuestion);
    _loadCurrentQuestionEvidence();
  }
}
