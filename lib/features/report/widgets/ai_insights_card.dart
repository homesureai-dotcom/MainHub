import 'package:flutter/material.dart';
import '../../../l10n/generated/app_localizations.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_section_header.dart';
import '../models/property_health_report.dart';
import '../../surebot/services/property_health_explainer.dart';

class AIInsightsCard extends StatelessWidget {
  final PropertyHealthReport report;

  const AIInsightsCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final explanation = const PropertyHealthExplainer().explain(
      report,
      languageCode: Localizations.localeOf(context).languageCode,
    );
    final currentScore = explanation.score.round();

    return AppCard(
      type: AppCardType.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: l10n.sureBotExplainerTitle,
            subtitle: l10n.sureBotExplainerSubtitle,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      child: Icon(Icons.smart_toy_outlined),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.assessmentExplanation,
                        style: AppTextStyles.title,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(explanation.summary, style: AppTextStyles.body),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _ScoreCard(
                        title: l10n.currentScore,
                        value: '$currentScore/100',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ScoreCard(
                        title: l10n.categories,
                        value: '${explanation.categories.length}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.ruleBasedDisclaimer, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.categoryExplanations, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.md),
          if (explanation.categories.isEmpty)
            Text(l10n.noCategoryResults, style: AppTextStyles.body)
          else
            ...explanation.categories.map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _DetailTile(
                  title: '${category.name} · ${category.score.round()}%',
                  description: category.explanation,
                  icon: Icons.analytics_outlined,
                ),
              ),
            ),
          const Divider(height: 40),
          Text(l10n.risksToReview, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.md),
          if (explanation.risks.isEmpty)
            Text(l10n.noRisksListed, style: AppTextStyles.body)
          else
            ...explanation.risks.map(
              (risk) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _DetailTile(
                  title: l10n.assessmentRisk,
                  description: risk,
                  icon: Icons.warning_amber_outlined,
                ),
              ),
            ),
          const Divider(height: 40),
          Text(l10n.recommendedNextActions, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.md),
          if (explanation.priorityActions.isEmpty)
            Text(l10n.noRecommendationsListed, style: AppTextStyles.body)
          else
            ...explanation.priorityActions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _DetailTile(
                  title: l10n.recommendedAction,
                  description: action,
                  icon: Icons.checklist_outlined,
                ),
              ),
            ),
          const Divider(height: 40),
          Text(l10n.evidenceToFollowUp, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.md),
          if (explanation.missingEvidence.isEmpty)
            Text(l10n.noMissingDocuments, style: AppTextStyles.body)
          else
            ...explanation.missingEvidence.map(
              (document) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _DetailTile(
                  title: l10n.evidenceCheck,
                  description: document,
                  icon: Icons.description_outlined,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(explanation.disclaimer, style: AppTextStyles.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _DetailTile({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.title),
                const SizedBox(height: 4),
                Text(description, style: AppTextStyles.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String title;
  final String value;

  const _ScoreCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.h2, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
