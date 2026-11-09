// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'होमश्योर AI';

  @override
  String get home => 'होम';

  @override
  String get properties => 'प्रॉपर्टी';

  @override
  String get health => 'प्रॉपर्टी की स्थिति';

  @override
  String get aiAdvisor => 'AI सलाहकार';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get language => 'भाषा';

  @override
  String get continueLabel => 'जारी रखें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सेव करें';

  @override
  String get back => 'वापस';

  @override
  String get next => 'आगे';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get error => 'कुछ गड़बड़ हुई है। कृपया फिर से कोशिश करें।';

  @override
  String get reportTitle => 'संपत्ति स्वास्थ्य रिपोर्ट';

  @override
  String get noReportFound => 'संपत्ति स्वास्थ्य रिपोर्ट नहीं मिली।';

  @override
  String get completeAssessmentFirst => 'कृपया पहले मूल्यांकन पूरा करें।';

  @override
  String get sureBotExplainerTitle => 'SureBot संपत्ति व्याख्या';

  @override
  String get sureBotExplainerSubtitle =>
      'मूल्यांकन के निष्कर्षों और अगले कदमों की व्याख्या।';

  @override
  String get assessmentExplanation => 'मूल्यांकन की व्याख्या';

  @override
  String get currentScore => 'वर्तमान स्कोर';

  @override
  String get categories => 'श्रेणियाँ';

  @override
  String get ruleBasedDisclaimer =>
      'मूल्यांकन डेटा पर आधारित नियम-आधारित व्याख्या। इस कार्ड में अभी जनरेटिव AI जुड़ा नहीं है।';

  @override
  String get categoryExplanations => 'श्रेणियों की व्याख्या';

  @override
  String get noCategoryResults => 'श्रेणी के परिणाम उपलब्ध नहीं हैं।';

  @override
  String get risksToReview => 'जाँचने योग्य जोखिम';

  @override
  String get noRisksListed =>
      'इस रिपोर्ट में कोई जोखिम सूचीबद्ध नहीं है। इसका अर्थ यह नहीं है कि कोई जोखिम मौजूद नहीं है।';

  @override
  String get recommendedNextActions => 'अगले सुझाए गए कदम';

  @override
  String get noRecommendationsListed =>
      'इस रिपोर्ट में कोई सुझाव सूचीबद्ध नहीं है।';

  @override
  String get evidenceToFollowUp => 'आगे जाँचने योग्य प्रमाण';

  @override
  String get noMissingDocuments =>
      'इस रिपोर्ट में कोई अनुपलब्ध दस्तावेज़ सूचीबद्ध नहीं है। प्रमाणों की पूर्णता की स्वतंत्र रूप से पुष्टि करें।';

  @override
  String get assessmentRisk => 'मूल्यांकन जोखिम';

  @override
  String get recommendedAction => 'सुझाई गई कार्रवाई';

  @override
  String get evidenceCheck => 'प्रमाण की जाँच';

  @override
  String get downloadReportPdf => 'संपत्ति जानकारी रिपोर्ट PDF डाउनलोड करें';

  @override
  String get assessmentYes => 'हाँ';

  @override
  String get assessmentNo => 'नहीं';

  @override
  String get assessmentNotSure => 'मुझे यकीन नहीं है';
}
