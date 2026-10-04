import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_status_rules.dart';

void main() {
  group('EvidenceStatusRules', () {
    late EvidenceStatusRules rules;

    setUp(() {
      rules = const EvidenceStatusRules();
    });

    test('notProvided can transition to provided', () {
      expect(
        rules.canTransition(
          EvidenceStatus.notProvided,
          EvidenceStatus.provided,
        ),
        isTrue,
      );
    });

    test('provided can transition to needsReview', () {
      expect(
        rules.canTransition(
          EvidenceStatus.provided,
          EvidenceStatus.needsReview,
        ),
        isTrue,
      );
    });

    test('provided can transition directly to verified', () {
      expect(
        rules.canTransition(
          EvidenceStatus.provided,
          EvidenceStatus.verified,
        ),
        isTrue,
      );
    });

    test('provided can transition to rejected', () {
      expect(
        rules.canTransition(
          EvidenceStatus.provided,
          EvidenceStatus.rejected,
        ),
        isTrue,
      );
    });

    test('needsReview can transition to verified', () {
      expect(
        rules.canTransition(
          EvidenceStatus.needsReview,
          EvidenceStatus.verified,
        ),
        isTrue,
      );
    });

    test('needsReview can transition to rejected', () {
      expect(
        rules.canTransition(
          EvidenceStatus.needsReview,
          EvidenceStatus.rejected,
        ),
        isTrue,
      );
    });

    test('verified cannot transition to another status', () {
      expect(
        rules.canTransition(
          EvidenceStatus.verified,
          EvidenceStatus.provided,
        ),
        isFalse,
      );

      expect(
        rules.canTransition(
          EvidenceStatus.verified,
          EvidenceStatus.needsReview,
        ),
        isFalse,
      );

      expect(
        rules.canTransition(
          EvidenceStatus.verified,
          EvidenceStatus.rejected,
        ),
        isFalse,
      );
    });

    test('rejected cannot transition to another status', () {
      expect(
        rules.canTransition(
          EvidenceStatus.rejected,
          EvidenceStatus.provided,
        ),
        isFalse,
      );

      expect(
        rules.canTransition(
          EvidenceStatus.rejected,
          EvidenceStatus.needsReview,
        ),
        isFalse,
      );

      expect(
        rules.canTransition(
          EvidenceStatus.rejected,
          EvidenceStatus.verified,
        ),
        isFalse,
      );
    });

    test('notProvided cannot transition directly to verified', () {
      expect(
        rules.canTransition(
          EvidenceStatus.notProvided,
          EvidenceStatus.verified,
        ),
        isFalse,
      );
    });

    test('notProvided cannot transition directly to rejected', () {
      expect(
        rules.canTransition(
          EvidenceStatus.notProvided,
          EvidenceStatus.rejected,
        ),
        isFalse,
      );
    });

    test('same status is treated as a valid no-op transition', () {
      for (final status in EvidenceStatus.values) {
        expect(
          rules.canTransition(status, status),
          isTrue,
          reason: '${status.name} should allow a no-op transition',
        );
      }
    });

    test('allowedTransitions returns the expected transitions', () {
      expect(
        rules.allowedTransitions(EvidenceStatus.notProvided),
        [
          EvidenceStatus.notProvided,
          EvidenceStatus.provided,
        ],
      );

      expect(
        rules.allowedTransitions(EvidenceStatus.provided),
        [
          EvidenceStatus.provided,
          EvidenceStatus.verified,
          EvidenceStatus.needsReview,
          EvidenceStatus.rejected,
        ],
      );

      expect(
        rules.allowedTransitions(EvidenceStatus.needsReview),
        [
          EvidenceStatus.verified,
          EvidenceStatus.needsReview,
          EvidenceStatus.rejected,
        ],
      );

      expect(
        rules.allowedTransitions(EvidenceStatus.verified),
        [
          EvidenceStatus.verified,
        ],
      );

      expect(
        rules.allowedTransitions(EvidenceStatus.rejected),
        [
          EvidenceStatus.rejected,
        ],
      );
    });

    test('validateTransition accepts a valid transition', () {
      expect(
        () => rules.validateTransition(
          EvidenceStatus.provided,
          EvidenceStatus.needsReview,
        ),
        returnsNormally,
      );
    });

    test('validateTransition rejects an invalid transition', () {
      expect(
        () => rules.validateTransition(
          EvidenceStatus.verified,
          EvidenceStatus.provided,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}