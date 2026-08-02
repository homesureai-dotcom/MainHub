import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/apartment.dart';

import '../widgets/apartment_selector.dart';
import '../widgets/health_card.dart';
import '../widgets/priority_card.dart';
import '../widgets/compliance_card.dart';

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

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}