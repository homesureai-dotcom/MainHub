import 'package:flutter/material.dart';

import 'widgets/hero_module.dart';

class PropertyCommandCenterScreen extends StatelessWidget {
  const PropertyCommandCenterScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF8FAFC),
        title: const Text(
          "Property Command Center",
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: const [
              HeroModule(
                propertyName: "Casagrand Aquene",
                phi: 91,
                potentialPhi: 97,
                status: "Certified Healthy",
                assessmentDate: "Today",
              ),
            ],
          ),
        ),
      ),
    );
  }
}