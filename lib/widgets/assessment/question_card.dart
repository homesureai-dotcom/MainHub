import 'package:flutter/material.dart';

import '../../core/phs/phs_question.dart';
import '../common/hs_info_bottom_sheet.dart';
import '../../core/phs/phs_categories.dart';

class QuestionCard extends StatelessWidget {
  final PHSQuestion question;

  const QuestionCard({
    super.key,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //----------------------------------------
          // Category Badge
          //----------------------------------------

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              question.category.displayName,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 28),

          //----------------------------------------
          // Question
          //----------------------------------------

          Text(
            question.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            question.helpText,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.7,
            ),
          ),

          //----------------------------------------
          // Learn More Card
          //----------------------------------------

          if (question.whyItMatters != null) ...[
            const SizedBox(height: 28),

            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                HSInfoBottomSheet.show(
                  context,
                  title: question.title,
                  category: question.category.displayName,
                  whyItMatters: question.whyItMatters!,
                  impact: question.impact ?? "",
                  priority:
                      question.priority?.name.toUpperCase() ?? "",
                  phiGain: question.potentialPHIGain ?? 0,
                  evidence: question.requiredEvidence,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFFEFF6FF),
                      child: Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),

                    SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Learn why this matters",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),

                          SizedBox(height: 4),

                          Text(
                            "Understand the impact on your Property Health Score",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}