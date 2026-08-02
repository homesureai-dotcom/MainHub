import 'package:flutter/material.dart';
import '../models/apartment.dart';
import '../services/property_advisor_service.dart';

class PropertyAdvisorCard extends StatelessWidget {
  final Apartment apartment;

  const PropertyAdvisorCard({
    super.key,
    required this.apartment,
  });

  @override
  Widget build(BuildContext context) {
    final strengths = PropertyAdvisorService.strengths(apartment);
    final warnings = PropertyAdvisorService.warnings(apartment);
    final recommendation =
        PropertyAdvisorService.recommendation(apartment);
    final confidence =
        PropertyAdvisorService.confidence(apartment);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Row(
              children: [
                Icon(Icons.smart_toy,
                    color: Colors.deepPurple),
                SizedBox(width: 10),
                Text(
                  "HomeSure AI Advisor",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              "Buy Confidence : $confidence",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Strengths",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            ...strengths.map(
              (item) => ListTile(
                dense: true,
                leading: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
                title: Text(item),
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              "Warnings",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            ...warnings.map(
              (item) => ListTile(
                dense: true,
                leading: const Icon(
                  Icons.warning,
                  color: Colors.orange,
                ),
                title: Text(item),
              ),
            ),

            const Divider(height: 30),

            const Text(
              "Recommendation",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              recommendation,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}