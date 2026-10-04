import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_type_mapper.dart';

void main() {
  group('EvidenceTypeMapper', () {
    late EvidenceTypeMapper mapper;

    setUp(() {
      mapper = const EvidenceTypeMapper();
    });

    test('should classify document evidence as document', () {
      expect(
        mapper.map('Occupancy Certificate'),
        EvidenceType.document,
      );

      expect(
        mapper.map('Registered Sale Deed'),
        EvidenceType.document,
      );

      expect(
        mapper.map('BESCOM documents'),
        EvidenceType.document,
      );

      expect(
        mapper.map('Fire NOC'),
        EvidenceType.document,
      );
    });

    test('should classify photograph evidence as photograph', () {
      expect(
        mapper.map('Inspection photographs'),
        EvidenceType.photograph,
      );

      expect(
        mapper.map('Site inspection photographs'),
        EvidenceType.photograph,
      );
    });

    test('should classify photo evidence case-insensitively', () {
      expect(
        mapper.map('Inspection Photographs'),
        EvidenceType.photograph,
      );

      expect(
        mapper.map('PHOTO evidence'),
        EvidenceType.photograph,
      );
    });

    test('should classify explicit video evidence as video', () {
      expect(
        mapper.map('Inspection video'),
        EvidenceType.video,
      );

      expect(
        mapper.map('Video evidence'),
        EvidenceType.video,
      );
    });

    test('should default unknown evidence labels to document', () {
      expect(
        mapper.map('Structural engineer report'),
        EvidenceType.document,
      );

      expect(
        mapper.map('Association financial records'),
        EvidenceType.document,
      );

      expect(
        mapper.map('Operational test records'),
        EvidenceType.document,
      );
    });

    test('should map all evidence labels in order', () {
      final labels = [
        'Occupancy Certificate',
        'Inspection photographs',
        'Fire NOC',
        'Maintenance records',
      ];

      final result = mapper.mapAll(labels);

      expect(
        result,
        [
          EvidenceType.document,
          EvidenceType.photograph,
          EvidenceType.document,
          EvidenceType.document,
        ],
      );
    });

    test('should return an empty list for empty evidence requirements', () {
      expect(
        mapper.mapAll(const []),
        isEmpty,
      );
    });
  });
}