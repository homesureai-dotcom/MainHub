import 'phs_categories.dart';

class PHSCategoryMetadata {
  static String displayName(PHSCategory category) {
    switch (category) {
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

  static String icon(PHSCategory category) {
    switch (category) {
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
}