import 'package:flutter/material.dart';
import '../../core/localization/app_locale_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../core/theme/homesure_tokens.dart';
import '../../features/auth/services/user_profile_service.dart';
import '../../features/auth/state/user_profile_state.dart';

import '../../features/property_submission/services/property_submission_service.dart';
import '../../features/surebot/models/surebot_context.dart';
import '../../widgets/assessment/surebot_avatar.dart';
import '../../widgets/common/app_button.dart';
import 'assessment_screen.dart';

class SureBotChatMessage {
  final bool isUser;
  final String text;
  final DateTime timestamp;

  SureBotChatMessage({
    required this.isUser,
    required this.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Preserves in-session SureBot Q&A history when the assistant modal is
/// dismissed and reopened from the floating AI button.
class SureBotConversationHistory {
  SureBotConversationHistory._();

  static final List<SureBotChatMessage> _messages = [];

  static List<SureBotChatMessage> get messages => List.unmodifiable(_messages);

  static void add(SureBotChatMessage message) {
    _messages.add(message);
  }

  static void clear() {
    _messages.clear();
  }
}

class SureBotScreen extends StatefulWidget {
  final SureBotContext? sureBotContext;
  final String? submissionId;
  final PropertySubmissionApprovalGateway? approvalGateway;
  final bool openAsAssistant;
  final VoidCallback? onBrowseProperties;

  const SureBotScreen({
    super.key,
    this.sureBotContext,
    this.submissionId,
    this.approvalGateway,
    this.openAsAssistant = false,
    this.onBrowseProperties,
  });

  @override
  State<SureBotScreen> createState() => _SureBotScreenState();
}

class _SureBotScreenState extends State<SureBotScreen> {
  UserProfileService? _profileService;
  String _languageCode = 'en';
  String _greetingName = 'there';
  bool _savingLanguage = false;
  final TextEditingController _questionController = TextEditingController();

  static const Map<String, Map<String, String>> _copy = {
    'en': {
      'greeting': 'Hi',
      'introTitle': "I'm SureBot",
      'introBody':
          "I'll guide you through a quick Property Health Assessment.\\n\\nThis takes less than 3 minutes.",
      'begin': "Let's Begin",
      'contextIntro':
          "I'm SureBot. I already have some context about your property.",
      'help': 'What can I help you understand?',
      'score': 'Why is my property score what it is?',
      'first': 'What should I address first?',
      'docs': 'Which documents need attention?',
    },
    'kn': {
      'greeting': 'ನಮಸ್ಕಾರ',
      'introTitle': 'ನಾನು SureBot',
      'introBody':
          'ನಿಮ್ಮ ಆಸ್ತಿಯ ಆರೋಗ್ಯ ಮೌಲ್ಯಮಾಪನದಲ್ಲಿ ನಾನು ನಿಮಗೆ ಮಾರ್ಗದರ್ಶನ ನೀಡುತ್ತೇನೆ.\\n\\nಇದಕ್ಕೆ 3 ನಿಮಿಷಗಳಿಗಿಂತ ಕಡಿಮೆ ಸಮಯ ಬೇಕಾಗುತ್ತದೆ.',
      'begin': 'ಪ್ರಾರಂಭಿಸೋಣ',
      'contextIntro':
          'ನಿಮ್ಮ ಆಸ್ತಿಯ ಬಗ್ಗೆ ಲಭ್ಯವಿರುವ ಮಾಹಿತಿಯನ್ನು ಆಧರಿಸಿ ನಾನು ಸಹಾಯ ಮಾಡುತ್ತೇನೆ.',
      'help': 'ನೀವು ಏನನ್ನು ತಿಳಿದುಕೊಳ್ಳಲು ಬಯಸುತ್ತೀರಿ?',
      'score': 'ನನ್ನ ಆಸ್ತಿಯ ಸ್ಕೋರ್ ಹೀಗೇಕಿದೆ?',
      'first': 'ನಾನು ಮೊದಲು ಯಾವುದನ್ನು ಸರಿಪಡಿಸಬೇಕು?',
      'docs': 'ಯಾವ ದಾಖಲೆಗಳನ್ನು ಪರಿಶೀಲಿಸಬೇಕು?',
    },
    'hi': {
      'greeting': 'नमस्ते',
      'introTitle': 'मैं SureBot हूँ',
      'introBody':
          'मैं आपके प्रॉपर्टी हेल्थ असेसमेंट में आपकी मदद करूँगा।\\n\\nइसमें 3 मिनट से कम समय लगेगा।',
      'begin': 'शुरू करें',
      'contextIntro':
          'मैं आपकी प्रॉपर्टी से जुड़ी उपलब्ध जानकारी के आधार पर मदद कर सकता हूँ।',
      'help': 'आप क्या समझना चाहते हैं?',
      'score': 'मेरी प्रॉपर्टी का स्कोर ऐसा क्यों है?',
      'first': 'मुझे सबसे पहले किस पर ध्यान देना चाहिए?',
      'docs': 'किन दस्तावेज़ों की जाँच ज़रूरी है?',
    },
    'te': {
      'greeting': 'నమస్కారం',
      'introTitle': 'నేను SureBot',
      'introBody':
          'మీ ప్రాపర్టీ హెల్త్ అసెస్‌మెంట్‌లో నేను మీకు మార్గనిర్దేశం చేస్తాను.\\n\\nదీనికి 3 నిమిషాల కంటే తక్కువ సమయం పడుతుంది.',
      'begin': 'ప్రారంభిద్దాం',
      'contextIntro':
          'మీ ప్రాపర్టీకి సంబంధించిన అందుబాటులో ఉన్న సమాచారంతో నేను సహాయం చేస్తాను.',
      'help': 'మీరు ఏమి తెలుసుకోవాలనుకుంటున్నారు?',
      'score': 'నా ప్రాపర్టీ స్కోరు ఇలా ఎందుకు ఉంది?',
      'first': 'నేను ముందుగా దేనిపై దృష్టి పెట్టాలి?',
      'docs': 'ఏ పత్రాలను పరిశీలించాలి?',
    },
    'ta': {
      'greeting': 'வணக்கம்',
      'introTitle': 'நான் SureBot',
      'introBody':
          'உங்கள் சொத்து நல மதிப்பீட்டில் நான் வழிகாட்டுகிறேன்.\\n\\nஇதற்கு 3 நிமிடங்களுக்கும் குறைவாகும்.',
      'begin': 'தொடங்கலாம்',
      'contextIntro':
          'உங்கள் சொத்து பற்றிய கிடைக்கும் தகவல்களின் அடிப்படையில் உதவுகிறேன்.',
      'help': 'நீங்கள் எதைப் புரிந்துகொள்ள விரும்புகிறீர்கள்?',
      'score': 'எனது சொத்து மதிப்பெண் ஏன் இப்படி உள்ளது?',
      'first': 'முதலில் எதில் கவனம் செலுத்த வேண்டும்?',
      'docs': 'எந்த ஆவணங்களைச் சரிபார்க்க வேண்டும்?',
    },
    'ml': {
      'greeting': 'നമസ്കാരം',
      'introTitle': 'ഞാൻ SureBot',
      'introBody':
          'നിങ്ങളുടെ പ്രോപ്പർട്ടി ഹെൽത്ത് അസസ്മെന്റിൽ ഞാൻ സഹായിക്കാം.\\n\\nഇതിന് 3 മിനിറ്റിൽ താഴെ സമയം മതി.',
      'begin': 'തുടങ്ങാം',
      'contextIntro':
          'നിങ്ങളുടെ പ്രോപ്പർട്ടിയെക്കുറിച്ച് ലഭ്യമായ വിവരങ്ങൾ അടിസ്ഥാനമാക്കി ഞാൻ സഹായിക്കാം.',
      'help': 'നിങ്ങൾ എന്താണ് മനസ്സിലാക്കാൻ ആഗ്രഹിക്കുന്നത്?',
      'score': 'എന്റെ പ്രോപ്പർട്ടി സ്കോർ ഇങ്ങനെയാകാൻ കാരണം എന്താണ്?',
      'first': 'ആദ്യം എന്തിലാണ് ശ്രദ്ധിക്കേണ്ടത്?',
      'docs': 'ഏത് രേഖകളാണ് പരിശോധിക്കേണ്ടത്?',
    },
  };

  String _t(String key) =>
      _copy[_languageCode]?[key] ?? _copy['en']![key] ?? key;

  @override
  void initState() {
    super.initState();
    _languageCode = AppLocaleController.instance.languageCode;
    _syncCachedProfileName();
    AppLocaleController.instance.locale.addListener(_onAppLocaleChanged);
    UserProfileState.instance.addListener(_onUserProfileChanged);
    _loadPreferences();
  }

  void _syncCachedProfileName() {
    final cached = UserProfileState.instance.firstNameOrDisplay.trim();
    if (cached.isNotEmpty) {
      _greetingName = cached;
    }
  }

  void _onUserProfileChanged() {
    if (!mounted) return;
    final updated = UserProfileState.instance.firstNameOrDisplay.trim();
    setState(() {
      _greetingName = updated.isNotEmpty ? updated : 'there';
    });
  }

  void _onAppLocaleChanged() {
    if (!mounted) return;
    final code = AppLocaleController.instance.languageCode;
    if (_languageCode != code && _copy.containsKey(code)) {
      setState(() => _languageCode = code);
    }
  }

  @override
  void dispose() {
    AppLocaleController.instance.locale.removeListener(_onAppLocaleChanged);
    UserProfileState.instance.removeListener(_onUserProfileChanged);
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    // Widget tests and preview contexts may not initialize Firebase.
    // Keep the default English experience available in those contexts.
    if (Firebase.apps.isEmpty) return;

    final profileService = _profileService ??= UserProfileService();
    var name = UserProfileState.instance.firstNameOrDisplay.trim();

    // The app normally loads this preference before showing screens.
    // Reload here as well for standalone routes and test contexts.
    await AppLocaleController.instance.loadSavedLanguage();
    try {
      if (name.isEmpty) {
        name = await profileService.getPreferredName();
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _languageCode = AppLocaleController.instance.languageCode;
      if (name.isNotEmpty) {
        _greetingName = name;
      }
    });
  }

  Future<void> _changeLanguage(String? code) async {
    if (code == null || !_copy.containsKey(code) || code == _languageCode) {
      return;
    }
    setState(() => _savingLanguage = true);
    try {
      // Updates the shared locale and saves the preference when signed in.
      // Without Firebase, the shared locale changes in memory for tests.
      await AppLocaleController.instance.setLanguage(code);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save language preference. Please sign in and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _savingLanguage = false);
    }
  }

  Widget _languageSelector() {
    const names = {
      'en': 'English',
      'kn': 'ಕನ್ನಡ',
      'hi': 'हिन्दी',
      'te': 'తెలుగు',
      'ta': 'தமிழ்',
      'ml': 'മലയാളം',
    };
    return DropdownButton<String>(
      value: _languageCode,
      dropdownColor: HomeSureColors.midnightCard,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: HomeSureColors.champagneInk,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
      iconEnabledColor: HomeSureColors.champagneHighlight,
      underline: const SizedBox.shrink(),
      onChanged: _savingLanguage ? null : _changeLanguage,
      items: names.entries
          .map(
            (entry) => DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            ),
          )
          .toList(),
    );
  }

  void _askSureBot(String prompt) {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) return;

    final reply = _buildContextualReply(trimmed);
    setState(() {
      SureBotConversationHistory.add(
        SureBotChatMessage(isUser: true, text: trimmed),
      );
      SureBotConversationHistory.add(
        SureBotChatMessage(isUser: false, text: reply),
      );
    });
    _questionController.clear();
  }

