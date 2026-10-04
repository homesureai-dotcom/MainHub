import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/engine/engine.dart';
import '../../core/engine/models/property_health_result.dart';
import '../../core/evidence/assessment_evidence_summary.dart';
import '../../core/evidence/assessment_evidence_summary_builder.dart';
import '../../core/evidence/evidence_repository.dart';
import '../../core/evidence/evidence_requirement_catalog.dart';
import '../../core/evidence/evidence_requirement_resolver.dart';
import '../../core/evidence/evidence_type_mapper.dart';
import '../../core/evidence/evidence_validator.dart';
import '../../core/evidence/phs_assessment_evidence_context_builder.dart';
import '../../core/evidence/phs_assessment_evidence_context_service.dart';
import '../../core/evidence/phs_assessment_evidence_integration.dart';
import '../../core/evidence/phs_question_evidence_context_builder.dart';
import '../../core/evidence/phs_question_evidence_context_service.dart';
import '../../data/phs_questions.dart';
import '../../state/assessment_state.dart';
import '../../widgets/assessment/analyzing_step.dart';
import 'property_health_result_screen.dart';

class AnalyzingScreen extends StatefulWidget {
  const AnalyzingScreen({super.key});

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen> {
  late final EvidenceRepository _evidenceRepository;

  late final EvidenceRequirementCatalog _evidenceCatalog;

  late final PHSAssessmentEvidenceContextService
      _assessmentEvidenceContextService;

  late final AssessmentEvidenceSummaryBuilder
      _assessmentEvidenceSummaryBuilder;

  @override
  void initState() {
    super.initState();

    _initializeEvidenceServices();
    _analyzeAssessment();
  }

  void _initializeEvidenceServices() {
    final state = AssessmentState.instance;

    // Use the same repository that was populated during the assessment.
    _evidenceRepository = state.evidenceRepository;

    final typeMapper = const EvidenceTypeMapper();

    final resolver = EvidenceRequirementResolver(
      typeMapper: typeMapper,
    );

    _evidenceCatalog = EvidenceRequirementCatalog(
      resolver: resolver,
    );

    final validator = EvidenceValidator();

    final questionContextBuilder =
        PHSQuestionEvidenceContextBuilder(
      validator: validator,
    );

    final questionContextService =
        PHSQuestionEvidenceContextService(
      repository: _evidenceRepository,
      catalog: _evidenceCatalog,
      builder: questionContextBuilder,
    );

    final assessmentContextBuilder =
        const PHSAssessmentEvidenceContextBuilder();

    _assessmentEvidenceContextService =
        PHSAssessmentEvidenceContextService(
      questionContextService: questionContextService,
      builder: assessmentContextBuilder,
    );

    _assessmentEvidenceSummaryBuilder =
        AssessmentEvidenceSummaryBuilder(
      validator: validator,
    );
  }

  Future<void> _analyzeAssessment() async {
    await Future.delayed(const Duration(seconds: 2));

    final state = AssessmentState.instance;

    final engine = PropertyIntelligenceEngine();

    final PropertyHealthResult result =
        engine.evaluateAssessment(state.answers);

    final evidenceContext =
        await _assessmentEvidenceContextService.buildForQuestions(
      phsQuestions,
    );

    final integration = PHSAssessmentEvidenceIntegration(
      healthResult: result,
      evidenceContext: evidenceContext,
    );

    final requirements = _evidenceCatalog.flatten(
      phsQuestions,
    );

    final evidence = await _evidenceRepository.getAll();

    final AssessmentEvidenceSummary evidenceSummary =
        _assessmentEvidenceSummaryBuilder.build(
      requirements: requirements,
      evidence: evidence,
    );

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyHealthResultScreen(
          result: integration.healthResult,
          evidenceSummary: evidenceSummary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const CircleAvatar(
                radius: 60,
                backgroundColor: Color(0xFF2563EB),
                child: Icon(
                  Icons.smart_toy,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Analyzing your Property',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'SureBot is evaluating your responses using the '
                'HomeSure Property Health Standard.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              const LinearProgressIndicator(),
              const SizedBox(height: 40),
              const AnalyzingStep(
                title: 'Legal & Ownership',
                completed: true,
              ),
              const AnalyzingStep(
                title: 'Construction Quality',
                completed: true,
              ),
              const AnalyzingStep(
                title: 'Utilities & Infrastructure',
                completed: true,
              ),
              const AnalyzingStep(
                title: 'Safety & Compliance',
                completed: true,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}