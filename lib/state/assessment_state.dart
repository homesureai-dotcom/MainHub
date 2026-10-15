import 'package:flutter/foundation.dart';

import '../core/assessment/assessment_result.dart';
import '../core/assessment/assessment_session.dart';
import '../core/evidence/evidence_repository.dart';
import '../core/evidence/in_memory_evidence_repository.dart';
import '../core/phs/phs_answer.dart';
import '../features/report/models/property_health_report.dart';

class AssessmentState extends ChangeNotifier {
  AssessmentState._();

  static final AssessmentState instance = AssessmentState._();

  final List<PHSAnswer> _answers = [];

  final EvidenceRepository _evidenceRepository =
      InMemoryEvidenceRepository();

  AssessmentResult? _latestResult;

  PropertyHealthReport? _latestReport;

  DateTime? _completedAt;

  String? _propertyId;

  AssessmentSession? _session;

  List<PHSAnswer> get answers => List.unmodifiable(_answers);

  EvidenceRepository get evidenceRepository => _evidenceRepository;

  AssessmentResult? get latestResult => _latestResult;

  PropertyHealthReport? get latestReport => _latestReport;

  DateTime? get completedAt => _completedAt;

  String? get propertyId => _propertyId;

  AssessmentSession? get session => _session;

  bool get hasAssessment => _latestResult != null;

  bool get hasReport => _latestReport != null;

  bool get hasActiveSession =>
      _session != null &&
      _session!.status == AssessmentSessionStatus.inProgress;

  bool get hasCompletedSession =>
      _session != null &&
      _session!.status == AssessmentSessionStatus.completed;

  String? get currentQuestionId => _session?.currentQuestionId;

  void startAssessment({
    String? propertyId,
    bool forceNew = false,
  }) {
    if (!forceNew &&
        _session != null &&
        _session!.status == AssessmentSessionStatus.inProgress) {
      if (propertyId == null || _session!.propertyId == propertyId) {
        _propertyId = _session!.propertyId;

        _restoreAnswersFromSession();

        notifyListeners();

        return;
      }
    }

    final now = DateTime.now();

    _answers.clear();
    _latestResult = null;
    _latestReport = null;
    _completedAt = null;
    _propertyId = propertyId;

    _evidenceRepository.clear();

    _session = AssessmentSession(
      assessmentId: 'ASSESSMENT_${now.microsecondsSinceEpoch}',
      propertyId: propertyId,
      startedAt: now,
      lastUpdatedAt: now,
      currentQuestionId: null,
      status: AssessmentSessionStatus.inProgress,
      answers: const [],
    );

    notifyListeners();
  }

  void saveAnswer(
    PHSAnswer answer, {
    String? currentQuestionId,
  }) {
    _answers.removeWhere(
      (a) => a.questionId == answer.questionId,
    );

    _answers.add(answer);

    _updateSession(
      currentQuestionId: currentQuestionId ?? answer.questionId,
    );

    notifyListeners();
  }

  void updateCurrentQuestion(String? questionId) {
    if (_session == null) {
      return;
    }

    _updateSession(currentQuestionId: questionId);

    notifyListeners();
  }

  void completeAssessment() {
    if (_session == null) {
      return;
    }

    final now = DateTime.now();

    _session = _session!.copyWith(
      lastUpdatedAt: now,
      status: AssessmentSessionStatus.completed,
    );

    _completedAt = now;

    notifyListeners();
  }

  void saveResult(AssessmentResult result) {
    _latestResult = result;
    _completedAt ??= DateTime.now();

    completeAssessment();

    notifyListeners();
  }

  void saveReport(PropertyHealthReport report) {
    _latestReport = report;

    notifyListeners();
  }

  void saveAndExit() {
    if (_session == null) {
      return;
    }

    final now = DateTime.now();

    _session = _session!.copyWith(
      lastUpdatedAt: now,
      answers: List.unmodifiable(_answers),
    );

    notifyListeners();
  }

  void clearAssessment() {
    _answers.clear();
    _latestResult = null;
    _latestReport = null;
    _completedAt = null;
    _propertyId = null;

    _session = null;

    _evidenceRepository.clear();

    notifyListeners();
  }

  void startNewAssessment({String? propertyId}) {
    startAssessment(
      propertyId: propertyId,
      forceNew: true,
    );
  }

  void _updateSession({String? currentQuestionId}) {
    final existingSession = _session;

    if (existingSession == null) {
      return;
    }

    final now = DateTime.now();

    _session = existingSession.copyWith(
      lastUpdatedAt: now,
      currentQuestionId:
          currentQuestionId ?? existingSession.currentQuestionId,
      answers: List.unmodifiable(_answers),
    );
  }

  void _restoreAnswersFromSession() {
    final existingSession = _session;

    if (existingSession == null) {
      return;
    }

    _answers
      ..clear()
      ..addAll(existingSession.answers);
  }
}
