import 'package:flutter/material.dart';

import '../../core/evidence/evidence.dart';
import '../../core/evidence/evidence_completeness.dart';
import '../../core/evidence/evidence_requirement.dart';
import '../../core/evidence/evidence_requirement_catalog.dart';
import '../../core/evidence/evidence_requirement_resolver.dart';
import '../../core/evidence/evidence_type_mapper.dart';
import '../../core/localization/app_locale_controller.dart';
import '../../core/phs/phs_answer.dart';
import '../../core/phs/phs_question.dart';
import '../../core/theme/homesure_tokens.dart';
import '../../features/assessment/localization/assessment_content_translations.dart';
import '../../features/assessment/localization/assessment_translations.dart';
import '../../l10n/generated/app_localizations.dart';
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

  /// 1-based position within the active pillar; when set along with
  /// [totalPillarQuestions], renders the compact HTML `.qcard` layout.
  final int? questionNumber;
  final int? totalPillarQuestions;

  /// Selected response & handlers rendered inline inside `.qcard`.
  final PHSResponse? selectedResponse;
  final ValueChanged<PHSResponse>? onResponseSelected;
  final VoidCallback? onClearResponse;

  /// When true, wraps "Evidence you may need" in an HTML-style collapsible
  /// accordion controlled by [evidenceExpanded] and [onToggleEvidenceExpanded].
  final bool collapsibleEvidence;
  final bool evidenceExpanded;
  final VoidCallback? onToggleEvidenceExpanded;

  const QuestionCard({
    super.key,
    required this.question,
    this.suppliedEvidence = const [],
    this.onEvidenceTypeSelected,
    this.onEvidenceStatusChange,
    this.onEvidenceDelete,
    this.questionNumber,
    this.totalPillarQuestions,
    this.selectedResponse,
    this.onResponseSelected,
    this.onClearResponse,
    this.collapsibleEvidence = false,
    this.evidenceExpanded = true,
    this.onToggleEvidenceExpanded,
  });

  List<EvidenceRequirement> _resolveEvidenceRequirements() {
    const typeMapper = EvidenceTypeMapper();
    const resolver = EvidenceRequirementResolver(typeMapper: typeMapper);
    const catalog = EvidenceRequirementCatalog(resolver: resolver);
    return catalog.getForQuestion(question);
  }

  Future<void> _handleAddEvidence(BuildContext context) async {
    final evidenceType = await EvidenceActionSheet.show(context);
    if (evidenceType == null) {
      return;
    }
    onEvidenceTypeSelected?.call(evidenceType);
  }

  void _openRationale(BuildContext context) {
    final code = AppLocaleController.instance.languageCode;
    final translations = AssessmentTranslations(code);
    final content = AssessmentContentTranslations(code);

    HSInfoBottomSheet.show(
      context,
      title: translations.questionTitle(question),
      category: translations.categoryName(question.category),
      whyItMatters: content.whyItMatters(question),
      impact: content.impact(question),
      priority: question.priority?.name.toUpperCase() ?? '',
      phiGain: question.potentialPHIGain ?? 0,
      evidence: content.requiredEvidence(question),
    );
  }

  Widget _buildEvidenceCoverage(EvidenceCompleteness completeness) {
    final percentage = completeness.coveragePercentage.clamp(0, 100).toDouble();
    final isComplete = completeness.isComplete;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: HomeSureColors.midnightSand,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete
              ? HomeSureColors.statusPositiveBorder
              : HomeSureColors.champagneBronze,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Evidence coverage',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: HomeSureColors.champagneInk,
                  ),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: isComplete
                      ? HomeSureColors.statusPositiveText
                      : HomeSureColors.champagneHighlight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 6,
              backgroundColor: HomeSureColors.midnightSelected,
              color: isComplete
                  ? HomeSureColors.statusPositiveText
                  : HomeSureColors.champagneGold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isComplete
                ? '${completeness.matchedRequirements} of '
                    '${completeness.totalRequirements} evidence '
                    'requirements met'
                : '${completeness.matchedRequirements} of '
                    '${completeness.totalRequirements} evidence '
                    'requirements met · '
                    '${completeness.missingRequirements} missing',
            style: const TextStyle(
              fontSize: 11.5,
              color: HomeSureColors.slateDetailBody,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyLink(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _openRationale(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 19,
              height: 19,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: HomeSureColors.champagneGold,
                  width: 1.5,
                ),
              ),
              child: const Text(
                '?',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  color: HomeSureColors.champagneHighlight,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 7),
            const Text(
              'Learn why this matters',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: HomeSureColors.champagneHighlight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineAnswerRadios(BuildContext context) {
    final labels = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );

    Widget buildChoice({
      required String label,
      required PHSResponse value,
    }) {
      final isSelected = selectedResponse == value;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onResponseSelected == null
              ? null
              : () => onResponseSelected!(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 39),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? HomeSureColors.midnightChoiceSelected
                  : HomeSureColors.midnightInteractive,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: isSelected
                    ? HomeSureColors.champagneGold
                    : HomeSureColors.borderInput,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 15,
                  color: isSelected
                      ? HomeSureColors.champagneGold
                      : HomeSureColors.slateMuted,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? HomeSureColors.champagneHighlight
                            : HomeSureColors.champagneInk,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            buildChoice(
              label: labels?.assessmentYes ?? 'Yes',
              value: PHSResponse.yes,
            ),
            const SizedBox(width: 6),
            buildChoice(
              label: labels?.assessmentNo ?? 'No',
              value: PHSResponse.no,
            ),
            const SizedBox(width: 6),
            buildChoice(
              label: labels?.assessmentNotSure ?? "I'm Not Sure",
              value: PHSResponse.unsure,
            ),
          ],
        ),
        if (selectedResponse != null && onClearResponse != null) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onClearResponse,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: HomeSureColors.champagneHighlight,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Clear answer',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: HomeSureColors.champagneHighlight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEvidenceBody(
    BuildContext context, {
    required List<EvidenceRequirement> evidenceRequirements,
    required EvidenceCompleteness evidenceCompleteness,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (evidenceRequirements.isNotEmpty) ...[
          const Text(
            'Suggested supporting evidence',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: HomeSureColors.champagneInk,
            ),
          ),
          const SizedBox(height: 8),
          ...evidenceRequirements.map(
            (requirement) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EvidenceRequirementCard(requirement: requirement),
            ),
          ),
          _buildEvidenceCoverage(evidenceCompleteness),
        ],
        if (suppliedEvidence.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Evidence provided',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: HomeSureColors.champagneInk,
            ),
          ),
          const SizedBox(height: 8),
          ...suppliedEvidence.map(
            (evidence) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
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
        const SizedBox(height: 10),
        AddEvidenceButton(onPressed: () => _handleAddEvidence(context)),
      ],
    );
  }

  Widget _buildCollapsibleEvidence(
    BuildContext context, {
    required List<EvidenceRequirement> evidenceRequirements,
    required EvidenceCompleteness evidenceCompleteness,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: HomeSureColors.midnightDetail,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HomeSureColors.borderInput),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onToggleEvidenceExpanded,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Evidence you may need',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: HomeSureColors.champagneInk,
                      ),
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: HomeSureColors.midnightSelected,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(
                      evidenceExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: HomeSureColors.champagneHighlight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (evidenceExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: HomeSureColors.midnightDetail,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: HomeSureColors.champagneBronze),
                ),
                child: _buildEvidenceBody(
                  context,
                  evidenceRequirements: evidenceRequirements,
                  evidenceCompleteness: evidenceCompleteness,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = AppLocaleController.instance.languageCode;
    final translations = AssessmentTranslations(code);
    final categoryName = translations.categoryName(question.category);
    final questionTitle = translations.questionTitle(question);
    final isCompactHtmlCard =
        questionNumber != null && totalPillarQuestions != null;

    final evidenceRequirements = _resolveEvidenceRequirements();
    final evidenceCompleteness = EvidenceCompleteness.calculate(
      requirements: evidenceRequirements,
      evidence: suppliedEvidence,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompactHtmlCard ? 14 : 18),
      decoration: BoxDecoration(
        color: HomeSureColors.midnightCard,
        borderRadius: BorderRadius.circular(isCompactHtmlCard ? 16 : 18),
        border: Border.all(color: HomeSureColors.borderSlate),
        boxShadow: HomeSureShadows.cardSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCompactHtmlCard)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                'QUESTION $questionNumber OF $totalPillarQuestions · $categoryName',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: HomeSureColors.champagneHighlight,
                  letterSpacing: 0.3,
                ),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: HomeSureColors.midnightInteractive,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: HomeSureColors.champagneBronze),
              ),
              child: Text(
                categoryName,
                style: const TextStyle(
                  color: HomeSureColors.champagneHighlight,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            questionTitle,
            style: TextStyle(
              fontSize: isCompactHtmlCard ? 14.5 : 21,
              fontWeight: isCompactHtmlCard ? FontWeight.w700 : FontWeight.w800,
              height: isCompactHtmlCard ? 1.38 : 1.3,
              color: HomeSureColors.champagneInk,
            ),
          ),
          if (!isCompactHtmlCard) ...[
            const SizedBox(height: 10),
            Text(
              AssessmentContentTranslations(code).helpText(question),
              style: const TextStyle(
                fontSize: 14,
                color: HomeSureColors.slateDetailBody,
                height: 1.5,
              ),
            ),
          ],
          if (question.whyItMatters != null) ...[
            SizedBox(height: isCompactHtmlCard ? 8 : 14),
            _buildWhyLink(context),
          ],
          if (onResponseSelected != null) _buildInlineAnswerRadios(context),
          if (collapsibleEvidence)
            _buildCollapsibleEvidence(
              context,
              evidenceRequirements: evidenceRequirements,
              evidenceCompleteness: evidenceCompleteness,
            )
          else ...[
            if (evidenceRequirements.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Evidence you may need',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: HomeSureColors.champagneInk,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'These items can help support your assessment response.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: HomeSureColors.slateMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
              ...evidenceRequirements.map(
                (requirement) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: EvidenceRequirementCard(requirement: requirement),
                ),
              ),
              const SizedBox(height: 6),
              _buildEvidenceCoverage(evidenceCompleteness),
            ],
            if (suppliedEvidence.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Evidence provided',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: HomeSureColors.champagneInk,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Evidence currently associated with this question.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: HomeSureColors.slateMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
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
            const SizedBox(height: 14),
            AddEvidenceButton(onPressed: () => _handleAddEvidence(context)),
          ],
        ],
      ),
    );
  }
}
