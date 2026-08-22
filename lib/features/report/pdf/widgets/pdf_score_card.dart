import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/report_export_model.dart';
import '../report_theme.dart';

class PdfScoreCard {
  PdfScoreCard._();

  static pw.Widget build(
    ReportExportModel report, {
    int? potentialScore,
  }) {
    final score = report.overallScore;

    final status = _status(score);

    final statusColor = _statusColor(score);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(28),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(16),
        border: pw.Border.all(
          color: ReportTheme.primaryBlue,
          width: 2,
        ),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            "HomeSure Property Health Score™",
            style: ReportTheme.sectionTitle(),
          ),

          pw.SizedBox(height: ReportTheme.lg),

          pw.Text(
            "$score",
            style: ReportTheme.score(),
          ),

          pw.SizedBox(height: ReportTheme.sm),

          pw.Text(
            report.grade.toUpperCase(),
            style: ReportTheme.grade(),
          ),

          pw.SizedBox(height: ReportTheme.md),

          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 8,
            ),
            decoration: pw.BoxDecoration(
              color: statusColor,
              borderRadius: pw.BorderRadius.circular(30),
            ),
            child: pw.Text(
              status,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),

          if (potentialScore != null) ...[
            pw.SizedBox(height: ReportTheme.xl),

            pw.Divider(),

            pw.SizedBox(height: ReportTheme.md),

            pw.Text(
              "Potential Score",
              style: ReportTheme.label(),
            ),

            pw.SizedBox(height: ReportTheme.sm),

            pw.Text(
              "$potentialScore",
              style: pw.TextStyle(
                fontSize: 34,
                fontWeight: pw.FontWeight.bold,
                color: ReportTheme.success,
              ),
            ),

            pw.SizedBox(height: ReportTheme.sm),

            pw.Text(
              "+${potentialScore - score} Improvement",
              style: pw.TextStyle(
                color: ReportTheme.success,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _status(int score) {
    if (score >= 90) {
      return "CERTIFIED HEALTHY";
    }

    if (score >= 75) {
      return "HEALTHY";
    }

    if (score >= 60) {
      return "NEEDS ATTENTION";
    }

    if (score >= 40) {
      return "HIGH RISK";
    }

    return "CRITICAL";
  }

  static PdfColor _statusColor(int score) {
    if (score >= 90) {
      return ReportTheme.success;
    }

    if (score >= 75) {
      return PdfColors.lightGreen700;
    }

    if (score >= 60) {
      return ReportTheme.warning;
    }

    if (score >= 40) {
      return PdfColors.orange800;
    }

    return ReportTheme.danger;
  }
}