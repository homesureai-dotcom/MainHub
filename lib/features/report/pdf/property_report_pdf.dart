import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/report_export_model.dart';
import 'property_report_pdf_labels.dart';

class PropertyReportPdf {
  const PropertyReportPdf._();

  static const _blue = PdfColor.fromInt(0xFF174A7E);
  static const _lightBlue = PdfColor.fromInt(0xFFEAF2F9);
  static const _dark = PdfColor.fromInt(0xFF202B38);
  static const _muted = PdfColor.fromInt(0xFF5F6B78);
  static const _line = PdfColor.fromInt(0xFFD8E0E8);

  static String _label(ReportExportModel report, String key) =>
      PropertyReportPdfLabels.text(report.languageCode, key);

  /// Loads a font for the requested language.
  ///
  /// Devanagari Noto Sans is used as the fallback for English so the PDF
  /// does not fall back to Helvetica for ordinary Latin text.
  static Future<pw.Font> _fontForLanguage(String languageCode) async {
    final assetPath = switch (languageCode) {
      'kn' => 'assets/fonts/NotoSansKannada-Regular.ttf',
      'hi' => 'assets/fonts/NotoSansDevanagari-Regular.ttf',
      'te' => 'assets/fonts/NotoSansTelugu-Regular.ttf',
      'ta' => 'assets/fonts/NotoSansTamil-Regular.ttf',
      'ml' => 'assets/fonts/NotoSansMalayalam-Regular.ttf',
      _ => 'assets/fonts/NotoSansDevanagari-Regular.ttf',
    };

    final fontData = await rootBundle.load(assetPath);
    return pw.Font.ttf(fontData);
  }

