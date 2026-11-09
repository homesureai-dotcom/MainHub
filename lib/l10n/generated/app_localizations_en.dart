// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'HomeSure AI';

  @override
  String get home => 'Home';

  @override
  String get properties => 'Properties';

  @override
  String get health => 'Health';

  @override
  String get aiAdvisor => 'AI Advisor';

  @override
  String get profile => 'Profile';

  @override
  String get language => 'Language';

  @override
  String get continueLabel => 'Continue';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Something went wrong. Please try again.';

  @override
  String get reportTitle => 'Property Health Report';

  @override
  String get noReportFound => 'No Property Health Report found.';

  @override
  String get completeAssessmentFirst => 'Please complete an assessment first.';

  @override
  String get sureBotExplainerTitle => 'SureBot Property Explainer';

  @override
  String get sureBotExplainerSubtitle =>
      'An explanation of your assessment findings and next steps.';

  @override
  String get assessmentExplanation => 'Assessment explanation';

  @override
  String get currentScore => 'Current Score';

  @override
  String get categories => 'Categories';

  @override
  String get ruleBasedDisclaimer =>
      'Rule-based explanation using assessment data. Generative AI is not connected to this card yet.';

  @override
  String get categoryExplanations => 'Category explanations';

  @override
  String get noCategoryResults => 'No category results are available.';

  @override
  String get risksToReview => 'Risks to review';

  @override
  String get noRisksListed =>
      'No risks are listed in this report. This does not prove that no risks exist.';

  @override
  String get recommendedNextActions => 'Recommended next actions';

  @override
  String get noRecommendationsListed =>
      'No recommendations are listed in this report.';

  @override
  String get evidenceToFollowUp => 'Evidence to follow up';

  @override
  String get noMissingDocuments =>
      'No missing documents are listed in this report. Confirm evidence completeness independently.';

  @override
  String get assessmentRisk => 'Assessment risk';

  @override
  String get recommendedAction => 'Recommended action';

  @override
  String get evidenceCheck => 'Evidence check';

  @override
  String get downloadReportPdf => 'Download Property Intelligence Report (PDF)';

  @override
  String get assessmentYes => 'Yes';

  @override
  String get assessmentNo => 'No';

  @override
  String get assessmentNotSure => 'I\'m Not Sure';
}
