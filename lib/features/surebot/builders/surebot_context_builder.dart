import '../../dashboard/models/dashboard_data.dart';
import '../../dashboard/models/dashboard_priority.dart';
import '../models/surebot_context.dart';

/// Builds the structured context that SureBot can use.
///
/// This class intentionally contains no AI generation logic.
/// DashboardData remains the source of truth for the values.
class SureBotContextBuilder {
  const SureBotContextBuilder();

  SureBotContext build(
    DashboardData data, {
    DashboardPriority? currentPriority,
  }) {
    return SureBotContext(
      property: SureBotPropertyContext(
        id: data.property.id,
        name: data.property.name,
        builderName: data.property.builderName,
        ownerName: data.property.ownerName,
        city: data.property.address.city,
        state: data.property.address.state,
        propertyType: _propertyTypeLabel(
          data.property.type,
        ),
        yearOfConstruction: data.property.yearOfConstruction,
      ),
      health: SureBotHealthContext(
        score: data.healthScore,
        grade: data.healthGrade,
        hasAssessment: data.hasAssessment,
        isComplete: data.isAssessmentComplete,
        evaluatedQuestionCount:
            data.evaluatedQuestionCount,
        totalQuestionCount:
            data.totalQuestionCount,
        questionCompletionPercentage:
            data.questionCompletionPercentage,
        evaluatedCategoryCount:
            data.evaluatedCategoryCount,
        totalCategoryCount:
            data.totalCategoryCount,
        riskCount: data.riskCount,
        recommendationCount:
            data.recommendationCount,
      ),
      evidence: SureBotEvidenceContext(
        coveragePercentage:
            data.evidenceCoveragePercentage,
        totalRequirements:
            data.totalEvidenceRequirements,
        satisfiedRequirements:
            data.satisfiedEvidenceRequirements,
        providedRequirements:
            data.evidenceSummary?.providedRequirements ?? 0,
        needsReviewRequirements:
            data.evidenceNeedsReviewCount,
        missingRequirements:
            data.missingEvidenceCount,
        rejectedRequirements:
            data.rejectedEvidenceCount,
        activeRiskCount:
            data.activeEvidenceRiskCount,
      ),
      currentPriority: currentPriority == null
          ? null
          : _buildPriorityContext(currentPriority),
    );
  }

  SureBotPriorityContext _buildPriorityContext(
    DashboardPriority priority,
  ) {
    return SureBotPriorityContext(
      id: priority.id,
      title: priority.title,
      description: priority.description,
      priority: priority.priority,
      estimatedPHIGain:
          priority.estimatedPHIGain,
      requiredDocuments:
          List.unmodifiable(
        priority.requiredDocuments,
      ),
      category: priority.category,
    );
  }

  String _propertyTypeLabel(
    dynamic type,
  ) {
    switch (type.toString().split('.').last) {
      case 'apartment':
        return 'Apartment';
      case 'villa':
        return 'Villa';
      case 'plot':
        return 'Plot';
      case 'commercial':
        return 'Commercial';
      default:
        return type.toString();
    }
  }
}