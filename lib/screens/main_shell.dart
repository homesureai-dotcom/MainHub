import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../core/localization/app_locale_controller.dart';
import '../core/theme/homesure_tokens.dart';
import '../features/auth/services/user_profile_service.dart';
import '../features/auth/state/user_profile_state.dart';
import '../features/dashboard/coordinators/dashboard_data_coordinator.dart';
import '../features/network/screens/network_home_screen.dart';
import '../features/property/models/property.dart';
import '../features/property/state/property_state.dart';
import '../features/surebot/builders/surebot_context_builder.dart';
import '../state/assessment_state.dart';
import '../widgets/common/floating_surebot_button.dart';
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

  Future<void> _openSureBotAssistant() async {
    final property = _selectedProperty;
    if (property != null) {
      final data = await DashboardDataCoordinator(
        propertyState: _propertyState,
        assessmentState: AssessmentState.instance,
      ).build();

      if (!mounted) return;
      final sureBotContext = data == null
          ? null
          : const SureBotContextBuilder().build(
              data,
              currentPriority:
                  data.priorities.isEmpty ? null : data.priorities.first,
            );

      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => SureBotScreen(
            sureBotContext: sureBotContext,
            openAsAssistant: true,
            onBrowseProperties: () {
              Navigator.of(context).pop();
              _switchTab(1);
            },
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SureBotScreen(
          openAsAssistant: true,
          onBrowseProperties: () {
            Navigator.of(context).pop();
            _switchTab(1);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      const HomeScreenV2(),
      const PropertySearchScreen(),
      AssessmentScreen(
        embeddedInTab: true,
        onSelectProperty: () => _switchTab(1),
      ),
      _buildNetworkTab(),
      _ProfileScreen(
        onBrowseProperties: () => _switchTab(1),
      ),
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
        body: Stack(
          children: [
            IndexedStack(index: currentIndex, children: screens),
            Positioned(
              right: 16,
              bottom: 12,
              child: SafeArea(
                top: false,
                left: false,
                bottom: false,
                child: FloatingSureBotButton(
                  onPressed: _openSureBotAssistant,
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: HomeSureColors.midnightBottomNav,
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

class _ProfileScreen extends StatefulWidget {
  final VoidCallback onBrowseProperties;

  const _ProfileScreen({required this.onBrowseProperties});

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

  @override
  void initState() {
    super.initState();
    UserProfileState.instance.addListener(_onProfileChanged);
    PropertyState.instance.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    UserProfileState.instance.removeListener(_onProfileChanged);
    PropertyState.instance.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (!mounted) return;
    setState(() {});
  }

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

  Future<void> _openEditProfileSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditUserProfileSheet(
        initialProfile: UserProfileState.instance.profile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user =
        Firebase.apps.isNotEmpty ? FirebaseAuth.instance.currentUser : null;
    final profile = UserProfileState.instance.profile;
    final displayName = UserProfileState.instance.displayName;
    final dob = profile?.dateOfBirth.trim() ?? '';
    final selectedProperty = PropertyState.instance.selectedProperty;

    return Scaffold(
      backgroundColor: HomeSureColors.backgroundWarm,
      appBar: AppBar(title: const Text('Profile & Preferences')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: HomeSureColors.primaryNavyTint,
                            borderRadius: BorderRadius.circular(
                              HomeSureRadius.md,
                            ),
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
                                'Account Profile',
                                style: HomeSureTypography.caption,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayName.isNotEmpty
                                    ? displayName
                                    : (user?.email ?? 'Signed in user'),
                                style: HomeSureTypography.cardTitle,
                              ),
                              if (user?.email != null &&
                                  user!.email!.isNotEmpty &&
                                  displayName.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  user.email!,
                                  style: HomeSureTypography.bodySecondary,
                                ),
                              ],
                              if (dob.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'DOB: $dob',
                                  style: HomeSureTypography.caption.copyWith(
                                    color: HomeSureColors.champagneHighlight,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        key: const ValueKey<String>('profile-edit-button'),
                        onPressed: _openEditProfileSheet,
                        icon: const Icon(Icons.edit_outlined, size: 17),
                        label: const Text('Edit Name & Date of Birth'),
                      ),
                    ),
                  ],
                ),
              ),
              if (selectedProperty != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: HomeSureColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(HomeSureRadius.lg),
                    border: Border.all(color: HomeSureColors.champagneBronze),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.apartment_rounded,
                        color: HomeSureColors.champagneHighlight,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected Property',
                              style: HomeSureTypography.caption,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selectedProperty.name,
                              style: HomeSureTypography.cardTitle,
                            ),
                            Text(
                              '${selectedProperty.builderName} • ${selectedProperty.address.city}',
                              style: HomeSureTypography.bodySecondary,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onBrowseProperties,
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ),
              ],
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
                  UserProfileState.instance.clear();
                  PropertyState.instance.clear();
                  AssessmentState.instance.clearAssessment();
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

class _EditUserProfileSheet extends StatefulWidget {
  final UserProfileData? initialProfile;

  const _EditUserProfileSheet({this.initialProfile});

  @override
  State<_EditUserProfileSheet> createState() => _EditUserProfileSheetState();
}

class _EditUserProfileSheetState extends State<_EditUserProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _dobCtrl;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(
      text: widget.initialProfile?.firstName ?? '',
    );
    _lastNameCtrl = TextEditingController(
      text: widget.initialProfile?.lastName ?? '',
    );
    _dobCtrl = TextEditingController(
      text: widget.initialProfile?.dateOfBirth ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 28, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 13, now.month, now.day),
    );
    if (picked == null || !mounted) return;
    final dd = picked.day.toString().padLeft(2, '0');
    final mm = picked.month.toString().padLeft(2, '0');
    setState(() {
      _dobCtrl.text = '$dd/$mm/${picked.year}';
    });
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final first = _firstNameCtrl.text.trim();
      final last = _lastNameCtrl.text.trim();
      final dob = _dobCtrl.text.trim();

      if (Firebase.apps.isNotEmpty &&
          FirebaseAuth.instance.currentUser != null) {
        await UserProfileService().saveUserProfile(
          firstName: first,
          lastName: last,
          dateOfBirth: dob,
        );
      } else {
        UserProfileState.instance.setProfile(
          UserProfileData(
            firstName: first,
            lastName: last,
            dateOfBirth: dob,
            email: widget.initialProfile?.email ?? '',
          ),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not update profile. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: HomeSureColors.midnightCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: HomeSureColors.borderSlate),
            left: BorderSide(color: HomeSureColors.borderSlate),
            right: BorderSide(color: HomeSureColors.borderSlate),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Edit Profile',
                          style: HomeSureTypography.sectionTitle,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: HomeSureColors.slateMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey<String>('profile-edit-first-name'),
                    controller: _firstNameCtrl,
                    style: const TextStyle(color: HomeSureColors.champagneInk),
                    decoration: const InputDecoration(
                      labelText: 'First Name *',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter first name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey<String>('profile-edit-last-name'),
                    controller: _lastNameCtrl,
                    style: const TextStyle(color: HomeSureColors.champagneInk),
                    decoration: const InputDecoration(
                      labelText: 'Last Name *',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter last name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey<String>('profile-edit-dob'),
                    controller: _dobCtrl,
                    style: const TextStyle(color: HomeSureColors.champagneInk),
                    decoration: InputDecoration(
                      labelText: 'Date of Birth *',
                      hintText: 'DD/MM/YYYY',
                      suffixIcon: IconButton(
                        onPressed: _pickDob,
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          color: HomeSureColors.champagneHighlight,
                        ),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter date of birth'
                        : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: HomeSureColors.statusCriticalText,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    key: const ValueKey<String>('profile-edit-save'),
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving...' : 'Save Changes'),
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
