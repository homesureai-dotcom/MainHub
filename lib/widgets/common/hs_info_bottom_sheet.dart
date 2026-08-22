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
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(32),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  //------------------------------------
                  // Title
                  //------------------------------------

                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Chip(
                    label: Text(category),
                  ),

                  const SizedBox(height: 32),

                  _section(
                    icon: Icons.lightbulb_outline,
                    color: Colors.amber,
                    title: "Why this matters",
                    body: whyItMatters,
                  ),

                  _section(
                    icon: Icons.warning_amber_rounded,
                    color: Colors.orange,
                    title: "Impact",
                    body: impact,
                  ),

                  _section(
                    icon: Icons.priority_high,
                    color: Colors.red,
                    title: "Priority",
                    body: priority,
                  ),

                  _section(
                    icon: Icons.trending_up,
                    color: Colors.green,
                    title: "Potential Property Health Gain",
                    body: "+$phiGain PHI",
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    "Required Evidence",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 12),

                  ...evidence.map(
                    (e) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.description_outlined),
                      title: Text(e),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Got it"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _section({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              Icon(
                icon,
                color: color,
              ),

              const SizedBox(width: 10),

              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
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
            ),
          ),
        ],
      ),
    );
  }
}