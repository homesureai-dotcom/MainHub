import '../../data/phs_questions.dart';
import '../phs/phs_question.dart';
import 'evidence_requirement.dart';
import 'evidence_type_mapper.dart';

/// Resolves canonical PHS evidence requirements into domain
/// [EvidenceRequirement] objects.
///
/// The resolver uses the evidence definitions already present on
/// [PHSQuestion.requiredEvidence]. It does not invent additional
/// requirements and does not modify PHS scoring.
class EvidenceRequirementResolver {
  final EvidenceTypeMapper _typeMapper;

  const EvidenceRequirementResolver({
    required this._typeMapper,
  });

  /// Resolves all evidence requirements for a single PHS question.
  List<EvidenceRequirement> resolve(
    PHSQuestion question,
  ) {
    return question.requiredEvidence
        .map(
          (label) => EvidenceRequirement(
            questionId: question.id,
            label: label,
            type: _typeMapper.map(label),
          ),
        )
        .toList(growable: false);
  }

  /// Resolves evidence requirements for multiple PHS questions.
  ///
  /// The returned map uses the canonical PHS question ID as its key.
  Map<String, List<EvidenceRequirement>> resolveAll(
    List<PHSQuestion> questions,
  ) {
    return Map.unmodifiable({
      for (final question in questions)
        question.id: resolve(question),
    });
  }

  /// Resolves requirements for a canonical PHS question ID.
  ///
  /// Returns an empty list when the question ID does not exist.
  List<EvidenceRequirement> resolveByQuestionId(
    String questionId,
  ) {
    for (final question in phsQuestions) {
      if (question.id == questionId) {
        return resolve(question);
      }
    }

    return const [];
  }

  /// Returns whether the supplied question has any evidence requirements.
  bool hasRequirements(
    PHSQuestion question,
  ) {
    return question.requiredEvidence.isNotEmpty;
  }
}