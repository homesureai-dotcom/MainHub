import 'package:flutter/material.dart';

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Why this is important',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 26,
                        height: 1.2,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Chip(
                      label: Text(category),
                      backgroundColor: const Color(0xFFE2E8F0),
                      side: BorderSide.none,
                    ),
                    const SizedBox(height: 28),
                    _section(
                      icon: Icons.lightbulb_outline_rounded,
                      color: Colors.amber.shade800,
                      title: 'Why this matters',
                      body: whyItMatters,
                    ),
                    _section(
                      icon: Icons.warning_amber_rounded,
                      color: Colors.orange.shade800,
                      title: 'Impact',
                      body: impact,
                    ),
                    _section(
                      icon: Icons.priority_high_rounded,
                      color: Colors.red.shade700,
                      title: 'Priority',
                      body: priority,
                    ),
                    _section(
                      icon: Icons.trending_up_rounded,
                      color: Colors.green.shade700,
                      title: 'Potential Property Health Gain',
                      body: '+$phiGain PHI',
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Required Evidence',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (evidence.isEmpty)
                      const Text(
                        'No specific evidence items are listed for this question.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Color(0xFF475569),
                        ),
                      )
                    else
                      ...evidence.map(
                        (item) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.description_outlined,
                            color: Color(0xFF475569),
                          ),
                          title: Text(
                            item,
                            style: const TextStyle(fontSize: 15, height: 1.4),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}
