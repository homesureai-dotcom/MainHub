import '../../../core/evidence/evidence.dart';
import '../../../core/phs/phs_answer.dart';
import '../../../core/phs/phs_question.dart';

/// Severity assigned to a review finding.
///
/// These labels are for triage only. They do not replace the PHS score.
enum AiReviewSeverity { high, medium, low, information }

/// A single finding produced by the assessment review prototype.
class AiReviewFinding {
  final String questionId;
  final String title;
  final String explanation;
  final String recommendedAction;
  final AiReviewSeverity severity;
  final String basis;

  const AiReviewFinding({
    required this.questionId,
    required this.title,
    required this.explanation,
    required this.recommendedAction,
    required this.severity,
    required this.basis,
  });
}

/// Safe summary of evidence metadata.
///
/// The storage locator is deliberately excluded. A future AI integration
/// must retrieve file content through an authorized service rather than
/// send local paths or storage identifiers directly to a model.
class AiEvidenceSummary {
  final String evidenceId;
  final String questionId;
  final String name;
  final String type;
  final String status;
  final String source;
  final String? contentKind;
  final String? contentLabel;

  const AiEvidenceSummary({
    required this.evidenceId,
    required this.questionId,
    required this.name,
    required this.type,
    required this.status,
    required this.source,
    this.contentKind,
    this.contentLabel,
  });

  factory AiEvidenceSummary.fromEvidence(Evidence evidence) {
    return AiEvidenceSummary(
      evidenceId: evidence.id,
      questionId: evidence.questionId,
      name: evidence.name,
      type: evidence.type.name,
      status: evidence.status.name,
      source: evidence.source.name,
      contentKind: evidence.content?.kind.name,
      contentLabel: evidence.content?.label,
    );
  }
}

/// Input contract for an assessment review.
///
/// This is a data-transfer model only; it does not evaluate or modify
/// the existing PHS scoring rules.
class AiAssessmentReviewRequest {
  final List<PHSQuestion> questions;
  final List<PHSAnswer> answers;
  final List<AiEvidenceSummary> evidence;
  final String languageCode;

  AiAssessmentReviewRequest({
    required List<PHSQuestion> questions,
    required List<PHSAnswer> answers,
    required List<AiEvidenceSummary> evidence,
    this.languageCode = 'en',
  }) : questions = List.unmodifiable(questions),
       answers = List.unmodifiable(answers),
       evidence = List.unmodifiable(evidence);

  factory AiAssessmentReviewRequest.fromAssessment({
    required List<PHSQuestion> questions,
    required List<PHSAnswer> answers,
    required List<Evidence> evidence,
    String languageCode = 'en',
  }) {
    return AiAssessmentReviewRequest(
      questions: questions,
      answers: answers,
      evidence: evidence
          .map(AiEvidenceSummary.fromEvidence)
          .toList(growable: false),
      languageCode: languageCode,
    );
  }
}

/// Structured result from the mock reviewer.
class AiAssessmentReviewResult {
  final List<AiReviewFinding> findings;
  final int questionsReviewed;
  final int answeredQuestions;
  final int evidenceItemsReviewed;
  final DateTime generatedAt;
  final bool isMockResult;

  AiAssessmentReviewResult({
    required List<AiReviewFinding> findings,
    required this.questionsReviewed,
    required this.answeredQuestions,
    required this.evidenceItemsReviewed,
    required this.generatedAt,
    this.isMockResult = true,
  }) : findings = List.unmodifiable(findings);
}

/// Local, deterministic prototype. Makes no network or AI API calls.
///
/// This service is a testable integration foundation, not a generative AI
/// implementation. Findings must be reviewed against real scenarios before
/// being presented as authoritative property advice.
class MockAiAssessmentReviewer {
  const MockAiAssessmentReviewer();

