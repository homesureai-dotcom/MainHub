import 'package:flutter_test/flutter_test.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement_matcher.dart';
import 'package:homesure_ai/core/evidence/evidence_validator.dart';
import 'package:homesure_ai/core/evidence/assessment_evidence_validation_service.dart';
import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_category_coverage.dart';
import 'package:homesure_ai/core/evidence/evidence_coverage.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';
import 'package:homesure_ai/core/evidence/evidence_risk_signal.dart';
import 'package:homesure_ai/core/evidence/evidence_validation_result.dart';

void main() {
  group('AssessmentEvidenceValidationService', () {
    late AssessmentEvidenceValidationService service;

    const occupancyRequirement = EvidenceRequirement(
      questionId: 'LEGAL_OC',
      label: 'Occupancy Certificate',
      type: EvidenceType.document,
    );

    const ocReferenceRequirement = EvidenceRequirement(
      questionId: 'LEGAL_OC',
      label: 'OC approval/reference details',
      type: EvidenceType.document,
    );

    const saleDeedRequirement = EvidenceRequirement(
      questionId: 'LEGAL_SD',
      label: 'Registered Sale Deed',
      type: EvidenceType.document,
    );

    final addedAt = DateTime(2026, 1, 1);

    Evidence createEvidence({
      required String id,
      required String questionId,
      required String name,
      required String requirementId,
      EvidenceStatus status = EvidenceStatus.provided,
    }) {
      return Evidence(
        id: id,
        questionId: questionId,
        requirementId: requirementId,
        type: EvidenceType.document,
        name: name,
        status: status,
        source: EvidenceSource.userUpload,
        addedAt: addedAt,
      );
    }

    setUp(() {
      service = const AssessmentEvidenceValidationService(
        validator: _TestEvidenceValidator(),
        matcher: _TestEvidenceRequirementMatcher(),
      );
    });

    test('validates all supplied requirements', () {
      final evidence = [
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          name: 'Occupancy Certificate',
          requirementId: Evidence.requirementKey(
            questionId: 'LEGAL_OC',
            label: 'Occupancy Certificate',
          ),
          status: EvidenceStatus.verified,
        ),
        createEvidence(
          id: 'E2',
          questionId: 'LEGAL_SD',
          name: 'Registered Sale Deed',
          requirementId: Evidence.requirementKey(
            questionId: 'LEGAL_SD',
            label: 'Registered Sale Deed',
          ),
          status: EvidenceStatus.verified,
        ),
      ];

      final results = service.validate(
        [
          occupancyRequirement,
          saleDeedRequirement,
        ],
        evidence,
      );

      expect(results.length, 2);
      expect(
        results.every(
          (result) => result.status ==
              EvidenceValidationStatus.satisfied,
        ),
        isTrue,
      );
    });

    test('calculates complete evidence coverage', () {
      final evidence = [
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          name: 'Occupancy Certificate',
          requirementId: Evidence.requirementKey(
            questionId: 'LEGAL_OC',
            label: 'Occupancy Certificate',
          ),
          status: EvidenceStatus.verified,
        ),
        createEvidence(
          id: 'E2',
          questionId: 'LEGAL_SD',
          name: 'Registered Sale Deed',
          requirementId: Evidence.requirementKey(
            questionId: 'LEGAL_SD',
            label: 'Registered Sale Deed',
          ),
          status: EvidenceStatus.verified,
        ),
      ];

      final coverage = service.calculateCoverage(
        [
          occupancyRequirement,
          saleDeedRequirement,
        ],
        evidence,
      );

      expect(coverage, isA<EvidenceCoverage>());
      expect(coverage.totalRequirements, 2);
      expect(coverage.satisfiedRequirements, 2);
      expect(coverage.coveragePercentage, 100);
      expect(coverage.isComplete, isTrue);
    });

    test('calculates incomplete evidence coverage', () {
      final evidence = [
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          name: 'Occupancy Certificate',
          requirementId: Evidence.requirementKey(
            questionId: 'LEGAL_OC',
            label: 'Occupancy Certificate',
          ),
          status: EvidenceStatus.verified,
        ),
      ];

      final coverage = service.calculateCoverage(
        [
          occupancyRequirement,
          saleDeedRequirement,
        ],
        evidence,
      );

      expect(coverage.totalRequirements, 2);
      expect(coverage.satisfiedRequirements, 1);
      expect(coverage.missingRequirements, 1);
      expect(coverage.coveragePercentage, 50);
      expect(coverage.isComplete, isFalse);
    });

    test('calculates category coverage', () {
      final evidence = [
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          name: 'Occupancy Certificate',
          requirementId: Evidence.requirementKey(
            questionId: 'LEGAL_OC',
            label: 'Occupancy Certificate',
          ),
          status: EvidenceStatus.verified,
        ),
        createEvidence(
          id: 'E2',
          questionId: 'LEGAL_OC',
          name: 'OC approval/reference details',
          requirementId: Evidence.requirementKey(
            questionId: 'LEGAL_OC',
            label: 'OC approval/reference details',
          ),
          status: EvidenceStatus.verified,
        ),
      ];

      final coverage = service.calculateCategoryCoverage(
        categoryId: 'LEGAL_OWNERSHIP',
        requirements: [
          occupancyRequirement,
          ocReferenceRequirement,
        ],
        evidence: evidence,
      );

      expect(
        coverage,
        isA<EvidenceCategoryCoverage>(),
      );
      expect(coverage.categoryId, 'LEGAL_OWNERSHIP');
      expect(coverage.totalRequirements, 2);
      expect(coverage.satisfiedRequirements, 2);
      expect(coverage.coveragePercentage, 100);
      expect(coverage.isComplete, isTrue);
    });

    test('generates risk signals for evidence gaps', () {
      final evidence = [
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          name: 'Occupancy Certificate',
          requirementId: Evidence.requirementKey(
            questionId: 'LEGAL_OC',
            label: 'Occupancy Certificate',
          ),
          status: EvidenceStatus.verified,
        ),
      ];

      final signals = service.generateRiskSignals(
        [
          occupancyRequirement,
          saleDeedRequirement,
        ],
        evidence,
      );

      expect(signals.length, 2);
      expect(
        signals,
        everyElement(isA<EvidenceRiskSignal>()),
      );

      expect(
        signals[0].level,
        EvidenceRiskLevel.none,
      );

      expect(
        signals[1].level,
        EvidenceRiskLevel.high,
      );
    });

    test('returns missing requirements', () {
      final evidence = [
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          name: 'Occupancy Certificate',
          requirementId: Evidence.requirementKey(
            questionId: 'LEGAL_OC',
            label: 'Occupancy Certificate',
          ),
          status: EvidenceStatus.verified,
        ),
      ];

      final missing = service.getMissingRequirements(
        [
          occupancyRequirement,
          saleDeedRequirement,
        ],
        evidence,
      );

      expect(missing, [saleDeedRequirement]);
    });

    test('reports when all requirements have matching evidence', () {
      final evidence = [
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          name: 'Occupancy Certificate',
          requirementId: Evidence.requirementKey(
            questionId: 'LEGAL_OC',
            label: 'Occupancy Certificate',
          ),
        ),
        createEvidence(
          id: 'E2',
          questionId: 'LEGAL_SD',
          name: 'Registered Sale Deed',
          requirementId: Evidence.requirementKey(
            questionId: 'LEGAL_SD',
            label: 'Registered Sale Deed',
          ),
        ),
      ];

      expect(
        service.hasEvidenceForAllRequirements(
          [
            occupancyRequirement,
            saleDeedRequirement,
          ],
          evidence,
        ),
        isTrue,
      );
    });

    test('reports when at least one requirement is missing', () {
      final evidence = [
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          name: 'Occupancy Certificate',
          requirementId: Evidence.requirementKey(
            questionId: 'LEGAL_OC',
            label: 'Occupancy Certificate',
          ),
        ),
      ];

      expect(
        service.hasEvidenceForAllRequirements(
          [
            occupancyRequirement,
            saleDeedRequirement,
          ],
          evidence,
        ),
        isFalse,
      );
    });

    test('returns matching evidence for a requirement', () {
      final matching = createEvidence(
        id: 'E1',
        questionId: 'LEGAL_OC',
        name: 'Occupancy Certificate',
        requirementId: Evidence.requirementKey(
          questionId: 'LEGAL_OC',
          label: 'Occupancy Certificate',
        ),
      );

      final unrelated = createEvidence(
        id: 'E2',
        questionId: 'LEGAL_SD',
        name: 'Registered Sale Deed',
        requirementId: Evidence.requirementKey(
          questionId: 'LEGAL_SD',
          label: 'Registered Sale Deed',
        ),
      );

      final result = service.getMatchingEvidence(
        occupancyRequirement,
        [
          matching,
          unrelated,
        ],
      );

      expect(result, [matching]);
    });

    test('returns evidence gaps from validation results', () {
      final evidence = [
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          name: 'Occupancy Certificate',
          requirementId: Evidence.requirementKey(
            questionId: 'LEGAL_OC',
            label: 'Occupancy Certificate',
          ),
          status: EvidenceStatus.verified,
        ),
      ];

      final gaps = service.getEvidenceGaps(
        [
          occupancyRequirement,
          saleDeedRequirement,
        ],
        evidence,
      );

      expect(gaps.length, 1);
      expect(
        gaps.single.requirement,
        saleDeedRequirement,
      );
      expect(
        gaps.single.isSatisfied,
        isFalse,
      );
    });

    test('returns no evidence gaps when all requirements are satisfied',
        () {
      final evidence = [
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          name: 'Occupancy Certificate',
          requirementId: Evidence.requirementKey(
            questionId: 'LEGAL_OC',
            label: 'Occupancy Certificate',
          ),
          status: EvidenceStatus.verified,
        ),
        createEvidence(
          id: 'E2',
          questionId: 'LEGAL_SD',
          name: 'Registered Sale Deed',
          requirementId: Evidence.requirementKey(
            questionId: 'LEGAL_SD',
            label: 'Registered Sale Deed',
          ),
          status: EvidenceStatus.verified,
        ),
      ];

      final gaps = service.getEvidenceGaps(
        [
          occupancyRequirement,
          saleDeedRequirement,
        ],
        evidence,
      );

      expect(gaps, isEmpty);
    });

    test('handles an empty requirement set', () {
      final evidence = createEvidence(
        id: 'E1',
        questionId: 'LEGAL_OC',
        name: 'Occupancy Certificate',
        requirementId: Evidence.requirementKey(
          questionId: 'LEGAL_OC',
          label: 'Occupancy Certificate',
        ),
      );

      expect(
        service.validate([], [evidence]),
        isEmpty,
      );

      expect(
        service.hasEvidenceForAllRequirements([], [evidence]),
        isTrue,
      );

      expect(
        service.getMissingRequirements([], [evidence]),
        isEmpty,
      );

      expect(
        service.getEvidenceGaps([], [evidence]),
        isEmpty,
      );
    });
  });
}

