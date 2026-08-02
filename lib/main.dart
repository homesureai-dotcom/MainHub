import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const HomeSureAI());
}

class HomeSureAI extends StatelessWidget {
  const HomeSureAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HomeSure AI',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}