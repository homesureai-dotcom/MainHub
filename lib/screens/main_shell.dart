import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/localization/app_locale_controller.dart';
import '../core/phs/phs_categories.dart';
import '../core/theme/homesure_components.dart';
import '../core/theme/homesure_tokens.dart';
import '../features/network/screens/network_home_screen.dart';
import '../features/property/models/property.dart';
import '../features/property/state/property_state.dart';
import '../state/assessment_state.dart';
import 'assessment/assessment_screen.dart';
import 'assessment/surebot_screen.dart';
import 'home_screen_v2.dart';
import 'onboarding/property_search_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int currentIndex = 0;

  final PropertyState _propertyState = PropertyState.instance;

  @override
  void initState() {
    super.initState();
    _propertyState.addListener(_onPropertyChanged);
  }

  @override
  void dispose() {
    _propertyState.removeListener(_onPropertyChanged);
    super.dispose();
  }

  void _onPropertyChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Property? get _selectedProperty => _propertyState.selectedProperty;

  void _switchTab(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  Widget _buildNetworkTab() {
    final property = _selectedProperty;

    if (property == null) {
      return _NoPropertySelectedScreen(
        onBrowseProperties: () => _switchTab(1),
      );
    }

    return NetworkHomeScreen(
      propertyId: property.id,
      propertyName: property.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      const HomeScreenV2(),
      const PropertySearchScreen(),
      _HealthWorkspaceScreen(
        selectedProperty: _selectedProperty,
        onBrowseProperties: () => _switchTab(1),
      ),
      _AiWorkspaceScreen(
        selectedProperty: _selectedProperty,
        onBrowseProperties: () => _switchTab(1),
      ),
      _buildNetworkTab(),
      const _ProfileScreen(),
    ];

    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && currentIndex != 0) {
          setState(() {
            currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        backgroundColor: HomeSureColors.backgroundWarm,
        body: IndexedStack(index: currentIndex, children: screens),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: HomeSureColors.surfaceWhite,
            border: Border(
              top: BorderSide(color: HomeSureColors.borderDivider, width: 1),
            ),
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: _switchTab,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.apartment_outlined),
                selectedIcon: Icon(Icons.apartment_rounded),
                label: 'Properties',
              ),
              NavigationDestination(
                icon: Icon(Icons.health_and_safety_outlined),
                selectedIcon: Icon(Icons.health_and_safety_rounded),
                label: 'Health',
              ),
              NavigationDestination(
                icon: Icon(Icons.smart_toy_outlined),
                selectedIcon: Icon(Icons.smart_toy_rounded),
                label: 'AI',
              ),
              NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups_rounded),
                label: 'Residents',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoPropertySelectedScreen extends StatelessWidget {
  final VoidCallback onBrowseProperties;

  const _NoPropertySelectedScreen({required this.onBrowseProperties});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeSureColors.backgroundWarm,
      appBar: AppBar(title: const Text('Residents Welfare')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: HomeSureColors.surfaceWhite,
                borderRadius: BorderRadius.circular(HomeSureRadius.lg),
                border: Border.all(color: HomeSureColors.borderDivider),
                boxShadow: HomeSureShadows.cardSubtle,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: HomeSureColors.primaryNavyTint,
                      borderRadius: BorderRadius.circular(HomeSureRadius.md),
                    ),
                    child: const Icon(
                      Icons.groups_2_outlined,
                      size: 28,
                      color: HomeSureColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select a Property First',
                    style: HomeSureTypography.sectionTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select a property first to access its Residents Welfare community, association updates, and governance records.',
                    textAlign: TextAlign.center,
                    style: HomeSureTypography.bodySecondary,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onBrowseProperties,
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: const Text('Browse Builders & Properties'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HealthWorkspaceScreen extends StatelessWidget {
  final Property? selectedProperty;
  final VoidCallback onBrowseProperties;

  const _HealthWorkspaceScreen({
    required this.selectedProperty,
    required this.onBrowseProperties,
  });

  @override
  Widget build(BuildContext context) {
    final assessmentState = AssessmentState.instance;
    final answeredCount = assessmentState.answers.length;

    return Scaffold(
      backgroundColor: HomeSureColors.backgroundWarm,
      appBar: AppBar(
        title: const Text('Property Health'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: HomeSureStatusBadge(
                label: '6-Pillar PHS Engine',
                tone: HomeSureBadgeTone.teal,
                icon: Icons.verified_user_outlined,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: HomeSureColors.primaryNavy,
                  borderRadius: BorderRadius.circular(HomeSureRadius.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PROPERTY HEALTH INTELLIGENCE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Color(0xFFB5C4D8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedProperty != null
                          ? selectedProperty!.name
                          : 'Evaluate Your Shortlisted Project',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selectedProperty != null
                          ? '${selectedProperty!.builderName} • ${selectedProperty!.address.line1}'
                          : 'Complete your property health assessment to view detailed category scores, risks, and recommendations.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFD5DFEC),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: HomeSureColors.accentTeal,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          if (selectedProperty == null && answeredCount == 0) {
                            onBrowseProperties();
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => answeredCount > 0
                                  ? const AssessmentScreen()
                                  : const SureBotScreen(),
                            ),
                          );
                        },
                        icon: Icon(
                          selectedProperty == null && answeredCount == 0
                              ? Icons.search_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(
                          selectedProperty == null && answeredCount == 0
                              ? 'Select a Property to Assess'
                              : answeredCount > 0
                                  ? 'Continue Assessment ($answeredCount Answered)'
                                  : 'Start Property Health Assessment',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const HomeSureSectionHeader(
                title: 'Six Evaluation Pillars',
                subtitle:
                    'Weighted diagnostic framework across statutory, financial, and engineering dimensions.',
              ),
              const SizedBox(height: 12),
              ...PHSCategory.values.map(
                (category) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: HomeSureColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(HomeSureRadius.md),
                    border: Border.all(color: HomeSureColors.borderDivider),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: HomeSureColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(HomeSureRadius.sm),
                        ),
                        child: Text(
                          category.icon,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.displayName,
                              style: HomeSureTypography.bodyMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Weight in Overall PHS: ${category.weight.round()}%',
                              style: HomeSureTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      HomeSureStatusBadge(
                        label: '${category.weight.round()}%',
                        tone: HomeSureBadgeTone.navy,
                      ),
                    ],
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

class _AiWorkspaceScreen extends StatelessWidget {
  final Property? selectedProperty;
  final VoidCallback onBrowseProperties;

  const _AiWorkspaceScreen({
    required this.selectedProperty,
    required this.onBrowseProperties,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeSureColors.backgroundWarm,
      appBar: AppBar(
        title: const Text('HomeSureAI Assistant'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: HomeSureStatusBadge(
                label: 'SureBot Due Diligence',
                tone: HomeSureBadgeTone.teal,
                icon: Icons.auto_awesome_outlined,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: HomeSureColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(HomeSureRadius.lg),
                  border: Border.all(color: HomeSureColors.borderDivider),
                  boxShadow: HomeSureShadows.cardSubtle,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: HomeSureColors.accentTealTint,
                            borderRadius: BorderRadius.circular(
                              HomeSureRadius.md,
                            ),
                          ),
                          child: const Icon(
                            Icons.smart_toy_outlined,
                            color: HomeSureColors.accentTealDark,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SureBot Intelligence Guide',
                                style: HomeSureTypography.sectionTitle,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selectedProperty != null
                                    ? 'Active Project: ${selectedProperty!.name}'
                                    : 'Multilingual K-RERA & Buyer Due-Diligence Assistant',
                                style: HomeSureTypography.bodySecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Start a property assessment from the Home or Properties tab to unlock guided AI assistance, document verification prompts, and risk explanations in 6 Indian languages.',
                      style: HomeSureTypography.bodySecondary,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SureBotScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 18,
                            ),
                            label: const Text('Launch SureBot'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: onBrowseProperties,
                          child: const Text('Browse Catalogue'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileScreen extends StatefulWidget {
  const _ProfileScreen();

  @override
  State<_ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<_ProfileScreen> {
  static const Map<String, String> _languages = {
    'en': 'English',
    'kn': 'ಕನ್ನಡ (Kannada)',
    'hi': 'हिन्दी (Hindi)',
    'te': 'తెలుగు (Telugu)',
    'ta': 'தமிழ் (Tamil)',
    'ml': 'മലയാളം (Malayalam)',
  };

  bool _savingLanguage = false;

  Future<void> _selectLanguage(String? code) async {
    if (code == null ||
        !_languages.containsKey(code) ||
        code == AppLocaleController.instance.languageCode) {
      return;
    }

    setState(() => _savingLanguage = true);
    try {
      await AppLocaleController.instance.setLanguage(code);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save language preference. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingLanguage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: HomeSureColors.backgroundWarm,
      appBar: AppBar(title: const Text('Profile & Preferences')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: HomeSureColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(HomeSureRadius.lg),
                  border: Border.all(color: HomeSureColors.borderDivider),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: HomeSureColors.primaryNavyTint,
                        borderRadius: BorderRadius.circular(HomeSureRadius.md),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: HomeSureColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Signed In Account',
                            style: HomeSureTypography.caption,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? 'Signed in user',
                            style: HomeSureTypography.cardTitle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: HomeSureColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(HomeSureRadius.lg),
                  border: Border.all(color: HomeSureColors.borderDivider),
                ),
                child: ValueListenableBuilder<Locale>(
                  valueListenable: AppLocaleController.instance.locale,
                  builder: (context, locale, _) {
                    final selectedCode =
                        _languages.containsKey(locale.languageCode)
                            ? locale.languageCode
                            : 'en';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preferred Language',
                          style: HomeSureTypography.cardTitle,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Applies to SureBot and localized assessment prompts.',
                          style: HomeSureTypography.bodySecondary,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          key: ValueKey<String>(selectedCode),
                          initialValue: selectedCode,
                          onChanged: _savingLanguage ? null : _selectLanguage,
                          items: _languages.entries
                              .map(
                                (entry) => DropdownMenuItem<String>(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
