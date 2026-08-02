import 'compliance_item.dart';
import 'timeline_event.dart';

class Apartment {
  final String projectName;
  final String builder;
  final String city;

  final int healthScore;

  final bool rera;
  final bool oc;
  final bool fireNoc;
  final bool bwssb;
  final bool bescom;
  final bool eKhata;
  final bool stp;

  final String priorityTask;
  final int estimatedMinutes;

  final List<ComplianceItem> complianceItems;
  final List<TimelineEvent> timeline;

  Apartment({
    required this.projectName,
    required this.builder,
    required this.city,
    required this.healthScore,
    required this.rera,
    required this.oc,
    required this.fireNoc,
    required this.bwssb,
    required this.bescom,
    required this.eKhata,
    required this.stp,
    required this.priorityTask,
    required this.estimatedMinutes,
    required this.complianceItems,
    required this.timeline,
  });
}