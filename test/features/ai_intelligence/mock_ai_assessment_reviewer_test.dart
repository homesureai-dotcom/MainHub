import 'package:flutter_test/flutter_test.dart';
import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_content.dart';
import 'package:homesure_ai/core/phs/phs_answer.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';
import 'package:homesure_ai/core/phs/phs_question.dart';
import 'package:homesure_ai/features/ai_intelligence/services/mock_ai_assessment_reviewer.dart';

void main() {
  const reviewer = MockAiAssessmentReviewer();

  const question = PHSQuestion(
    id: 'LEGAL_OC',
    category: PHSCategory.legalOwnership,
    title: 'Is the Occupancy Certificate available?',
    helpText: 'Check whether the certificate is available.',
    whyItMatters: 'It supports the occupancy approval review.',
    impact: 'Missing approval may require follow-up.',
    priority: QuestionPriority.critical,
    weight: 10,
    requiredEvidence: ['Occupancy Certificate'],
    applicableTo: [PropertyType.apartment],
  );

  group('MockAiAssessmentReviewer', () {
    test('flags a No answer without changing assessment data', () {
      final request = AiAssessmentReviewRequest.fromAssessment(
        questions: const [question],
        answers: const [
          PHSAnswer(questionId: 'LEGAL_OC', response: PHSResponse.no),
        ],
        evidence: const [],
      );

      final result = reviewer.review(request);

      expect(result.isMockResult, isTrue);
      expect(result.questionsReviewed, 1);
      expect(result.answeredQuestions, 1);
      expect(
        result.findings.any(
          (finding) =>
              finding.questionId == 'LEGAL_OC' &&
              finding.title == 'Potential issue to review' &&
              finding.severity == AiReviewSeverity.high,
        ),
        isTrue,
      );
      expect(result.evidenceItemsReviewed, 0);
    });

    test('reports missing answers as information, not a conclusion', () {
      final request = AiAssessmentReviewRequest.fromAssessment(
        questions: const [question],
        answers: const [],
        evidence: const [],
      );

      final result = reviewer.review(request);

      expect(result.answeredQuestions, 0);
      expect(
        result.findings.any(
          (finding) =>
              finding.title == 'Answer not provided' &&
              finding.severity == AiReviewSeverity.information,
        ),
        isTrue,
      );
    });

    test('summarizes evidence without exposing its storage locator', () {
      final evidence = Evidence(
        id: 'evidence-1',
        questionId: 'LEGAL_OC',
        type: EvidenceType.document,
        name: 'OC certificate',
        status: EvidenceStatus.provided,
        source: EvidenceSource.userUpload,
        addedAt: DateTime.utc(2026, 10, 28),
        content: EvidenceContent(
          kind: EvidenceContentKind.file,
          locator: '/private/example/occupancy-certificate.pdf',
          label: 'Occupancy Certificate',
        ),
      );

      final request = AiAssessmentReviewRequest.fromAssessment(
        questions: const [question],
        answers: const [
          PHSAnswer(questionId: 'LEGAL_OC', response: PHSResponse.yes),
        ],
        evidence: [evidence],
      );

      final result = reviewer.review(request);
      final summary = request.evidence.single;

      expect(result.evidenceItemsReviewed, 1);
      expect(summary.name, 'OC certificate');
      expect(summary.contentLabel, 'Occupancy Certificate');
      expect(summary.status, 'provided');
      expect(summary.toString().contains('/private/example/'), isFalse);
      expect(
        result.findings.any(
          (finding) => finding.title == 'Evidence needs attention',
        ),
        isTrue,
      );
    });

    test('keeps evidence associated with its question ID', () {
      final evidence = Evidence(
        id: 'evidence-2',
        questionId: 'A_DIFFERENT_QUESTION',
        type: EvidenceType.document,
        name: 'Unrelated document',
        status: EvidenceStatus.verified,
        source: EvidenceSource.userUpload,
        addedAt: DateTime.utc(2026, 10, 28),
      );

      final request = AiAssessmentReviewRequest.fromAssessment(
        questions: const [question],
        answers: const [
          PHSAnswer(questionId: 'LEGAL_OC', response: PHSResponse.yes),
        ],
        evidence: [evidence],
      );

      final result = reviewer.review(request);

      expect(
        result.findings.any(
          (finding) =>
              finding.questionId == 'LEGAL_OC' &&
              finding.title == 'Supporting evidence not linked',
        ),
        isTrue,
      );
    });
  });
}
