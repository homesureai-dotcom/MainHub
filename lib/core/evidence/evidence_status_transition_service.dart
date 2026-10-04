import 'evidence.dart';
import 'evidence_repository.dart';
import 'evidence_status_rules.dart';

/// Applies evidence lifecycle rules when updating persisted evidence.
///
/// This service prevents callers from bypassing [EvidenceStatusRules]
/// through direct repository updates.
class EvidenceStatusTransitionService {
  final EvidenceRepository _repository;
  final EvidenceStatusRules _statusRules;

  const EvidenceStatusTransitionService({
    required this._repository,
    this._statusRules = const EvidenceStatusRules(),
  });

  /// Updates an existing evidence item after validating its lifecycle
  /// transition and immutable question association.
  ///
  /// The evidence ID must already exist.
  ///
  /// The question ID cannot be changed during a status transition.
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

  /// Returns the currently persisted evidence item.
  Future<Evidence?> getEvidenceById(String evidenceId) {
    return _repository.getById(evidenceId);
  }
}