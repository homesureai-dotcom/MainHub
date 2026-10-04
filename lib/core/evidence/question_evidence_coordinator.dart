import 'evidence.dart';
import 'evidence_repository.dart';
import 'evidence_requirement.dart';
import 'evidence_risk_signal.dart';
import 'evidence_validator.dart';
import 'question_evidence_summary.dart';

/// Coordinates persisted evidence with validation for a single PHS question.
///
/// This class provides an application-facing entry point for loading
/// evidence associated with one question and producing a
/// [QuestionEvidenceSummary].
///
/// It does not modify PHS scoring.
class QuestionEvidenceCoordinator {
  final EvidenceRepository _repository;
  final EvidenceValidator _validator;

  const QuestionEvidenceCoordinator({
    required this._repository,
    required this._validator,
  });

  /// Loads all persisted evidence associated with [questionId].
  Future<List<Evidence>> loadEvidence(
    String questionId,
  ) async {
    final evidence = await _repository.getByQuestionId(
      questionId,
    );

    return List.unmodifiable(evidence);
  }

  /// Builds a question-level evidence summary using persisted evidence.
  ///
  /// Only requirements belonging to [questionId] should be supplied.
  Future<QuestionEvidenceSummary> buildSummary({
    required String questionId,
    required List<EvidenceRequirement> requirements,
  }) async {
    final evidence = await loadEvidence(questionId);

    final validationResults = _validator.validateAll(
      requirements,
      evidence,
    );

    final riskSignals = validationResults
        .map(
          (result) =>
              EvidenceRiskSignal.fromValidationResult(result),
        )
        .toList(growable: false);

    return QuestionEvidenceSummary(
      questionId: questionId,
      requirements: requirements,
      evidence: evidence,
      validationResults: validationResults,
      riskSignals: riskSignals,
    );
  }

  /// Adds evidence to the underlying repository.
  Future<void> addEvidence(Evidence evidence) {
    _validateQuestionId(
      evidence.questionId,
    );

    return _repository.add(evidence);
  }

  /// Updates evidence through the underlying repository.
  ///
  /// Lifecycle validation remains the responsibility of the appropriate
  /// evidence management service.
  Future<void> updateEvidence(Evidence evidence) {
    _validateQuestionId(
      evidence.questionId,
    );

    return _repository.update(evidence);
  }

  /// Deletes one evidence item by ID.
  Future<bool> deleteEvidence(String evidenceId) {
    return _repository.delete(evidenceId);
  }

  /// Deletes all evidence associated with [questionId].
  Future<int> deleteAllEvidence(
    String questionId,
  ) {
    _validateQuestionId(questionId);

    return _repository.deleteByQuestionId(
      questionId,
    );
  }

  void _validateQuestionId(String questionId) {
    if (questionId.trim().isEmpty) {
      throw ArgumentError.value(
        questionId,
        'questionId',
        'Question ID cannot be empty.',
      );
    }
  }
}