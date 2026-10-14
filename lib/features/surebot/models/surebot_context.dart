import '../../../core/phs/phs_categories.dart';
import '../../../models/property_health/recommendation.dart';

/// A read-only snapshot of the property information that SureBot
/// can use when answering contextual questions.
///
/// This model contains structured facts only.
/// It does not contain generated AI responses or business rules.
class SureBotContext {
  final SureBotPropertyContext property;
  final SureBotHealthContext health;
  final SureBotEvidenceContext evidence;
  final SureBotPriorityContext? currentPriority;

  const SureBotContext({
    required this.property,
    required this.health,
    required this.evidence,
    this.currentPriority,
  });

  bool get hasPriority => currentPriority != null;

  bool get hasAssessment => health.hasAssessment;

  bool get hasEvidence => evidence.totalRequirements > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is SureBotContext &&
        other.property == property &&
        other.health == health &&
        other.evidence == evidence &&
        other.currentPriority == currentPriority;
  }

  @override
  int get hashCode => Object.hash(
        property,
        health,
        evidence,
        currentPriority,
      );

  @override
  String toString() {
    return 'SureBotContext('
        'property: ${property.name}, '
        'healthScore: ${health.score}, '
        'currentPriority: ${currentPriority?.title}'
        ')';
  }
}

/// Property information available to SureBot.
class SureBotPropertyContext {
  final String id;
  final String name;
  final String builderName;
  final String ownerName;
  final String city;
  final String state;
  final String propertyType;
  final int yearOfConstruction;

  const SureBotPropertyContext({
    required this.id,
    required this.name,
    required this.builderName,
    required this.ownerName,
    required this.city,
    required this.state,
    required this.propertyType,
    required this.yearOfConstruction,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is SureBotPropertyContext &&
        other.id == id &&
        other.name == name &&
        other.builderName == builderName &&
        other.ownerName == ownerName &&
        other.city == city &&
        other.state == state &&
        other.propertyType == propertyType &&
        other.yearOfConstruction == yearOfConstruction;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        builderName,
        ownerName,
        city,
        state,
        propertyType,
        yearOfConstruction,
      );
}

/// Assessment and Property Health information available to SureBot.
class SureBotHealthContext {
  final double? score;
  final String? grade;
  final bool hasAssessment;
  final bool isComplete;
  final int evaluatedQuestionCount;
  final int totalQuestionCount;
  final double questionCompletionPercentage;
  final int evaluatedCategoryCount;
  final int totalCategoryCount;
  final int riskCount;
  final int recommendationCount;

  const SureBotHealthContext({
    required this.score,
    required this.grade,
    required this.hasAssessment,
    required this.isComplete,
    required this.evaluatedQuestionCount,
    required this.totalQuestionCount,
    required this.questionCompletionPercentage,
    required this.evaluatedCategoryCount,
    required this.totalCategoryCount,
    required this.riskCount,
    required this.recommendationCount,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is SureBotHealthContext &&
        other.score == score &&
        other.grade == grade &&
        other.hasAssessment == hasAssessment &&
        other.isComplete == isComplete &&
        other.evaluatedQuestionCount == evaluatedQuestionCount &&
        other.totalQuestionCount == totalQuestionCount &&
        other.questionCompletionPercentage ==
            questionCompletionPercentage &&
        other.evaluatedCategoryCount ==
            evaluatedCategoryCount &&
        other.totalCategoryCount == totalCategoryCount &&
        other.riskCount == riskCount &&
        other.recommendationCount == recommendationCount;
  }

  @override
  int get hashCode => Object.hash(
        score,
        grade,
        hasAssessment,
        isComplete,
        evaluatedQuestionCount,
        totalQuestionCount,
        questionCompletionPercentage,
        evaluatedCategoryCount,
        totalCategoryCount,
        riskCount,
        recommendationCount,
      );
}

/// Overall evidence state available to SureBot.
class SureBotEvidenceContext {
  final double coveragePercentage;
  final int totalRequirements;
  final int satisfiedRequirements;
  final int providedRequirements;
  final int needsReviewRequirements;
  final int missingRequirements;
  final int rejectedRequirements;
  final int activeRiskCount;

  const SureBotEvidenceContext({
    required this.coveragePercentage,
    required this.totalRequirements,
    required this.satisfiedRequirements,
    required this.providedRequirements,
    required this.needsReviewRequirements,
    required this.missingRequirements,
    required this.rejectedRequirements,
    required this.activeRiskCount,
  });

  bool get hasGaps =>
      missingRequirements > 0 ||
      needsReviewRequirements > 0 ||
      rejectedRequirements > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is SureBotEvidenceContext &&
        other.coveragePercentage == coveragePercentage &&
        other.totalRequirements == totalRequirements &&
        other.satisfiedRequirements == satisfiedRequirements &&
        other.providedRequirements == providedRequirements &&
        other.needsReviewRequirements ==
            needsReviewRequirements &&
        other.missingRequirements == missingRequirements &&
        other.rejectedRequirements ==
            rejectedRequirements &&
        other.activeRiskCount == activeRiskCount;
  }

  @override
  int get hashCode => Object.hash(
        coveragePercentage,
        totalRequirements,
        satisfiedRequirements,
        providedRequirements,
        needsReviewRequirements,
        missingRequirements,
        rejectedRequirements,
        activeRiskCount,
      );
}

/// The priority currently being discussed with SureBot.
class SureBotPriorityContext {
  final String id;
  final String title;
  final String description;
  final RecommendationPriority priority;
  final int estimatedPHIGain;
  final List<String> requiredDocuments;
  final PHSCategory? category;

  const SureBotPriorityContext({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.estimatedPHIGain,
    required this.requiredDocuments,
    this.category,
  });

  bool get isCritical =>
      priority == RecommendationPriority.critical;

  bool get isHigh =>
      priority == RecommendationPriority.high;

  bool get isMedium =>
      priority == RecommendationPriority.medium;

  bool get isLow =>
      priority == RecommendationPriority.low;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is SureBotPriorityContext &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.priority == priority &&
        other.estimatedPHIGain == estimatedPHIGain &&
        _listEquals(
          other.requiredDocuments,
          requiredDocuments,
        ) &&
        other.category == category;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        priority,
        estimatedPHIGain,
        Object.hashAll(requiredDocuments),
        category,
      );

  static bool _listEquals(
    List<String> first,
    List<String> second,
  ) {
    if (first.length != second.length) {
      return false;
    }

    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) {
        return false;
      }
    }

    return true;
  }
}
