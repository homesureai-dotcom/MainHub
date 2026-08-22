import 'package:flutter/material.dart';

import 'gauge_painter.dart';

class PropertyHealthGauge extends StatelessWidget {
  final int score;
  final String status;
  final double size;

  const PropertyHealthGauge({
    super.key,
    required this.score,
    required this.status,
    this.size = 260,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: GaugePainter(
          progress: score / 100,
        ),
      ),
    );
  }
}