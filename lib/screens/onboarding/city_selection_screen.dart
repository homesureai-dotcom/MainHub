import 'package:flutter/material.dart';

import '../../data/cities.dart';
import '../../features/auth/services/user_profile_service.dart';
import '../../features/auth/screens/auth_gate.dart';
import '../../widgets/city/city_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_search_field.dart';
import '../../widgets/common/onboarding_scaffold.dart';

class CitySelectionScreen extends StatefulWidget {
  const CitySelectionScreen({super.key});

  @override
  State<CitySelectionScreen> createState() => _CitySelectionScreenState();
}

class _CitySelectionScreenState extends State<CitySelectionScreen> {
  int? selectedIndex;
  bool _isSaving = false;
  String? _errorMessage;

  final UserProfileService _profileService = UserProfileService();

  Future<void> _saveCityAndContinue() async {
    if (_isSaving || selectedIndex == null) return;

    final selectedCity = cities[selectedIndex!];

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _profileService.saveSelectedCity(
        city: selectedCity.name,
        state: selectedCity.state,
      );

      authGateRefreshNotifier.value++;
      // AuthGate reloads the saved profile and switches to MainShell.
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'We could not save your city. Check your connection and try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'Where is your property?',
      subtitle:
          "We'll personalise your Property Health Record based on its location.",
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) ...[
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
          AppButton(
            text: _isSaving ? 'Saving...' : 'Continue',
            enabled: selectedIndex != null && !_isSaving,
            onPressed: _saveCityAndContinue,
            icon: _isSaving ? Icons.hourglass_top : Icons.arrow_forward,
          ),
        ],
      ),
      child: Column(
        children: [
          AppSearchField(
            hintText: 'Search city',
            onChanged: (value) {
              // Search functionality will be added later.
            },
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Popular Locations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: cities.length,
              itemBuilder: (context, index) {
                return CityCard(
                  city: cities[index],
                  selected: selectedIndex == index,
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
