import 'package:flutter/material.dart';

import '../../../../widgets/common/property_health_gauge/property_health_gauge.dart';

class ComponentGalleryScreen extends StatelessWidget {
  const ComponentGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text("HomeSure Design System"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(32),
        children: const [

          Text(
            "Property Health Gauge™",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 30),

          Center(
            child: PropertyHealthGauge(
              score: 78,
              status: "Healthy",
              size: 280,
            ),
          ),
        ],
      ),
    );
  }
}