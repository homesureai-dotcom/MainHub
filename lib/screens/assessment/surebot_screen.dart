import 'package:flutter/material.dart';
import '../../core/localization/app_locale_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../features/auth/services/user_profile_service.dart';

import '../../features/property_submission/services/property_submission_service.dart';
import '../../features/surebot/models/surebot_context.dart';
import '../../widgets/assessment/surebot_avatar.dart';
import '../../widgets/common/app_button.dart';
import 'assessment_screen.dart';

class SureBotScreen extends StatefulWidget {
  final SureBotContext? sureBotContext;
  final String? submissionId;
  final PropertySubmissionApprovalGateway? approvalGateway;

  const SureBotScreen({
    super.key,
    this.sureBotContext,
    this.submissionId,
    this.approvalGateway,
  });

  @override
  State<SureBotScreen> createState() => _SureBotScreenState();
}

class _SureBotScreenState extends State<SureBotScreen> {
  UserProfileService? _profileService;
  String _languageCode = 'en';
  String _greetingName = 'there';
  bool _savingLanguage = false;

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
    AppLocaleController.instance.locale.addListener(_onAppLocaleChanged);
    _loadPreferences();
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
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    // Widget tests and preview contexts may not initialize Firebase.
    // Keep the default English experience available in those contexts.
    if (Firebase.apps.isEmpty) return;

    final profileService = _profileService ??= UserProfileService();
    var name = 'there';

    // The app normally loads this preference before showing screens.
    // Reload here as well for standalone routes and test contexts.
    await AppLocaleController.instance.loadSavedLanguage();
    try {
      name = await profileService.getPreferredName();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _languageCode = AppLocaleController.instance.languageCode;
      _greetingName = name;
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

  Widget _greeting({required double fontSize, required Color color}) {
    final prefix = _t('greeting');
    final suffix = _languageCode == 'en' && _greetingName != 'there'
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
    if (hasContext) return _buildContextualSureBot(context);
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const SureBotAvatar(),
              const SizedBox(height: 36),
              _greeting(fontSize: 34, color: const Color(0xFF0F172A)),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: _languageSelector(),
              ),
              const SizedBox(height: 18),
              Text(
                _t('introTitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _t('introBody'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  color: Colors.grey,
                  height: 1.6,
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
    final data = widget.sureBotContext!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('SureBot'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: _languageSelector()),
          ),
        ],
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: SureBotAvatar()),
              const SizedBox(height: 24),
              _greeting(fontSize: 28, color: const Color(0xFF0F172A)),
              const SizedBox(height: 8),
              Text(
                _t('contextIntro'),
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              _buildPropertyCard(data.property),
              const SizedBox(height: 16),
              _buildHealthCard(data.health),
              const SizedBox(height: 16),
              _buildEvidenceCard(data.evidence),
              if (data.currentPriority != null) ...[
                const SizedBox(height: 16),
                _buildPriorityCard(data.currentPriority!),
              ],
              const SizedBox(height: 24),
              Text(
                _t('help'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              _buildQuestionChip(
                icon: Icons.health_and_safety_outlined,
                label: _t('score'),
              ),
              _buildQuestionChip(
                icon: Icons.warning_amber_outlined,
                label: _t('first'),
              ),
              _buildQuestionChip(
                icon: Icons.description_outlined,
                label: _t('docs'),
              ),
            ],
          ),
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
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          priority.description,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
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
              color: Color(0xFF2563EB),
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
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          ...priority.requiredDocuments.map(
            (document) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $document',
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuestionChip({required IconData icon, required String label}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 21, color: const Color(0xFF2563EB)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
        ],
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2563EB)),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
