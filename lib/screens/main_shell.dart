import 'package:flutter/material.dart';

import 'home_screen_v2.dart';
import 'onboarding/property_search_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {

  int currentIndex = 0;

  late final List<Widget> pages = [

    const HomeScreenV2(),

    const PropertySearchScreen(),

    const _ComingSoonScreen(
      title: "Property Health Record",
      icon: Icons.health_and_safety_outlined,
    ),

    const _ComingSoonScreen(
      title: "AI Advisor",
      icon: Icons.smart_toy_outlined,
    ),

    const _ComingSoonScreen(
      title: "Profile",
      icon: Icons.person_outline,
    ),
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),

      bottomNavigationBar: NavigationBar(

        selectedIndex: currentIndex,

        onDestinationSelected: (index) {

          setState(() {

            currentIndex = index;

          });

        },

        destinations: const [

          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: "Home",
          ),

          NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment),
            label: "Properties",
          ),

          NavigationDestination(
            icon: Icon(Icons.health_and_safety_outlined),
            selectedIcon: Icon(Icons.health_and_safety),
            label: "Health",
          ),

          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: "AI",
          ),

          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

class _ComingSoonScreen extends StatelessWidget {

  final String title;
  final IconData icon;

  const _ComingSoonScreen({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text(title),
      ),

      body: Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Icon(
              icon,
              size: 80,
              color: Colors.grey,
            ),

            const SizedBox(height: 24),

            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              "Coming Soon",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}