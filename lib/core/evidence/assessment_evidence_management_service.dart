import 'evidence.dart';
import 'evidence_repository.dart';
import 'evidence_status_rules.dart';

/// Provides controlled assessment-level evidence management.
///
/// This service protects the relationship between an evidence item
/// and its PHS question while allowing assessment-level callers to
/// update or delete evidence safely.
class AssessmentEvidenceManagementService {
  final EvidenceRepository _repository;
  final EvidenceStatusRules _statusRules;

  const AssessmentEvidenceManagementService({
    required this._repository,
    this._statusRules = const EvidenceStatusRules(),
  });

  /// Updates an existing evidence item.
  ///
  /// The evidence ID must already exist.
  ///
  /// The PHS question association cannot be changed during an update.
  ///
  /// The evidence status must follow the configured evidence lifecycle
  /// transition rules.
  Future<void> updateEvidence(Evidence updatedEvidence) async {
    final existingEvidence = await _repository.getById(
      updatedEvidence.id,
    );

    if (existingEvidence == null) {
      throw StateError(
        'Evidence with ID "${updatedEvidence.id}" does not exist.',
      );
    }

    if (existingEvidence.questionId != updatedEvidence.questionId) {
      throw StateError(
        'Evidence question ID cannot be changed during an update.',
      );
    }

    _statusRules.validateTransition(
      existingEvidence.status,
      updatedEvidence.status,
    );

    await _repository.update(updatedEvidence);
  }

  /// Deletes an evidence item by ID.
  ///
  /// Returns `true` when the evidence existed and was deleted.
  /// Returns `false` when no evidence with the supplied ID existed.
  Future<bool> deleteEvidence(String evidenceId) {
    return _repository.delete(evidenceId);
  }

  /// Deletes all evidence associated with a specific PHS question.
  ///
  /// Returns the number of evidence items removed.
  Future<int> deleteEvidenceForQuestion(String questionId) {
    return _repository.deleteByQuestionId(questionId);
  }

  /// Retrieves an evidence item by ID.
  Future<Evidence?> getEvidenceById(String evidenceId) {
    return _repository.getById(evidenceId);
  }
}