import 'package:flutter/material.dart';

import '../../core/theme/homesure_tokens.dart';
import '../../features/property/models/krera_project_models.dart';

/// Filter trigger button + active filter badges that open a multi-select
/// Bengaluru Urban taluk modal with staged selection and Apply confirmation.
class BengaluruTalukFilterBar extends StatelessWidget {
  final Set<BengaluruTalukFilter> selectedTaluks;
  final ValueChanged<Set<BengaluruTalukFilter>> onChanged;
  final String keyPrefix;

  const BengaluruTalukFilterBar({
    super.key,
    required this.selectedTaluks,
    required this.onChanged,
    this.keyPrefix = 'locality-filter',
  });

  Set<BengaluruTalukFilter> get _activeTaluks => selectedTaluks
      .where((f) => f != BengaluruTalukFilter.all)
      .toSet();

  Future<void> _openFilterModal(BuildContext context) async {
    final result = await showModalBottomSheet<Set<BengaluruTalukFilter>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BengaluruTalukFilterModalSheet(
        initialTaluks: _activeTaluks,
        keyPrefix: keyPrefix,
      ),
    );

    if (result == null) return;
    final normalized =
        result.where((f) => f != BengaluruTalukFilter.all).toSet();
    final current = _activeTaluks;
    if (normalized.length != current.length ||
        !normalized.containsAll(current)) {
      onChanged(Set<BengaluruTalukFilter>.unmodifiable(normalized));
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTaluks = _activeTaluks;
    final orderedActive = BengaluruTalukFilter.values
        .where((f) => f != BengaluruTalukFilter.all && activeTaluks.contains(f))
        .toList();
    final hasActiveFilter = orderedActive.isNotEmpty;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          key: ValueKey<String>('$keyPrefix-button'),
          onPressed: () => _openFilterModal(context),
          style: OutlinedButton.styleFrom(
            backgroundColor: hasActiveFilter
                ? HomeSureColors.midnightSelected
                : HomeSureColors.midnightInteractive,
            foregroundColor: HomeSureColors.champagneHighlight,
            side: BorderSide(
              color: hasActiveFilter
                  ? HomeSureColors.champagneGold
                  : HomeSureColors.borderSlate,
              width: hasActiveFilter ? 1.4 : 1,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HomeSureRadius.pill),
            ),
          ),
          icon: const Icon(Icons.tune_rounded, size: 16),
          label: Text(
            hasActiveFilter ? 'Filters (${orderedActive.length})' : 'Filters',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final taluk in orderedActive)
          Container(
            padding: const EdgeInsets.only(
              left: 10,
              right: 4,
              top: 4,
              bottom: 4,
            ),
            decoration: BoxDecoration(
              color: HomeSureColors.midnightSelected,
              borderRadius: BorderRadius.circular(HomeSureRadius.pill),
              border: Border.all(color: HomeSureColors.champagneBronze),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Taluk: ${taluk.label}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: HomeSureColors.champagneHighlight,
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  key: ValueKey<String>('$keyPrefix-clear-${taluk.name}'),
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    final next = Set<BengaluruTalukFilter>.from(activeTaluks)
                      ..remove(taluk);
                    onChanged(Set<BengaluruTalukFilter>.unmodifiable(next));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: HomeSureColors.champagneHighlight,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BengaluruTalukFilterModalSheet extends StatefulWidget {
  final Set<BengaluruTalukFilter> initialTaluks;
  final String keyPrefix;

  const _BengaluruTalukFilterModalSheet({
    required this.initialTaluks,
    required this.keyPrefix,
  });

  @override
  State<_BengaluruTalukFilterModalSheet> createState() =>
      _BengaluruTalukFilterModalSheetState();
}

class _BengaluruTalukFilterModalSheetState
    extends State<_BengaluruTalukFilterModalSheet> {
  late final Set<BengaluruTalukFilter> _pendingTaluks =
      Set<BengaluruTalukFilter>.from(
        widget.initialTaluks.where((f) => f != BengaluruTalukFilter.all),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: HomeSureColors.midnightCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: HomeSureColors.borderSlate),
          left: BorderSide(color: HomeSureColors.borderSlate),
          right: BorderSide(color: HomeSureColors.borderSlate),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: HomeSureColors.borderSlate,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filter Properties',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: HomeSureColors.champagneInk,
                      ),
                    ),
                  ),
                  TextButton(
                    key: ValueKey<String>('${widget.keyPrefix}-reset'),
                    onPressed: () {
                      setState(() {
                        _pendingTaluks.clear();
                      });
                    },
                    child: const Text('Reset'),
                  ),
                  IconButton(
                    tooltip: 'Close filters',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: HomeSureColors.slateMuted,
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              const Text(
                'TALUK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                  color: HomeSureColors.champagneHighlight,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Bengaluru Urban Taluk',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: HomeSureColors.champagneInk,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select one or more taluks below and tap Apply.',
                style: TextStyle(
                  fontSize: 12,
                  color: HomeSureColors.slateMuted,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: BengaluruTalukFilter.values.map((filter) {
                  final isAll = filter == BengaluruTalukFilter.all;
                  final isSelected = isAll
                      ? _pendingTaluks.isEmpty
                      : _pendingTaluks.contains(filter);
                  return ChoiceChip(
                    key: ValueKey<String>('${widget.keyPrefix}-${filter.name}'),
                    label: Text(filter.label),
                    selected: isSelected,
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() {
                        if (isAll) {
                          _pendingTaluks.clear();
                        } else if (_pendingTaluks.contains(filter)) {
                          _pendingTaluks.remove(filter);
                        } else {
                          _pendingTaluks.add(filter);
                        }
                      });
                    },
                    selectedColor: HomeSureColors.midnightSelected,
                    backgroundColor: HomeSureColors.midnightInteractive,
                    side: BorderSide(
                      color: isSelected
                          ? HomeSureColors.champagneGold
                          : HomeSureColors.borderInput,
                      width: isSelected ? 1.5 : 1,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? HomeSureColors.champagneHighlight
                          : HomeSureColors.champagneInk,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(HomeSureRadius.pill),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: ValueKey<String>('${widget.keyPrefix}-apply'),
                  onPressed: () => Navigator.of(context).pop(
                    Set<BengaluruTalukFilter>.unmodifiable(_pendingTaluks),
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
