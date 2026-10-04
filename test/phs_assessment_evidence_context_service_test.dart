import 'package:flutter_test/flutter_test.dart';
import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement_catalog.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement_matcher.dart';
import 'package:homesure_ai/core/evidence/evidence_repository.dart';
import 'package:homesure_ai/core/evidence/evidence_type_mapper.dart';
import 'package:homesure_ai/core/evidence/evidence_validation_result.dart';
import 'package:homesure_ai/core/evidence/evidence_validator.dart';
import 'package:homesure_ai/core/evidence/in_memory_evidence_repository.dart';
import 'package:homesure_ai/core/evidence/phs_assessment_evidence_context_builder.dart';
import 'package:homesure_ai/core/evidence/phs_assessment_evidence_context_service.dart';
import 'package:homesure_ai/core/evidence/phs_question_evidence_context_builder.dart';
import 'package:homesure_ai/core/evidence/phs_question_evidence_context_service.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement_resolver.dart';
import 'package:homesure_ai/data/phs_questions.dart';

void main() {
  late EvidenceRepository repository;
  late PHSQuestionEvidenceContextService questionContextService;
  late PHSAssessmentEvidenceContextService service;

  setUp(() {
    repository = InMemoryEvidenceRepository();

    final typeMapper = const EvidenceTypeMapper();

    final resolver = EvidenceRequirementResolver(
      typeMapper: typeMapper,
    );

    final catalog = EvidenceRequirementCatalog(
      resolver: resolver,
    );

    final matcher = const EvidenceRequirementMatcher();

    final validator = EvidenceValidator(
      matcher: matcher,
    );

    final questionContextBuilder = PHSQuestionEvidenceContextBuilder(
      validator: validator,
    );

    questionContextService = PHSQuestionEvidenceContextService(
      repository: repository,
      catalog: catalog,
      builder: questionContextBuilder,
    );

    final assessmentBuilder =
        const PHSAssessmentEvidenceContextBuilder();

    service = PHSAssessmentEvidenceContextService(
      questionContextService: questionContextService,
      builder: assessmentBuilder,
    );
  });

  test(
    'buildForQuestions returns empty assessment context for empty list',
    () async {
      final context = await service.buildForQuestions([]);

      expect(context.questionCount, 0);
      expect(context.completeQuestionCount, 0);
      expect(context.hasEvidenceGaps, isFalse);
      expect(context.hasEvidenceRisk, isFalse);
      expect(context.isComplete, isFalse);
    },
  );

  test(
    'buildForQuestions creates one question context per question',
    () async {
      final questions = phsQuestions.take(2).toList();

      final context = await service.buildForQuestions(questions);

      expect(context.questionCount, 2);

      for (final question in questions) {
        expect(context.containsQuestion(question.id), isTrue);
        expect(
          context.getForQuestion(question.id),
          isNotNull,
        );
      }
    },
  );

  test(
    'buildForQuestions uses the canonical question IDs',
    () async {
      final questions = phsQuestions.take(3).toList();

      final context = await service.buildForQuestions(questions);

      expect(
        context.contexts.keys,
        containsAll(
          questions.map((question) => question.id),
        ),
      );
    },
  );

  test(
    'buildForQuestions resolves requirements from each question',
    () async {
      final question = phsQuestions.firstWhere(
        (item) => item.requiredEvidence.isNotEmpty,
      );

      final context = await service.buildForQuestions([question]);
      final questionContext = context.getForQuestion(question.id);

      expect(questionContext, isNotNull);
      expect(
        questionContext!.totalRequirements,
        question.requiredEvidence.length,
      );
    },
  );

  test(
    'buildForQuestions reflects missing evidence',
    () async {
      final question = phsQuestions.firstWhere(
        (item) => item.requiredEvidence.isNotEmpty,
      );

      final context = await service.buildForQuestions([question]);
      final questionContext = context.getForQuestion(question.id);

      expect(questionContext, isNotNull);
      expect(
        questionContext!.missingRequirements,
        greaterThan(0),
      );
      expect(questionContext.hasEvidenceGaps, isTrue);
      expect(questionContext.hasEvidenceRisk, isTrue);
    },
  );

  test(
    'buildForQuestions reflects supplied evidence',
    () async {
      final question = phsQuestions.firstWhere(
        (item) => item.requiredEvidence.isNotEmpty,
      );

      final requirementLabel = question.requiredEvidence.first;

      final evidence = Evidence(
        id: 'evidence-1',
        questionId: question.id,
        type: EvidenceTypeMapper().map(requirementLabel),
        name: requirementLabel,
        status: EvidenceStatus.provided,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 1, 1),
      );

      await repository.add(evidence);

      final context = await service.buildForQuestions([question]);
      final questionContext = context.getForQuestion(question.id);

      expect(questionContext, isNotNull);
      expect(
        questionContext!.providedRequirements,
        greaterThan(0),
      );
      expect(questionContext.hasEvidenceGaps, isTrue);
    },
  );

  test(
    'buildForQuestions reflects verified evidence for the supplied requirement',
    () async {
      final question = phsQuestions.firstWhere(
        (item) => item.requiredEvidence.isNotEmpty,
      );

      final requirementLabel = question.requiredEvidence.first;

      final evidence = Evidence(
        id: 'evidence-verified',
        questionId: question.id,
        type: EvidenceTypeMapper().map(requirementLabel),
        name: requirementLabel,
        status: EvidenceStatus.verified,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 1, 1),
      );

      await repository.add(evidence);

      final context = await service.buildForQuestions([question]);
      final questionContext = context.getForQuestion(question.id);

      expect(questionContext, isNotNull);

      final matchingValidation = questionContext!.validations.firstWhere(
        (validation) =>
            validation.requirement.label == requirementLabel,
      );

      expect(
        matchingValidation.isSatisfied,
        isTrue,
      );

      expect(
        matchingValidation.status,
        EvidenceValidationStatus.satisfied,
      );
    },
  );

  test(
    'buildForQuestion wraps a single question context',
    () async {
      final question = phsQuestions.first;

      final context = await service.buildForQuestion(question);

      expect(context.questionCount, 1);
      expect(context.containsQuestion(question.id), isTrue);
      expect(
        context.getForQuestion(question.id),
        isNotNull,
      );
    },
  );

  test(
    'buildQuestionContexts returns question contexts without aggregate',
    () async {
      final questions = phsQuestions.take(3).toList();

      final contexts =
          await service.buildQuestionContexts(questions);

      expect(contexts.length, 3);
      expect(
        contexts.map((context) => context.questionId),
        containsAll(
          questions.map((question) => question.id),
        ),
      );
    },
  );

  test(
    'buildQuestionContexts returns an immutable list',
    () async {
      final questions = phsQuestions.take(2).toList();

      final contexts =
          await service.buildQuestionContexts(questions);

      expect(
        () => contexts.add(contexts.first),
        throwsUnsupportedError,
      );
    },
  );

  test(
    'assessment context is immutable through contexts getter',
    () async {
      final question = phsQuestions.first;

      final context = await service.buildForQuestions([question]);

      expect(
        () => context.contexts.remove(question.id),
        throwsUnsupportedError,
      );
    },
  );

  test(
    'multiple questions retain independent evidence states',
    () async {
      final questions = phsQuestions
          .where(
            (question) => question.requiredEvidence.isNotEmpty,
          )
          .take(2)
          .toList();

      final firstQuestion = questions[0];
      final firstRequirement = firstQuestion.requiredEvidence.first;

      await repository.add(
        Evidence(
          id: 'first-question-evidence',
          questionId: firstQuestion.id,
          type: EvidenceTypeMapper().map(firstRequirement),
          name: firstRequirement,
          status: EvidenceStatus.verified,
          source: EvidenceSource.userUpload,
          addedAt: DateTime(2026, 1, 1),
        ),
      );

      final context = await service.buildForQuestions(questions);

      final firstContext =
          context.getForQuestion(firstQuestion.id);

      final secondContext =
          context.getForQuestion(questions[1].id);

      expect(firstContext, isNotNull);
      expect(secondContext, isNotNull);
      expect(firstContext!.suppliedEvidence.length, 1);
      expect(secondContext!.suppliedEvidence, isEmpty);
    },
  );
}