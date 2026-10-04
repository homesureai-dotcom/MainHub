import 'evidence.dart';

/// Defines persistence operations for assessment evidence.
///
/// This contract intentionally contains no storage-specific implementation.
/// Concrete repositories can later use in-memory storage, local persistence,
/// or a remote backend without changing the evidence domain model.
abstract interface class EvidenceRepository {
  /// Returns all evidence associated with a PHS question.
  Future<List<Evidence>> getByQuestionId(String questionId);

  /// Returns a single evidence item by its unique ID.
  Future<Evidence?> getById(String evidenceId);

  /// Returns all stored evidence.
  Future<List<Evidence>> getAll();

  /// Adds a new evidence item.
  ///
  /// Implementations should reject duplicate evidence IDs.
  Future<void> add(Evidence evidence);

  /// Replaces an existing evidence item.
  ///
  /// Implementations should reject the operation when the evidence ID
  /// does not already exist.
  Future<void> update(Evidence evidence);

  /// Removes an evidence item by ID.
  ///
  /// Returns `true` when an item was removed and `false` when no item
  /// with the supplied ID existed.
  Future<bool> delete(String evidenceId);

  /// Removes all evidence associated with a PHS question.
  ///
  /// Returns the number of evidence items removed.
  Future<int> deleteByQuestionId(String questionId);

  /// Removes all stored evidence.
  Future<void> clear();
}