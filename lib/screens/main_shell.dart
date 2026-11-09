
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/localization/app_locale_controller.dart';
import '../features/auth/services/auth_service.dart';
import '../features/network/screens/network_home_screen.dart';
import '../features/property/state/property_state.dart';
import 'home_screen_v2.dart';
import 'onboarding/property_search_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int currentIndex = 0;

  late final List<Widget> pages = [
    const HomeScreenV2(),
    const PropertySearchScreen(),
    const _ComingSoonScreen(
      title: 'Property Health Record',
      icon: Icons.health_and_safety_outlined,
    ),
    const _ComingSoonScreen(
      title: 'AI Advisor',
      icon: Icons.smart_toy_outlined,
    ),
    _NetworkDestination(
      onSelectProperty: () {
        setState(() {
          currentIndex = 1;
        });
      },
    ),
    const _ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment),
            label: 'Properties',
          ),
          NavigationDestination(
            icon: Icon(Icons.health_and_safety_outlined),
            selectedIcon: Icon(Icons.health_and_safety),
            label: 'Health',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Residents',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Connects Residents Welfare to the currently selected property.
class _NetworkDestination extends StatelessWidget {
  const _NetworkDestination({
    required this.onSelectProperty,
  });

  final VoidCallback onSelectProperty;

  @override
  Widget build(BuildContext context) {
    final propertyState = PropertyState.instance;

    return AnimatedBuilder(
      animation: propertyState,
      builder: (context, _) {
        final property = propertyState.selectedProperty;

        if (property == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Residents Welfare'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.apartment_outlined,
                      size: 64,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Select your property first',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Select your apartment to access '
                      'Residents Welfare and association services.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: onSelectProperty,
                      icon: const Icon(Icons.search),
                      label: const Text('Choose property'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return NetworkHomeScreen(
          key: ValueKey<String>(property.id),
          propertyId: property.id,
          propertyName: property.name,
        );
      },
    );
  }
}

class _ProfileScreen extends StatefulWidget {
  const _ProfileScreen();

  @override
  State<_ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<_ProfileScreen> {
  final AuthService _authService = AuthService();

  bool _isSigningOut = false;
  String? _errorMessage;

  Future<void> _changeProfileLanguage(String? code) async {
    if (code == null ||
        code == AppLocaleController.instance.languageCode) {
      return;
    }

    try {
      await AppLocaleController.instance.setLanguage(code);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Language preference updated.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save language preference. Please try again.',
          ),
        ),
      );
    }
  }

  Widget _profileLanguageTile() {
    const languages = <String, String>{
      'en': 'English',
      'kn': 'ಕನ್ನಡ',
      'hi': 'हिन्दी',
      'te': 'తెలుగు',
      'ta': 'தமிழ்',
      'ml': 'മലയാളം',
    };

    return ValueListenableBuilder<Locale>(
      valueListenable: AppLocaleController.instance.locale,
      builder: (context, locale, _) {
        final selectedCode =
            languages.containsKey(locale.languageCode)
                ? locale.languageCode
                : 'en';

        return ListTile(
          leading: const Icon(Icons.language),
          title: const Text('App language'),
          subtitle: const Text('Choose your preferred language'),
          trailing: DropdownButton<String>(
            value: selectedCode,
            items: languages.entries
                .map(
                  (entry) => DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: _changeProfileLanguage,
          ),
        );
      },
    );
  }

  Future<void> _confirmSignOut() async {
    if (_isSigningOut) return;

    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You can sign back in anytime. Your account and saved profile '
          'will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldSignOut != true || !mounted) return;

    setState(() {
      _isSigningOut = true;
      _errorMessage = null;
    });

    try {
      await _authService.signOut();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Could not sign out. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _authService.currentUser;
    final email = user?.email ?? 'No email available';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          const CircleAvatar(
            radius: 44,
            child: Icon(Icons.person_outline, size: 48),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your HomeSure AI account',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            email,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          const Divider(),
          _profileLanguageTile(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('Account status'),
            subtitle: Text(
              user == null ? 'Signed out' : 'Signed in',
            ),
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null) ...[
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  _isSigningOut ? null : _confirmSignOut,
              icon: _isSigningOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.logout),
              label: Text(
                _isSigningOut ? 'Signing out...' : 'Sign Out',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Signing out does not delete your account or saved property profile.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ComingSoonScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _ComingSoonScreen({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
