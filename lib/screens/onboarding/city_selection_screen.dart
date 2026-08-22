import 'package:flutter/material.dart';

import '../../data/cities.dart';
import '../../widgets/city/city_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_search_field.dart';
import '../../widgets/common/onboarding_scaffold.dart';
import '../main_shell.dart';

class CitySelectionScreen extends StatefulWidget {
  const CitySelectionScreen({super.key});

  @override
  State<CitySelectionScreen> createState() =>
      _CitySelectionScreenState();
}

class _CitySelectionScreenState
    extends State<CitySelectionScreen> {

  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: "Where is your property?",

      subtitle:
          "We'll personalise your Property Health Record based on its location.",

      bottom: AppButton(
        text: "Continue",

        enabled: selectedIndex != null,

        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const MainShell(),
            ),
          );
        },
      ),

      child: Column(
        children: [
          AppSearchField(
            hintText: "Search city",
            onChanged: (value) {
              // Search functionality will be added later
            },
          ),

          const SizedBox(height: 24),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Popular Locations",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: ListView.builder(
              itemCount: cities.length,
              itemBuilder: (context, index) {
                return CityCard(
                  city: cities[index],
                  selected: selectedIndex == index,
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
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