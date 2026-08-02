import 'package:flutter/material.dart';
import 'compliance_item.dart';

class ComplianceCard extends StatelessWidget {
  const ComplianceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Compliance Status",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(height: 15),

            ComplianceItem(
              icon: Icons.check_circle,
              title: "RERA Registered",
              color: Colors.green,
            ),

            ComplianceItem(
              icon: Icons.check_circle,
              title: "Occupancy Certificate",
              color: Colors.green,
            ),

            ComplianceItem(
              icon: Icons.check_circle,
              title: "Fire NOC",
              color: Colors.green,
            ),

            ComplianceItem(
              icon: Icons.warning,
              title: "e-Khata Pending",
              color: Colors.orange,
            ),

            ComplianceItem(
              icon: Icons.warning,
              title: "BESCOM Pending",
              color: Colors.orange,
            ),

            ComplianceItem(
              icon: Icons.cancel,
              title: "STP Issue",
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}