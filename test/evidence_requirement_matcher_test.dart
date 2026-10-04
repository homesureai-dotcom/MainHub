import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement_matcher.dart';

void main() {
  group('EvidenceRequirementMatcher', () {
    const matcher = EvidenceRequirementMatcher();

    const documentRequirement = EvidenceRequirement(
      questionId: 'PHS_LEGAL_OC',
      label: 'Occupancy Certificate',
      type: EvidenceType.document,
    );

    const photographRequirement = EvidenceRequirement(
      questionId: 'PHS_CONSTRUCTION_CRACKS',
      label: 'Inspection photographs',
      type: EvidenceType.photograph,
    );

    final matchingDocument = Evidence(
      id: 'EVIDENCE_001',
      questionId: 'PHS_LEGAL_OC',
      type: EvidenceType.document,
      name: 'Occupancy Certificate.pdf',
      status: EvidenceStatus.provided,
      source: EvidenceSource.userUpload,
      addedAt: DateTime(2026, 9, 19),
    );

    final matchingPhotograph = Evidence(
      id: 'EVIDENCE_002',
      questionId: 'PHS_CONSTRUCTION_CRACKS',
      type: EvidenceType.photograph,
      name: 'Crack inspection.jpg',
      status: EvidenceStatus.provided,
      source: EvidenceSource.userUpload,
      addedAt: DateTime(2026, 9, 19),
    );

    final differentQuestionEvidence = Evidence(
      id: 'EVIDENCE_003',
      questionId: 'PHS_LEGAL_KHATA',
      type: EvidenceType.document,
      name: 'Khata Certificate.pdf',
      status: EvidenceStatus.provided,
      source: EvidenceSource.userUpload,
      addedAt: DateTime(2026, 9, 19),
    );

    final differentTypeEvidence = Evidence(
      id: 'EVIDENCE_004',
      questionId: 'PHS_LEGAL_OC',
      type: EvidenceType.photograph,
      name: 'OC photograph.jpg',
      status: EvidenceStatus.provided,
      source: EvidenceSource.userUpload,
      addedAt: DateTime(2026, 9, 19),
    );

    test('matches evidence when question ID and type both match', () {
      expect(
        matcher.matches(
          matchingDocument,
          documentRequirement,
        ),
        isTrue,
      );
    });

    test('does not match evidence from a different question', () {
      expect(
        matcher.matches(
          differentQuestionEvidence,
          documentRequirement,
        ),
        isFalse,
      );
    });

    test('does not match evidence with a different evidence type', () {
      expect(
        matcher.matches(
          differentTypeEvidence,
          documentRequirement,
        ),
        isFalse,
      );
    });

    test('matches photograph evidence with the corresponding requirement',
        () {
      expect(
        matcher.matches(
          matchingPhotograph,
          photographRequirement,
        ),
        isTrue,
      );
    });

    test('matchingEvidence returns only matching evidence', () {
      final evidence = [
        matchingDocument,
        differentQuestionEvidence,
        differentTypeEvidence,
        matchingPhotograph,
      ];

      final matches = matcher.matchingEvidence(
        documentRequirement,
        evidence,
      );

      expect(
        matches,
        [matchingDocument],
      );
    });

    test('matchingEvidence returns an empty list when nothing matches', () {
      final matches = matcher.matchingEvidence(
        documentRequirement,
        [
          differentQuestionEvidence,
          differentTypeEvidence,
        ],
      );

      expect(matches, isEmpty);
    });

    test('hasMatch returns true when matching evidence exists', () {
      expect(
        matcher.hasMatch(
          documentRequirement,
          [
            differentQuestionEvidence,
            matchingDocument,
          ],
        ),
        isTrue,
      );
    });

    test('hasMatch returns false when no matching evidence exists', () {
      expect(
        matcher.hasMatch(
          documentRequirement,
          [
            differentQuestionEvidence,
            differentTypeEvidence,
          ],
        ),
        isFalse,
      );
    });

    test('matchingEvidence does not mutate the supplied evidence list', () {
      final evidence = [
        matchingDocument,
        differentQuestionEvidence,
      ];

      final originalLength = evidence.length;

      matcher.matchingEvidence(
        documentRequirement,
        evidence,
      );

      expect(evidence.length, originalLength);
      expect(evidence, [
        matchingDocument,
        differentQuestionEvidence,
      ]);
    });

    test('hasMatch does not depend on evidence status', () {
      final verifiedEvidence = matchingDocument.copyWith(
        status: EvidenceStatus.verified,
      );

      final rejectedEvidence = matchingDocument.copyWith(
        status: EvidenceStatus.rejected,
      );

      expect(
        matcher.hasMatch(
          documentRequirement,
          [verifiedEvidence],
        ),
        isTrue,
      );

      expect(
        matcher.hasMatch(
          documentRequirement,
          [rejectedEvidence],
        ),
        isTrue,
      );
    });
  });
}