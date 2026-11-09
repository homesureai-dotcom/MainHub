import 'package:flutter/material.dart';

import '../../features/assessment/localization/assessment_translations.dart';
import '../../core/localization/app_locale_controller.dart';
import '../../core/phs/phs_categories.dart';
import '../../core/phs/phs_category_progress.dart';
import '../../core/phs/phs_question.dart';

class ClassicCategoryAccordion extends StatefulWidget {
  const ClassicCategoryAccordion({
    super.key,
    required this.questions,
    required this.progressFor,
    required this.isAnswered,
    required this.currentQuestionId,
    required this.onQuestionSelected,
  });

  final List<PHSQuestion> questions;
  final PHSCategoryProgress? Function(PHSCategory category) progressFor;
  final bool Function(String questionId) isAnswered;
  final String currentQuestionId;
  final ValueChanged<PHSQuestion> onQuestionSelected;

  @override
  State<ClassicCategoryAccordion> createState() =>
      _ClassicCategoryAccordionState();
}

class _ClassicCategoryAccordionState extends State<ClassicCategoryAccordion> {
  PHSCategory? _selectedCategory;

  PHSCategory? _categoryForQuestion(String id) {
    for (final question in widget.questions) {
      if (question.id == id) return question.category;
    }
    return null;
  }

  List<PHSCategory> get _availableCategories {
    return PHSCategory.values
        .where(
          (category) =>
              widget.questions.any((question) => question.category == category),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    final available = _availableCategories;
    _selectedCategory =
        _categoryForQuestion(widget.currentQuestionId) ??
        (available.isNotEmpty ? available.first : null);
  }

  @override
  void didUpdateWidget(covariant ClassicCategoryAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentCategory = _categoryForQuestion(widget.currentQuestionId);
    if (currentCategory != null && currentCategory != _selectedCategory) {
      _selectedCategory = currentCategory;
    }
  }

  @override
  Widget build(BuildContext context) {
    final translations = AssessmentTranslations(
      AppLocaleController.instance.languageCode,
    );
    final categories = _availableCategories;
    final selected = categories.contains(_selectedCategory)
        ? _selectedCategory
        : (categories.isNotEmpty ? categories.first : null);

    final selectedQuestions = selected == null
        ? <PHSQuestion>[]
        : widget.questions
              .where((question) => question.category == selected)
              .toList();

    final selectedProgress = selected == null
        ? null
        : widget.progressFor(selected);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: .45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  'Assessment category',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                if (selected != null)
                  Text(
                    '${selectedProgress?.completionPercentage ?? 0}% complete',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<PHSCategory>(
              key: const ValueKey('assessment-category-dropdown'),
              initialValue: selected,
              isExpanded: true,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: categories.map((category) {
                final categoryQuestions = widget.questions
                    .where((question) => question.category == category)
                    .toList();
                final answered = categoryQuestions
                    .where((question) => widget.isAnswered(question.id))
                    .length;

                return DropdownMenuItem<PHSCategory>(
                  key: ValueKey('classic-category-option-${category.name}'),
                  value: category,
                  child: Text(
                    '${translations.categoryName(category)}  $answered/${categoryQuestions.length}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (category) {
                if (category == null) return;
                setState(() => _selectedCategory = category);
              },
            ),
            if (selectedQuestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(selectedQuestions.length, (index) {
                  final question = selectedQuestions[index];
                  final isCurrent = question.id == widget.currentQuestionId;
                  final answered = widget.isAnswered(question.id);

                  return ActionChip(
                    key: ValueKey('classic-question-${question.id}'),
                    avatar: Icon(
                      answered ? Icons.check_circle : Icons.circle_outlined,
                      size: 15,
                      color: isCurrent
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                    ),
                    label: Text('Q${index + 1}'),
                    onPressed: () => widget.onQuestionSelected(question),
                    backgroundColor: isCurrent
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    labelStyle: TextStyle(
                      color: isCurrent
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }),
              ),
              const SizedBox(height: 2),
              Text(
                selectedQuestions.any(
                      (question) => question.id == widget.currentQuestionId,
                    )
                    ? translations.questionTitle(
                        selectedQuestions.firstWhere(
                          (question) => question.id == widget.currentQuestionId,
                        ),
                      )
                    : 'Select a question to open it',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