/// Test adapter used to keep the service tests deterministic.
///
/// It delegates to the production behavior while allowing the service
/// dependencies to remain explicit.
class _TestEvidenceValidator implements EvidenceValidator {
  const _TestEvidenceValidator();

  @override
  EvidenceValidationResult validate(
    EvidenceRequirement requirement,
    List<Evidence> evidence,
  ) {
    final requirementId = Evidence.requirementKey(
      questionId: requirement.questionId,
      label: requirement.label,
    );

    final matches = evidence.where(
      (item) =>
          item.questionId == requirement.questionId &&
          item.requirementId == requirementId &&
          item.type == requirement.type,
    );

    if (matches.any(
      (item) => item.status == EvidenceStatus.verified,
    )) {
      return EvidenceValidationResult(
        requirement: requirement,
        status: EvidenceValidationStatus.satisfied,
        message: 'Evidence requirement is satisfied.',
      );
    }

    if (matches.any(
      (item) => item.status == EvidenceStatus.needsReview,
    )) {
      return EvidenceValidationResult(
        requirement: requirement,
        status: EvidenceValidationStatus.needsReview,
        message: 'Evidence requires review.',
      );
    }

    if (matches.any(
      (item) => item.status == EvidenceStatus.provided,
    )) {
      return EvidenceValidationResult(
        requirement: requirement,
        status: EvidenceValidationStatus.provided,
        message: 'Evidence has been provided but is not verified.',
      );
    }

    if (matches.any(
      (item) => item.status == EvidenceStatus.rejected,
    )) {
      return EvidenceValidationResult(
        requirement: requirement,
        status: EvidenceValidationStatus.rejected,
        message: 'Evidence was rejected.',
      );
    }

    return EvidenceValidationResult(
      requirement: requirement,
      status: EvidenceValidationStatus.missing,
      message: 'Required evidence has not been provided.',
    );
  }

  @override
  List<EvidenceValidationResult> validateAll(
    List<EvidenceRequirement> requirements,
    List<Evidence> evidence,
  ) {
    return requirements
        .map(
          (requirement) => validate(
            requirement,
            evidence,
          ),
        )
        .toList(growable: false);
  }
}

class _TestEvidenceRequirementMatcher
    implements EvidenceRequirementMatcher {
  const _TestEvidenceRequirementMatcher();

  @override
  bool matches(
    Evidence evidence,
    EvidenceRequirement requirement,
  ) {
    final requirementId = Evidence.requirementKey(
      questionId: requirement.questionId,
      label: requirement.label,
    );

    return evidence.questionId == requirement.questionId &&
        evidence.requirementId == requirementId &&
        evidence.type == requirement.type;
  }

  @override
  List<Evidence> matchingEvidence(
    EvidenceRequirement requirement,
    List<Evidence> evidence,
  ) {
    return evidence
        .where(
          (item) => matches(
            item,
            requirement,
          ),
        )
        .toList(growable: false);
  }

  @override
  bool hasMatch(
    EvidenceRequirement requirement,
    List<Evidence> evidence,
  ) {
    return evidence.any(
      (item) => matches(
        item,
        requirement,
      ),
    );
  }
}