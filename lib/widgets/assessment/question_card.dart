import '../../features/assessment/localization/assessment_translations.dart';
import '../../features/assessment/localization/assessment_content_translations.dart';
import '../../core/localization/app_locale_controller.dart';
import 'package:flutter/material.dart';

import '../../core/evidence/evidence.dart';
import '../../core/evidence/evidence_completeness.dart';
import '../../core/evidence/evidence_requirement.dart';
import '../../core/evidence/evidence_requirement_catalog.dart';
import '../../core/evidence/evidence_requirement_resolver.dart';
import '../../core/evidence/evidence_type_mapper.dart';
import '../../core/phs/phs_question.dart';
import '../common/hs_info_bottom_sheet.dart';
import 'add_evidence_button.dart';
import 'evidence_action_sheet.dart';
import 'evidence_item_card.dart';
import 'evidence_requirement_card.dart';

class QuestionCard extends StatelessWidget {
  final PHSQuestion question;
  final List<Evidence> suppliedEvidence;
  final ValueChanged<EvidenceType>? onEvidenceTypeSelected;
  final ValueChanged<Evidence>? onEvidenceStatusChange;
  final ValueChanged<Evidence>? onEvidenceDelete;

  const QuestionCard({
    super.key,
    required this.question,
    this.suppliedEvidence = const [],
    this.onEvidenceTypeSelected,
    this.onEvidenceStatusChange,
    this.onEvidenceDelete,
  });

  List<EvidenceRequirement> _resolveEvidenceRequirements() {
    final typeMapper = const EvidenceTypeMapper();

    final resolver = EvidenceRequirementResolver(typeMapper: typeMapper);

    final catalog = EvidenceRequirementCatalog(resolver: resolver);

    return catalog.getForQuestion(question);
  }

  Future<void> _handleAddEvidence(BuildContext context) async {
    final evidenceType = await EvidenceActionSheet.show(context);

    if (evidenceType == null) {
      return;
    }

    onEvidenceTypeSelected?.call(evidenceType);
  }

  Widget _buildEvidenceCoverage(EvidenceCompleteness completeness) {
    final percentage = completeness.coveragePercentage.clamp(0, 100).toDouble();

    final isComplete = completeness.isComplete;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isComplete ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isComplete ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isComplete
                    ? Icons.verified_outlined
                    : Icons.fact_check_outlined,
                color: isComplete
                    ? const Color(0xFF15803D)
                    : const Color(0xFFB45309),
                size: 22,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Evidence coverage',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isComplete
                      ? const Color(0xFF15803D)
                      : const Color(0xFFB45309),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isComplete
                ? '${completeness.matchedRequirements} of '
                      '${completeness.totalRequirements} evidence '
                      'requirements met'
                : '${completeness.matchedRequirements} of '
                      '${completeness.totalRequirements} evidence '
                      'requirements met · '
                      '${completeness.missingRequirements} missing',
            style: TextStyle(
              fontSize: 14,
              color: isComplete
                  ? const Color(0xFF166534)
                  : const Color(0xFF92400E),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final evidenceRequirements = _resolveEvidenceRequirements();

    final evidenceCompleteness = EvidenceCompleteness.calculate(
      requirements: evidenceRequirements,
      evidence: suppliedEvidence,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              AssessmentTranslations(
                AppLocaleController.instance.languageCode,
              ).categoryName(question.category),
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
            AssessmentTranslations(
              AppLocaleController.instance.languageCode,
            ).questionTitle(question),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            AssessmentContentTranslations(
              AppLocaleController.instance.languageCode,
            ).helpText(question),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.7,
            ),
          ),

          //----------------------------------------
          // Evidence Requirements
          //----------------------------------------
          if (evidenceRequirements.isNotEmpty) ...[
            const SizedBox(height: 28),

            const Text(
              'Evidence you may need',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 8),

            const Text(
              'These items can help support your assessment response.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blueGrey,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 14),

            ...evidenceRequirements.map(
              (requirement) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: EvidenceRequirementCard(requirement: requirement),
              ),
            ),

            const SizedBox(height: 8),

            //----------------------------------------
            // Evidence Coverage
            //----------------------------------------
            _buildEvidenceCoverage(evidenceCompleteness),
          ],

          //----------------------------------------
          // Supplied Evidence
          //----------------------------------------
          if (suppliedEvidence.isNotEmpty) ...[
            const SizedBox(height: 28),

            const Text(
              'Evidence provided',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 8),

            const Text(
              'Evidence currently associated with this question.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blueGrey,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 14),

            ...suppliedEvidence.map(
              (evidence) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: EvidenceItemCard(
                  evidence: evidence,
                  onStatusChange: onEvidenceStatusChange == null
                      ? null
                      : (status) {
                          onEvidenceStatusChange!(
                            evidence.copyWith(status: status),
                          );
                        },
                  onDelete: onEvidenceDelete == null
                      ? null
                      : () {
                          onEvidenceDelete!(evidence);
                        },
                ),
              ),
            ),
          ],

          //----------------------------------------
          // Add Evidence
          //----------------------------------------
          const SizedBox(height: 18),

          AddEvidenceButton(onPressed: () => _handleAddEvidence(context)),

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
                  title: AssessmentTranslations(
                    AppLocaleController.instance.languageCode,
                  ).questionTitle(question),
                  category: AssessmentTranslations(
                    AppLocaleController.instance.languageCode,
                  ).categoryName(question.category),
                  whyItMatters: AssessmentContentTranslations(
                    AppLocaleController.instance.languageCode,
                  ).whyItMatters(question),
                  impact: AssessmentContentTranslations(
                    AppLocaleController.instance.languageCode,
                  ).impact(question),
                  priority: question.priority?.name.toUpperCase() ?? '',
                  phiGain: question.potentialPHIGain ?? 0,
                  evidence: AssessmentContentTranslations(
                    AppLocaleController.instance.languageCode,
                  ).requiredEvidence(question),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Learn why this matters',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Understand the impact on your Property Health Score',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey),
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
