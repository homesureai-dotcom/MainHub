enum TimelineStatus {
  completed,
  ongoing,
  pending,
}

class TimelineEvent {
  final String title;
  final String date;
  final TimelineStatus status;
  final String description;

  /// Optional authority issuing the milestone
  final String? authority;

  /// Optional document reference number
  final String? referenceNumber;

  const TimelineEvent({
    required this.title,
    required this.date,
    required this.status,
    required this.description,
    this.authority,
    this.referenceNumber,
  });
}