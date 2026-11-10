import '../../../core/evidence/evidence_repository.dart';
import '../../../core/evidence/evidence_requirement.dart';
import '../../../core/evidence/evidence_requirement_catalog.dart';
import '../../../core/evidence/evidence_requirement_resolver.dart';
import '../../../core/evidence/evidence_type_mapper.dart';
import '../../../core/evidence/evidence_validator.dart';
import '../../../data/phs_questions.dart';
import '../models/dashboard_priority.dart';
import '../models/priority_evidence_context.dart';

/// Resolves the evidence requirements associated with a dashboard priority.
///
/// The resolver deliberately uses the existing PHS evidence definitions,
/// repository, and validator. It does not create or modify evidence rules
/// and does not participate in PHS scoring.
class PriorityEvidenceResolver {
  final EvidenceRepository _repository;
  final EvidenceRequirementCatalog _catalog;
  final EvidenceValidator _validator;

  const PriorityEvidenceResolver({
    required EvidenceRepository repository,
    EvidenceRequirementCatalog? catalog,
    EvidenceValidator? validator,
  })  : _repository = repository,
        _catalog = catalog ??
            const EvidenceRequirementCatalog(
              resolver: EvidenceRequirementResolver(
                typeMapper: EvidenceTypeMapper(),
              ),
            ),
        _validator = validator ?? const EvidenceValidator();

  /// Resolves evidence context for all requirements represented by
  /// [priority.requiredDocuments].
  ///
  /// A priority may contain document labels that correspond to canonical
  /// PHS evidence requirements. Only matching canonical requirements are
  /// returned.
  Future<List<PriorityEvidenceContext>> resolve(
    DashboardPriority priority,
  ) async {
    if (priority.requiredDocuments.isEmpty) {
      return const [];
    }

    final contexts = <PriorityEvidenceContext>[];

    for (final documentLabel in priority.requiredDocuments) {
      final requirement = _findRequirement(
        documentLabel,
      );

      if (requirement == null) {
        continue;
      }

      final evidence = await _repository.getByQuestionId(
        requirement.questionId,
      );

      final validation = _validator.validate(
        requirement,
        evidence,
      );

      contexts.add(
        PriorityEvidenceContext(
          requirement: requirement,
          evidence: List.unmodifiable(evidence),
          validation: validation,
        ),
      );
    }

    return List.unmodifiable(contexts);
  }

  /// Resolves one specific evidence requirement label.
  ///
  /// Returns null when the label does not correspond to a canonical PHS
  /// evidence requirement.
  EvidenceRequirement? _findRequirement(
    String documentLabel,
  ) {
    for (final question in phsQuestions) {
      final requirements = _catalog.getForQuestion(question);

      for (final requirement in requirements) {
        if (requirement.label == documentLabel) {
          return requirement;
        }
      }
    }

    return null;
  }
}