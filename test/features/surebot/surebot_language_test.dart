import 'package:flutter_test/flutter_test.dart';
import 'package:homesure_ai/features/surebot/models/surebot_language.dart';

void main() {
  group('SureBotLanguage', () {
    test('provides all six supported languages', () {
      expect(
        SureBotLanguage.supported.map((language) => language.code).toList(),
        ['en', 'kn', 'hi', 'te', 'ta', 'ml'],
      );
    });

    test('provides native-language names for users', () {
      expect(SureBotLanguage.kannada.nativeName, 'ಕನ್ನಡ');
      expect(SureBotLanguage.hindi.nativeName, 'हिन्दी');
      expect(SureBotLanguage.telugu.nativeName, 'తెలుగు');
      expect(SureBotLanguage.tamil.nativeName, 'தமிழ்');
      expect(SureBotLanguage.malayalam.nativeName, 'മലയാളം');
    });

    test('resolves supported language codes', () {
      expect(SureBotLanguage.fromCode('te'), SureBotLanguage.telugu);
      expect(SureBotLanguage.fromCode('ta'), SureBotLanguage.tamil);
      expect(SureBotLanguage.fromCode('ml'), SureBotLanguage.malayalam);
    });

    test('returns null for unsupported codes', () {
      expect(SureBotLanguage.fromCode('xx'), isNull);
      expect(SureBotLanguage.fromCode(null), isNull);
    });

    test('defaults to English', () {
      expect(SureBotLanguage.defaultLanguage.code, 'en');
    });
  });
}