  String _buildContextualReply(String prompt) {
    final ctx = widget.sureBotContext;
    if (ctx == null) {
      return 'Select a K-RERA registered property first from the Properties tab or complete your 33-question PHI assessment so I can analyze your exact score, legal evidence gaps, and priority actions.';
    }

    final lower = prompt.toLowerCase();
    final scoreText = ctx.health.score == null
        ? 'not yet calculated (${ctx.health.evaluatedQuestionCount}/${ctx.health.totalQuestionCount} questions evaluated)'
        : '${ctx.health.score!.round()} out of 100 (${ctx.health.grade ?? 'Rated'})';

    if (lower.contains('score') || lower.contains('phi') || lower.contains('why')) {
      return 'For ${ctx.property.name}, your current Property Health Index is $scoreText with ${ctx.health.riskCount} flagged risk items and ${ctx.evidence.coveragePercentage.round()}% evidence coverage.';
    }
    if (lower.contains('first') || lower.contains('priority') || lower.contains('address')) {
      if (ctx.currentPriority != null) {
        final p = ctx.currentPriority!;
        final gain = p.estimatedPHIGain > 0 ? ' (estimated +${p.estimatedPHIGain} PHI gain)' : '';
        return 'Your top priority is "${p.title}"$gain: ${p.description}';
      }
      return 'Continue answering unanswered PHS questions in your Health tab to reveal priority legal and technical actions.';
    }
    if (lower.contains('doc') || lower.contains('evidence')) {
      return 'Evidence status for ${ctx.property.name}: ${ctx.evidence.satisfiedRequirements} satisfied, ${ctx.evidence.missingRequirements} missing, and ${ctx.evidence.needsReviewRequirements} needing review.';
    }
    return 'SureBot analyzed ${ctx.property.name} (${ctx.property.builderName}): PHI is $scoreText and evidence coverage is ${ctx.evidence.coveragePercentage.round()}%. Ask about your score, top priority, or missing documents anytime.';
  }

