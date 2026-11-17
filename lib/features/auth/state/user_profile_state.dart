import 'package:flutter/foundation.dart';

/// Authenticated user profile details stored under `users/{uid}` in Firestore.
class UserProfileData {
  final String firstName;
  final String lastName;
  final String dateOfBirth;
  final String email;

  const UserProfileData({
    this.firstName = '',
    this.lastName = '',
    this.dateOfBirth = '',
    this.email = '',
  });

  String get fullName => '$firstName $lastName'.trim();

  bool get isComplete =>
      firstName.trim().isNotEmpty &&
      lastName.trim().isNotEmpty &&
      dateOfBirth.trim().isNotEmpty;

  UserProfileData copyWith({
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? email,
  }) {
    return UserProfileData(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      email: email ?? this.email,
    );
  }
}

/// Shared in-memory cache of the signed-in user's profile so Home, SureBot,
/// Property Context, and Profile screens stay synchronized without delay.
class UserProfileState extends ChangeNotifier {
  UserProfileState._();

  static final UserProfileState instance = UserProfileState._();

  UserProfileData? _profile;

  UserProfileData? get profile => _profile;

  String get displayName {
    final p = _profile;
    if (p == null) return '';
    if (p.fullName.isNotEmpty) return p.fullName;
    if (p.firstName.trim().isNotEmpty) return p.firstName.trim();
    final email = p.email.trim();
    if (email.contains('@')) {
      final raw = email
          .split('@')
          .first
          .replaceAll(RegExp(r'[._-]+'), ' ')
          .replaceAll(RegExp(r'\d+'), ' ')
          .trim();
      if (raw.isNotEmpty && raw.length <= 40) {
        return raw
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .map((part) => part[0].toUpperCase() + part.substring(1))
            .join(' ');
      }
    }
    return '';
  }

  String get firstNameOrDisplay {
    final p = _profile;
    if (p != null && p.firstName.trim().isNotEmpty) {
      return p.firstName.trim();
    }
    final name = displayName.trim();
    if (name.isEmpty) return '';
    return name.split(RegExp(r'\s+')).first;
  }

  void setProfile(UserProfileData? profile) {
    _profile = profile;
    notifyListeners();
  }

  void clear() {
    if (_profile == null) return;
    _profile = null;
    notifyListeners();
  }
}
