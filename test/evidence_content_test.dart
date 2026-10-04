import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence_content.dart';

void main() {
  group('EvidenceContent', () {
    test('should create content with required fields', () {
      final content = EvidenceContent(
        kind: EvidenceContentKind.file,
        locator: 'file:///documents/occupancy-certificate.pdf',
      );

      expect(content.kind, EvidenceContentKind.file);
      expect(
        content.locator,
        'file:///documents/occupancy-certificate.pdf',
      );
      expect(content.label, isNull);
    });

    test('should support optional label', () {
      final content = EvidenceContent(
        kind: EvidenceContentKind.file,
        locator: 'file:///documents/occupancy-certificate.pdf',
        label: 'Occupancy Certificate PDF',
      );

      expect(content.label, 'Occupancy Certificate PDF');
    });

    test('should support all content kinds', () {
      expect(
        EvidenceContentKind.values,
        contains(EvidenceContentKind.file),
      );
      expect(
        EvidenceContentKind.values,
        contains(EvidenceContentKind.image),
      );
      expect(
        EvidenceContentKind.values,
        contains(EvidenceContentKind.video),
      );
      expect(
        EvidenceContentKind.values,
        contains(EvidenceContentKind.manual),
      );
    });

    test('copyWith should create updated content', () {
      final original = EvidenceContent(
        kind: EvidenceContentKind.file,
        locator: 'file:///documents/original.pdf',
        label: 'Original document',
      );

      final updated = original.copyWith(
        label: 'Updated document',
      );

      expect(updated.kind, original.kind);
      expect(updated.locator, original.locator);
      expect(updated.label, 'Updated document');

      expect(original.label, 'Original document');
    });

    test('should reject an empty locator', () {
      expect(
        () => EvidenceContent(
          kind: EvidenceContentKind.file,
          locator: '',
        ),
        throwsArgumentError,
      );
    });

    test('should reject a whitespace-only locator', () {
      expect(
        () => EvidenceContent(
          kind: EvidenceContentKind.file,
          locator: '   ',
        ),
        throwsArgumentError,
      );
    });
  });
}