import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('kn'),
    Locale('ml'),
    Locale('ta'),
    Locale('te'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'HomeSure AI'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @properties.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get properties;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// No description provided for @aiAdvisor.
  ///
  /// In en, this message translates to:
  /// **'AI Advisor'**
  String get aiAdvisor;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get error;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Property Health Report'**
  String get reportTitle;

  /// No description provided for @noReportFound.
  ///
  /// In en, this message translates to:
  /// **'No Property Health Report found.'**
  String get noReportFound;

  /// No description provided for @completeAssessmentFirst.
  ///
  /// In en, this message translates to:
  /// **'Please complete an assessment first.'**
  String get completeAssessmentFirst;

  /// No description provided for @sureBotExplainerTitle.
  ///
  /// In en, this message translates to:
  /// **'SureBot Property Explainer'**
  String get sureBotExplainerTitle;

  /// No description provided for @sureBotExplainerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'An explanation of your assessment findings and next steps.'**
  String get sureBotExplainerSubtitle;

  /// No description provided for @assessmentExplanation.
  ///
  /// In en, this message translates to:
  /// **'Assessment explanation'**
  String get assessmentExplanation;

  /// No description provided for @currentScore.
  ///
  /// In en, this message translates to:
  /// **'Current Score'**
  String get currentScore;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @ruleBasedDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Rule-based explanation using assessment data. Generative AI is not connected to this card yet.'**
  String get ruleBasedDisclaimer;

  /// No description provided for @categoryExplanations.
  ///
  /// In en, this message translates to:
  /// **'Category explanations'**
  String get categoryExplanations;

  /// No description provided for @noCategoryResults.
  ///
  /// In en, this message translates to:
  /// **'No category results are available.'**
  String get noCategoryResults;

  /// No description provided for @risksToReview.
  ///
  /// In en, this message translates to:
  /// **'Risks to review'**
  String get risksToReview;

  /// No description provided for @noRisksListed.
  ///
  /// In en, this message translates to:
  /// **'No risks are listed in this report. This does not prove that no risks exist.'**
  String get noRisksListed;

  /// No description provided for @recommendedNextActions.
  ///
  /// In en, this message translates to:
  /// **'Recommended next actions'**
  String get recommendedNextActions;

  /// No description provided for @noRecommendationsListed.
  ///
  /// In en, this message translates to:
  /// **'No recommendations are listed in this report.'**
  String get noRecommendationsListed;

  /// No description provided for @evidenceToFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Evidence to follow up'**
  String get evidenceToFollowUp;

  /// No description provided for @noMissingDocuments.
  ///
  /// In en, this message translates to:
  /// **'No missing documents are listed in this report. Confirm evidence completeness independently.'**
  String get noMissingDocuments;

  /// No description provided for @assessmentRisk.
  ///
  /// In en, this message translates to:
  /// **'Assessment risk'**
  String get assessmentRisk;

  /// No description provided for @recommendedAction.
  ///
  /// In en, this message translates to:
  /// **'Recommended action'**
  String get recommendedAction;

  /// No description provided for @evidenceCheck.
  ///
  /// In en, this message translates to:
  /// **'Evidence check'**
  String get evidenceCheck;

  /// No description provided for @downloadReportPdf.
  ///
  /// In en, this message translates to:
  /// **'Download Property Intelligence Report (PDF)'**
  String get downloadReportPdf;

  /// No description provided for @assessmentYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get assessmentYes;

  /// No description provided for @assessmentNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get assessmentNo;

  /// No description provided for @assessmentNotSure.
  ///
  /// In en, this message translates to:
  /// **'I\'m Not Sure'**
  String get assessmentNotSure;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'hi',
    'kn',
    'ml',
    'ta',
    'te',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
