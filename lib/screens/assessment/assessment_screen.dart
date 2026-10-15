import 'dart:async';

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
import '../../core/phs/phs_answer.dart';
import '../../core/phs/phs_categories.dart';
import '../../core/phs/phs_category_question_resolver.dart';
import '../../core/phs/phs_question_progress.dart';
import '../../core/phs/phs_question_progress_resolver.dart';
import '../../data/phs_questions.dart';
import '../../core/phs/phs_question.dart';
import '../../features/property/state/property_state.dart';
import '../../models/property_health/category_score.dart';
import '../../models/property_health/score_calculator.dart';
import '../../state/assessment_state.dart';
import '../../widgets/assessment/answer_option.dart';
import '../../widgets/assessment/assessment_progress.dart';
import '../../widgets/assessment/current_question_progress.dart';
import '../../widgets/assessment/phs_pillar_progress.dart';
import '../../widgets/assessment/premium_assessment_view.dart';
import '../../widgets/assessment/question_card.dart';
import 'analyzing_screen.dart';

class AssessmentScreen extends StatefulWidget {
  final EvidenceCaptureService? evidenceCaptureService;

  const AssessmentScreen({super.key, this.evidenceCaptureService});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  int currentQuestion = 0;

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

  PHSCategory? _selectedPremiumCategory;

  Timer? _answerAdvanceTimer;

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
      _initializeAssessment();
    });
  }

  @override
  void dispose() {
    _answerAdvanceTimer?.cancel();
    super.dispose();
  }

  void _initializeAssessment() {
    assessmentState.startAssessment(
      propertyId: propertyState.selectedProperty?.id,
    );

    _restoreCurrentQuestion();

    _loadCurrentQuestionEvidence();
  }

  void _restoreCurrentQuestion() {
    final savedQuestionId = assessmentState.currentQuestionId;

    if (savedQuestionId != null) {
      final savedIndex = phsQuestions.indexWhere(
        (question) => question.id == savedQuestionId,
      );

      if (savedIndex >= 0) {
        setState(() {
          currentQuestion = savedIndex;
          _selectedResponse = null;
          _isAnswering = false;
        });

        return;
      }
    }

    final answers = assessmentState.answers;

    if (answers.isEmpty) {
      setState(() {
        currentQuestion = 0;
        _selectedResponse = null;
        _isAnswering = false;
      });

      return;
    }

    final answeredQuestionIds = answers.map((answer) => answer.questionId);

    final nextUnansweredIndex = phsQuestions.indexWhere(
      (question) => !answeredQuestionIds.contains(question.id),
    );

    if (nextUnansweredIndex >= 0) {
      setState(() {
        currentQuestion = nextUnansweredIndex;
        _selectedResponse = null;
        _isAnswering = false;
      });

      return;
    }

    setState(() {
      currentQuestion = phsQuestions.length - 1;
      _selectedResponse = null;
      _isAnswering = false;
    });
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

    _answerAdvanceTimer?.cancel();

    setState(() {
      currentQuestion = questionIndex;
      _selectedResponse = null;
      _isAnswering = false;
      _currentQuestionEvidence = const [];
      _selectedPremiumCategory = category;
    });

    assessmentState.updateCurrentQuestion(question.id);

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
    _answerAdvanceTimer?.cancel();

    setState(() {
      _premiumView = premium;

      if (premium) {
        _selectedPremiumCategory ??= phsQuestions[currentQuestion].category;
      }
    });
  }

  void saveAnswer(PHSResponse response) {
    if (_isAnswering) {
      return;
    }

    final question = phsQuestions[currentQuestion];

    final isLastQuestion = currentQuestion == phsQuestions.length - 1;

    final nextQuestionId = isLastQuestion
        ? question.id
        : phsQuestions[currentQuestion + 1].id;

    assessmentState.saveAnswer(
      PHSAnswer(questionId: question.id, response: response),
      currentQuestionId: nextQuestionId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedResponse = response;
      _isAnswering = true;
    });

    _answerAdvanceTimer?.cancel();

    _answerAdvanceTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }

      if (!isLastQuestion) {
        setState(() {
          currentQuestion++;
          _selectedResponse = null;
          _isAnswering = false;
          _currentQuestionEvidence = const [];

          if (_premiumView) {
            _selectedPremiumCategory = phsQuestions[currentQuestion].category;
          }
        });

        _loadCurrentQuestionEvidence();

        return;
      }

      setState(() {
        _isAnswering = false;
      });

      assessmentState.completeAssessment();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AnalyzingScreen()),
      );
    });
  }

  void _saveAndExit() {
    assessmentState.updateCurrentQuestion(phsQuestions[currentQuestion].id);

    assessmentState.saveAndExit();

    Navigator.pop(context);
  }

  Widget _buildAnswerOptions(PHSResponse? selectedResponse) {
    return Column(
      children: [
        AnswerOption(
          icon: Icons.check_circle,
          color: Colors.green,
          text: 'Yes',
          selected: selectedResponse == PHSResponse.yes,
          onTap: _isAnswering ? null : () => saveAnswer(PHSResponse.yes),
        ),
        const SizedBox(height: 14),
        AnswerOption(
          icon: Icons.cancel,
          color: Colors.red,
          text: 'No',
          selected: selectedResponse == PHSResponse.no,
          onTap: _isAnswering ? null : () => saveAnswer(PHSResponse.no),
        ),
        const SizedBox(height: 14),
        AnswerOption(
          icon: Icons.help,
          color: Colors.orange,
          text: "I'm Not Sure",
          selected: selectedResponse == PHSResponse.unsure,
          onTap: _isAnswering ? null : () => saveAnswer(PHSResponse.unsure),
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
    final question = phsQuestions[currentQuestion];

    final selectedResponse =
        _selectedResponse ?? _savedResponseForQuestion(question.id);

    final progress = assessmentState.assessmentProgress;

    final questionProgress = _currentQuestionProgress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AssessmentProgress(
          current: currentQuestion + 1,
          total: phsQuestions.length,
        ),
        const SizedBox(height: 8),
        Text(
          '${progress.answeredQuestions} of '
          '${progress.totalQuestions} questions answered',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),
        PHSAssessmentPillarProgress(
          progress: progress,
          onCategoryTap: _openCategory,
        ),
        if (questionProgress != null) ...[
          const SizedBox(height: 16),
          CurrentQuestionProgress(progress: questionProgress),
        ],
        const SizedBox(height: 24),
        QuestionCard(
          question: question,
          suppliedEvidence: _currentQuestionEvidence,
          onEvidenceTypeSelected: handleEvidenceTypeSelected,
          onEvidenceStatusChange: _handleEvidenceStatusChange,
          onEvidenceDelete: _handleEvidenceDelete,
        ),
        const SizedBox(height: 24),
        _buildAnswerOptions(selectedResponse),
        const SizedBox(height: 32),
        if (currentQuestion > 0)
          Center(
            child: TextButton.icon(
              onPressed: _isAnswering ? null : _goToPreviousQuestion,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous Question'),
            ),
          ),
        const SizedBox(height: 20),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _premiumView
              ? Column(
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
                    if (currentQuestion > 0)
                      Center(
                        child: TextButton.icon(
                          onPressed: _isAnswering
                              ? null
                              : _goToPreviousQuestion,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Previous Question'),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                )
              : _buildClassicView(),
        ),
      ),
    );
  }

  void _goToPreviousQuestion() {
    if (currentQuestion <= 0) {
      return;
    }

    _answerAdvanceTimer?.cancel();

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

    _loadCurrentQuestionEvidence();
  }
}
