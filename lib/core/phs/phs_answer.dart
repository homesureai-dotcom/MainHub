/// User responses supported by the HomeSure Property Health Standard.
///
/// Future versions can introduce:
/// - notApplicable
/// - pendingVerification
enum PHSResponse {
  yes,
  unsure,
  no,
}

extension PHSResponseExtension on PHSResponse {
  /// Normalized score used by the Assessment Engine.
  ///
  /// Yes     = 1.0
  /// Unsure = 0.5
  /// No      = 0.0
  double get value {
    switch (this) {
      case PHSResponse.yes:
        return 1.0;

      case PHSResponse.unsure:
        return 0.5;

      case PHSResponse.no:
        return 0.0;
    }
  }

  String get displayName {
    switch (this) {
      case PHSResponse.yes:
        return "Yes";

      case PHSResponse.unsure:
        return "Unsure";

      case PHSResponse.no:
        return "No";
    }
  }
}

/// Represents one user's answer to one PHS question.
class PHSAnswer {
  /// Question identifier.
  final String questionId;

  /// User's response.
  final PHSResponse response;

  const PHSAnswer({
    required this.questionId,
    required this.response,
  });
}