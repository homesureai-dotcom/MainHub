import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/homesure_tokens.dart';
import '../../../screens/main_shell.dart';
import '../../../widgets/common/app_logo.dart';
import '../../property/state/property_state.dart';
import '../services/user_profile_service.dart';
import '../state/user_profile_state.dart';
import 'signed_out_flow.dart';
import 'user_profile_setup_screen.dart';

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
  Future<UserProfileData>? _sessionFuture;

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
      _sessionFuture = null;
      _loadedRefreshVersion = null;
    });
  }

  Future<UserProfileData> _loadUserSession(String uid) {
    final refreshVersion = authGateRefreshNotifier.value;

    if (_profileUserId != uid ||
        _sessionFuture == null ||
        _loadedRefreshVersion != refreshVersion) {
      _profileUserId = uid;
      _loadedRefreshVersion = refreshVersion;
      _sessionFuture = () async {
        final results = await Future.wait<Object?>([
          _profileService.loadUserProfile(),
          PropertyState.instance.restorePersistedProperty(),
        ]);
        return results.first! as UserProfileData;
      }();
    }

    return _sessionFuture!;
  }

  void _retryProfile(String uid) {
    setState(() {
      _profileUserId = uid;
      _loadedRefreshVersion = authGateRefreshNotifier.value;
      _sessionFuture = null;
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
          _sessionFuture = null;
          UserProfileState.instance.clear();
          PropertyState.instance.clear();
          return const SignedOutFlow();
        }

        return FutureBuilder<UserProfileData>(
          future: _loadUserSession(user.uid),
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

            final profile = profileSnapshot.data ?? UserProfileState.instance.profile;
            if (profile == null || !profile.isComplete) {
              return UserProfileSetupScreen(initialProfile: profile);
            }

            // Authenticated users with a completed profile land directly on
            // the HomeSure AI primary workspace.
            return const MainShell();
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
    return Scaffold(
      backgroundColor: HomeSureColors.midnightBg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            AppLogo(
              variant: AppLogoVariant.full,
              height: 150,
            ),
            SizedBox(height: 24),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: HomeSureColors.champagneGold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthErrorScreen extends StatelessWidget {
  const _AuthErrorScreen({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeSureColors.midnightBg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: HomeSureColors.midnightCard,
              borderRadius: BorderRadius.circular(HomeSureRadius.lg),
              border: Border.all(color: HomeSureColors.borderSlate),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(
                  variant: AppLogoVariant.emblem,
                  height: 54,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: HomeSureColors.champagneInk,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
