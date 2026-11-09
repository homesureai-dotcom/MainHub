import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../screens/main_shell.dart';
import '../../../screens/onboarding/city_selection_screen.dart';
import '../services/user_profile_service.dart';
import 'signed_out_flow.dart';

/// Lets onboarding screens request a fresh profile check from AuthGate.
final ValueNotifier<int> authGateRefreshNotifier = ValueNotifier<int>(0);

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final UserProfileService _profileService = UserProfileService();

  String? _profileUserId;
  int? _loadedRefreshVersion;
  Future<bool>? _profileFuture;

  @override
  void initState() {
    super.initState();
    authGateRefreshNotifier.addListener(_onProfileRefreshRequested);
  }

  @override
  void dispose() {
    authGateRefreshNotifier.removeListener(_onProfileRefreshRequested);
    super.dispose();
  }

  void _onProfileRefreshRequested() {
    if (!mounted) return;

    setState(() {
      _profileFuture = null;
      _loadedRefreshVersion = null;
    });
  }

  Future<bool> _loadProfile(String uid) {
    final refreshVersion = authGateRefreshNotifier.value;

    if (_profileUserId != uid ||
        _profileFuture == null ||
        _loadedRefreshVersion != refreshVersion) {
      _profileUserId = uid;
      _loadedRefreshVersion = refreshVersion;
      _profileFuture = _profileService.hasCompletedOnboarding();
    }

    return _profileFuture!;
  }

  void _retryProfile(String uid) {
    setState(() {
      _profileUserId = uid;
      _loadedRefreshVersion = authGateRefreshNotifier.value;
      _profileFuture = _profileService.hasCompletedOnboarding();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.hasError) {
          return const _AuthErrorScreen(
            message:
                'Unable to check your sign-in status. Please restart the app.',
          );
        }

        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final user = authSnapshot.data;

        if (user == null) {
          _profileUserId = null;
          _loadedRefreshVersion = null;
          _profileFuture = null;
          return const SignedOutFlow();
        }

        return FutureBuilder<bool>(
          future: _loadProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            if (profileSnapshot.hasError) {
              return _AuthErrorScreen(
                message:
                    'Unable to load your profile. Check your connection and try again.',
                onRetry: () => _retryProfile(user.uid),
              );
            }

            if (profileSnapshot.data == true) {
              return const MainShell();
            }

            return const CitySelectionScreen();
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _AuthErrorScreen extends StatelessWidget {
  const _AuthErrorScreen({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
