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
import '../../data/phs_questions.dart';
import '../../state/assessment_state.dart';
import '../../widgets/assessment/answer_option.dart';
import '../../widgets/assessment/assessment_progress.dart';
import '../../widgets/assessment/question_card.dart';
import 'analyzing_screen.dart';

class AssessmentScreen extends StatefulWidget {
  final EvidenceCaptureService? evidenceCaptureService;

  const AssessmentScreen({
    super.key,
    this.evidenceCaptureService,
  });

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  int currentQuestion = 0;

  final AssessmentState assessmentState = AssessmentState.instance;

  late final QuestionEvidenceCoordinator _evidenceCoordinator;
  late final AssessmentEvidenceManagementService
      _evidenceManagementService;
  late final EvidenceCaptureCoordinator _evidenceCaptureCoordinator;

  List<Evidence> _currentQuestionEvidence = const [];

  @override
  void initState() {
    super.initState();

    _initializeEvidenceCoordinator();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      assessmentState.startAssessment();

      _loadCurrentQuestionEvidence();
    });
  }

  void _initializeEvidenceCoordinator() {
    final typeMapper = const EvidenceTypeMapper();

    final resolver = EvidenceRequirementResolver(
      typeMapper: typeMapper,
    );

    final catalog = EvidenceRequirementCatalog(
      resolver: resolver,
    );

    final validator = EvidenceValidator();

    _evidenceCoordinator = QuestionEvidenceCoordinator(
      repository: assessmentState.evidenceRepository,
      validator: validator,
    );

    _evidenceManagementService =
        AssessmentEvidenceManagementService(
      repository: assessmentState.evidenceRepository,
    );

    final captureService =
        widget.evidenceCaptureService ??
            CompositeEvidenceCaptureService(
              documentCaptureService:
                  FilePickerEvidenceCaptureService(
                filePicker: const PlatformFilePickerGateway(),
              ),
              photographCaptureService:
                  ImagePickerEvidenceCaptureService(
                imagePicker: PlatformImagePickerGateway(),
              ),
              videoCaptureService:
                  VideoCaptureService(
                imagePicker: PlatformImagePickerGateway(),
              ),
            );

    _evidenceCaptureCoordinator =
        EvidenceCaptureCoordinator(
      captureService: captureService,
      repository: assessmentState.evidenceRepository,
    );

    catalog.getForQuestion(
      phsQuestions[currentQuestion],
    );
  }

  Future<void> _loadCurrentQuestionEvidence() async {
    final question = phsQuestions[currentQuestion];

    final evidence =
        await _evidenceCoordinator.loadEvidence(
      question.id,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _currentQuestionEvidence = evidence;
    });
  }

  Future<void> handleEvidenceTypeSelected(
    EvidenceType type,
  ) async {
    if (type == EvidenceType.document ||
        type == EvidenceType.photograph ||
        type == EvidenceType.video) {
      await _captureEvidence(type);
      return;
    }

    await _createPendingEvidence(type);
  }

  Future<void> _captureEvidence(
    EvidenceType type,
  ) async {
    final question = phsQuestions[currentQuestion];

    final label = switch (type) {
      EvidenceType.document => 'Document',
      EvidenceType.photograph => 'Photograph',
      EvidenceType.video => 'Video',
      EvidenceType.manual => 'Manual Entry',
    };

    final request = switch (type) {
      EvidenceType.document =>
        const EvidenceCaptureRequest.document(),
      EvidenceType.photograph =>
        const EvidenceCaptureRequest.photograph(),
      EvidenceType.video =>
        const EvidenceCaptureRequest.video(),
      EvidenceType.manual =>
        const EvidenceCaptureRequest.manual(),
    };

    try {
      final evidence =
          await _evidenceCaptureCoordinator.captureEvidence(
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
          content: Text(
            '$label evidence added successfully.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } on UnsupportedError catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ??
                '$label capture is unavailable.',
          ),
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

  Future<void> _createPendingEvidence(
    EvidenceType type,
  ) async {
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

    await _evidenceCoordinator.addEvidence(
      evidence,
    );

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

  Future<void> _handleEvidenceStatusChange(
    Evidence updatedEvidence,
  ) async {
    try {
      await _evidenceManagementService.updateEvidence(
        updatedEvidence,
      );

      await _loadCurrentQuestionEvidence();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Evidence status updated.',
          ),
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

  Future<void> _handleEvidenceDelete(
    Evidence evidence,
  ) async {
    try {
      final deleted =
          await _evidenceManagementService.deleteEvidence(
        evidence.id,
      );

      if (!deleted) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Evidence could not be found.',
            ),
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

  void saveAnswer(PHSResponse response) {
    final question = phsQuestions[currentQuestion];

    assessmentState.saveAnswer(
      PHSAnswer(
        questionId: question.id,
        response: response,
      ),
    );

    if (currentQuestion < phsQuestions.length - 1) {
      setState(() {
        currentQuestion++;
        _currentQuestionEvidence = const [];
      });

      _loadCurrentQuestionEvidence();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AnalyzingScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = phsQuestions[currentQuestion];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Property Assessment'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              AssessmentProgress(
                current: currentQuestion + 1,
                total: phsQuestions.length,
              ),
              const SizedBox(height: 24),
              QuestionCard(
                question: question,
                suppliedEvidence:
                    _currentQuestionEvidence,
                onEvidenceTypeSelected:
                    handleEvidenceTypeSelected,
                onEvidenceStatusChange:
                    _handleEvidenceStatusChange,
                onEvidenceDelete:
                    _handleEvidenceDelete,
              ),
              const SizedBox(height: 24),
              AnswerOption(
                icon: Icons.check_circle,
                color: Colors.green,
                text: 'Yes',
                onTap: () =>
                    saveAnswer(PHSResponse.yes),
              ),
              const SizedBox(height: 14),
              AnswerOption(
                icon: Icons.cancel,
                color: Colors.red,
                text: 'No',
                onTap: () =>
                    saveAnswer(PHSResponse.no),
              ),
              const SizedBox(height: 14),
              AnswerOption(
                icon: Icons.help,
                color: Colors.orange,
                text: "I'm Not Sure",
                onTap: () =>
                    saveAnswer(PHSResponse.unsure),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}