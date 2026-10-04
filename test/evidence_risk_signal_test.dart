import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';
import 'package:homesure_ai/core/evidence/evidence_risk_signal.dart';
import 'package:homesure_ai/core/evidence/evidence_validation_result.dart';

void main() {
  group('EvidenceRiskSignal', () {
    const requirement = EvidenceRequirement(
      questionId: 'PHS_LEGAL_OC',
      label: 'Occupancy Certificate',
      type: EvidenceType.document,
    );

    EvidenceValidationResult result(
      EvidenceValidationStatus status,
    ) {
      return EvidenceValidationResult(
        requirement: requirement,
        status: status,
        message: status.name,
      );
    }

    test('satisfied evidence produces no risk', () {
      final signal = EvidenceRiskSignal.fromValidationResult(
        result(EvidenceValidationStatus.satisfied),
      );

      expect(signal.questionId, 'PHS_LEGAL_OC');
      expect(signal.requirementLabel, 'Occupancy Certificate');
      expect(
        signal.validationStatus,
        EvidenceValidationStatus.satisfied,
      );
      expect(signal.level, EvidenceRiskLevel.none);
      expect(signal.hasRisk, isFalse);
      expect(
        signal.message,
        'Evidence requirement is satisfied.',
      );
    });

    test('provided evidence produces low risk', () {
      final signal = EvidenceRiskSignal.fromValidationResult(
        result(EvidenceValidationStatus.provided),
      );

      expect(signal.level, EvidenceRiskLevel.low);
      expect(signal.hasRisk, isTrue);
      expect(
        signal.message,
        'Evidence has been provided but is not verified.',
      );
    });

    test('needs-review evidence produces medium risk', () {
      final signal = EvidenceRiskSignal.fromValidationResult(
        result(EvidenceValidationStatus.needsReview),
      );

      expect(signal.level, EvidenceRiskLevel.medium);
      expect(signal.hasRisk, isTrue);
      expect(
        signal.message,
        'Evidence requires review.',
      );
    });

    test('missing evidence produces high risk', () {
      final signal = EvidenceRiskSignal.fromValidationResult(
        result(EvidenceValidationStatus.missing),
      );

      expect(signal.level, EvidenceRiskLevel.high);
      expect(signal.hasRisk, isTrue);
      expect(
        signal.message,
        'Required evidence has not been provided.',
      );
    });

    test('rejected evidence produces high risk', () {
      final signal = EvidenceRiskSignal.fromValidationResult(
        result(EvidenceValidationStatus.rejected),
      );

      expect(signal.level, EvidenceRiskLevel.high);
      expect(signal.hasRisk, isTrue);
      expect(
        signal.message,
        'Evidence was rejected.',
      );
    });

    test('risk mapping covers every validation status', () {
      final expectedLevels = <EvidenceValidationStatus,
          EvidenceRiskLevel>{
        EvidenceValidationStatus.satisfied:
            EvidenceRiskLevel.none,
        EvidenceValidationStatus.provided:
            EvidenceRiskLevel.low,
        EvidenceValidationStatus.needsReview:
            EvidenceRiskLevel.medium,
        EvidenceValidationStatus.missing:
            EvidenceRiskLevel.high,
        EvidenceValidationStatus.rejected:
            EvidenceRiskLevel.high,
      };

      for (final entry in expectedLevels.entries) {
        final signal = EvidenceRiskSignal.fromValidationResult(
          result(entry.key),
        );

        expect(
          signal.level,
          entry.value,
          reason:
              '${entry.key.name} should map to '
              '${entry.value.name}',
        );
      }
    });

    test('value equality works for identical risk signals', () {
      final first = EvidenceRiskSignal.fromValidationResult(
        result(EvidenceValidationStatus.missing),
      );

      final second = EvidenceRiskSignal.fromValidationResult(
        result(EvidenceValidationStatus.missing),
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('different risk signals are not equal', () {
      final missing = EvidenceRiskSignal.fromValidationResult(
        result(EvidenceValidationStatus.missing),
      );

      final provided = EvidenceRiskSignal.fromValidationResult(
        result(EvidenceValidationStatus.provided),
      );

      expect(missing, isNot(provided));
    });

    test('toString contains the key risk information', () {
      final signal = EvidenceRiskSignal.fromValidationResult(
        result(EvidenceValidationStatus.missing),
      );

      final output = signal.toString();

      expect(output, contains('PHS_LEGAL_OC'));
      expect(output, contains('Occupancy Certificate'));
      expect(output, contains('missing'));
      expect(output, contains('high'));
    });

    test('risk signals preserve the requirement identity', () {
      const anotherRequirement = EvidenceRequirement(
        questionId: 'PHS_CONSTRUCTION_CRACKS',
        label: 'Inspection photographs',
        type: EvidenceType.photograph,
      );

      final signal = EvidenceRiskSignal.fromValidationResult(
        EvidenceValidationResult(
          requirement: anotherRequirement,
          status: EvidenceValidationStatus.needsReview,
          message: 'Requires review',
        ),
      );

      expect(
        signal.questionId,
        'PHS_CONSTRUCTION_CRACKS',
      );

      expect(
        signal.requirementLabel,
        'Inspection photographs',
      );

      expect(
        signal.validationStatus,
        EvidenceValidationStatus.needsReview,
      );

      expect(
        signal.level,
        EvidenceRiskLevel.medium,
      );
    });
  });
}