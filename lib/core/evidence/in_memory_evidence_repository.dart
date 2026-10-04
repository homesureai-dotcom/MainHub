import 'evidence.dart';
import 'evidence_repository.dart';

/// In-memory implementation of [EvidenceRepository].
///
/// This implementation is intentionally storage-agnostic and deterministic.
/// It is primarily useful for domain testing and as a temporary persistence
/// implementation before a durable storage layer is introduced.
class InMemoryEvidenceRepository implements EvidenceRepository {
  final Map<String, Evidence> _evidenceById = {};

  @override
  Future<List<Evidence>> getByQuestionId(String questionId) async {
    return _evidenceById.values
        .where((evidence) => evidence.questionId == questionId)
        .toList(growable: false);
  }

  @override
  Future<Evidence?> getById(String evidenceId) async {
    return _evidenceById[evidenceId];
  }

  @override
  Future<List<Evidence>> getAll() async {
    return _evidenceById.values.toList(growable: false);
  }

  @override
  Future<void> add(Evidence evidence) async {
    if (_evidenceById.containsKey(evidence.id)) {
      throw StateError(
        'Evidence with ID "${evidence.id}" already exists.',
      );
    }

    _evidenceById[evidence.id] = evidence;
  }

  @override
  Future<void> update(Evidence evidence) async {
    if (!_evidenceById.containsKey(evidence.id)) {
      throw StateError(
        'Evidence with ID "${evidence.id}" does not exist.',
      );
    }

    _evidenceById[evidence.id] = evidence;
  }

  @override
  Future<bool> delete(String evidenceId) async {
    return _evidenceById.remove(evidenceId) != null;
  }

  @override
  Future<int> deleteByQuestionId(String questionId) async {
    final idsToDelete = _evidenceById.values
        .where((evidence) => evidence.questionId == questionId)
        .map((evidence) => evidence.id)
        .toList(growable: false);

    for (final id in idsToDelete) {
      _evidenceById.remove(id);
    }

    return idsToDelete.length;
  }

  @override
  Future<void> clear() async {
    _evidenceById.clear();
  }
}