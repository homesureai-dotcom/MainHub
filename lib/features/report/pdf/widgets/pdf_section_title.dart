import 'package:pdf/widgets.dart' as pw;

import '../report_theme.dart';

class PdfSectionTitle {
  PdfSectionTitle._();

  static pw.Widget build(
    String title, {
    String? subtitle,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: ReportTheme.sectionTitle(),
        ),

        if (subtitle != null) ...[
          pw.SizedBox(height: ReportTheme.xs),
          pw.Text(
            subtitle,
            style: ReportTheme.body(),
          ),
        ],

        pw.SizedBox(height: ReportTheme.sm),

        pw.Container(
          height: 2,
          width: 80,
          color: ReportTheme.primaryBlue,
        ),

        pw.SizedBox(height: ReportTheme.lg),
      ],
    );
  }
}