/// Supported languages for the HomeSureAI SureBot experience.
class SureBotLanguage {
  final String code;
  final String englishName;
  final String nativeName;
  final String aiLanguageName;

  const SureBotLanguage({
    required this.code,
    required this.englishName,
    required this.nativeName,
    required this.aiLanguageName,
  });

  static const english = SureBotLanguage(
    code: 'en',
    englishName: 'English',
    nativeName: 'English',
    aiLanguageName: 'English',
  );

  static const kannada = SureBotLanguage(
    code: 'kn',
    englishName: 'Kannada',
    nativeName: 'ಕನ್ನಡ',
    aiLanguageName: 'Kannada',
  );

  static const hindi = SureBotLanguage(
    code: 'hi',
    englishName: 'Hindi',
    nativeName: 'हिन्दी',
    aiLanguageName: 'Hindi',
  );

  static const telugu = SureBotLanguage(
    code: 'te',
    englishName: 'Telugu',
    nativeName: 'తెలుగు',
    aiLanguageName: 'Telugu',
  );

  static const tamil = SureBotLanguage(
    code: 'ta',
    englishName: 'Tamil',
    nativeName: 'தமிழ்',
    aiLanguageName: 'Tamil',
  );

  static const malayalam = SureBotLanguage(
    code: 'ml',
    englishName: 'Malayalam',
    nativeName: 'മലയാളം',
    aiLanguageName: 'Malayalam',
  );

  static const List<SureBotLanguage> supported = [
    english,
    kannada,
    hindi,
    telugu,
    tamil,
    malayalam,
  ];

  static SureBotLanguage? fromCode(String? code) {
    for (final language in supported) {
      if (language.code == code) return language;
    }
    return null;
  }

  static const defaultLanguage = english;
}
