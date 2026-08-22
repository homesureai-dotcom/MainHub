import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportTheme {
  ReportTheme._();

  // Brand Colors
  static const PdfColor primaryBlue = PdfColor.fromInt(0xFF2563EB);
  static const PdfColor darkBlue = PdfColor.fromInt(0xFF0F172A);

  static const PdfColor success = PdfColor.fromInt(0xFF16A34A);
  static const PdfColor warning = PdfColor.fromInt(0xFFF59E0B);
  static const PdfColor danger = PdfColor.fromInt(0xFFDC2626);

  static const PdfColor background = PdfColor.fromInt(0xFFF8FAFC);

  static const PdfColor card = PdfColors.white;

  static const PdfColor divider = PdfColor.fromInt(0xFFE2E8F0);

  static const PdfColor textPrimary = PdfColor.fromInt(0xFF0F172A);

  static const PdfColor textSecondary = PdfColor.fromInt(0xFF64748B);

  // Spacing

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // Typography

  static pw.TextStyle title() => pw.TextStyle(
        fontSize: 30,
        fontWeight: pw.FontWeight.bold,
        color: darkBlue,
      );

  static pw.TextStyle reportTitle() => pw.TextStyle(
        fontSize: 24,
        fontWeight: pw.FontWeight.bold,
        color: darkBlue,
      );

  static pw.TextStyle sectionTitle() => pw.TextStyle(
        fontSize: 18,
        fontWeight: pw.FontWeight.bold,
        color: darkBlue,
      );

  static pw.TextStyle score() => pw.TextStyle(
        fontSize: 72,
        fontWeight: pw.FontWeight.bold,
        color: primaryBlue,
      );

  static pw.TextStyle grade() => pw.TextStyle(
        fontSize: 22,
        fontWeight: pw.FontWeight.bold,
        color: success,
      );

  static pw.TextStyle label() => pw.TextStyle(
        fontSize: 12,
        color: textSecondary,
      );

  static pw.TextStyle value() => pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
        color: textPrimary,
      );

  static pw.TextStyle body() => pw.TextStyle(
        fontSize: 13,
        color: textPrimary,
      );
}