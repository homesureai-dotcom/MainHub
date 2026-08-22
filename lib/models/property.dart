class Property {
  final String id;
  final String name;
  final String builder;
  final String city;

  final int overallScore;

  final int legalScore;
  final int utilityScore;
  final int safetyScore;
  final int builderScore;

  final bool verified;

  const Property({
    required this.id,
    required this.name,
    required this.builder,
    required this.city,
    required this.overallScore,
    required this.legalScore,
    required this.utilityScore,
    required this.safetyScore,
    required this.builderScore,
    required this.verified,
  });
}