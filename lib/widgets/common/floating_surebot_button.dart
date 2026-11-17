import 'package:flutter/material.dart';

import '../../core/theme/homesure_tokens.dart';

/// Floating HomeSure AI character entry point anchored above the bottom bar.
///
/// Opens the existing [SureBotScreen] assistant without duplicating backend
/// logic. Uses a single-shot entrance transition (no continuous ticker loop)
/// so automated UI tests and `pumpAndSettle` complete cleanly.
class FloatingSureBotButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String? tooltip;

  const FloatingSureBotButton({
    super.key,
    required this.onPressed,
    this.tooltip,
  });

  @override
  State<FloatingSureBotButton> createState() => _FloatingSureBotButtonState();
}

class _FloatingSureBotButtonState extends State<FloatingSureBotButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Tooltip(
          message: widget.tooltip ?? 'Ask HomeSure AI (SureBot)',
          child: Semantics(
            button: true,
            label: 'Open HomeSure AI Assistant',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const ValueKey<String>('floating-surebot-button'),
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
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
                          width: 1.8,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66000000),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                          BoxShadow(
                            color: Color(0x28C9A47E),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const CustomPaint(
                        painter: _SureBotCharacterPainter(),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              HomeSureColors.champagneGold,
                              HomeSureColors.champagneHighlight,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: HomeSureShadows.cardSubtle,
                        ),
                        child: const Text(
                          'SureBot AI',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: HomeSureColors.midnightBg,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SureBotCharacterPainter extends CustomPainter {
  const _SureBotCharacterPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 2;

    // Pitched champagne house-bot roof cap
    final roofPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          HomeSureColors.champagneHighlight,
          HomeSureColors.champagneGold,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(cx - 18, cy - 22, 36, 16))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final roofPath = Path()
      ..moveTo(cx - 16, cy - 6)
      ..lineTo(cx, cy - 19)
      ..lineTo(cx + 16, cy - 6);
    canvas.drawPath(roofPath, roofPaint);

    // Friendly antenna spark at roof peak
    final sparkPaint = Paint()
      ..color = HomeSureColors.champagneHighlight
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy - 21.5), 2.2, sparkPaint);

    // Rounded house-bot face visor
    final visorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 4), width: 26, height: 19),
      const Radius.circular(8),
    );
    final visorFill = Paint()..color = HomeSureColors.midnightBg;
    final visorBorder = Paint()
      ..color = HomeSureColors.champagneBronze
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRRect(visorRect, visorFill);
    canvas.drawRRect(visorRect, visorBorder);

    // Expressive glowing eyes
    final eyePaint = Paint()..color = HomeSureColors.champagneHighlight;
    canvas.drawCircle(Offset(cx - 5.5, cy + 2), 2.3, eyePaint);
    canvas.drawCircle(Offset(cx + 5.5, cy + 2), 2.3, eyePaint);

    // Friendly smile curve
    final smilePaint = Paint()
      ..color = HomeSureColors.champagneGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final smileRect = Rect.fromCenter(
      center: Offset(cx, cy + 5.5),
      width: 10,
      height: 6,
    );
    canvas.drawArc(smileRect, 0.25, 2.65, false, smilePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
