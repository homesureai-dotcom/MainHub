import 'package:flutter/material.dart';

import '../../models/property_health/recommendation.dart';

class PropertyHealthRecommendationCard extends StatelessWidget {
  final Recommendation recommendation;

  const PropertyHealthRecommendationCard({
    super.key,
    required this.recommendation,
  });

  Color _priorityColor() {
    switch (recommendation.priority) {
      case RecommendationPriority.critical:
        return Colors.red.shade700;
      case RecommendationPriority.high:
        return Colors.orange.shade700;
      case RecommendationPriority.medium:
        return Colors.blue.shade700;
      case RecommendationPriority.low:
        return Colors.green.shade700;
    }
  }

  String _priorityLabel() {
    switch (recommendation.priority) {
      case RecommendationPriority.critical:
        return 'Critical Priority';
      case RecommendationPriority.high:
        return 'High Priority';
      case RecommendationPriority.medium:
        return 'Medium Priority';
      case RecommendationPriority.low:
        return 'Low Priority';
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor();

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: priorityColor.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    color: priorityColor,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _priorityLabel(),
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recommendation.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              recommendation.description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '+${recommendation.estimatedPHIGain} PHI',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                if (recommendation.requiredDocuments.isNotEmpty)
                  Expanded(
                    child: Text(
                      '${recommendation.requiredDocuments.length} '
                      '${recommendation.requiredDocuments.length == 1 ? 'document' : 'documents'} '
                      'required',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
              ],
            ),

            if (recommendation.requiredDocuments.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recommendation.requiredDocuments
                    .map(
                      (document) => Chip(
                        avatar: const Icon(
                          Icons.description_outlined,
                          size: 16,
                        ),
                        label: Text(document),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}