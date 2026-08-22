import 'package:flutter/foundation.dart';

import '../core/assessment/assessment_result.dart';
import '../core/phs/phs_answer.dart';
import '../features/report/models/property_health_report.dart';

class AssessmentState extends ChangeNotifier {
  AssessmentState._();

  static final AssessmentState instance = AssessmentState._();

  final List<PHSAnswer> _answers = [];

  AssessmentResult? _latestResult;

  PropertyHealthReport? _latestReport;

  DateTime? _completedAt;

  String? _propertyId;

  List<PHSAnswer> get answers => List.unmodifiable(_answers);

  AssessmentResult? get latestResult => _latestResult;

  PropertyHealthReport? get latestReport => _latestReport;

  DateTime? get completedAt => _completedAt;

  String? get propertyId => _propertyId;

  bool get hasAssessment => _latestResult != null;

  bool get hasReport => _latestReport != null;

  void startAssessment({
    String? propertyId,
  }) {
    _answers.clear();
    _latestResult = null;
    _latestReport = null;
    _completedAt = null;
    _propertyId = propertyId;

    notifyListeners();
  }

  void saveAnswer(PHSAnswer answer) {
    _answers.removeWhere(
      (a) => a.questionId == answer.questionId,
    );

    _answers.add(answer);

    notifyListeners();
  }

  void saveResult(AssessmentResult result) {
    _latestResult = result;
    _completedAt = DateTime.now();

    notifyListeners();
  }

  void saveReport(PropertyHealthReport report) {
    _latestReport = report;

    notifyListeners();
  }

  void clearAssessment() {
    _answers.clear();
    _latestResult = null;
    _latestReport = null;
    _completedAt = null;
    _propertyId = null;

    notifyListeners();
  }
}