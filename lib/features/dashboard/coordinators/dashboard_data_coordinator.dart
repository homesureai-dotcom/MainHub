import '../../../core/engine/engine.dart';
import '../../../core/engine/models/property_health_result.dart';
import '../../../core/evidence/assessment_evidence_summary.dart';
import '../../../core/evidence/assessment_evidence_summary_builder.dart';
import '../../../core/evidence/evidence_requirement_catalog.dart';
import '../../../core/evidence/evidence_requirement_resolver.dart';
import '../../../core/evidence/evidence_type_mapper.dart';
import '../../../core/evidence/evidence_validator.dart';
import '../../../data/phs_questions.dart';
import '../../../state/assessment_state.dart';
import '../../property/state/property_state.dart';
import '../models/dashboard_data.dart';
import 'dashboard_priority_mapper.dart';

class DashboardDataCoordinator {
  final PropertyState _propertyState;
  final AssessmentState _assessmentState;
  final DashboardPriorityMapper _priorityMapper;

  DashboardDataCoordinator({
    required this._propertyState,
    required this._assessmentState,
    this._priorityMapper = const DashboardPriorityMapper(),
  });

  Future<DashboardData?> build() async {
    final property = _propertyState.selectedProperty;

    if (property == null) {
      return null;
    }

    final healthResult = _buildHealthResult();
    final evidenceSummary = await _buildEvidenceSummary();
    final priorities = _priorityMapper.map(healthResult);

    return DashboardData(
      property: property,
      healthResult: healthResult,
      evidenceSummary: evidenceSummary,
      priorities: priorities,
    );
  }

  PropertyHealthResult? _buildHealthResult() {
    if (_assessmentState.answers.isEmpty) {
      return null;
    }

    final engine = PropertyIntelligenceEngine();

    return engine.evaluateAssessment(
      _assessmentState.answers,
    );
  }

  Future<AssessmentEvidenceSummary?> _buildEvidenceSummary() async {
    final evidence =
        await _assessmentState.evidenceRepository.getAll();

    final typeMapper = const EvidenceTypeMapper();

    final resolver = EvidenceRequirementResolver(
      typeMapper: typeMapper,
    );

    final catalog = EvidenceRequirementCatalog(
      resolver: resolver,
    );

    final validator = EvidenceValidator();

    final requirements = catalog.flatten(
      phsQuestions,
    );

    final builder = AssessmentEvidenceSummaryBuilder(
      validator: validator,
    );

    return builder.build(
      requirements: requirements,
      evidence: evidence,
    );
  }
}