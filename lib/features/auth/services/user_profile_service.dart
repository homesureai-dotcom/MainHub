import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../property/models/property.dart';
import '../state/user_profile_state.dart';

class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> _profileReference(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  /// Loads the signed-in user's profile (`firstName`, `lastName`, `dateOfBirth`)
  /// and syncs [UserProfileState.instance].
  Future<UserProfileData> loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      const empty = UserProfileData();
      UserProfileState.instance.clear();
      return empty;
    }

    Map<String, dynamic> data = const {};
    try {
      final snapshot = await _profileReference(user.uid).get();
      data = snapshot.data() ?? const {};
    } catch (_) {}

    var firstName = (data['firstName'] ?? '').toString().trim();
    var lastName = (data['lastName'] ?? '').toString().trim();
    final dateOfBirth = (data['dateOfBirth'] ?? '').toString().trim();

    if (firstName.isEmpty) {
      for (final key in ['fullName', 'displayName', 'name']) {
        final raw = data[key]?.toString().trim() ?? '';
        if (raw.isNotEmpty) {
          final parts = raw.split(RegExp(r'\s+'));
          firstName = parts.first;
          if (lastName.isEmpty && parts.length > 1) {
            lastName = parts.sublist(1).join(' ');
          }
          break;
        }
      }
    }

    final profile = UserProfileData(
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      email: user.email ?? '',
    );

    UserProfileState.instance.setProfile(profile);
    return profile;
  }

  /// Saves the signed-in user's personal profile and updates [UserProfileState].
  Future<void> saveUserProfile({
    required String firstName,
    required String lastName,
    required String dateOfBirth,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to save your profile.');
    }

    final trimmedFirst = firstName.trim();
    final trimmedLast = lastName.trim();
    final trimmedDob = dateOfBirth.trim();
    final fullName = '$trimmedFirst $trimmedLast'.trim();

    await _profileReference(user.uid).set({
      'firstName': trimmedFirst,
      'lastName': trimmedLast,
      'fullName': fullName,
      'displayName': fullName,
      'dateOfBirth': trimmedDob,
      'profileCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    UserProfileState.instance.setProfile(
      UserProfileData(
        firstName: trimmedFirst,
        lastName: trimmedLast,
        dateOfBirth: trimmedDob,
        email: user.email ?? '',
      ),
    );
  }

  /// Persists the user's selected property under `users/{uid}` so it restores
  /// across app restarts and screen exits.
  Future<void> saveSelectedProperty(Property property) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _profileReference(user.uid).set({
      'selectedPropertyId': property.id,
      'selectedProperty': property.toPersistenceMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Loads the user's persisted selected property from `users/{uid}`, if any.
  Future<Property?> loadSelectedProperty() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snapshot = await _profileReference(user.uid).get();
    final data = snapshot.data();
    if (data == null) return null;

    final rawSelected = data['selectedProperty'];
    if (rawSelected is Map) {
      final restored = Property.fromPersistenceMap(
        Map<String, dynamic>.from(rawSelected),
      );
      if (restored.id.trim().isNotEmpty && restored.name.trim().isNotEmpty) {
        return restored;
      }
    }
    return null;
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

  /// Returns a friendly first/display name for the signed-in user.
  Future<String> getPreferredName() async {
    final cached = UserProfileState.instance.firstNameOrDisplay;
    if (cached.isNotEmpty) return cached;

    final user = _auth.currentUser;
    if (user == null) return 'there';

    final profile = await loadUserProfile();
    if (profile.firstName.trim().isNotEmpty) {
      return profile.firstName.trim();
    }

    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName.split(RegExp(r'\s+')).first;
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
