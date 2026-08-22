enum AssessmentResponse {
  yes,
  no,
  unsure,
}

class AssessmentAnswer {
  final String questionId;
  final AssessmentResponse response;

  const AssessmentAnswer({
    required this.questionId,
    required this.response,
  });
}