import '../models/apartment.dart';
import '../enums/compliance_status.dart';

class ApartmentScoreService {
  static int calculateHealthScore(Apartment apartment) {
    int score = 0;

    for (final item in apartment.complianceItems) {
      switch (item.status) {
        case ComplianceStatus.verified:
          score += item.weight ~/ 2;
          break;

        case ComplianceStatus.pending:
          score += item.weight ~/ 2;
          break;

        case ComplianceStatus.issue:
          break;

        case ComplianceStatus.notApplicable:
          score += item.weight ~/ 2;
          break;
      }
    }

    return score;
  }
}