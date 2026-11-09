import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'assessment_session.dart';
import '../phs/phs_answer.dart';

/// Persists assessment sessions privately under the signed-in user's account.
///
/// Firestore path:
/// users/{uid}/assessment_sessions/{assessmentId}
///
/// This store never changes property submission approval status.
class AssessmentSessionStore {
  AssessmentSessionStore({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> _sessionDocument(
    String assessmentId,
  ) {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Sign in before saving assessment progress.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('assessment_sessions')
        .doc(assessmentId);
  }

  Map<String, dynamic> _sessionToMap(AssessmentSession session) {
    return {
      'assessmentId': session.assessmentId,
      'propertyId': session.propertyId,
      'submissionId': session.submissionId,
      'startedAt': Timestamp.fromDate(session.startedAt),
      'lastUpdatedAt': Timestamp.fromDate(session.lastUpdatedAt),
      'currentQuestionId': session.currentQuestionId,
      'status': session.status.name,
      'answers': session.answers
          .map(
            (answer) => {
              'questionId': answer.questionId,
              'response': answer.response.name,
            },
          )
          .toList(),
    };
  }

  AssessmentSession _sessionFromMap(Map<String, dynamic> data) {
    final rawAnswers = data['answers'];

    final answers = <PHSAnswer>[];

    if (rawAnswers is List) {
      for (final item in rawAnswers) {
        if (item is! Map) continue;

        final questionId = item['questionId'];
        final responseName = item['response'];

        if (questionId is! String || responseName is! String) {
          continue;
        }

        final response = PHSResponse.values.where(
          (value) => value.name == responseName,
        );

        if (response.isEmpty) continue;

        answers.add(
          PHSAnswer(questionId: questionId, response: response.first),
        );
      }
    }

    final statusName = data['status'];
    final status = AssessmentSessionStatus.values.where(
      (value) => value.name == statusName,
    );

    final startedAt = data['startedAt'];
    final lastUpdatedAt = data['lastUpdatedAt'];

    if (startedAt is! Timestamp ||
        lastUpdatedAt is! Timestamp ||
        status.isEmpty ||
        data['assessmentId'] is! String) {
      throw const FormatException('Invalid saved assessment session.');
    }

    return AssessmentSession(
      assessmentId: data['assessmentId'] as String,
      propertyId: data['propertyId'] as String?,
      submissionId: data['submissionId'] as String?,
      startedAt: startedAt.toDate(),
      lastUpdatedAt: lastUpdatedAt.toDate(),
      currentQuestionId: data['currentQuestionId'] as String?,
      status: status.first,
      answers: List.unmodifiable(answers),
    );
  }

  Future<void> save(AssessmentSession session) async {
    await _sessionDocument(
      session.assessmentId,
    ).set(_sessionToMap(session), SetOptions(merge: true));
  }

  Future<AssessmentSession?> load(String assessmentId) async {
    final snapshot = await _sessionDocument(assessmentId).get();

    if (!snapshot.exists) return null;

    final data = snapshot.data();

    if (data == null) return null;

    return _sessionFromMap(data);
  }

  /// Loads the newest in-progress session for the signed-in user.
  /// The caller must verify approval before resuming submitted properties.
  Future<AssessmentSession?> loadMostRecentInProgress() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Sign in before restoring assessment progress.');
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('assessment_sessions')
        .where('status', isEqualTo: 'inProgress')
        .orderBy('lastUpdatedAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return _sessionFromMap(snapshot.docs.first.data());
  }

  Future<AssessmentSession?> loadLatestInProgress({
    String? propertyId,
    String? submissionId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Sign in before restoring assessment progress.');
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('assessment_sessions')
        .where('status', isEqualTo: 'inProgress')
        .orderBy('lastUpdatedAt', descending: true)
        .limit(10)
        .get();

    for (final document in snapshot.docs) {
      final session = _sessionFromMap(document.data());

      if (session.propertyId == propertyId &&
          session.submissionId == submissionId) {
        return session;
      }
    }

    return null;
  }
}
