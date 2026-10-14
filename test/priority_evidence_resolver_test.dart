import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';
import 'package:homesure_ai/core/evidence/evidence_validation_result.dart';
import 'package:homesure_ai/core/evidence/in_memory_evidence_repository.dart';
import 'package:homesure_ai/features/dashboard/models/dashboard_priority.dart';
import 'package:homesure_ai/features/dashboard/models/priority_evidence_context.dart';
import 'package:homesure_ai/features/dashboard/services/priority_evidence_resolver.dart';
import 'package:homesure_ai/models/property_health/recommendation.dart';

void main() {
  group('PriorityEvidenceResolver', () {
    late InMemoryEvidenceRepository repository;
    late PriorityEvidenceResolver resolver;

    setUp(() {
      repository = InMemoryEvidenceRepository();

      resolver = PriorityEvidenceResolver(
        repository: repository,
      );
    });

    DashboardPriority createPriority({
      List<String> requiredDocuments = const [
        'Registered Sale Deed',
      ],
    }) {
      return DashboardPriority(
        id: 'OBTAIN_SD',
        title: 'Obtain Registered Sale Deed',
        description:
            'Obtain and verify the registered Sale Deed for the property.',
        priority: RecommendationPriority.critical,
        estimatedPHIGain: 25,
        requiredDocuments: requiredDocuments,
      );
    }

    Evidence createEvidence({
      String id = 'E1',
      EvidenceStatus status = EvidenceStatus.provided,
      String? requirementId,
    }) {
      return Evidence(
        id: id,
        questionId: 'LEGAL_SD',
        requirementId: requirementId,
        type: EvidenceType.document,
        name: 'Registered Sale Deed',
        status: status,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 10, 14),
      );
    }

    test(
      'resolves Registered Sale Deed to the canonical LEGAL_SD requirement',
      () async {
        final contexts = await resolver.resolve(
          createPriority(),
        );

        expect(contexts, hasLength(1));

        final context = contexts.single;

        expect(
          context.requirement,
          const EvidenceRequirement(
            questionId: 'LEGAL_SD',
            label: 'Registered Sale Deed',
            type: EvidenceType.document,
          ),
        );

        expect(
          context.questionId,
          'LEGAL_SD',
        );

        expect(
          context.label,
          'Registered Sale Deed',
        );
      },
    );

    test(
      'returns missing when no matching evidence exists',
      () async {
        final contexts = await resolver.resolve(
          createPriority(),
        );

        expect(contexts, hasLength(1));

        expect(
          contexts.single.status,
          EvidenceValidationStatus.missing,
        );

        expect(
          contexts.single.isMissing,
          isTrue,
        );

        expect(
          contexts.single.isSatisfied,
          isFalse,
        );
      },
    );

    test(
      'returns provided when evidence exists but is not verified',
      () async {
        await repository.add(
          createEvidence(
            status: EvidenceStatus.provided,
          ),
        );

        final contexts = await resolver.resolve(
          createPriority(),
        );

        expect(contexts, hasLength(1));

        expect(
          contexts.single.status,
          EvidenceValidationStatus.provided,
        );

        expect(
          contexts.single.isProvided,
          isTrue,
        );
      },
    );

    test(
      'returns satisfied when matching evidence is verified',
      () async {
        await repository.add(
          createEvidence(
            status: EvidenceStatus.verified,
          ),
        );

        final contexts = await resolver.resolve(
          createPriority(),
        );

        expect(contexts, hasLength(1));

        expect(
          contexts.single.status,
          EvidenceValidationStatus.satisfied,
        );

        expect(
          contexts.single.isSatisfied,
          isTrue,
        );
      },
    );

    test(
      'returns needsReview when matching evidence requires review',
      () async {
        await repository.add(
          createEvidence(
            status: EvidenceStatus.needsReview,
          ),
        );

        final contexts = await resolver.resolve(
          createPriority(),
        );

        expect(contexts, hasLength(1));

        expect(
          contexts.single.status,
          EvidenceValidationStatus.needsReview,
        );

        expect(
          contexts.single.needsReview,
          isTrue,
        );
      },
    );

    test(
      'returns rejected when matching evidence was rejected',
      () async {
        await repository.add(
          createEvidence(
            status: EvidenceStatus.rejected,
          ),
        );

        final contexts = await resolver.resolve(
          createPriority(),
        );

        expect(contexts, hasLength(1));

        expect(
          contexts.single.status,
          EvidenceValidationStatus.rejected,
        );

        expect(
          contexts.single.isRejected,
          isTrue,
        );
      },
    );

    test(
      'ignores priority documents that are not canonical PHS requirements',
      () async {
        final contexts = await resolver.resolve(
          createPriority(
            requiredDocuments: [
              'Document That Does Not Exist',
            ],
          ),
        );

        expect(contexts, isEmpty);
      },
    );

    test(
      'returns empty context when priority has no required documents',
      () async {
        final contexts = await resolver.resolve(
          createPriority(
            requiredDocuments: const [],
          ),
        );

        expect(contexts, isEmpty);
      },
    );

    test(
      'preserves the evidence returned by the repository',
      () async {
        final evidence = createEvidence(
          status: EvidenceStatus.verified,
        );

        await repository.add(evidence);

        final contexts = await resolver.resolve(
          createPriority(),
        );

        expect(contexts, hasLength(1));
        expect(contexts.single.evidence, hasLength(1));
        expect(contexts.single.evidence.single, evidence);
      },
    );
  });
}