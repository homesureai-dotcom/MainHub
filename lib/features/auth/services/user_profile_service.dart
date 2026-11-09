import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> _profileReference(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  /// Returns the signed-in user's preferred SureBot language.
  /// Existing profiles without a preference default to English.
  Future<String> getPreferredLanguage() async {
    final user = _auth.currentUser;
    if (user == null) return 'en';

    final snapshot = await _profileReference(user.uid).get();
    final value = snapshot.data()?['preferredLanguage'];

    const supportedCodes = {'en', 'kn', 'hi', 'te', 'ta', 'ml'};
    if (value is String && supportedCodes.contains(value)) {
      return value;
    }

    return 'en';
  }

  /// Saves the preferred SureBot language in the user's own profile.
  Future<void> savePreferredLanguage(String languageCode) async {
    const supportedCodes = {'en', 'kn', 'hi', 'te', 'ta', 'ml'};

    if (!supportedCodes.contains(languageCode)) {
      throw ArgumentError.value(
        languageCode,
        'languageCode',
        'Unsupported SureBot language.',
      );
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to save your profile.');
    }

    await _profileReference(user.uid).set({
      'preferredLanguage': languageCode,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Returns a friendly name for the signed-in user.
  /// Priority: saved profile name, Firebase display name, email name.
  Future<String> getPreferredName() async {
    final user = _auth.currentUser;
    if (user == null) return 'there';

    try {
      final snapshot = await _profileReference(user.uid).get();
      final data = snapshot.data();

      for (final key in ['displayName', 'fullName', 'name']) {
        final value = data?[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    } catch (_) {
      // Fall back to Firebase Auth if the profile cannot be read.
    }

    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final emailName = user.email?.split('@').first;
    if (emailName == null || emailName.trim().isEmpty) return 'there';

    final cleaned = emailName
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .replaceAll(RegExp(r'\d+'), ' ')
        .trim();

    if (cleaned.isEmpty || cleaned.length > 40) return 'there';

    return cleaned
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  Future<bool> hasCompletedOnboarding() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final snapshot = await _profileReference(user.uid).get();
    final data = snapshot.data();

    return data?['onboardingCompleted'] == true;
  }

  Future<void> saveSelectedCity({
    required String city,
    required String state,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to save your profile.');
    }

    await _profileReference(user.uid).set({
      'city': city,
      'state': state,
      'onboardingCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
