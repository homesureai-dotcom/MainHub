import 'package:flutter_test/flutter_test.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';
import 'package:homesure_ai/core/phs/phs_question.dart';
import 'package:homesure_ai/features/assessment/localization/assessment_content_translations.dart';

void main() {
  const supportedLanguages = ['en', 'hi', 'kn', 'te', 'ta', 'ml'];

  PHSQuestion question(String id) => PHSQuestion(
        id: id,
        category: PHSCategory.legalOwnership,
        title: 'English title',
        helpText: 'English help',
        whyItMatters: 'English why',
        impact: 'English impact',
        weight: 1,
        requiredEvidence: const ['English evidence'],
        applicableTo: const [PropertyType.apartment],
      );

  test('provides supporting translations for four legal questions', () {
    expect(
      AssessmentContentTranslations.translatedQuestionIds,
      containsAll(['LEGAL_OC', 'LEGAL_SD', 'LEGAL_KHATA', 'LEGAL_EC']),
    );
    expect(AssessmentContentTranslations.translatedQuestionIds, hasLength(4));
  });

  test('each translated legal question has all six language entries', () {
    for (final language in supportedLanguages) {
      final service = AssessmentContentTranslations(language);
      for (final id in AssessmentContentTranslations.translatedQuestionIds) {
        final q = question(id);
        expect(service.helpText(q), isNotEmpty, reason: '$id helpText $language');
        expect(service.whyItMatters(q), isNotEmpty, reason: '$id whyItMatters $language');
        expect(service.impact(q), isNotEmpty, reason: '$id impact $language');
        expect(service.requiredEvidence(q), isNotEmpty, reason: '$id evidence $language');
      }
    }
  });

  test('unsupported language falls back to English', () {
    final service = AssessmentContentTranslations('fr');
    final q = question('LEGAL_OC');
    expect(service.helpText(q), contains('competent authority'));
    expect(service.requiredEvidence(q).first, 'Occupancy Certificate');
  });

  test('unknown question falls back to canonical source text and evidence', () {
    final service = AssessmentContentTranslations('hi');
    final q = question('CONSTRUCTION_CRACKS');
    expect(service.helpText(q), 'English help');
    expect(service.whyItMatters(q), 'English why');
    expect(service.impact(q), 'English impact');
    expect(service.requiredEvidence(q), ['English evidence']);
  });
}
