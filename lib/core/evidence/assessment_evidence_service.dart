import 'evidence.dart';
import 'evidence_repository.dart';

/// Provides assessment-level access to evidence.
///
/// The evidence repository remains responsible for persistence.
/// This service provides a higher-level API for callers that need to
/// work with all evidence associated with an assessment.
class AssessmentEvidenceService {
  final EvidenceRepository _repository;

  const AssessmentEvidenceService({
    required this._repository,
  });

  /// Returns all evidence associated with the supplied question IDs.
  ///
  /// The returned list preserves the order of [questionIds].
  /// Within each question, the repository's evidence order is preserved.
  Future<List<Evidence>> getEvidenceForQuestions(
    List<String> questionIds,
  ) async {
    final evidence = <Evidence>[];

    for (final questionId in questionIds) {
      final questionEvidence = await _repository.getByQuestionId(
        questionId,
      );

      evidence.addAll(questionEvidence);
    }

    return List.unmodifiable(evidence);
  }

  /// Returns all evidence belonging to the supplied question IDs,
  /// grouped by question ID.
  ///
  /// Every requested question ID is included in the returned map,
  /// even when no evidence exists for that question.
  Future<Map<String, List<Evidence>>> getEvidenceGroupedByQuestion(
    List<String> questionIds,
  ) async {
    final grouped = <String, List<Evidence>>{};

    for (final questionId in questionIds) {
      final evidence = await _repository.getByQuestionId(
        questionId,
      );

      grouped[questionId] = List.unmodifiable(evidence);
    }

    return Map.unmodifiable(grouped);
  }

  /// Returns the number of evidence items associated with the supplied
  /// question IDs.
  Future<int> countEvidenceForQuestions(
    List<String> questionIds,
  ) async {
    final evidence = await getEvidenceForQuestions(questionIds);
    return evidence.length;
  }

  /// Returns whether at least one evidence item exists for every supplied
  /// question ID.
  ///
  /// An empty question list returns true because there are no missing
  /// questions to satisfy.
  Future<bool> hasEvidenceForEveryQuestion(
    List<String> questionIds,
  ) async {
    if (questionIds.isEmpty) {
      return true;
    }

    final grouped = await getEvidenceGroupedByQuestion(
      questionIds,
    );

    return questionIds.every(
      (questionId) => grouped[questionId]?.isNotEmpty ?? false,
    );
  }
}