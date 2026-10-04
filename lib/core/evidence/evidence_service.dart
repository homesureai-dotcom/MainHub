import 'evidence.dart';
import 'evidence_repository.dart';

/// Domain-level service for evidence CRUD operations.
///
/// The service keeps application/domain callers independent of the
/// concrete evidence repository implementation.
class EvidenceService {
  final EvidenceRepository _repository;

  const EvidenceService({
    required this._repository,
  });

  /// Adds a new evidence item.
  Future<void> addEvidence(Evidence evidence) {
    return _repository.add(evidence);
  }

  /// Retrieves evidence by its unique ID.
  Future<Evidence?> getEvidenceById(String evidenceId) {
    return _repository.getById(evidenceId);
  }

  /// Retrieves all evidence associated with a PHS question.
  Future<List<Evidence>> getEvidenceForQuestion(
    String questionId,
  ) {
    return _repository.getByQuestionId(questionId);
  }

  /// Retrieves all stored evidence.
  Future<List<Evidence>> getAllEvidence() {
    return _repository.getAll();
  }

  /// Updates an existing evidence item.
  Future<void> updateEvidence(Evidence evidence) {
    return _repository.update(evidence);
  }

  /// Deletes one evidence item by ID.
  Future<bool> deleteEvidence(String evidenceId) {
    return _repository.delete(evidenceId);
  }

  /// Deletes all evidence associated with a PHS question.
  Future<int> deleteEvidenceForQuestion(String questionId) {
    return _repository.deleteByQuestionId(questionId);
  }

  /// Removes all evidence from the repository.
  Future<void> clearEvidence() {
    return _repository.clear();
  }
}