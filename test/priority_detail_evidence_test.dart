import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_validation_result.dart';
import 'package:homesure_ai/core/evidence/in_memory_evidence_repository.dart';
import 'package:homesure_ai/features/dashboard/models/dashboard_priority.dart';
import 'package:homesure_ai/models/property_health/recommendation.dart';
import 'package:homesure_ai/screens/dashboard/priority_detail_screen.dart';

void main() {
  group('PriorityDetailScreen evidence', () {
    DashboardPriority createPriority() {
      return const DashboardPriority(
        id: 'OBTAIN_SD',
        title: 'Obtain Registered Sale Deed',
        description:
            'Complete registration and obtain the Sale Deed.',
        priority: RecommendationPriority.critical,
        estimatedPHIGain: 25,
        requiredDocuments: [
          'Registered Sale Deed',
        ],
      );
    }

    Evidence createEvidence({
      String id = 'E1',
      EvidenceStatus status = EvidenceStatus.provided,
    }) {
      return Evidence(
        id: id,
        questionId: 'LEGAL_SD',
        requirementId: Evidence.requirementKey(
          questionId: 'LEGAL_SD',
          label: 'Registered Sale Deed',
        ),
        type: EvidenceType.document,
        name: 'Registered Sale Deed',
        status: status,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 10, 14),
      );
    }

    Future<void> pumpScreen(
      WidgetTester tester, {
      required InMemoryEvidenceRepository repository,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PriorityDetailScreen(
            priority: createPriority(),
            evidenceRepository: repository,
          ),
        ),
      );

      await tester.pumpAndSettle();
    }

    testWidgets(
      'shows missing evidence when no evidence exists',
      (tester) async {
        final repository = InMemoryEvidenceRepository();

        await pumpScreen(
          tester,
          repository: repository,
        );

        expect(
          find.text('Evidence'),
          findsOneWidget,
        );

        expect(
          find.text('MISSING'),
          findsOneWidget,
        );

        expect(
          find.text(
            'Required evidence has not been provided.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows provided evidence when evidence exists but is not verified',
      (tester) async {
        final repository = InMemoryEvidenceRepository();

        await repository.add(
          createEvidence(
            status: EvidenceStatus.provided,
          ),
        );

        await pumpScreen(
          tester,
          repository: repository,
        );

        expect(
          find.text('PROVIDED'),
          findsOneWidget,
        );

        expect(
          find.text(
            'Evidence has been provided but is not verified.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows satisfied evidence when evidence is verified',
      (tester) async {
        final repository = InMemoryEvidenceRepository();

        await repository.add(
          createEvidence(
            status: EvidenceStatus.verified,
          ),
        );

        await pumpScreen(
          tester,
          repository: repository,
        );

        expect(
          find.text('SATISFIED'),
          findsOneWidget,
        );

        expect(
          find.text(
            'Evidence requirement is satisfied.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows needs review when evidence requires review',
      (tester) async {
        final repository = InMemoryEvidenceRepository();

        await repository.add(
          createEvidence(
            status: EvidenceStatus.needsReview,
          ),
        );

        await pumpScreen(
          tester,
          repository: repository,
        );

        expect(
          find.text('NEEDS REVIEW'),
          findsOneWidget,
        );

        expect(
          find.text('Evidence requires review.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows rejected when evidence has been rejected',
      (tester) async {
        final repository = InMemoryEvidenceRepository();

        await repository.add(
          createEvidence(
            status: EvidenceStatus.rejected,
          ),
        );

        await pumpScreen(
          tester,
          repository: repository,
        );

        expect(
          find.text('REJECTED'),
          findsOneWidget,
        );

        expect(
          find.text('Evidence was rejected.'),
          findsOneWidget,
        );
      },
    );
  });
}