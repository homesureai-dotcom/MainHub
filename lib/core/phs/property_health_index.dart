enum PropertyHealthStatus {
  certifiedHealthy,
  healthy,
  needsAttention,
  highRisk,
  critical,
}

extension PropertyHealthStatusExtension on PropertyHealthStatus {
  String get title {
    switch (this) {
      case PropertyHealthStatus.certifiedHealthy:
        return "Certified Healthy";

      case PropertyHealthStatus.healthy:
        return "Healthy";

      case PropertyHealthStatus.needsAttention:
        return "Needs Attention";

      case PropertyHealthStatus.highRisk:
        return "High Risk";

      case PropertyHealthStatus.critical:
        return "Critical";
    }
  }

  String get description {
    switch (this) {
      case PropertyHealthStatus.certifiedHealthy:
        return "Your property demonstrates excellent legal, technical and operational health.";

      case PropertyHealthStatus.healthy:
        return "Your property is in good condition with only minor improvements recommended.";

      case PropertyHealthStatus.needsAttention:
        return "Several improvements are recommended to improve the property's overall health.";

      case PropertyHealthStatus.highRisk:
        return "Important issues should be addressed to reduce future legal and operational risks.";

      case PropertyHealthStatus.critical:
        return "Immediate action is recommended to protect the property's value and compliance.";
    }
  }
}

class PropertyHealthIndex {
  final int score;

  const PropertyHealthIndex({
    required this.score,
  });

  PropertyHealthStatus get status {
    if (score >= 90) {
      return PropertyHealthStatus.certifiedHealthy;
    }

    if (score >= 75) {
      return PropertyHealthStatus.healthy;
    }

    if (score >= 60) {
      return PropertyHealthStatus.needsAttention;
    }

    if (score >= 40) {
      return PropertyHealthStatus.highRisk;
    }

    return PropertyHealthStatus.critical;
  }

  int get potentialImprovement => 100 - score;

  bool get isExcellent => score >= 90;

  bool get needsImmediateAttention => score < 40;
}