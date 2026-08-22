import 'package:flutter/material.dart';

class SureBotAvatar extends StatelessWidget {
  const SureBotAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF1D4ED8),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.smart_toy_rounded,
        color: Colors.white,
        size: 60,
      ),
    );
  }
}