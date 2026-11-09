import 'package:flutter/material.dart';

import '../../../state/assessment_state.dart';

import '../models/property_health_report.dart';

import '../widgets/report_cover_card.dart';
import '../widgets/report_header.dart';
import '../widgets/property_details_card.dart';
import '../widgets/executive_summary_card.dart';
import '../widgets/category_analysis_card.dart';
import '../widgets/risk_analysis_card.dart';
import '../widgets/recommendations_card.dart';
import '../widgets/missing_documents_card.dart';
import '../widgets/ai_insights_card.dart';
import '../widgets/report_footer.dart';

import '../services/report_export_mapper.dart';
import '../services/report_export_service.dart';
import '../components/factory/report_component_factory.dart';

class PropertyHealthReportScreen extends StatelessWidget {
  const PropertyHealthReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PropertyHealthReport? report = AssessmentState.instance.latestReport;
    final executiveSummary = report == null
        ? null
        : ReportComponentFactory.buildExecutiveSummary(report);

    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Property Health Report")),
        body: const Center(
          child: Text(
            "No Property Health Report found.\nPlease complete an assessment first.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text("Property Health Report")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //--------------------------------------------------
              // REPORT COVER
              //--------------------------------------------------
              ReportCoverCard(report: report),

              const SizedBox(height: 32),

              //--------------------------------------------------
              // REPORT HEADER
              //--------------------------------------------------
              ReportHeader(report: report),

              const SizedBox(height: 24),

              //--------------------------------------------------
              // PROPERTY DETAILS
              //--------------------------------------------------
              PropertyDetailsCard(report: report),

              const SizedBox(height: 24),

              //--------------------------------------------------
              // EXECUTIVE SUMMARY
              //--------------------------------------------------
              ExecutiveSummaryCard(summary: executiveSummary!),

              const SizedBox(height: 24),

              //--------------------------------------------------
              // CATEGORY ANALYSIS
              //--------------------------------------------------
              CategoryAnalysisCard(report: report),

              const SizedBox(height: 24),

              //--------------------------------------------------
              // RISK ANALYSIS
              //--------------------------------------------------
              RiskAnalysisCard(report: report),

              const SizedBox(height: 24),

              //--------------------------------------------------
              // RECOMMENDATIONS
              //--------------------------------------------------
              RecommendationsCard(report: report),

              const SizedBox(height: 24),

              //--------------------------------------------------
              // MISSING DOCUMENTS
              //--------------------------------------------------
              MissingDocumentsCard(report: report),

              const SizedBox(height: 24),

              //--------------------------------------------------
              // AI INSIGHTS
              //--------------------------------------------------

              //--------------------------------------------------
              // AI INSIGHTS
              //--------------------------------------------------
              AIInsightsCard(report: report),

              const SizedBox(height: 24),

              //--------------------------------------------------
              // REPORT FOOTER
              //--------------------------------------------------
              ReportFooter(
                reportId: ReportExportMapper.fromReport(report).reportId,
              ),

              //--------------------------------------------------
              // PDF EXPORT
              //--------------------------------------------------
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final exportModel = ReportExportMapper.fromReport(
                      report,
                      languageCode: Localizations.localeOf(
                        context,
                      ).languageCode,
                    );

                    await ReportExportService.export(exportModel);
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text(
                    "Download Property Intelligence Report (PDF)",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
