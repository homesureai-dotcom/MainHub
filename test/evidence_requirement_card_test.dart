import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';
import 'package:homesure_ai/widgets/assessment/evidence_requirement_card.dart';

void main() {
  group('EvidenceRequirementCard', () {
    testWidgets(
      'displays document requirement',
      (tester) async {
        const requirement = EvidenceRequirement(
          questionId: 'LEGAL_OC',
          label: 'Occupancy Certificate',
          type: EvidenceType.document,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EvidenceRequirementCard(
                requirement: requirement,
              ),
            ),
          ),
        );

        expect(
          find.text('Occupancy Certificate'),
          findsOneWidget,
        );

        expect(
          find.text('Document'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'displays photograph requirement',
      (tester) async {
        const requirement = EvidenceRequirement(
          questionId: 'CONSTRUCTION_CRACKS',
          label: 'Photographs of visible cracks',
          type: EvidenceType.photograph,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EvidenceRequirementCard(
                requirement: requirement,
              ),
            ),
          ),
        );

        expect(
          find.text('Photographs of visible cracks'),
          findsOneWidget,
        );

        expect(
          find.text('Photograph'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'displays video requirement',
      (tester) async {
        const requirement = EvidenceRequirement(
          questionId: 'CONSTRUCTION_LEAKAGE',
          label: 'Video showing active leakage',
          type: EvidenceType.video,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EvidenceRequirementCard(
                requirement: requirement,
              ),
            ),
          ),
        );

        expect(
          find.text('Video showing active leakage'),
          findsOneWidget,
        );

        expect(
          find.text('Video'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'displays manual requirement',
      (tester) async {
        const requirement = EvidenceRequirement(
          questionId: 'UTILITIES_WATER',
          label: 'User-entered water availability details',
          type: EvidenceType.manual,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EvidenceRequirementCard(
                requirement: requirement,
              ),
            ),
          ),
        );

        expect(
          find.text('User-entered water availability details'),
          findsOneWidget,
        );

        expect(
          find.text('Manual'),
          findsOneWidget,
        );
      },
    );
  });
}