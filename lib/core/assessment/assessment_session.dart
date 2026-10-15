import '../phs/phs_answer.dart';

enum AssessmentSessionStatus {
  notStarted,
  inProgress,
  completed,
}

class AssessmentSession {
  final String assessmentId;
  final String? propertyId;
  final DateTime startedAt;
  final DateTime lastUpdatedAt;
  final String? currentQuestionId;
  final AssessmentSessionStatus status;
  final List<PHSAnswer> answers;

  const AssessmentSession({
    required this.assessmentId,
    required this.propertyId,
    required this.startedAt,
    required this.lastUpdatedAt,
    required this.currentQuestionId,
    required this.status,
    required this.answers,
  });

  int get answeredQuestionCount => answers.length;

  bool get isNotStarted =>
      status == AssessmentSessionStatus.notStarted;

  bool get isInProgress =>
      status == AssessmentSessionStatus.inProgress;

  bool get isCompleted =>
      status == AssessmentSessionStatus.completed;

  AssessmentSession copyWith({
    String? assessmentId,
    String? propertyId,
    DateTime? startedAt,
    DateTime? lastUpdatedAt,
    String? currentQuestionId,
    AssessmentSessionStatus? status,
    List<PHSAnswer>? answers,
  }) {
    return AssessmentSession(
      assessmentId:
          assessmentId ?? this.assessmentId,
      propertyId:
          propertyId ?? this.propertyId,
      startedAt:
          startedAt ?? this.startedAt,
      lastUpdatedAt:
          lastUpdatedAt ?? this.lastUpdatedAt,
      currentQuestionId:
          currentQuestionId ?? this.currentQuestionId,
      status:
          status ?? this.status,
      answers:
          answers ?? this.answers,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is AssessmentSession &&
        other.assessmentId == assessmentId &&
        other.propertyId == propertyId &&
        other.startedAt == startedAt &&
        other.lastUpdatedAt == lastUpdatedAt &&
        other.currentQuestionId ==
            currentQuestionId &&
        other.status == status &&
        _listEquals(
          other.answers,
          answers,
        );
  }

  @override
  int get hashCode => Object.hash(
        assessmentId,
        propertyId,
        startedAt,
        lastUpdatedAt,
        currentQuestionId,
        status,
        Object.hashAll(answers),
      );

  static bool _listEquals<T>(
    List<T> first,
    List<T> second,
  ) {
    if (first.length != second.length) {
      return false;
    }

    for (var index = 0;
        index < first.length;
        index++) {
      if (first[index] != second[index]) {
        return false;
      }
    }

    return true;
  }
}
