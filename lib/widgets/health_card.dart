import 'package:flutter/material.dart';
import '../models/apartment.dart';
import '../services/apartment_score_service.dart';

class HealthCard extends StatelessWidget {
  final Apartment apartment;

  const HealthCard({
    super.key,
    required this.apartment,
  });

  @override
  Widget build(BuildContext context) {
    final score = ApartmentScoreService.calculateHealthScore(apartment);
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.home, color: Colors.blue),
                SizedBox(width: 10),
                Text(
                  "Apartment Health",
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Text(
              "$score%",
              style: const TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              score >= 90
                  ? "Excellent"
                  : score >= 75
                      ? "Good"
                      : "Needs Attention",
              style: const TextStyle(
                color: Colors.green,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}