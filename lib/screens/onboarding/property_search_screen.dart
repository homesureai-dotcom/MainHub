import 'package:flutter/material.dart';

import '../../data/properties.dart';
import '../../models/property.dart' as legacy;
import '../../features/property/models/property.dart' as feature;
import '../../features/property/models/property_adapter.dart';
import '../../features/property/state/property_state.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_search_field.dart';
import '../../widgets/common/onboarding_scaffold.dart';
import '../../widgets/property/property_card.dart';
import '../property/property_details_screen.dart';

class PropertySearchScreen extends StatefulWidget {
  const PropertySearchScreen({super.key});

  @override
  State<PropertySearchScreen> createState() =>
      _PropertySearchScreenState();
}

class _PropertySearchScreenState
    extends State<PropertySearchScreen> {
  final PropertyState propertyState =
      PropertyState.instance;

  List<legacy.Property> filteredProperties =
      properties;

  legacy.Property? selectedProperty;

  @override
  void initState() {
    super.initState();

    final feature.Property? sharedProperty =
        propertyState.selectedProperty;

    if (sharedProperty == null) {
      return;
    }

    for (final legacy.Property property in properties) {
      if (property.id == sharedProperty.id ||
          property.name == sharedProperty.name) {
        selectedProperty = property;
        break;
      }
    }
  }

  void _persistSelectedProperty(
    legacy.Property property,
  ) {
    feature.Property? canonicalProperty;

    for (final feature.Property candidate
        in propertyState.properties) {
      if (candidate.id == property.id ||
          candidate.name == property.name) {
        canonicalProperty = candidate;
        break;
      }
    }

    if (canonicalProperty != null) {
      propertyState.selectProperty(
        canonicalProperty,
      );
      return;
    }

    propertyState.selectProperty(
      PropertyAdapter.fromLegacy(property),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: "Find Your Property",
      subtitle:
          "Search from verified HomeSure properties.",
      bottom: AppButton(
        text: "Continue",
        enabled: selectedProperty != null,
        onPressed: () {
          final legacy.Property? property =
              selectedProperty;

          if (property == null) {
            return;
          }

          _persistSelectedProperty(property);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PropertyDetailsScreen(
                property: property,
              ),
            ),
          );
        },
      ),
      child: Column(
        children: [
          AppSearchField(
            hintText: "Search properties",
            onChanged: (value) {
              setState(() {
                filteredProperties =
                    properties.where(
                  (legacy.Property property) {
                    return property.name
                            .toLowerCase()
                            .contains(
                              value.toLowerCase(),
                            ) ||
                        property.builder
                            .toLowerCase()
                            .contains(
                              value.toLowerCase(),
                            );
                  },
                ).toList();
              });
            },
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Recommended Properties",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount:
                  filteredProperties.length,
              itemBuilder: (context, index) {
                final legacy.Property property =
                    filteredProperties[index];

                return PropertyCard(
                  property: property,
                  onTap: () {
                    setState(() {
                      selectedProperty = property;
                    });

                    _persistSelectedProperty(
                      property,
                    );
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