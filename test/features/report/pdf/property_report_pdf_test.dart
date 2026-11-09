import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:homesure_ai/features/report/models/report_export_model.dart';
import 'package:homesure_ai/features/report/pdf/property_report_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const languages = ['en', 'kn', 'hi', 'te', 'ta', 'ml'];

  ReportExportModel sampleReport(String languageCode) {
    return ReportExportModel(
      reportId: 'HS-TEST-001',
      propertyName: 'Sample Apartment',
      builderName: 'Sample Builder',
      ownerName: 'Test Owner',
      address: 'Sample Road',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '560001',
      assessmentDate: '27 October 2026',
      overallScore: 82,
      grade: 'B',
      summary: 'Sample property assessment for PDF testing.',
      categories: const [
        ReportExportCategory(
          name: 'Legal Compliance',
          percentage: 82,
          weight: 0.4,
          weightedContribution: 32.8,
        ),
      ],
      risks: const [
        ReportExportRisk(
          title: 'Approval verification',
          description: 'Verify required approvals and supporting records.',
          severity: 'Medium',
        ),
      ],
      recommendations: const [
        ReportExportRecommendation(
          title: 'Collect missing records',
          description: 'Request copies of relevant documents.',
          expectedScoreIncrease: 5,
          estimatedTimeline: '2 weeks',
        ),
      ],
      missingDocuments: const [
        ReportExportDocument(
          name: 'Approval certificate',
          mandatory: true,
        ),
      ],
      aiInsights: const [
        'Sample insight for PDF generation testing.',
      ],
      languageCode: languageCode,
    );
  }

  for (final languageCode in languages) {
    test('generates a non-empty PDF for $languageCode', () async {
      final bytes = await PropertyReportPdf.build(
        sampleReport(languageCode),
      );

      expect(bytes, isNotEmpty);
      expect(
        utf8.decode(bytes.take(5).toList()),
        '%PDF-',
        reason: 'Expected a valid PDF header for $languageCode.',
      );
    });
  }
}