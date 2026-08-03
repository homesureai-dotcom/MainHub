enum DocumentStatus {
  verified,
  pending,
 missing,
 expired,
}

class PropertyDocument {
  final String name;
  final String category;
  final DocumentStatus status;
  final String? uploadedDate;
  final String? expiryDate;

  const PropertyDocument({
    required this.name,
    required this.category,
    required this.status,
    this.uploadedDate,
    this.expiryDate,
  });
}