  Widget _greeting({required double fontSize, required Color color}) {
    final prefix = _t('greeting');
    final suffix = _greetingName.isNotEmpty && _greetingName != 'there'
        ? ' $_greetingName'
        : '';
    return Text(
      '$prefix$suffix 👋',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  bool get hasContext => widget.sureBotContext != null;

  @override
  Widget build(BuildContext context) {
    if (hasContext || widget.openAsAssistant) {
      return _buildContextualSureBot(context);
    }
    return _buildAssessmentOnboarding(context);
  }

  Future<void> _beginAssessment(BuildContext context) async {
    final id = widget.submissionId?.trim();

    // Existing catalogue and dashboard flows retain their current behavior.
    // Submitted properties must pass a fresh approval check.
    if (id != null && id.isNotEmpty) {
      try {
        final checker = widget.approvalGateway ?? PropertySubmissionService();

        final approved = await checker.isSubmissionApproved(id);

        if (!context.mounted) return;

        if (!approved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'This property is not currently approved '
                'for assessment.',
              ),
            ),
          );
          return;
        }
      } catch (_) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'We could not verify this property’s approval. '
              'Please try again.',
            ),
          ),
        );
        return;
      }
    }

    if (!context.mounted) return;

    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AssessmentScreen(
          submissionId: id,
          approvalGateway: widget.approvalGateway,
        ),
      ),
    );
  }

  Widget _buildAssessmentOnboarding(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeSureColors.midnightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const SureBotAvatar(),
              const SizedBox(height: 28),
              _greeting(fontSize: 28, color: HomeSureColors.champagneInk),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: _languageSelector(),
              ),
              const SizedBox(height: 16),
              Text(
                _t('introTitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: HomeSureColors.champagneHighlight,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _t('introBody'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15.5,
                  color: HomeSureColors.slateMuted,
                  height: 1.55,
                ),
              ),
              const Spacer(),
              AppButton(
                text: _t('begin'),
                icon: Icons.arrow_forward,
                onPressed: () => _beginAssessment(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextualSureBot(BuildContext context) {
    final data = widget.sureBotContext;
    final history = SureBotConversationHistory.messages;

    return Scaffold(
      backgroundColor: HomeSureColors.midnightBg,
      appBar: AppBar(
        backgroundColor: HomeSureColors.midnightHeader,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Dismiss SureBot',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('SureBot'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: _languageSelector()),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: SureBotAvatar(size: 92)),
                    const SizedBox(height: 18),
                    _greeting(fontSize: 24, color: HomeSureColors.champagneInk),
                    const SizedBox(height: 6),
                    Text(
                      data != null
                          ? _t('contextIntro')
                          : 'Ask about your K-RERA project checks, PHI scoring methodology, or select a property to unlock project-specific due diligence.',
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: HomeSureColors.slateMuted,
                        height: 1.45,
                      ),
                    ),
                    if (data != null) ...[
                      const SizedBox(height: 18),
                      _buildPropertyCard(data.property),
                      const SizedBox(height: 12),
                      _buildHealthCard(data.health),
                      const SizedBox(height: 12),
                      _buildEvidenceCard(data.evidence),
                      if (data.currentPriority != null) ...[
                        const SizedBox(height: 12),
                        _buildPriorityCard(data.currentPriority!),
                      ],
                    ] else if (widget.onBrowseProperties != null) ...[
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: widget.onBrowseProperties,
                          icon: const Icon(Icons.apartment_rounded, size: 18),
                          label: const Text('Select Property for Project Context'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      _t('help'),
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: HomeSureColors.champagneInk,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildQuestionChip(
                      icon: Icons.health_and_safety_outlined,
                      label: _t('score'),
                      onTap: () => _askSureBot(_t('score')),
                    ),
                    _buildQuestionChip(
                      icon: Icons.warning_amber_outlined,
                      label: _t('first'),
                      onTap: () => _askSureBot(_t('first')),
                    ),
                    _buildQuestionChip(
                      icon: Icons.description_outlined,
                      label: _t('docs'),
                      onTap: () => _askSureBot(_t('docs')),
                    ),
                    if (history.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Conversation',
                            style: HomeSureTypography.sectionTitle,
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                SureBotConversationHistory.clear();
                              });
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...history.map(
                        (msg) => Align(
                          alignment: msg.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            constraints: const BoxConstraints(maxWidth: 320),
                            decoration: BoxDecoration(
                              color: msg.isUser
                                  ? HomeSureColors.midnightSelected
                                  : HomeSureColors.midnightCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: msg.isUser
                                    ? HomeSureColors.champagneBronze
                                    : HomeSureColors.borderSlate,
                              ),
                            ),
                            child: Text(
                              msg.text,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.45,
                                color: msg.isUser
                                    ? HomeSureColors.champagneHighlight
                                    : HomeSureColors.champagneInk,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: const BoxDecoration(
                color: HomeSureColors.midnightHeader,
                border: Border(
                  top: BorderSide(color: HomeSureColors.borderSlate),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      style: const TextStyle(color: HomeSureColors.champagneInk),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _askSureBot,
                      decoration: const InputDecoration(
                        hintText: 'Ask SureBot about your property...',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _askSureBot(_questionController.text),
                    child: const Icon(Icons.send_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard(SureBotPropertyContext property) {
    return _ContextCard(
      icon: Icons.home_outlined,
      title: property.name,
      children: [
        _FactRow(label: 'Builder', value: property.builderName),
        _FactRow(
          label: 'Location',
          value: '${property.city}, ${property.state}',
        ),
        _FactRow(label: 'Property type', value: property.propertyType),
        _FactRow(
          label: 'Year built',
          value: property.yearOfConstruction.toString(),
        ),
      ],
    );
  }

  Widget _buildHealthCard(SureBotHealthContext health) {
    final score = health.score?.round();

    return _ContextCard(
      icon: Icons.favorite_outline,
      title: 'Property Health',
      children: [
        _FactRow(
          label: 'PHI score',
          value: score?.toString() ?? 'Not assessed',
        ),
        _FactRow(label: 'Grade', value: health.grade ?? 'Not assessed'),
        _FactRow(
          label: 'Assessment',
          value: health.hasAssessment
              ? (health.isComplete ? 'Complete' : 'In progress')
              : 'Not started',
        ),
        _FactRow(
          label: 'Questions evaluated',
          value:
              '${health.evaluatedQuestionCount}/${health.totalQuestionCount}',
        ),
        _FactRow(label: 'Risks', value: health.riskCount.toString()),
      ],
    );
  }

  Widget _buildEvidenceCard(SureBotEvidenceContext evidence) {
    return _ContextCard(
      icon: Icons.verified_outlined,
      title: 'Evidence',
      children: [
        _FactRow(
          label: 'Coverage',
          value: '${evidence.coveragePercentage.round()}%',
        ),
        _FactRow(
          label: 'Satisfied',
          value: evidence.satisfiedRequirements.toString(),
        ),
        _FactRow(
          label: 'Missing',
          value: evidence.missingRequirements.toString(),
        ),
        _FactRow(
          label: 'Needs review',
          value: evidence.needsReviewRequirements.toString(),
        ),
        _FactRow(
          label: 'Rejected',
          value: evidence.rejectedRequirements.toString(),
        ),
      ],
    );
  }

  Widget _buildPriorityCard(SureBotPriorityContext priority) {
    return _ContextCard(
      icon: Icons.priority_high_outlined,
      title: 'Current Priority',
      children: [
        Text(
          priority.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: HomeSureColors.champagneInk,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          priority.description,
          style: const TextStyle(
            fontSize: 14,
            color: HomeSureColors.slateMuted,
            height: 1.5,
          ),
        ),
        if (priority.estimatedPHIGain > 0) ...[
          const SizedBox(height: 12),
          Text(
            'Potential PHI improvement: +${priority.estimatedPHIGain}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: HomeSureColors.champagneHighlight,
            ),
          ),
        ],
        if (priority.requiredDocuments.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Required documents',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: HomeSureColors.champagneInk,
            ),
          ),
          const SizedBox(height: 6),
          ...priority.requiredDocuments.map(
            (document) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $document',
                style: const TextStyle(
                  fontSize: 14,
                  color: HomeSureColors.slateMuted,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuestionChip({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: HomeSureColors.midnightCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HomeSureColors.borderSlate),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: HomeSureColors.champagneHighlight),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: HomeSureColors.champagneInk,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: HomeSureColors.slateMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContextCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _ContextCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HomeSureColors.midnightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HomeSureColors.borderSlate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: HomeSureColors.champagneHighlight, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: HomeSureColors.champagneInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  final String label;
  final String value;

  const _FactRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: HomeSureColors.slateMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: HomeSureColors.champagneInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
