import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/homesure_tokens.dart';

enum AppLogoVariant {
  emblem,
  full,
  horizontal,
  brandHeader,
}

/// Official HomeSure AI brand mark renderer.
///
/// Uses the approved champagne-on-midnight logo assets under `assets/brand/`
/// while preserving aspect ratios (`BoxFit.contain`).
class AppLogo extends StatelessWidget {
  final AppLogoVariant variant;
  final double height;
  final double? width;
  final bool showSubtitle;

  const AppLogo({
    super.key,
    this.variant = AppLogoVariant.horizontal,
    this.height = 44,
    this.width,
    this.showSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case AppLogoVariant.emblem:
        return SizedBox(
          height: height,
          width: width ?? height * (240 / 298),
          child: Image.asset(
            'assets/brand/homesure-emblem-transparent.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => SvgPicture.asset(
              'assets/brand/homesure-emblem.svg',
              fit: BoxFit.contain,
            ),
          ),
        );

      case AppLogoVariant.full:
        return SizedBox(
          height: height,
          width: width ?? height * (600 / 500),
          child: Image.asset(
            'assets/brand/homesure-logo-full-transparent.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => SvgPicture.asset(
              'assets/brand/homesure-logo-full.svg',
              fit: BoxFit.contain,
            ),
          ),
        );

      case AppLogoVariant.horizontal:
        return SizedBox(
          height: height,
          width: width ?? height * (680 / 150),
          child: Image.asset(
            'assets/brand/homesure-logo-horizontal-transparent.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => SvgPicture.asset(
              'assets/brand/homesure-logo-horizontal.svg',
              fit: BoxFit.contain,
            ),
          ),
        );

      case AppLogoVariant.brandHeader:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: height,
              width: height * (240 / 298),
              child: Image.asset(
                'assets/brand/homesure-emblem-transparent.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 9),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  const TextSpan(
                    children: [
                      TextSpan(
                        text: 'HomeSure',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: HomeSureColors.champagneInk,
                          letterSpacing: -0.2,
                        ),
                      ),
                      TextSpan(
                        text: 'AI',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: HomeSureColors.champagneHighlight,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showSubtitle)
                  const Text(
                    'Property Intelligence Platform',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: HomeSureColors.slateMuted,
                    ),
                  ),
              ],
            ),
          ],
        );
    }
  }
}
