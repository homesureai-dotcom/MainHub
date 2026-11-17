import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../auth/services/user_profile_service.dart';
import '../models/property.dart';

class PropertyState extends ChangeNotifier {
  PropertyState._();

  static final PropertyState instance = PropertyState._();

  Property? _selectedProperty;

  List<Property> _properties = [];

  bool _restoreAttempted = false;

  Property? get selectedProperty => _selectedProperty;

  List<Property> get properties => List.unmodifiable(_properties);

  bool get hasSelectedProperty => _selectedProperty != null;

  void initialize({
    required List<Property> properties,
    Property? selectedProperty,
  }) {
    _properties = List<Property>.from(properties);

    if (_properties.isNotEmpty) {
      _selectedProperty = selectedProperty ?? _properties.first;
    } else {
      _selectedProperty = selectedProperty;
    }

    notifyListeners();
  }

  void selectProperty(
    Property property,
  ) {
    _selectedProperty = property;

    final index = _properties.indexWhere((p) => p.id == property.id);
    if (index == -1) {
      _properties.add(property);
    } else {
      _properties[index] = property;
    }

    notifyListeners();

    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      unawaited(
        UserProfileService().saveSelectedProperty(property).catchError((_) {}),
      );
    }
  }

  /// Restores the signed-in user's previously selected property from Firestore
  /// if no property is currently held in memory.
  Future<void> restorePersistedProperty() async {
    if (_selectedProperty != null || _restoreAttempted) {
      return;
    }
    if (Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null) {
      return;
    }
    _restoreAttempted = true;

    try {
      final restored = await UserProfileService().loadSelectedProperty();
      if (restored != null && _selectedProperty == null) {
        _selectedProperty = restored;
        final index = _properties.indexWhere((p) => p.id == restored.id);
        if (index == -1) {
          _properties.add(restored);
        } else {
          _properties[index] = restored;
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  void addProperty(
    Property property,
  ) {
    _properties.add(property);

    _selectedProperty ??= property;

    notifyListeners();
  }

  void updateProperty(
    Property property,
  ) {
    final index = _properties.indexWhere(
      (p) => p.id == property.id,
    );

    if (index == -1) return;

    _properties[index] = property;

    if (_selectedProperty?.id == property.id) {
      _selectedProperty = property;
    }

    notifyListeners();
  }

  void removeProperty(
    String propertyId,
  ) {
    _properties.removeWhere(
      (p) => p.id == propertyId,
    );

    if (_selectedProperty?.id == propertyId) {
      _selectedProperty = _properties.isEmpty ? null : _properties.first;
    }

    notifyListeners();
  }

  void clear() {
    _properties.clear();
    _selectedProperty = null;
    _restoreAttempted = false;
    notifyListeners();
  }
}
