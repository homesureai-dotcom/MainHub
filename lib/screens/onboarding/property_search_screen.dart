import 'package:flutter/material.dart';

import '../../data/properties.dart';
import '../../models/property.dart';
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

  List<Property> filteredProperties = properties;

  Property? selectedProperty;

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
          if (selectedProperty == null) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PropertyDetailsScreen(
                property: selectedProperty!,
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

                filteredProperties = properties.where((property) {

                  return property.name
                          .toLowerCase()
                          .contains(value.toLowerCase()) ||
                      property.builder
                          .toLowerCase()
                          .contains(value.toLowerCase());

                }).toList();

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
              itemCount: filteredProperties.length,

              itemBuilder: (context, index) {

                final property = filteredProperties[index];

                return PropertyCard(
                  property: property,

                  onTap: () {

                    setState(() {

                      selectedProperty = property;

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