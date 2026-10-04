import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_content.dart';

void main() {
  group('Evidence Model', () {
    test('should create evidence with required fields', () {
      final addedAt = DateTime(2026, 9, 19);

      final evidence = Evidence(
        id: 'EVIDENCE_001',
        questionId: 'LEGAL_OC',
        type: EvidenceType.document,
        name: 'Occupancy Certificate',
        status: EvidenceStatus.provided,
        source: EvidenceSource.userUpload,
        addedAt: addedAt,
      );

      expect(evidence.id, 'EVIDENCE_001');
      expect(evidence.questionId, 'LEGAL_OC');
      expect(evidence.type, EvidenceType.document);
      expect(evidence.name, 'Occupancy Certificate');
      expect(evidence.description, isNull);
      expect(evidence.content, isNull);
      expect(evidence.status, EvidenceStatus.provided);
      expect(evidence.source, EvidenceSource.userUpload);
      expect(evidence.addedAt, addedAt);
    });

    test('should support optional description', () {
      final evidence = Evidence(
        id: 'EVIDENCE_002',
        questionId: 'DOCUMENTATION_PROPERTY_TAX',
        type: EvidenceType.document,
        name: 'Latest Property Tax Receipt',
        description: 'Property tax receipt for the current financial year.',
        status: EvidenceStatus.provided,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 9, 19),
      );

      expect(
        evidence.description,
        'Property tax receipt for the current financial year.',
      );
    });

    test('should support captured content', () {
      final content = EvidenceContent(
        kind: EvidenceContentKind.file,
        locator: 'file:///documents/occupancy-certificate.pdf',
        label: 'Occupancy Certificate PDF',
      );

      final evidence = Evidence(
        id: 'EVIDENCE_003',
        questionId: 'LEGAL_OC',
        type: EvidenceType.document,
        name: 'Occupancy Certificate',
        content: content,
        status: EvidenceStatus.provided,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 9, 19),
      );

      expect(evidence.content, content);
      expect(
        evidence.content!.kind,
        EvidenceContentKind.file,
      );
      expect(
        evidence.content!.locator,
        'file:///documents/occupancy-certificate.pdf',
      );
      expect(
        evidence.content!.label,
        'Occupancy Certificate PDF',
      );
    });

    test('should identify verified evidence', () {
      final evidence = Evidence(
        id: 'EVIDENCE_004',
        questionId: 'LEGAL_OC',
        type: EvidenceType.document,
        name: 'Occupancy Certificate',
        status: EvidenceStatus.verified,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 9, 19),
      );

      expect(evidence.isVerified, isTrue);
      expect(evidence.needsReview, isFalse);
      expect(evidence.isRejected, isFalse);
    });

    test('should identify evidence requiring review', () {
      final evidence = Evidence(
        id: 'EVIDENCE_005',
        questionId: 'UTILITY_BWSSB',
        type: EvidenceType.document,
        name: 'BWSSB Document',
        status: EvidenceStatus.needsReview,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 9, 19),
      );

      expect(evidence.isVerified, isFalse);
      expect(evidence.needsReview, isTrue);
      expect(evidence.isRejected, isFalse);
    });

    test('should identify rejected evidence', () {
      final evidence = Evidence(
        id: 'EVIDENCE_006',
        questionId: 'DOCUMENTATION_BESCOM',
        type: EvidenceType.document,
        name: 'BESCOM Record',
        status: EvidenceStatus.rejected,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 9, 19),
      );

      expect(evidence.isVerified, isFalse);
      expect(evidence.needsReview, isFalse);
      expect(evidence.isRejected, isTrue);
    });

    test('copyWith should create updated evidence', () {
      final original = Evidence(
        id: 'EVIDENCE_007',
        questionId: 'LEGAL_OC',
        type: EvidenceType.document,
        name: 'Occupancy Certificate',
        status: EvidenceStatus.provided,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 9, 19),
      );

      final updated = original.copyWith(
        status: EvidenceStatus.verified,
      );

      expect(updated.id, original.id);
      expect(updated.questionId, original.questionId);
      expect(updated.type, original.type);
      expect(updated.name, original.name);
      expect(updated.content, original.content);
      expect(updated.status, EvidenceStatus.verified);
      expect(original.status, EvidenceStatus.provided);
    });

    test('copyWith should update captured content', () {
      final originalContent = EvidenceContent(
        kind: EvidenceContentKind.file,
        locator: 'file:///documents/original.pdf',
      );

      final updatedContent = EvidenceContent(
        kind: EvidenceContentKind.file,
        locator: 'file:///documents/updated.pdf',
      );

      final original = Evidence(
        id: 'EVIDENCE_008',
        questionId: 'LEGAL_OC',
        type: EvidenceType.document,
        name: 'Occupancy Certificate',
        content: originalContent,
        status: EvidenceStatus.provided,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 9, 19),
      );

      final updated = original.copyWith(
        content: updatedContent,
      );

      expect(updated.content, updatedContent);
      expect(original.content, originalContent);
    });

    test('should support all evidence types', () {
      expect(EvidenceType.values, contains(EvidenceType.document));
      expect(EvidenceType.values, contains(EvidenceType.photograph));
      expect(EvidenceType.values, contains(EvidenceType.video));
      expect(EvidenceType.values, contains(EvidenceType.manual));
    });

    test('should support all evidence statuses', () {
      expect(
        EvidenceStatus.values,
        contains(EvidenceStatus.notProvided),
      );
      expect(
        EvidenceStatus.values,
        contains(EvidenceStatus.provided),
      );
      expect(
        EvidenceStatus.values,
        contains(EvidenceStatus.verified),
      );
      expect(
        EvidenceStatus.values,
        contains(EvidenceStatus.needsReview),
      );
      expect(
        EvidenceStatus.values,
        contains(EvidenceStatus.rejected),
      );
    });
  });
}