import 'evidence.dart';

/// Defines the allowed lifecycle transitions for evidence.
///
/// Evidence status changes are deliberately kept separate from the
/// Evidence model so that the lifecycle rules can be tested and
/// reused by the UI, engine, and future persistence layer.
class EvidenceStatusRules {
  const EvidenceStatusRules();

  /// Returns true when [from] can transition to [to].
  bool canTransition(
    EvidenceStatus from,
    EvidenceStatus to,
  ) {
    if (from == to) {
      return true;
    }

    switch (from) {
      case EvidenceStatus.notProvided:
        return to == EvidenceStatus.provided;

      case EvidenceStatus.provided:
        return to == EvidenceStatus.needsReview ||
            to == EvidenceStatus.verified ||
            to == EvidenceStatus.rejected;

      case EvidenceStatus.needsReview:
        return to == EvidenceStatus.verified ||
            to == EvidenceStatus.rejected;

      case EvidenceStatus.verified:
        return false;

      case EvidenceStatus.rejected:
        return false;
    }
  }

  /// Returns all statuses that can be reached from [status].
  List<EvidenceStatus> allowedTransitions(
    EvidenceStatus status,
  ) {
    return EvidenceStatus.values
        .where(
          (candidate) => canTransition(status, candidate),
        )
        .toList(growable: false);
  }

  /// Validates a transition and throws a [StateError] when it
  /// is not allowed.
  void validateTransition(
    EvidenceStatus from,
    EvidenceStatus to,
  ) {
    if (!canTransition(from, to)) {
      throw StateError(
        'Invalid evidence status transition: '
        '${from.name} -> ${to.name}',
      );
    }
  }
}