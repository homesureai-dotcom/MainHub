import 'package:flutter/material.dart';

import '../../core/theme/homesure_tokens.dart';

class SureBotAvatar extends StatelessWidget {
  final double size;

  const SureBotAvatar({
    super.key,
    this.size = 104,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            HomeSureColors.midnightSelected,
            HomeSureColors.midnightCard,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: HomeSureColors.champagneGold,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        color: HomeSureColors.champagneHighlight,
        size: size * 0.48,
      ),
    );
  }
}