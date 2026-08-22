import 'package:flutter/foundation.dart';

import '../models/property.dart';

class PropertyState extends ChangeNotifier {
  PropertyState._();

  static final PropertyState instance = PropertyState._();

  Property? _selectedProperty;

  List<Property> _properties = [];

  Property? get selectedProperty => _selectedProperty;

  List<Property> get properties =>
      List.unmodifiable(_properties);

  bool get hasSelectedProperty =>
      _selectedProperty != null;

  void initialize({
    required List<Property> properties,
    Property? selectedProperty,
  }) {
    _properties = List<Property>.from(properties);

    if (_properties.isNotEmpty) {
      _selectedProperty =
          selectedProperty ?? _properties.first;
    }

    notifyListeners();
  }

  void selectProperty(
    Property property,
  ) {
    _selectedProperty = property;

    notifyListeners();
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
      _selectedProperty =
          _properties.isEmpty ? null : _properties.first;
    }

    notifyListeners();
  }

  void clear() {
    _properties.clear();

    _selectedProperty = null;

    notifyListeners();
  }
}