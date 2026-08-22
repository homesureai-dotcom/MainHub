/// Property Health Standard (PHS) Categories.
///
/// These categories represent the six pillars used to evaluate
/// a property's overall HomeSure Property Health Score.
enum PHSCategory {
  legalOwnership,
  constructionQuality,
  utilitiesInfrastructure,
  safetyCompliance,
  communityMaintenance,
  documentation,
}

/// Extension providing metadata for each PHS category.
extension PHSCategoryExtension on PHSCategory {
  /// Display name shown in the UI.
  String get displayName {
    switch (this) {
      case PHSCategory.legalOwnership:
        return "Legal & Ownership";

      case PHSCategory.constructionQuality:
        return "Construction Quality";

      case PHSCategory.utilitiesInfrastructure:
        return "Utilities & Infrastructure";

      case PHSCategory.safetyCompliance:
        return "Safety & Compliance";

      case PHSCategory.communityMaintenance:
        return "Community & Maintenance";

      case PHSCategory.documentation:
        return "Documentation";
    }
  }

  /// Description of the category.
  String get description {
    switch (this) {
      case PHSCategory.legalOwnership:
        return "Verifies legal ownership, approvals and statutory compliance.";

      case PHSCategory.constructionQuality:
        return "Evaluates structural integrity, workmanship and construction quality.";

      case PHSCategory.utilitiesInfrastructure:
        return "Measures the readiness and reliability of utilities and infrastructure.";

      case PHSCategory.safetyCompliance:
        return "Evaluates fire safety, emergency preparedness and statutory safety compliance.";

      case PHSCategory.communityMaintenance:
        return "Measures community management, maintenance and operational readiness.";

      case PHSCategory.documentation:
        return "Assesses availability and completeness of supporting property documents.";
    }
  }

  /// Weight (%) used in the overall HomeSure Property Health Score.
  double get weight {
    switch (this) {
      case PHSCategory.legalOwnership:
        return 25.0;

      case PHSCategory.constructionQuality:
        return 25.0;

      case PHSCategory.utilitiesInfrastructure:
        return 15.0;

      case PHSCategory.safetyCompliance:
        return 15.0;

      case PHSCategory.communityMaintenance:
        return 10.0;

      case PHSCategory.documentation:
        return 10.0;
    }
  }

  /// Icon used throughout the application.
  String get icon {
    switch (this) {
      case PHSCategory.legalOwnership:
        return "⚖️";

      case PHSCategory.constructionQuality:
        return "🏗️";

      case PHSCategory.utilitiesInfrastructure:
        return "⚡";

      case PHSCategory.safetyCompliance:
        return "🛡️";

      case PHSCategory.communityMaintenance:
        return "🏘️";

      case PHSCategory.documentation:
        return "📄";
    }
  }

  /// Color identifier (for future UI theming).
  String get colorName {
    switch (this) {
      case PHSCategory.legalOwnership:
        return "blue";

      case PHSCategory.constructionQuality:
        return "orange";

      case PHSCategory.utilitiesInfrastructure:
        return "green";

      case PHSCategory.safetyCompliance:
        return "red";

      case PHSCategory.communityMaintenance:
        return "purple";

      case PHSCategory.documentation:
        return "teal";
    }
  }
}