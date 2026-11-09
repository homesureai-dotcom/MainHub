import 'package:flutter/foundation.dart';

import '../core/assessment/assessment_result.dart';
import '../core/assessment/assessment_session.dart';
import '../core/assessment/assessment_session_store.dart';
import '../core/evidence/evidence_repository.dart';
import '../core/evidence/in_memory_evidence_repository.dart';
import '../core/phs/phs_answer.dart';
import '../core/phs/phs_assessment_progress.dart';
import '../core/phs/phs_question_progress.dart';
import '../core/phs/phs_question_progress_resolver.dart';
import '../data/phs_questions.dart';
import '../features/report/models/property_health_report.dart';

class AssessmentState extends ChangeNotifier {
  AssessmentState._();

  static final AssessmentState instance = AssessmentState._();

  AssessmentSessionStore? _sessionStore;
  Future<void> _pendingPersistence = Future<void>.value();
  Object? _persistenceError;

  Object? get persistenceError => _persistenceError;

  /// Enable Firestore persistence after Firebase has been initialized.
  void configurePersistence(AssessmentSessionStore store) {
    _sessionStore = store;
    _persistenceError = null;
  }

  /// Wait until all queued session saves have finished.
  Future<void> flushPersistence() async {
    await _pendingPersistence;
  }

  /// Restore an in-progress session only when its property identity matches.
  Future<bool> restoreInProgress({
    String? propertyId,
    String? submissionId,
  }) async {
    final store = _sessionStore;
    if (store == null) return false;

    final saved = await store.loadLatestInProgress(
      propertyId: propertyId,
      submissionId: submissionId,
    );

    if (saved == null) return false;

    _session = saved;
    _propertyId = saved.propertyId;
    _submissionId = saved.submissionId;
    _restoreAnswersFromSession();
    _latestResult = null;
    _latestReport = null;
    _completedAt = null;
    _evidenceRepository.clear();
    notifyListeners();
    return true;
  }

  /// Finds the newest saved session without changing the active state.
  Future<AssessmentSession?> loadLatestInProgressCandidate() async {
    final store = _sessionStore;
    if (store == null) return null;
    return store.loadMostRecentInProgress();
  }

  String? _submissionId;

  void _queueSessionSave() {
    final store = _sessionStore;
    final session = _session;
    if (store == null || session == null) return;

    _pendingPersistence = _pendingPersistence.then((_) async {
      try {
        await store.save(session);
        _persistenceError = null;
      } catch (error) {
        _persistenceError = error;
      }
    });
  }

  final List<PHSAnswer> _answers = [];

  final EvidenceRepository _evidenceRepository = InMemoryEvidenceRepository();

  final PHSQuestionProgressResolver _questionProgressResolver =
      const PHSQuestionProgressResolver();

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

  String? get submissionId => _submissionId;

  AssessmentSession? get session => _session;

  bool get hasAssessment => _latestResult != null;

  bool get hasReport => _latestReport != null;

  bool get hasActiveSession =>
      _session != null &&
      _session!.status == AssessmentSessionStatus.inProgress;

  bool get hasCompletedSession =>
      _session != null && _session!.status == AssessmentSessionStatus.completed;

  String? get currentQuestionId => _session?.currentQuestionId;

  int get answeredQuestionCount => _answers.length;

  PHSAssessmentProgress get assessmentProgress =>
      PHSAssessmentProgress.fromQuestions(
        questions: phsQuestions,
        answers: _answers,
      );

  PHSQuestionProgress? get currentQuestionProgress {
    final questionId = currentQuestionId;

    if (questionId == null) {
      return null;
    }

    return _questionProgressResolver.resolve(
      questionId: questionId,
      questions: phsQuestions,
    );
  }

  void startAssessment({
    String? propertyId,
    String? submissionId,
    bool forceNew = false,
  }) {
    if (!forceNew &&
        _session != null &&
        _session!.status == AssessmentSessionStatus.inProgress) {
      if ((propertyId == null || _session!.propertyId == propertyId) &&
          (submissionId == null || _session!.submissionId == submissionId)) {
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

    _submissionId = submissionId;

    _evidenceRepository.clear();

    _session = AssessmentSession(
      assessmentId: 'ASSESSMENT_${now.microsecondsSinceEpoch}',
      propertyId: propertyId,
      submissionId: submissionId,
      startedAt: now,
      lastUpdatedAt: now,
      currentQuestionId: null,
      status: AssessmentSessionStatus.inProgress,
      answers: const [],
    );

    notifyListeners();
    _queueSessionSave();
  }

  void saveAnswer(PHSAnswer answer, {String? currentQuestionId}) {
    _answers.removeWhere(
      (existing) => existing.questionId == answer.questionId,
    );

    _answers.add(answer);

    _updateSession(currentQuestionId: currentQuestionId ?? answer.questionId);

    notifyListeners();
    _queueSessionSave();
  }

  void updateCurrentQuestion(String? questionId) {
    if (_session == null) {
      return;
    }

    _updateSession(currentQuestionId: questionId);

    notifyListeners();
    _queueSessionSave();
    _queueSessionSave();
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
    _queueSessionSave();
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
    _queueSessionSave();
  }

  void clearAssessment() {
    _answers.clear();

    _latestResult = null;

    _latestReport = null;

    _completedAt = null;

    _propertyId = null;

    _submissionId = null;

    _session = null;

    _evidenceRepository.clear();

    notifyListeners();
  }

  void startNewAssessment({String? propertyId, String? submissionId}) {
    startAssessment(
      propertyId: propertyId,
      submissionId: submissionId,
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
      currentQuestionId: currentQuestionId ?? existingSession.currentQuestionId,
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
