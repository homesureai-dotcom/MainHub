import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence_repository.dart';
import 'package:homesure_ai/core/evidence/in_memory_evidence_repository.dart';
import 'package:homesure_ai/core/engine/models/property_health_result.dart';
import 'package:homesure_ai/features/dashboard/coordinators/dashboard_data_coordinator.dart';
import 'package:homesure_ai/features/dashboard/coordinators/dashboard_priority_mapper.dart';
import 'package:homesure_ai/features/dashboard/models/dashboard_priority.dart';
import 'package:homesure_ai/features/property/models/assessment_summary.dart';
import 'package:homesure_ai/features/property/models/compliance_summary.dart';
import 'package:homesure_ai/features/property/models/document_summary.dart';
import 'package:homesure_ai/features/property/models/property.dart';
import 'package:homesure_ai/features/property/state/property_state.dart';
import 'package:homesure_ai/models/property_health/recommendation.dart';
import 'package:homesure_ai/state/assessment_state.dart';

class TestDashboardPriorityMapper
    extends DashboardPriorityMapper {
  final List<DashboardPriority> mappedPriorities;
  PropertyHealthResult? receivedHealthResult;

  TestDashboardPriorityMapper({
    required this.mappedPriorities,
  });

  @override
  List<DashboardPriority> map(
    PropertyHealthResult? healthResult,
  ) {
    receivedHealthResult = healthResult;
    return mappedPriorities;
  }
}

void main() {
  late PropertyState propertyState;
  late AssessmentState assessmentState;

  setUp(() {
    propertyState = PropertyState.instance;
    assessmentState = AssessmentState.instance;

    propertyState.clear();
    assessmentState.clearAssessment();
  });

  tearDown(() {
    propertyState.clear();
    assessmentState.clearAssessment();
  });

  Property createProperty({
    String id = 'property-1',
    String name = 'Test Apartment',
  }) {
    return Property(
      id: id,
      name: name,
      builderName: 'Test Builder',
      ownerName: 'Test Owner',
      address: const Address(
        line1: '123 Test Street',
        city: 'Bengaluru',
        state: 'Karnataka',
        pincode: '560001',
      ),
      type: PropertyType.apartment,
      yearOfConstruction: 2025,
      carpetArea: 708,
      totalUnits: 333,
      compliance: const ComplianceSummary(
        verifiedCount: 3,
        pendingCount: 1,
        issueCount: 0,
        compliancePercentage: 75,
      ),
      assessment: const AssessmentSummary(),
      documents: const DocumentSummary(
        verifiedDocuments: 2,
        pendingDocuments: 1,
        missingDocuments: 0,
      ),
    );
  }

  test(
    'returns null when there is no selected property',
    () async {
      final coordinator = DashboardDataCoordinator(
        propertyState: propertyState,
        assessmentState: assessmentState,
      );

      final data = await coordinator.build();

      expect(data, isNull);
    },
  );

  test(
    'returns property data when a property is selected',
    () async {
      final property = createProperty();

      propertyState.initialize(
        properties: [property],
      );

      final coordinator = DashboardDataCoordinator(
        propertyState: propertyState,
        assessmentState: assessmentState,
      );

      final data = await coordinator.build();

      expect(data, isNotNull);
      expect(data!.property, property);
      expect(data.property.id, 'property-1');
      expect(data.hasAssessment, isFalse);
      expect(data.healthScore, isNull);
      expect(data.priorities, isEmpty);
    },
  );

  test(
    'does not invent a health result when there are no answers',
    () async {
      propertyState.initialize(
        properties: [createProperty()],
      );

      final coordinator = DashboardDataCoordinator(
        propertyState: propertyState,
        assessmentState: assessmentState,
      );

      final data = await coordinator.build();

      expect(data, isNotNull);
      expect(data!.healthResult, isNull);
      expect(data.hasAssessment, isFalse);
      expect(data.hasFinalScore, isFalse);
      expect(data.priorities, isEmpty);
    },
  );

  test(
    'builds evidence summary from the shared assessment repository',
    () async {
      propertyState.initialize(
        properties: [createProperty()],
      );

      final coordinator = DashboardDataCoordinator(
        propertyState: propertyState,
        assessmentState: assessmentState,
      );

      final data = await coordinator.build();

      expect(data, isNotNull);
      expect(data!.evidenceSummary, isNotNull);

      expect(
        data.totalEvidenceRequirements,
        greaterThan(0),
      );

      expect(
        data.evidenceCoveragePercentage,
        0,
      );

      expect(
        data.hasEvidenceGaps,
        isTrue,
      );
    },
  );

  test(
    'uses the shared evidence repository instance',
    () async {
      propertyState.initialize(
        properties: [createProperty()],
      );

      final EvidenceRepository repository =
          assessmentState.evidenceRepository;

      expect(
        repository,
        isA<InMemoryEvidenceRepository>(),
      );

      final coordinator = DashboardDataCoordinator(
        propertyState: propertyState,
        assessmentState: assessmentState,
      );

      final data = await coordinator.build();

      expect(data, isNotNull);
      expect(data!.evidenceSummary, isNotNull);
    },
  );

  test(
    'exposes mapper priorities through dashboard data',
    () async {
      propertyState.initialize(
        properties: [createProperty()],
      );

      const expectedPriority = DashboardPriority(
        id: 'priority-001',
        title: 'Complete e-Khata',
        description: 'Complete the pending e-Khata process.',
        priority: RecommendationPriority.high,
        estimatedPHIGain: 8,
        requiredDocuments: [
          'Sale Deed',
          'Khata Certificate',
        ],
      );

      final mapper = TestDashboardPriorityMapper(
        mappedPriorities: const [
          expectedPriority,
        ],
      );

      final coordinator = DashboardDataCoordinator(
        propertyState: propertyState,
        assessmentState: assessmentState,
        priorityMapper: mapper,
      );

      final data = await coordinator.build();

      expect(data, isNotNull);
      expect(data!.priorities, hasLength(1));
      expect(data.priorities.first, expectedPriority);

      expect(data.hasPriorities, isTrue);
      expect(data.criticalPriorityCount, 0);
      expect(data.highPriorityCount, 1);
      expect(data.hasCriticalPriorities, isFalse);
      expect(data.hasHighPriorities, isTrue);
    },
  );

  test(
    'passes the generated health result to the priority mapper',
    () async {
      propertyState.initialize(
        properties: [createProperty()],
      );

      final mapper = TestDashboardPriorityMapper(
        mappedPriorities: const [],
      );

      final coordinator = DashboardDataCoordinator(
        propertyState: propertyState,
        assessmentState: assessmentState,
        priorityMapper: mapper,
      );

      final data = await coordinator.build();

      expect(data, isNotNull);
      expect(mapper.receivedHealthResult, isNull);
    },
  );
}