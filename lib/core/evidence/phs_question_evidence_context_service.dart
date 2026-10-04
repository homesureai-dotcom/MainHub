import 'evidence.dart';
import 'evidence_requirement.dart';
import 'evidence_repository.dart';
import 'evidence_requirement_catalog.dart';
import 'phs_question_evidence_context.dart';
import 'phs_question_evidence_context_builder.dart';
import '../phs/phs_question.dart';

/// Provides the application-facing evidence context for a PHS question.
///
/// The service coordinates:
/// - canonical PHS evidence requirements,
/// - persisted evidence,
/// - evidence validation,
/// - evidence risk signals.
///
/// It does not modify or calculate the PHS score.
class PHSQuestionEvidenceContextService {
  final EvidenceRepository _repository;
  final EvidenceRequirementCatalog _catalog;
  final PHSQuestionEvidenceContextBuilder _builder;

  const PHSQuestionEvidenceContextService({
    required EvidenceRepository repository,
    required EvidenceRequirementCatalog catalog,
    required PHSQuestionEvidenceContextBuilder builder,
  })  : _repository = repository,
        _catalog = catalog,
        _builder = builder;

  /// Builds the complete evidence context for a canonical PHS question.
  ///
  /// Returns an empty evidence context when the question has no evidence
  /// requirements or when no evidence has yet been supplied.
  Future<PHSQuestionEvidenceContext> buildForQuestion(
    PHSQuestion question,
  ) async {
    final requirements = _catalog.getForQuestion(question);
    final evidence = await _repository.getByQuestionId(question.id);

    return _builder.build(
      questionId: question.id,
      requirements: requirements,
      evidence: evidence,
    );
  }

  /// Returns the persisted evidence for a PHS question.
  Future<List<Evidence>> getEvidenceForQuestion(
    String questionId,
  ) async {
    final evidence = await _repository.getByQuestionId(questionId);
    return List.unmodifiable(evidence);
  }

  /// Returns the canonical evidence requirements for a PHS question.
  List<EvidenceRequirement> getRequirementsForQuestion(
    PHSQuestion question,
  ) {
    return _catalog.getForQuestion(question);
  }

  /// Returns the canonical evidence requirements for a PHS question ID.
  List<EvidenceRequirement> getRequirementsForQuestionId(
    String questionId,
  ) {
    return _catalog.getForQuestionId(questionId);
  }
}