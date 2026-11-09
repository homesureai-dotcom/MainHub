import 'package:flutter_test/flutter_test.dart';
import 'package:homesure_ai/features/report/pdf/property_report_pdf_labels.dart';

void main() {
  group('PropertyReportPdfLabels', () {
    test('supports all six launch languages', () {
      expect(
        PropertyReportPdfLabels.supportedLanguages,
        containsAll(['en', 'kn', 'hi', 'te', 'ta', 'ml']),
      );
    });

    test('provides report headings for every supported language', () {
      for (final language in PropertyReportPdfLabels.supportedLanguages) {
        expect(
          PropertyReportPdfLabels.text(language, 'reportTitle'),
          isNotEmpty,
          reason: 'Missing report title for $language',
        );
        expect(
          PropertyReportPdfLabels.text(language, 'disclaimerTitle'),
          isNotEmpty,
          reason: 'Missing disclaimer title for $language',
        );
      }
    });

    test('falls back to English for an unsupported language', () {
      expect(
        PropertyReportPdfLabels.text('fr', 'reportTitle'),
        PropertyReportPdfLabels.text('en', 'reportTitle'),
      );
    });

    test('falls back to the key for an unknown label', () {
      expect(
        PropertyReportPdfLabels.text('en', 'unknownLabel'),
        'unknownLabel',
      );
    });

    test('returns distinct localized report titles', () {
      final titles = {
        for (final language in PropertyReportPdfLabels.supportedLanguages)
          PropertyReportPdfLabels.text(language, 'reportTitle'),
      };

      expect(titles, hasLength(6));
    });
  });
}