  AiAssessmentReviewResult review(AiAssessmentReviewRequest request) {
    final findings = <AiReviewFinding>[];

    final answersByQuestion = <String, PHSAnswer>{
      for (final answer in request.answers) answer.questionId: answer,
    };

    final evidenceByQuestion = <String, List<AiEvidenceSummary>>{};

    for (final item in request.evidence) {
      evidenceByQuestion
          .putIfAbsent(item.questionId, () => <AiEvidenceSummary>[])
          .add(item);
    }

    for (final question in request.questions) {
      final answer = answersByQuestion[question.id];
      final evidence =
          evidenceByQuestion[question.id] ?? const <AiEvidenceSummary>[];

      if (answer == null) {
        findings.add(
          AiReviewFinding(
            questionId: question.id,
            title: 'Answer not provided',
            explanation:
                'This assessment question has no recorded answer. '
                'The review cannot draw a conclusion from missing data.',
            recommendedAction:
                'Complete this question or mark it for follow-up.',
            severity: AiReviewSeverity.information,
            basis: 'No answer exists for question ID ${question.id}.',
          ),
        );
        continue;
      }

      switch (answer.response) {
        case PHSResponse.no:
          findings.add(
            AiReviewFinding(
              questionId: question.id,
              title: 'Potential issue to review',
              explanation:
                  'The answer to "${question.title}" is No. '
                  'This may indicate an issue that requires follow-up; '
                  'the answer alone does not establish its legal or '
                  'technical significance.',
              recommendedAction:
                  'Review the answer and obtain the relevant supporting '
                  'documents or professional confirmation.',
              severity: _severityFor(question),
              basis: 'Recorded response: No.',
            ),
          );
        case PHSResponse.unsure:
          findings.add(
            AiReviewFinding(
              questionId: question.id,
              title: 'Confirmation needed',
              explanation:
                  'The answer to "${question.title}" is Unsure. '
                  'The current assessment data is insufficient to '
                  'confirm the position.',
              recommendedAction:
                  'Verify the relevant details and update the answer '
                  'when supporting information is available.',
              severity: AiReviewSeverity.medium,
              basis: 'Recorded response: Unsure.',
            ),
          );
        case PHSResponse.yes:
          // A Yes answer is not proof of compliance. Evidence is still
          // reviewed independently below.
          break;
      }

      if (evidence.isEmpty) {
        findings.add(
          AiReviewFinding(
            questionId: question.id,
            title: 'Supporting evidence not linked',
            explanation:
                'No evidence item is currently linked to this question. '
                'This does not prove the document is missing; it means '
                'the app has no linked evidence record to review.',
            recommendedAction:
                'Attach relevant supporting evidence if available, '
                'or record why it cannot be provided.',
            severity: AiReviewSeverity.low,
            basis: 'No evidence records match question ID ${question.id}.',
          ),
        );
      } else {
        final needsReview = evidence.where(
          (item) =>
              item.status == EvidenceStatus.needsReview.name ||
              item.status == EvidenceStatus.provided.name,
        );
        final rejected = evidence.where(
          (item) => item.status == EvidenceStatus.rejected.name,
        );

        if (needsReview.isNotEmpty || rejected.isNotEmpty) {
          findings.add(
            AiReviewFinding(
              questionId: question.id,
              title: 'Evidence needs attention',
              explanation:
                  '${needsReview.length} evidence item(s) are provided '
                  'or awaiting review, and ${rejected.length} item(s) '
                  'are rejected. The mock reviewer has not inspected '
                  'the underlying file content.',
              recommendedAction:
                  'Review the listed evidence items and resolve their '
                  'statuses through the existing evidence workflow.',
              severity: rejected.isNotEmpty
                  ? AiReviewSeverity.medium
                  : AiReviewSeverity.low,
              basis: 'Evidence lifecycle status metadata.',
            ),
          );
        }
      }
    }

    findings.sort((a, b) => a.severity.index.compareTo(b.severity.index));

    return AiAssessmentReviewResult(
      findings: findings,
      questionsReviewed: request.questions.length,
      answeredQuestions: answersByQuestion.length,
      evidenceItemsReviewed: request.evidence.length,
      generatedAt: DateTime.now().toUtc(),
    );
  }

  AiReviewSeverity _severityFor(PHSQuestion question) {
    switch (question.priority) {
      case QuestionPriority.critical:
        return AiReviewSeverity.high;
      case QuestionPriority.high:
        return AiReviewSeverity.high;
      case QuestionPriority.medium:
        return AiReviewSeverity.medium;
      case QuestionPriority.low:
        return AiReviewSeverity.low;
      case null:
        return AiReviewSeverity.medium;
    }
  }
}