  static Future<Uint8List> build(ReportExportModel report) async {
    final font = await _fontForLanguage(report.languageCode);

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: font,
        bold: font,
        italic: font,
        boldItalic: font,
      ),
      title: 'Property Intelligence Report',
      author: 'HomeSure AI',
      subject: 'Residential property assessment report',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 44),
        header: (context) => _pageHeader(context, report),
        footer: (context) => _pageFooter(context, report),
        build: (context) => [
          _cover(report),
          pw.SizedBox(height: 24),
          _sectionTitle(_label(report, 'executiveSummary')),
          _paragraph(report.summary),
          pw.SizedBox(height: 16),
          _sectionTitle(_label(report, 'propertyDetails')),
          _details(report),
          pw.SizedBox(height: 16),
          _sectionTitle(_label(report, 'categoryAnalysis')),
          _paragraph(_label(report, 'categoryExplanation')),
          pw.SizedBox(height: 8),
          if (report.categories.isEmpty)
            _empty(_label(report, 'noCategoryBreakdown'))
          else
            _categoryTable(report.categories, report),
          pw.SizedBox(height: 18),
          _sectionTitle(_label(report, 'identifiedRisks')),
          if (report.risks.isEmpty)
            _empty(_label(report, 'noRisks'))
          else
            ...report.risks.map((risk) => _riskCard(risk, report)),
          pw.SizedBox(height: 18),
          _sectionTitle(_label(report, 'recommendations')),
          if (report.recommendations.isEmpty)
            _empty(_label(report, 'noRecommendations'))
          else
            ...report.recommendations.map(
              (item) => _recommendationCard(item, report),
            ),
          pw.SizedBox(height: 18),
          _sectionTitle(_label(report, 'missingDocuments')),
          if (report.missingDocuments.isEmpty)
            _empty(_label(report, 'noMissingDocuments'))
          else
            pw.Table(
              border: pw.TableBorder.all(color: _line, width: 0.6),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(1.5),
              },
              children: [
                _tableHeader([
                  _label(report, 'document'),
                  _label(report, 'requirement'),
                ]),
                ...report.missingDocuments.map(
                  (document) => _tableRow([
                    document.name,
                    document.mandatory
                        ? _label(report, 'mandatory')
                        : _label(report, 'optional'),
                  ]),
                ),
              ],
            ),
          pw.SizedBox(height: 18),
          _sectionTitle(_label(report, 'assessmentInsights')),
          if (report.aiInsights.isEmpty)
            _empty(_label(report, 'noInsights'))
          else
            ...report.aiInsights.map(
              (insight) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 7),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('-  ', style: pw.TextStyle(color: _blue)),
                    pw.Expanded(child: _paragraph(insight)),
                  ],
                ),
              ),
            ),
          pw.SizedBox(height: 24),
          _disclaimer(report),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _cover(ReportExportModel report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        color: _lightBlue,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _line),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _label(report, 'platform'),
            style: pw.TextStyle(
              color: _blue,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            _label(report, 'reportTitle'),
            style: pw.TextStyle(
              color: _dark,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            report.propertyName,
            style: pw.TextStyle(
              color: _dark,
              fontSize: 17,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _info(
                  _label(report, 'overallScore'),
                  '${report.overallScore}/100',
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(child: _info('Grade', report.grade)),
            ],
          ),
          pw.SizedBox(height: 12),
          _info(_label(report, 'assessmentDate'), report.assessmentDate),
        ],
      ),
    );
  }

  static pw.Widget _pageHeader(pw.Context context, ReportExportModel report) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _line)),
      ),
      child: pw.Text(
        _label(report, 'reportTitle'),
        style: const pw.TextStyle(color: _muted, fontSize: 8),
      ),
    );
  }

  static pw.Widget _pageFooter(pw.Context context, ReportExportModel report) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _line)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'HomeSure AI - ${_label(report, 'footer')}',
            style: const pw.TextStyle(color: _muted, fontSize: 8),
          ),
          pw.Text(
            '${_label(report, 'page')} ${context.pageNumber} / '
            '${context.pagesCount}',
            style: const pw.TextStyle(color: _muted, fontSize: 8),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _line)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: _blue,
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _paragraph(String text) {
    return pw.Text(
      text,
      style: const pw.TextStyle(color: _dark, fontSize: 9, lineSpacing: 3),
    );
  }

  static pw.Widget _details(ReportExportModel report) {
    final rows = <List<String>>[
      ['Property', report.propertyName],
      [_label(report, 'owner'), report.ownerName],
      [_label(report, 'builder'), report.builderName],
      [
        _label(report, 'address'),
        [
          report.address,
          report.city,
          report.state,
          report.pincode,
        ].where((value) => value.trim().isNotEmpty).join(', '),
      ],
      [_label(report, 'reportId'), report.reportId],
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.6),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(3.5),
      },
      children: rows.map(_tableRow).toList(),
    );
  }

  static pw.Widget _categoryTable(
    List<ReportExportCategory> categories,
    ReportExportModel report,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.6),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.2),
      },
      children: [
        _tableHeader([
          _label(report, 'category'),
          _label(report, 'score'),
          _label(report, 'weight'),
          _label(report, 'contribution'),
        ]),
        ...categories.map(
          (category) => _tableRow([
            category.name,
            '${category.percentage.toStringAsFixed(0)}%',
            '${(category.weight * 100).toStringAsFixed(0)}%',
            category.weightedContribution.toStringAsFixed(1),
          ]),
        ),
      ],
    );
  }

  static pw.Widget _riskCard(ReportExportRisk risk, ReportExportModel report) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            risk.title,
            style: pw.TextStyle(
              color: _dark,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          _paragraph(risk.description),
          pw.SizedBox(height: 5),
          pw.Text(
            risk.severity,
            style: pw.TextStyle(
              color: _blue,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _recommendationCard(
    ReportExportRecommendation item,
    ReportExportModel report,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _lightBlue,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            item.title,
            style: pw.TextStyle(
              color: _dark,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          _paragraph(item.description),
          pw.SizedBox(height: 5),
          pw.Text(
            '${_label(report, 'expectedImprovement')}: '
            '+${item.expectedScoreIncrease}',
            style: const pw.TextStyle(color: _blue, fontSize: 8),
          ),
          pw.Text(
            '${_label(report, 'estimatedTimeline')}: '
            '${item.estimatedTimeline}',
            style: const pw.TextStyle(color: _muted, fontSize: 8),
          ),
        ],
      ),
    );
  }

  static pw.Widget _disclaimer(ReportExportModel report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _lightBlue,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _label(report, 'disclaimerTitle'),
            style: pw.TextStyle(
              color: _blue,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          _paragraph(_label(report, 'disclaimer')),
        ],
      ),
    );
  }

  static pw.TableRow _tableHeader(List<String> cells) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: _lightBlue),
      children: cells
          .map(
            (cell) => pw.Padding(
              padding: const pw.EdgeInsets.all(7),
              child: pw.Text(
                cell,
                style: pw.TextStyle(
                  color: _blue,
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  static pw.TableRow _tableRow(List<String> cells) {
    return pw.TableRow(
      children: cells
          .map(
            (cell) => pw.Padding(
              padding: const pw.EdgeInsets.all(7),
              child: pw.Text(
                cell.trim().isEmpty ? '—' : cell,
                style: const pw.TextStyle(color: _dark, fontSize: 8),
              ),
            ),
          )
          .toList(),
    );
  }

  static pw.Widget _empty(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        text,
        style: const pw.TextStyle(color: _muted, fontSize: 9),
      ),
    );
  }

  static pw.Widget _info(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(color: _muted, fontSize: 8)),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: _dark,
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
