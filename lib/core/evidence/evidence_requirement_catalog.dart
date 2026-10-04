import '../phs/phs_question.dart';
import 'evidence_requirement.dart';
import 'evidence_requirement_resolver.dart';

/// Provides indexed access to the canonical evidence requirements
/// defined by the Property Health Standard (PHS) questions.
///
/// The catalog delegates requirement construction to
/// [EvidenceRequirementResolver], ensuring that PHS evidence definitions
/// remain the single source of truth.
class EvidenceRequirementCatalog {
  final EvidenceRequirementResolver _resolver;

  const EvidenceRequirementCatalog({
    required EvidenceRequirementResolver resolver,
  }) : _resolver = resolver;

  /// Returns all evidence requirements for the supplied PHS questions.
  ///
  /// The returned map is keyed by canonical PHS question ID.
  Map<String, List<EvidenceRequirement>> getForQuestions(
    List<PHSQuestion> questions,
  ) {
    return _resolver.resolveAll(questions);
  }

  /// Returns all evidence requirements for a single PHS question.
  List<EvidenceRequirement> getForQuestion(
    PHSQuestion question,
  ) {
    return _resolver.resolve(question);
  }

  /// Returns evidence requirements for a canonical question ID.
  ///
  /// Returns an empty list when the question ID is unknown.
  List<EvidenceRequirement> getForQuestionId(
    String questionId,
  ) {
    return _resolver.resolveByQuestionId(questionId);
  }

  /// Returns whether a canonical question has at least one
  /// evidence requirement.
  bool hasRequirements(String questionId) {
    return getForQuestionId(questionId).isNotEmpty;
  }

  /// Returns whether the supplied requirement exists for the question.
  bool containsRequirement({
    required String questionId,
    required String label,
  }) {
    final requirements = getForQuestionId(questionId);

    return requirements.any(
      (requirement) => requirement.label == label,
    );
  }

  /// Returns all requirements from the supplied questions as a
  /// single immutable list.
  List<EvidenceRequirement> flatten(
    List<PHSQuestion> questions,
  ) {
    final requirements = <EvidenceRequirement>[];

    for (final question in questions) {
      requirements.addAll(
        getForQuestion(question),
      );
    }

    return List.unmodifiable(requirements);
  }
}