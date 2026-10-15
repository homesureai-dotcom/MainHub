import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/engine/engine.dart';
import 'package:homesure_ai/core/engine/models/property_health_result.dart';
import 'package:homesure_ai/core/phs/phs_answer.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';
import 'package:homesure_ai/data/phs_questions.dart';
import 'package:homesure_ai/features/dashboard/coordinators/dashboard_data_coordinator.dart';
import 'package:homesure_ai/features/property/models/assessment_summary.dart';
import 'package:homesure_ai/features/property/models/compliance_summary.dart';
import 'package:homesure_ai/features/property/models/document_summary.dart';
import 'package:homesure_ai/features/property/models/property.dart';
import 'package:homesure_ai/features/property/state/property_state.dart';
import 'package:homesure_ai/state/assessment_state.dart';

void main() {
  late AssessmentState assessmentState;
  late PropertyState propertyState;

  setUp(() {
    assessmentState = AssessmentState.instance;
    propertyState = PropertyState.instance;

    assessmentState.clearAssessment();
    propertyState.clear();
  });

  tearDown(() {
    assessmentState.clearAssessment();
    propertyState.clear();
  });

  Property createProperty() {
    return const Property(
      id: 'property-1',
      name: 'Test Apartment',
      builderName: 'Test Builder',
      ownerName: 'Test Owner',
      address: Address(
        line1: '123 Test Street',
        city: 'Bengaluru',
        state: 'Karnataka',
        pincode: '560001',
      ),
      type: PropertyType.apartment,
      yearOfConstruction: 2025,
      carpetArea: 708,
      totalUnits: 333,
      compliance: ComplianceSummary(
        verifiedCount: 5,
        pendingCount: 2,
        issueCount: 1,
        compliancePercentage: 62.5,
      ),
      assessment: AssessmentSummary(),
      documents: DocumentSummary(
        verifiedDocuments: 8,
        pendingDocuments: 2,
        missingDocuments: 1,
      ),
    );
  }

  void saveAnswers({
    required List<PHSAnswer> answers,
  }) {
    assessmentState.startAssessment(
      propertyId: 'property-1',
    );

    for (final answer in answers) {
      assessmentState.saveAnswer(
        answer,
        currentQuestionId: answer.questionId,
      );
    }
  }

  List<PHSAnswer> answersForAllQuestions({
    PHSResponse response = PHSResponse.yes,
  }) {
    return phsQuestions
        .map(
          (question) => PHSAnswer(
            questionId: question.id,
            response: response,
          ),
        )
        .toList();
  }

  test(
    'complete assessment answers produce a complete final PHS result',
    () {
      final answers = answersForAllQuestions();

      saveAnswers(answers: answers);

      final engine = PropertyIntelligenceEngine();

      final PropertyHealthResult result =
          engine.evaluateAssessment(assessmentState.answers);

      expect(
        assessmentState.answers,
        hasLength(phsQuestions.length),
      );

      expect(
        result.evaluatedQuestionCount,
        phsQuestions.length,
      );

      expect(
        result.totalQuestionCount,
        phsQuestions.length,
      );

      expect(
        result.evaluatedCategoryCount,
        PHSCategory.values.length,
      );

      expect(
        result.totalCategoryCount,
        PHSCategory.values.length,
      );

      expect(result.isComplete, isTrue);
      expect(result.hasFinalScore, isTrue);

      expect(
        result.categoryScores.keys,
        containsAll(PHSCategory.values),
      );

      expect(result.overallScore, inInclusiveRange(0, 100));
    },
  );

  test(
    'incomplete assessment answers do not expose a final PHS score',
    () {
      final incompleteAnswers = phsQuestions
          .take(3)
          .map(
            (question) => PHSAnswer(
              questionId: question.id,
              response: PHSResponse.yes,
            ),
          )
          .toList();

      saveAnswers(
        answers: incompleteAnswers,
      );

      final engine = PropertyIntelligenceEngine();

      final result = engine.evaluateAssessment(
        assessmentState.answers,
      );

      expect(
        result.evaluatedQuestionCount,
        incompleteAnswers.length,
      );

      expect(
        result.totalQuestionCount,
        phsQuestions.length,
      );

      expect(result.isComplete, isFalse);
      expect(result.hasFinalScore, isFalse);

      expect(
        result.questionCompletionPercentage,
        lessThan(100),
      );
    },
  );

  test(
    'dashboard reconstructs the completed assessment result from assessment answers',
    () async {
      final property = createProperty();

      propertyState.initialize(
        properties: [property],
      );

      final answers = answersForAllQuestions();

      saveAnswers(answers: answers);

      final engine = PropertyIntelligenceEngine();

      final expectedResult = engine.evaluateAssessment(
        assessmentState.answers,
      );

      final coordinator = DashboardDataCoordinator(
        propertyState: propertyState,
        assessmentState: assessmentState,
      );

      final dashboardData = await coordinator.build();

      expect(dashboardData, isNotNull);
      expect(dashboardData!.healthResult, isNotNull);

      final actualResult = dashboardData.healthResult!;

      expect(
        actualResult.overallScore,
        expectedResult.overallScore,
      );

      expect(
        actualResult.categoryScores,
        expectedResult.categoryScores,
      );

      expect(
        actualResult.evaluatedQuestionCount,
        expectedResult.evaluatedQuestionCount,
      );

      expect(
        actualResult.totalQuestionCount,
        expectedResult.totalQuestionCount,
      );

      expect(
        actualResult.evaluatedCategoryCount,
        expectedResult.evaluatedCategoryCount,
      );

      expect(
        actualResult.totalCategoryCount,
        expectedResult.totalCategoryCount,
      );

      expect(
        actualResult.hasFinalScore,
        isTrue,
      );

      expect(
        dashboardData.hasFinalScore,
        isTrue,
      );

      expect(
        dashboardData.healthScore,
        expectedResult.overallScore,
      );
    },
  );
}
