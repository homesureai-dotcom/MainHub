import '../../../core/phs/phs_categories.dart';
import '../../../core/phs/phs_question.dart';
import 'assessment_question_title_translations.dart';

/// Shared, ID-based translations for assessment content.
///
/// The canonical PHSQuestion data remains the source of truth for scoring,
/// evidence requirements, applicability, and other assessment rules.
/// Untranslated fields temporarily fall back to their canonical English text.
class AssessmentTranslations {
  const AssessmentTranslations(this.languageCode);

  final String languageCode;

  static const Map<PHSCategory, Map<String, String>> _categories = {
    PHSCategory.legalOwnership: {
      'en': 'Legal & Ownership',
      'hi': 'कानूनी और स्वामित्व',
      'kn': 'ಕಾನೂನು ಮತ್ತು ಮಾಲೀಕತ್ವ',
      'te': 'చట్టపరమైన అంశాలు మరియు యాజమాన్యం',
      'ta': 'சட்டம் மற்றும் உரிமை',
      'ml': 'നിയമവും ഉടമസ്ഥാവകാശവും',
    },
    PHSCategory.constructionQuality: {
      'en': 'Construction Quality',
      'hi': 'निर्माण की गुणवत्ता',
      'kn': 'ನಿರ್ಮಾಣ ಗುಣಮಟ್ಟ',
      'te': 'నిర్మాణ నాణ్యత',
      'ta': 'கட்டுமானத் தரம்',
      'ml': 'നിർമ്മാണ നിലവാരം',
    },
    PHSCategory.utilitiesInfrastructure: {
      'en': 'Utilities & Infrastructure',
      'hi': 'उपयोगिताएँ और बुनियादी ढाँचा',
      'kn': 'ಸೌಲಭ್ಯಗಳು ಮತ್ತು ಮೂಲಸೌಕರ್ಯ',
      'te': 'సదుపాయాలు మరియు మౌలిక సదుపాయాలు',
      'ta': 'பயன்பாடுகள் மற்றும் உள்கட்டமைப்பு',
      'ml': 'യൂട്ടിലിറ്റികളും അടിസ്ഥാന സൗകര്യങ്ങളും',
    },
    PHSCategory.safetyCompliance: {
      'en': 'Safety & Compliance',
      'hi': 'सुरक्षा और अनुपालन',
      'kn': 'ಸುರಕ್ಷತೆ ಮತ್ತು ಅನುಸರಣೆ',
      'te': 'భద్రత మరియు అనుసరణ',
      'ta': 'பாதுகாப்பு மற்றும் இணக்கம்',
      'ml': 'സുരക്ഷയും നിയമാനുസരണവും',
    },
    PHSCategory.communityMaintenance: {
      'en': 'Community & Maintenance',
      'hi': 'समुदाय और रखरखाव',
      'kn': 'ಸಮುದಾಯ ಮತ್ತು ನಿರ್ವಹಣೆ',
      'te': 'సమాజం మరియు నిర్వహణ',
      'ta': 'சமூகம் மற்றும் பராமரிப்பு',
      'ml': 'സമൂഹവും പരിപാലനവും',
    },
    PHSCategory.documentation: {
      'en': 'Documentation',
      'hi': 'दस्तावेज़',
      'kn': 'ದಾಖಲೆಗಳು',
      'te': 'పత్రాలు',
      'ta': 'ஆவணங்கள்',
      'ml': 'രേഖകൾ',
    },
  };

  String categoryName(PHSCategory category) {
    final translations = _categories[category];
    return translations?[languageCode] ??
        translations?['en'] ??
        category.displayName;
  }

  String questionTitle(PHSQuestion question) {
    return AssessmentQuestionTitleTranslations(languageCode).title(question);
  }

  /// Help text remains canonical until its translation batch is integrated.
  String questionHelpText(PHSQuestion question) => question.helpText;

  /// Exposes all question IDs covered by the title translation service.
  static Set<String> get translatedQuestionIds =>
      AssessmentQuestionTitleTranslations.translatedQuestionIds;
}
