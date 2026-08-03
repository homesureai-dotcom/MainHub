import 'package:flutter/material.dart';

import '../models/apartment.dart';

class PropertyHealthRecordScreen extends StatelessWidget {
  final Apartment apartment;

  const PropertyHealthRecordScreen({
    super.key,
    required this.apartment,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Property Health Record"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [

                    Text(
                      apartment.projectName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      "PROPERTY HEALTH RECORD",
                      style: TextStyle(
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 30),

                    Text(
                      "${apartment.healthScore}/100",
                      style: const TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      apartment.healthScore >= 90
                          ? "Excellent"
                          : apartment.healthScore >= 75
                              ? "Good"
                              : "Needs Attention",
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Card(
              child: ListTile(
                leading: Icon(Icons.smart_toy),
                title: Text("AI Verdict"),
                subtitle: Text("Buy with Conditions"),
              ),
            ),

            const Card(
              child: ListTile(
                leading: Icon(Icons.gavel),
                title: Text("Compliance"),
                subtitle: Text("5 Verified • 2 Pending • 1 Issue"),
              ),
            ),

            const Card(
              child: ListTile(
                leading: Icon(Icons.description),
                title: Text("Documents"),
                subtitle: Text("7 Available • 3 Missing"),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.timeline),
                title: const Text("Project Journey"),
                subtitle: Text("${apartment.timeline.length} Milestones"),
              ),
            ),

            const Card(
              child: ListTile(
                leading: Icon(Icons.warning),
                title: Text("Top Risks"),
                subtitle: Text("e-Khata • BESCOM • STP"),
              ),
            ),

            Card(
              color: Colors.blue.shade50,
              child: const ListTile(
                leading: Icon(Icons.lightbulb),
                title: Text("Recommended Next Step"),
                subtitle: Text("Apply for e-Khata"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}