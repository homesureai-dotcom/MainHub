class DocumentSummary {
  final int verifiedDocuments;

  final int pendingDocuments;

  final int missingDocuments;

  const DocumentSummary({
    required this.verifiedDocuments,
    required this.pendingDocuments,
    required this.missingDocuments,
  });

  int get totalDocuments =>
      verifiedDocuments +
      pendingDocuments +
      missingDocuments;

  bool get hasMissingDocuments =>
      missingDocuments > 0;
}