import 'package:flutter/material.dart';

import '../../../core/theme/homesure_tokens.dart';
import '../../../widgets/common/app_logo.dart';
import '../services/user_profile_service.dart';
import '../state/user_profile_state.dart';
import 'auth_gate.dart';

/// Post-sign-in onboarding step collecting First Name, Last Name, and Date of
/// Birth whenever a user's profile is incomplete.
class UserProfileSetupScreen extends StatefulWidget {
  final UserProfileData? initialProfile;

  const UserProfileSetupScreen({super.key, this.initialProfile});

  @override
  State<UserProfileSetupScreen> createState() => _UserProfileSetupScreenState();
}

class _UserProfileSetupScreenState extends State<UserProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _dobCtrl;

  bool _saving = false;
  String? _errorMessage;

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

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initial = DateTime(now.year - 28, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 13, now.month, now.day),
    );
    if (picked == null || !mounted) return;
    final dd = picked.day.toString().padLeft(2, '0');
    final mm = picked.month.toString().padLeft(2, '0');
    final yyyy = picked.year.toString();
    setState(() {
      _dobCtrl.text = '$dd/$mm/$yyyy';
    });
  }

  Future<void> _saveAndContinue() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await UserProfileService().saveUserProfile(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        dateOfBirth: _dobCtrl.text.trim(),
      );
      authGateRefreshNotifier.value++;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Could not save your profile details. Please check your connection and try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeSureColors.midnightBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                decoration: BoxDecoration(
                  color: HomeSureColors.midnightCard,
                  borderRadius: BorderRadius.circular(HomeSureRadius.lg),
                  border: Border.all(color: HomeSureColors.borderSlate),
                  boxShadow: HomeSureShadows.cardElevated,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: AppLogo(
                          variant: AppLogoVariant.emblem,
                          height: 56,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Complete Your Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: HomeSureColors.champagneInk,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tell us your name and date of birth to personalise your HomeSure AI workspace.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: HomeSureColors.slateMuted,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 22),
                      TextFormField(
                        key: const ValueKey<String>('profile-setup-first-name'),
                        controller: _firstNameCtrl,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(color: HomeSureColors.champagneInk),
                        decoration: const InputDecoration(
                          labelText: 'First Name *',
                          hintText: 'Enter your first name',
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            color: HomeSureColors.champagneHighlight,
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter your first name'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const ValueKey<String>('profile-setup-last-name'),
                        controller: _lastNameCtrl,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(color: HomeSureColors.champagneInk),
                        decoration: const InputDecoration(
                          labelText: 'Last Name *',
                          hintText: 'Enter your last name',
                          prefixIcon: Icon(
                            Icons.badge_outlined,
                            color: HomeSureColors.champagneHighlight,
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter your last name'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const ValueKey<String>('profile-setup-dob'),
                        controller: _dobCtrl,
                        keyboardType: TextInputType.datetime,
                        style: const TextStyle(color: HomeSureColors.champagneInk),
                        decoration: InputDecoration(
                          labelText: 'Date of Birth *',
                          hintText: 'DD/MM/YYYY',
                          prefixIcon: const Icon(
                            Icons.cake_outlined,
                            color: HomeSureColors.champagneHighlight,
                          ),
                          suffixIcon: IconButton(
                            tooltip: 'Select date of birth',
                            onPressed: _pickDateOfBirth,
                            icon: const Icon(
                              Icons.calendar_today_outlined,
                              color: HomeSureColors.champagneHighlight,
                            ),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter your date of birth'
                            : null,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: HomeSureColors.statusCriticalText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      FilledButton(
                        key: const ValueKey<String>('profile-setup-submit'),
                        onPressed: _saving ? null : _saveAndContinue,
                        child: Text(_saving ? 'Saving...' : 'Continue'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
