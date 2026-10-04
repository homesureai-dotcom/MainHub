import 'assessment_evidence_summary.dart';
import 'assessment_evidence_summary_builder.dart';
import 'evidence.dart';
import 'evidence_repository.dart';
import 'evidence_requirement.dart';

/// Coordinates persisted assessment evidence with evidence validation.
///
/// This class provides an application-facing entry point for loading
/// evidence from the repository and producing an assessment-level
/// evidence summary.
///
/// It does not modify PHS scoring.
class AssessmentEvidenceCoordinator {
  final EvidenceRepository _repository;
  final AssessmentEvidenceSummaryBuilder _summaryBuilder;

  const AssessmentEvidenceCoordinator({
    required this._repository,
    required this._summaryBuilder,
  });

  /// Loads all persisted evidence associated with [questionIds].
  ///
  /// The returned list follows the order of [questionIds].
  Future<List<Evidence>> loadEvidence(
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

  /// Builds an assessment evidence summary using persisted evidence.
  ///
  /// [requirements] contains all evidence requirements for the assessment.
  ///
  /// [questionIds] identifies the PHS questions whose persisted evidence
  /// should be included.
  ///
  /// [categoryRequirements] optionally maps category IDs to their
  /// corresponding evidence requirements.
  Future<AssessmentEvidenceSummary> buildSummary({
    required List<EvidenceRequirement> requirements,
    required List<String> questionIds,
    Map<String, List<EvidenceRequirement>> categoryRequirements =
        const {},
  }) async {
    final evidence = await loadEvidence(questionIds);

    return _summaryBuilder.build(
      requirements: requirements,
      evidence: evidence,
      categoryRequirements: categoryRequirements,
    );
  }

  /// Adds evidence to the underlying repository.
  Future<void> addEvidence(Evidence evidence) {
    return _repository.add(evidence);
  }

  /// Updates evidence through the underlying repository.
  ///
  /// Lifecycle validation remains the responsibility of the appropriate
  /// evidence management service.
  Future<void> updateEvidence(Evidence evidence) {
    return _repository.update(evidence);
  }

  /// Deletes evidence by ID.
  Future<bool> deleteEvidence(String evidenceId) {
    return _repository.delete(evidenceId);
  }

  /// Deletes all evidence associated with a PHS question.
  Future<int> deleteEvidenceForQuestion(String questionId) {
    return _repository.deleteByQuestionId(questionId);
  }
}