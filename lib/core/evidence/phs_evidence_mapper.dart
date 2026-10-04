import '../../core/phs/phs_question.dart';
import 'evidence_requirement.dart';
import 'evidence_type_mapper.dart';

/// Converts the evidence requirements already defined on PHS questions
/// into structured Sprint 9 evidence requirements.
///
/// `PHSQuestion.requiredEvidence` remains the single source of truth.
/// This mapper does not maintain a second list of evidence definitions.
class PHSEvidenceMapper {
  final EvidenceTypeMapper _typeMapper;

  const PHSEvidenceMapper({
    EvidenceTypeMapper typeMapper = const EvidenceTypeMapper(),
  }) : _typeMapper = typeMapper;

  /// Maps all evidence requirements for a PHS question.
  List<EvidenceRequirement> mapQuestion(
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

  /// Maps the evidence requirements for every supplied PHS question.
  Map<String, List<EvidenceRequirement>> mapQuestions(
    List<PHSQuestion> questions,
  ) {
    return Map.unmodifiable({
      for (final question in questions)
        question.id: mapQuestion(question),
    });
  }
}