import 'package:printing/printing.dart';

import '../models/report_export_model.dart';
import '../pdf/property_report_pdf.dart';

class ReportExportService {
  const ReportExportService._();

  static Future<void> export(
    ReportExportModel report,
  ) async {
    await Printing.layoutPdf(
      onLayout: (_) async {
        return PropertyReportPdf.build(report);
      },
      name: "Property Intelligence Report",
    );
  }
}