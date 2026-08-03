import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/apartment.dart';

import '../widgets/apartment_selector.dart';
import '../widgets/health_card.dart';
import '../widgets/priority_card.dart';
import '../widgets/compliance_card.dart';
import '../widgets/score_breakdown_card.dart';
import '../widgets/property_advisor_card.dart';
import '../widgets/project_journey_card.dart';
import 'property_health_record_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  Apartment selectedApartment = apartments.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(
                selectedApartment.projectName,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Vinod",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              ApartmentSelector(
                selectedApartment: selectedApartment,
                onChanged: (Apartment apartment) {
                  setState(() {
                    selectedApartment = apartment;
                  });
                },
              ),

              const SizedBox(height: 25),

              HealthCard(
             apartment: selectedApartment,
             ),

              const SizedBox(height: 25),

              const PriorityCard(),

              const SizedBox(height: 25),

              const ComplianceCard(),

              const SizedBox(height: 25),
            
              const ScoreBreakdownCard(),

              const SizedBox(height: 25),

              PropertyAdvisorCard(
               apartment: selectedApartment,
              ),

              const SizedBox(height: 25),

             ProjectJourneyCard(
              apartment: selectedApartment,
              ),

              const SizedBox(height: 20),

              SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
             icon: const Icon(Icons.health_and_safety),
              label: const Text(
              "View Property Health Record",
              style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
               padding: const EdgeInsets.symmetric(vertical: 18),
              ),
             onPressed: () {
             Navigator.push(
              context,
             MaterialPageRoute(
               builder: (_) => PropertyHealthRecordScreen(
              apartment: selectedApartment,
          ),
        ),
      );
    },
  ),
),

const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}