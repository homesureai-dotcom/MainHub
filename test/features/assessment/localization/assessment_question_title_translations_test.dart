import 'package:flutter_test/flutter_test.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';
import 'package:homesure_ai/core/phs/phs_question.dart';
import 'package:homesure_ai/features/assessment/localization/assessment_question_title_translations.dart';

void main() {
  const languages = ['en', 'hi', 'kn', 'te', 'ta', 'ml'];

  PHSQuestion question(String id) => PHSQuestion(
        id: id,
        category: PHSCategory.legalOwnership,
        title: 'Canonical title',
        helpText: 'Help',
        weight: 1,
        requiredEvidence: const [],
        applicableTo: const [PropertyType.apartment],
      );

  test('contains all 33 stable question IDs', () {
    expect(AssessmentQuestionTitleTranslations.translatedQuestionIds, hasLength(33));
  });

  test('every question has a non-empty title in all six supported languages', () {
    final serviceByLanguage = {
      for (final language in languages)
        language: AssessmentQuestionTitleTranslations(language),
    };
    for (final id in AssessmentQuestionTitleTranslations.translatedQuestionIds) {
      for (final language in languages) {
        final title = serviceByLanguage[language]!.title(question(id));
        expect(title.trim(), isNotEmpty, reason: '$id missing $language title');
      }
    }
  });

  test('unknown IDs fall back to canonical title', () {
    final service = AssessmentQuestionTitleTranslations('hi');
    expect(service.title(question('UNKNOWN_ID')), 'Canonical title');
  });

  test('unsupported languages fall back to English title', () {
    final service = AssessmentQuestionTitleTranslations('fr');
    expect(service.title(question('LEGAL_OC')), 'Is the Occupancy Certificate (OC) available?');
  });
}
