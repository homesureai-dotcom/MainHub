import 'package:flutter/material.dart';

import 'city_selection_screen.dart';

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const SizedBox(height: 20),

            const Text(
              "How HomeSure AI Works",
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            const ListTile(
              leading: CircleAvatar(child: Text("1")),
              title: Text("Search your apartment"),
            ),

            const ListTile(
              leading: CircleAvatar(child: Text("2")),
              title: Text("Answer a few questions"),
            ),

            const ListTile(
              leading: CircleAvatar(child: Text("3")),
              title: Text("Receive your HomeSure Score"),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 56,

              child: FilledButton(
                onPressed: () {

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CitySelectionScreen(),
                    ),
                  );

                },
                child: const Text("Continue"),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}