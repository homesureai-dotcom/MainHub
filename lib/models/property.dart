class Property {
  final String id;
  final String name;
  final String builder;
  final String city;

  /// Locality or neighbourhood where the project is located.
  final String locality;

  /// RERA registration number, when available.
  final String reraNumber;

  final int overallScore;
  final int legalScore;
  final int utilityScore;
  final int safetyScore;
  final int builderScore;

  /// Indicates the existing catalogue verification flag.
  /// This must not be treated as proof of legal compliance
  /// without independently reviewed supporting evidence.
  final bool verified;

  const Property({
    required this.id,
    required this.name,
    required this.builder,
    required this.city,
    this.locality = '',
    this.reraNumber = '',
    required this.overallScore,
    required this.legalScore,
    required this.utilityScore,
    required this.safetyScore,
    required this.builderScore,
    required this.verified,
  });
}
