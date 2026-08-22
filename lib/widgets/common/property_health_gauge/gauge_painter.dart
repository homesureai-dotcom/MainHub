import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'gauge_theme.dart';

class GaugePainter extends CustomPainter {
  final double progress;

  const GaugePainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius =
        (math.min(size.width, size.height) / 2) -
        GaugeTheme.strokeWidth;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    //----------------------------------------------------------
    // Background Arc
    //----------------------------------------------------------

    final backgroundPaint = Paint()
      ..color = GaugeTheme.background
      ..strokeWidth = GaugeTheme.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawArc(
      rect,
      _degToRad(GaugeTheme.startAngle),
      _degToRad(GaugeTheme.sweepAngle),
      false,
      backgroundPaint,
    );

    //----------------------------------------------------------
    // Progress Arc
    //----------------------------------------------------------

    final progressPaint = Paint()
      ..color = GaugeTheme.healthy
      ..strokeWidth = GaugeTheme.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawArc(
      rect,
      _degToRad(GaugeTheme.startAngle),
      _degToRad(
        GaugeTheme.sweepAngle * progress,
      ),
      false,
      progressPaint,
    );
  }

  double _degToRad(double degrees) {
    return degrees * math.pi / 180;
  }

  @override
  bool shouldRepaint(covariant GaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}