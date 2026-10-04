import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';
import 'package:homesure_ai/core/phs/phs_question.dart';
import 'package:homesure_ai/widgets/assessment/add_evidence_button.dart';
import 'package:homesure_ai/widgets/assessment/evidence_item_card.dart';
import 'package:homesure_ai/widgets/assessment/question_card.dart';

void main() {
  final question = PHSQuestion(
    id: 'LEGAL_OC',
    category: PHSCategory.legalOwnership,
    title: 'Do you have the Occupancy Certificate?',
    helpText:
        'Check whether the project has received its Occupancy Certificate.',
    whyItMatters:
        'The Occupancy Certificate confirms permitted occupancy.',
    impact:
        'Missing documentation may create ownership and compliance risks.',
    priority: QuestionPriority.high,
    potentialPHIGain: 10,
    weight: 10,
    requiredEvidence: const [
      'Occupancy Certificate',
    ],
    applicableTo: const [],
    mandatory: true,
    phsVersion: '1.0',
  );

  final questionWithTwoRequirements = PHSQuestion(
    id: 'LEGAL_OC_TWO',
    category: PHSCategory.legalOwnership,
    title: 'Do you have the Occupancy Certificate?',
    helpText:
        'Check whether the project has received its Occupancy Certificate.',
    whyItMatters:
        'The Occupancy Certificate confirms permitted occupancy.',
    impact:
        'Missing documentation may create ownership and compliance risks.',
    priority: QuestionPriority.high,
    potentialPHIGain: 10,
    weight: 10,
    requiredEvidence: const [
      'Occupancy Certificate',
      'OC approval/reference details',
    ],
    applicableTo: const [],
    mandatory: true,
    phsVersion: '1.0',
  );

  Evidence buildEvidence({
    String id = 'EVIDENCE_001',
    String name = 'Occupancy Certificate',
    EvidenceStatus status = EvidenceStatus.provided,
  }) {
    return Evidence(
      id: id,
      questionId: 'LEGAL_OC',
      type: EvidenceType.document,
      name: name,
      status: status,
      source: EvidenceSource.userUpload,
      addedAt: DateTime(2026, 9, 19),
    );
  }

  Evidence buildTwoRequirementEvidence({
    String id = 'EVIDENCE_TWO_001',
    String name = 'Occupancy Certificate',
  }) {
    return Evidence(
      id: id,
      questionId: 'LEGAL_OC_TWO',
      type: EvidenceType.document,
      name: name,
      status: EvidenceStatus.provided,
      source: EvidenceSource.userUpload,
      addedAt: DateTime(2026, 9, 19),
    );
  }

  Widget buildQuestionCard({
    PHSQuestion? cardQuestion,
    List<Evidence> evidence = const [],
    ValueChanged<EvidenceType>? onEvidenceTypeSelected,
    ValueChanged<Evidence>? onEvidenceStatusChange,
    ValueChanged<Evidence>? onEvidenceDelete,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: QuestionCard(
            question: cardQuestion ?? question,
            suppliedEvidence: evidence,
            onEvidenceTypeSelected: onEvidenceTypeSelected,
            onEvidenceStatusChange: onEvidenceStatusChange,
            onEvidenceDelete: onEvidenceDelete,
          ),
        ),
      ),
    );
  }

  group('QuestionCard evidence coverage', () {
    testWidgets(
      'shows complete coverage when all requirements are matched',
      (tester) async {
        await tester.pumpWidget(
          buildQuestionCard(
            evidence: [
              buildEvidence(),
            ],
          ),
        );

        expect(
          find.text('Evidence coverage'),
          findsOneWidget,
        );

        expect(
          find.text('100%'),
          findsOneWidget,
        );

        expect(
          find.text('1 of 1 evidence requirements met'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows zero coverage when no evidence is supplied',
      (tester) async {
        await tester.pumpWidget(
          buildQuestionCard(),
        );

        expect(
          find.text('Evidence coverage'),
          findsOneWidget,
        );

        expect(
          find.text('0%'),
          findsOneWidget,
        );

        expect(
          find.text(
            '0 of 1 evidence requirements met · 1 missing',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows partial coverage when some requirements are matched',
      (tester) async {
        await tester.pumpWidget(
          buildQuestionCard(
            cardQuestion: questionWithTwoRequirements,
            evidence: [
              buildTwoRequirementEvidence(),
            ],
          ),
        );

        expect(
          find.text('Evidence coverage'),
          findsOneWidget,
        );

        expect(
          find.text('50%'),
          findsOneWidget,
        );

        expect(
          find.text(
            '1 of 2 evidence requirements met · 1 missing',
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('QuestionCard supplied evidence', () {
    testWidgets(
      'does not display supplied evidence section when no evidence exists',
      (tester) async {
        await tester.pumpWidget(
          buildQuestionCard(),
        );

        expect(
          find.text('Evidence provided'),
          findsNothing,
        );

        expect(
          find.byType(EvidenceItemCard),
          findsNothing,
        );
      },
    );

    testWidgets(
      'displays supplied evidence section when evidence exists',
      (tester) async {
        await tester.pumpWidget(
          buildQuestionCard(
            evidence: [
              buildEvidence(),
            ],
          ),
        );

        expect(
          find.text('Evidence provided'),
          findsOneWidget,
        );

        expect(
          find.byType(EvidenceItemCard),
          findsOneWidget,
        );

        expect(
          find.text('Occupancy Certificate'),
          findsWidgets,
        );
      },
    );

    testWidgets(
      'displays supplied evidence status',
      (tester) async {
        await tester.pumpWidget(
          buildQuestionCard(
            evidence: [
              buildEvidence(
                status: EvidenceStatus.verified,
              ),
            ],
          ),
        );

        expect(
          find.text('Verified'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'displays Add Evidence entry point',
      (tester) async {
        await tester.pumpWidget(
          buildQuestionCard(),
        );

        expect(
          find.byType(AddEvidenceButton),
          findsOneWidget,
        );

        expect(
          find.text('Add Evidence'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'returns selected evidence type through callback',
      (tester) async {
        EvidenceType? selectedType;

        await tester.pumpWidget(
          buildQuestionCard(
            onEvidenceTypeSelected: (type) {
              selectedType = type;
            },
          ),
        );

        final addEvidenceButton = find.text('Add Evidence');

        expect(
          addEvidenceButton,
          findsOneWidget,
        );

        await tester.ensureVisible(
          addEvidenceButton,
        );

        await tester.pumpAndSettle();

        await tester.tap(
          addEvidenceButton,
        );

        await tester.pumpAndSettle();

        final actionSheetDocument =
            find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data == 'Document' &&
              widget.style?.fontSize == 15 &&
              widget.style?.fontWeight == FontWeight.w700,
        );

        expect(
          actionSheetDocument,
          findsOneWidget,
        );

        await tester.tap(
          actionSheetDocument,
        );

        await tester.pumpAndSettle();

        expect(
          selectedType,
          EvidenceType.document,
        );
      },
    );

    testWidgets(
      'forwards evidence status changes through callback',
      (tester) async {
        Evidence? updatedEvidence;

        final evidence = buildEvidence(
          status: EvidenceStatus.provided,
        );

        await tester.pumpWidget(
          buildQuestionCard(
            evidence: [
              evidence,
            ],
            onEvidenceStatusChange: (updated) {
              updatedEvidence = updated;
            },
          ),
        );

        final updateStatusButton = find.text('Update Status');

        expect(
          updateStatusButton,
          findsOneWidget,
        );

        await tester.ensureVisible(
          updateStatusButton,
        );

        await tester.pumpAndSettle();

        await tester.tap(
          updateStatusButton,
        );

        await tester.pumpAndSettle();

        expect(
          updatedEvidence,
          isNotNull,
        );

        expect(
          updatedEvidence!.id,
          evidence.id,
        );

        expect(
          updatedEvidence!.questionId,
          evidence.questionId,
        );

        expect(
          updatedEvidence!.type,
          evidence.type,
        );

        expect(
          updatedEvidence!.status,
          EvidenceStatus.needsReview,
        );
      },
    );

    testWidgets(
      'forwards evidence deletion through callback',
      (tester) async {
        Evidence? deletedEvidence;

        final evidence = buildEvidence();

        await tester.pumpWidget(
          buildQuestionCard(
            evidence: [
              evidence,
            ],
            onEvidenceDelete: (deleted) {
              deletedEvidence = deleted;
            },
          ),
        );

        final deleteButton = find.text('Delete');

        expect(
          deleteButton,
          findsOneWidget,
        );

        await tester.ensureVisible(
          deleteButton,
        );

        await tester.pumpAndSettle();

        await tester.tap(
          deleteButton,
        );

        await tester.pumpAndSettle();

        expect(
          deletedEvidence,
          isNotNull,
        );

        expect(
          deletedEvidence!.id,
          evidence.id,
        );

        expect(
          deletedEvidence!.questionId,
          evidence.questionId,
        );

        expect(
          deletedEvidence!.name,
          evidence.name,
        );
      },
    );
  });
}