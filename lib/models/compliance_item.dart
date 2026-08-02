import '../enums/compliance_status.dart';

class ComplianceItem {
  final String title;
  final ComplianceStatus status;
  final int weight;
  final String recommendation;

  const ComplianceItem({
    required this.title,
    required this.status,
    required this.weight,
    required this.recommendation,
  });
}