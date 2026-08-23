import '../questions/question_rule.dart';
import '../questions/occupancy_certificate_rule.dart';
import '../questions/sale_deed_rule.dart';
import '../questions/ekhata_rule.dart';
import '../questions/encumbrance_rule.dart';

/// Registers every assessment rule in the system.
///
/// The PropertyHealthEngine never creates rules directly.
/// It simply asks the registry for the correct rule.
class QuestionRuleRegistry {
  const QuestionRuleRegistry();

  QuestionRule? getRule(String questionId) {
    switch (questionId) {
      case "LEGAL_OC":
        return const OccupancyCertificateRule();

      case "LEGAL_SD":
        return const SaleDeedRule();

      case "LEGAL_KHATA":
        return const EkhataRule();

      case "LEGAL_EC":
        return const EncumbranceRule();

      default:
        return null;
    }
  }
}