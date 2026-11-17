import 'package:flutter/material.dart';

import '../../core/theme/homesure_tokens.dart';

class HSInfoBottomSheet {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String category,
    required String whyItMatters,
    required String impact,
    required String priority,
    required int phiGain,
    required List<String> evidence,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _QuestionRationalePage(
          title: title,
          category: category,
          whyItMatters: whyItMatters,
          impact: impact,
          priority: priority,
          phiGain: phiGain,
          evidence: evidence,
        ),
      ),
    );
  }
}

class _QuestionRationalePage extends StatelessWidget {
  final String title;
  final String category;
  final String whyItMatters;
  final String impact;
  final String priority;
  final int phiGain;
  final List<String> evidence;

  const _QuestionRationalePage({
    required this.title,
    required this.category,
    required this.whyItMatters,
    required this.impact,
    required this.priority,
    required this.phiGain,
    required this.evidence,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeSureColors.midnightBg,
      appBar: AppBar(
        backgroundColor: HomeSureColors.midnightHeader,
        surfaceTintColor: HomeSureColors.midnightHeader,
        foregroundColor: HomeSureColors.champagneInk,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Why this is important',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: HomeSureColors.champagneInk,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: HomeSureColors.champagneInk,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Chip(
                      label: Text(category),
                      backgroundColor: HomeSureColors.midnightSand,
                      labelStyle: const TextStyle(
                        color: HomeSureColors.champagneHighlight,
                        fontWeight: FontWeight.w700,
                      ),
                      side: const BorderSide(
                        color: HomeSureColors.champagneBronze,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _section(
                      icon: Icons.lightbulb_outline_rounded,
                      color: HomeSureColors.champagneHighlight,
                      title: 'Why this matters',
                      body: whyItMatters,
                    ),
                    _section(
                      icon: Icons.warning_amber_rounded,
                      color: HomeSureColors.statusWarningText,
                      title: 'Impact',
                      body: impact,
                    ),
                    _section(
                      icon: Icons.priority_high_rounded,
                      color: HomeSureColors.statusCriticalText,
                      title: 'Priority',
                      body: priority,
                    ),
                    _section(
                      icon: Icons.trending_up_rounded,
                      color: HomeSureColors.statusPositiveText,
                      title: 'Potential Property Health Gain',
                      body: '+$phiGain PHI',
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Required Evidence',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: HomeSureColors.champagneInk,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (evidence.isEmpty)
                      const Text(
                        'No specific evidence items are listed for this question.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: HomeSureColors.slateMuted,
                        ),
                      )
                    else
                      ...evidence.map(
                        (item) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: HomeSureColors.midnightCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: HomeSureColors.borderSlate,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.description_outlined,
                                color: HomeSureColors.champagneHighlight,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    height: 1.4,
                                    color: HomeSureColors.champagneInk,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                color: HomeSureColors.midnightHeader,
                border: Border(
                  top: BorderSide(color: HomeSureColors.borderSlate),
                ),
              ),
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Back to question'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: HomeSureColors.midnightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HomeSureColors.borderSlate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16.5,
                    color: HomeSureColors.champagneInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(left: 10),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: HomeSureColors.champagneGold,
                  width: 3,
                ),
              ),
            ),
            child: Text(
              body,
              style: const TextStyle(
                fontSize: 15,
                height: 1.55,
                color: HomeSureColors.slateDetailBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
