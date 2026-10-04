import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_category_coverage.dart';
import 'package:homesure_ai/core/evidence/evidence_completeness.dart';
import 'package:homesure_ai/core/evidence/evidence_coverage.dart';
import 'package:homesure_ai/core/evidence/evidence_coverage_calculator.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement_matcher.dart';
import 'package:homesure_ai/core/evidence/evidence_risk_signal.dart';
import 'package:homesure_ai/core/evidence/evidence_validation_result.dart';
import 'package:homesure_ai/core/evidence/evidence_validator.dart';
import 'package:homesure_ai/core/evidence/phs_evidence_mapper.dart';
import 'package:homesure_ai/core/phs/phs_question.dart';
import 'package:homesure_ai/data/phs_questions.dart';

void main() {
  group('Sprint 9.3 Evidence Integration', () {
    const mapper = PHSEvidenceMapper();
    const matcher = EvidenceRequirementMatcher();
    const validator = EvidenceValidator();
    const coverageCalculator = EvidenceCoverageCalculator();

    test('canonical PHS dataset contains 33 questions', () {
      expect(phsQuestions, hasLength(33));
    });

    test('canonical PHS dataset produces evidence requirements', () {
      final requirements = phsQuestions
          .expand(mapper.mapQuestion)
          .toList(growable: false);

      expect(requirements, isNotEmpty);

      for (final requirement in requirements) {
        expect(requirement.questionId, isNotEmpty);
        expect(requirement.label, isNotEmpty);
      }
    });

    test('every canonical PHS question has mapped evidence requirements',
        () {
      final mapped = mapper.mapQuestions(phsQuestions);

      expect(mapped.length, phsQuestions.length);

      for (final question in phsQuestions) {
        expect(mapped.containsKey(question.id), isTrue);
        expect(mapped[question.id], isNotNull);
        expect(mapped[question.id]!, isNotEmpty);
      }
    });

    test('mapped requirements preserve question identity', () {
      final mapped = mapper.mapQuestions(phsQuestions);

      for (final question in phsQuestions) {
        final requirements = mapped[question.id]!;

        for (final requirement in requirements) {
          expect(requirement.questionId, question.id);
        }
      }
    });

    test('evidence can satisfy an exact document requirement', () {
      const requirement = EvidenceRequirement(
        questionId: 'PHS_LEGAL_OC',
        label: 'Occupancy Certificate',
        type: EvidenceType.document,
      );

      final evidence = Evidence(
        id: 'evidence-1',
        questionId: 'PHS_LEGAL_OC',
        requirementId: Evidence.requirementKey(
          questionId: 'PHS_LEGAL_OC',
          label: 'Occupancy Certificate',
        ),
        type: EvidenceType.document,
        name: 'OC.pdf',
        status: EvidenceStatus.verified,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 1, 1),
      );

      expect(
        matcher.matches(evidence, requirement),
        isTrue,
      );

      final validation = validator.validate(
        requirement,
        [evidence],
      );

      expect(
        validation.status,
        EvidenceValidationStatus.satisfied,
      );

      expect(validation.isSatisfied, isTrue);
    });

    test('unverified evidence does not become satisfied', () {
      const requirement = EvidenceRequirement(
        questionId: 'PHS_LEGAL_OC',
        label: 'Occupancy Certificate',
        type: EvidenceType.document,
      );

      final evidence = Evidence(
        id: 'evidence-2',
        questionId: 'PHS_LEGAL_OC',
        requirementId: Evidence.requirementKey(
          questionId: 'PHS_LEGAL_OC',
          label: 'Occupancy Certificate',
        ),
        type: EvidenceType.document,
        name: 'OC.pdf',
        status: EvidenceStatus.provided,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 1, 1),
      );

      final validation = validator.validate(
        requirement,
        [evidence],
      );

      expect(
        validation.status,
        EvidenceValidationStatus.provided,
      );

      expect(validation.isSatisfied, isFalse);
    });

    test('missing evidence produces a high risk signal', () {
      const requirement = EvidenceRequirement(
        questionId: 'PHS_LEGAL_OC',
        label: 'Occupancy Certificate',
        type: EvidenceType.document,
      );

      final validation = validator.validate(
        requirement,
        const [],
      );

      final signal = EvidenceRiskSignal.fromValidationResult(
        validation,
      );

      expect(
        validation.status,
        EvidenceValidationStatus.missing,
      );

      expect(
        signal.level,
        EvidenceRiskLevel.high,
      );

      expect(signal.hasRisk, isTrue);
    });

    test('verified evidence produces no risk signal', () {
      const requirement = EvidenceRequirement(
        questionId: 'PHS_LEGAL_OC',
        label: 'Occupancy Certificate',
        type: EvidenceType.document,
      );

      final evidence = Evidence(
        id: 'evidence-3',
        questionId: 'PHS_LEGAL_OC',
        requirementId: Evidence.requirementKey(
          questionId: 'PHS_LEGAL_OC',
          label: 'Occupancy Certificate',
        ),
        type: EvidenceType.document,
        name: 'OC.pdf',
        status: EvidenceStatus.verified,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 1, 1),
      );

      final validation = validator.validate(
        requirement,
        [evidence],
      );

      final signal = EvidenceRiskSignal.fromValidationResult(
        validation,
      );

      expect(
        signal.level,
        EvidenceRiskLevel.none,
      );

      expect(signal.hasRisk, isFalse);
    });

    test('coverage calculator reflects mixed evidence states', () {
      const requirements = [
        EvidenceRequirement(
          questionId: 'Q1',
          label: 'Document A',
          type: EvidenceType.document,
        ),
        EvidenceRequirement(
          questionId: 'Q2',
          label: 'Document B',
          type: EvidenceType.document,
        ),
        EvidenceRequirement(
          questionId: 'Q3',
          label: 'Photograph',
          type: EvidenceType.photograph,
        ),
        EvidenceRequirement(
          questionId: 'Q4',
          label: 'Document D',
          type: EvidenceType.document,
        ),
      ];

      final evidence = [
        Evidence(
          id: 'e1',
          questionId: 'Q1',
          requirementId: Evidence.requirementKey(
            questionId: 'Q1',
            label: 'Document A',
          ),
          type: EvidenceType.document,
          name: 'document-a.pdf',
          status: EvidenceStatus.verified,
          source: EvidenceSource.userUpload,
          addedAt: DateTime(2026, 1, 1),
        ),
        Evidence(
          id: 'e2',
          questionId: 'Q2',
          requirementId: Evidence.requirementKey(
            questionId: 'Q2',
            label: 'Document B',
          ),
          type: EvidenceType.document,
          name: 'document-b.pdf',
          status: EvidenceStatus.provided,
          source: EvidenceSource.userUpload,
          addedAt: DateTime(2026, 1, 1),
        ),
        Evidence(
          id: 'e3',
          questionId: 'Q3',
          type: EvidenceType.photograph,
          name: 'inspection-photo.jpg',
          status: EvidenceStatus.needsReview,
          source: EvidenceSource.userUpload,
          addedAt: DateTime(2026, 1, 1),
        ),
      ];

      final coverage = coverageCalculator.calculate(
        requirements: requirements,
        evidence: evidence,
      );

      expect(coverage.totalRequirements, 4);
      expect(coverage.satisfiedRequirements, 1);
      expect(coverage.providedRequirements, 1);
      expect(coverage.needsReviewRequirements, 1);
      expect(coverage.missingRequirements, 1);
      expect(coverage.rejectedRequirements, 0);
      expect(coverage.coveragePercentage, 25);
      expect(coverage.isComplete, isFalse);
      expect(coverage.hasEvidenceGaps, isTrue);
    });

    test('completeness and validation remain consistent', () {
      const requirements = [
        EvidenceRequirement(
          questionId: 'Q1',
          label: 'Document A',
          type: EvidenceType.document,
        ),
        EvidenceRequirement(
          questionId: 'Q2',
          label: 'Document B',
          type: EvidenceType.document,
        ),
      ];

      final evidence = [
        Evidence(
          id: 'e1',
          questionId: 'Q1',
          requirementId: Evidence.requirementKey(
            questionId: 'Q1',
            label: 'Document A',
          ),
          type: EvidenceType.document,
          name: 'document-a.pdf',
          status: EvidenceStatus.verified,
          source: EvidenceSource.userUpload,
          addedAt: DateTime(2026, 1, 1),
        ),
      ];

      final validationResults = validator.validateAll(
        requirements,
        evidence,
      );

      final completeness = EvidenceCompleteness.calculate(
        requirements: requirements,
        evidence: evidence,
      );

      final coverage =
          coverageCalculator.calculateFromResults(
        validationResults,
      );

      expect(validationResults, hasLength(2));

      expect(
        completeness.totalRequirements,
        coverage.totalRequirements,
      );

      expect(
        completeness.matchedRequirements,
        1,
      );

      expect(
        completeness.missingRequirements,
        1,
      );

      expect(
        coverage.satisfiedRequirements,
        1,
      );

      expect(
        coverage.missingRequirements,
        1,
      );
    });

    test('category coverage can be calculated from validation results',
        () {
      const legalRequirements = [
        EvidenceRequirement(
          questionId: 'PHS_LEGAL_OC',
          label: 'Occupancy Certificate',
          type: EvidenceType.document,
        ),
        EvidenceRequirement(
          questionId: 'PHS_LEGAL_SALE_DEED',
          label: 'Registered Sale Deed',
          type: EvidenceType.document,
        ),
      ];

      final results = [
        EvidenceValidationResult(
          requirement: legalRequirements[0],
          status: EvidenceValidationStatus.satisfied,
          message: 'Satisfied',
        ),
        EvidenceValidationResult(
          requirement: legalRequirements[1],
          status: EvidenceValidationStatus.missing,
          message: 'Missing',
        ),
      ];

      final coverage =
          EvidenceCategoryCoverage.calculateForRequirements(
        categoryId: 'legal_ownership',
        requirements: legalRequirements,
        results: results,
      );

      expect(coverage.categoryId, 'legal_ownership');
      expect(coverage.totalRequirements, 2);
      expect(coverage.satisfiedRequirements, 1);
      expect(coverage.missingRequirements, 1);
      expect(coverage.coveragePercentage, 50);
      expect(coverage.isComplete, isFalse);
      expect(coverage.hasEvidenceGaps, isTrue);
    });

    test('category coverage ignores unrelated validation results', () {
      const legalRequirement = EvidenceRequirement(
        questionId: 'PHS_LEGAL_OC',
        label: 'Occupancy Certificate',
        type: EvidenceType.document,
      );

      const constructionRequirement = EvidenceRequirement(
        questionId: 'PHS_CONSTRUCTION_CRACKS',
        label: 'Inspection photographs',
        type: EvidenceType.photograph,
      );

      final results = [
        EvidenceValidationResult(
          requirement: legalRequirement,
          status: EvidenceValidationStatus.satisfied,
          message: 'Satisfied',
        ),
        EvidenceValidationResult(
          requirement: constructionRequirement,
          status: EvidenceValidationStatus.missing,
          message: 'Missing',
        ),
      ];

      final coverage =
          EvidenceCategoryCoverage.calculateForRequirements(
        categoryId: 'legal_ownership',
        requirements: const [legalRequirement],
        results: results,
      );

      expect(coverage.totalRequirements, 1);
      expect(coverage.satisfiedRequirements, 1);
      expect(coverage.missingRequirements, 0);
      expect(coverage.coveragePercentage, 100);
      expect(coverage.isComplete, isTrue);
      expect(coverage.hasEvidenceGaps, isFalse);
    });

    test('all canonical evidence requirements can be validated', () {
      final requirements = phsQuestions
          .expand(mapper.mapQuestion)
          .toList(growable: false);

      final results = validator.validateAll(
        requirements,
        const [],
      );

      expect(results.length, requirements.length);

      for (final result in results) {
        expect(
          result.status,
          EvidenceValidationStatus.missing,
        );
      }
    });

    test('all canonical missing requirements produce high risk signals',
        () {
      final requirements = phsQuestions
          .expand(mapper.mapQuestion)
          .toList(growable: false);

      final results = validator.validateAll(
        requirements,
        const [],
      );

      final signals = results
          .map(EvidenceRiskSignal.fromValidationResult)
          .toList(growable: false);

      expect(signals.length, requirements.length);

      for (final signal in signals) {
        expect(signal.level, EvidenceRiskLevel.high);
        expect(signal.hasRisk, isTrue);
        expect(signal.questionId, isNotEmpty);
        expect(signal.requirementLabel, isNotEmpty);
      }
    });

    test('canonical requirements have valid evidence types', () {
      final requirements = phsQuestions
          .expand(mapper.mapQuestion)
          .toList(growable: false);

      for (final requirement in requirements) {
        expect(
          EvidenceType.values,
          contains(requirement.type),
        );
      }
    });

    test('canonical requirement identities remain unique', () {
      final requirements = phsQuestions
          .expand(mapper.mapQuestion)
          .toList(growable: false);

      final identities = requirements
          .map(
            (requirement) => EvidenceRequirementKey.fromRequirement(
              requirement,
            ),
          )
          .toSet();

      expect(
        identities.length,
        requirements.length,
      );
    });
  });
}