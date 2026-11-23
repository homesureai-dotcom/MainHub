import 'package:flutter/material.dart';

import '../../core/theme/homesure_components.dart';
import '../../core/theme/homesure_tokens.dart';
import '../../features/property/models/krera_project_models.dart';
import '../../features/property/models/property.dart' as feature;
import '../../features/property/models/property_adapter.dart';
import '../../features/property/services/property_repository.dart';
import '../../features/property/state/property_state.dart';
import '../../models/property.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/property/property_hero_card.dart';
import '../assessment/surebot_screen.dart';

enum _PropertyDetailSection {
  overview('Overview'),
  legal('Legal'),
  development('Development'),
  documents('Documents'),
  issues('Issues');

  final String label;
  const _PropertyDetailSection(this.label);
}

class PropertyDetailsScreen extends StatefulWidget {
  final Property property;
  final PropertyCatalogueGateway? catalogueGateway;

  const PropertyDetailsScreen({
    super.key,
    required this.property,
    this.catalogueGateway,
  });

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  final PropertyState _propertyState = PropertyState.instance;
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _overviewKey = GlobalKey();
  final GlobalKey _legalKey = GlobalKey();
  final GlobalKey _developmentKey = GlobalKey();
  final GlobalKey _documentsKey = GlobalKey();
  final GlobalKey _issuesKey = GlobalKey();

  late Property _property;
  ProjectRegulatoryDetailBundle? _detailBundle;
  List<ProjectUnitRecord> _projectUnits = const [];
  ProjectUnitRecord? _buyerSelectedUnit;
  bool _isLoadingDetailBundle = false;
  String? _detailBundleError;
  _PropertyDetailSection _activeSection = _PropertyDetailSection.overview;
  bool _showAllDocuments = false;
  bool _showAllComplaints = false;

  PropertyCatalogueGateway get _catalogueGateway =>
      widget.catalogueGateway ?? PropertyRepository.instance;

  bool get _isCatalogueSummary => _property.isCatalogueSummary;

  @override
  void initState() {
    super.initState();
    _property = widget.property;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _selectCanonicalProperty();
      }
    });
    _loadProjectDetailAndUnits();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectDetailAndUnits() async {
    if (_property.id.isEmpty) return;

    setState(() {
      _isLoadingDetailBundle = true;
      _detailBundleError = null;
    });

    try {
      final hydrated = await _catalogueGateway.fetchProjectById(_property.id);
      final effective = hydrated ?? _property;
      final bundle = effective.isCatalogueSummary
          ? null
          : await _catalogueGateway.fetchProjectRegulatoryDetail(_property.id);
      final units = effective.isCatalogueSummary
          ? const <ProjectUnitRecord>[]
          : await _catalogueGateway.fetchProjectUnits(_property.id);

      if (!mounted) return;
      setState(() {
        if (hydrated != null) {
          _property = hydrated;
        }
        _detailBundle = bundle;
        _projectUnits = units;
        if (_buyerSelectedUnit == null && units.isNotEmpty) {
          _buyerSelectedUnit = units.first;
        }
        _isLoadingDetailBundle = false;
      });
      if (hydrated != null) {
        _selectCanonicalProperty();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingDetailBundle = false;
        _detailBundleError = 'Unable to load extended K-RERA details: $error';
      });
    }
  }

  void _jumpToSection(_PropertyDetailSection section) {
    setState(() {
      _activeSection = section;
    });
    final key = switch (section) {
      _PropertyDetailSection.overview => _overviewKey,
      _PropertyDetailSection.legal => _legalKey,
      _PropertyDetailSection.development => _developmentKey,
      _PropertyDetailSection.documents => _documentsKey,
      _PropertyDetailSection.issues => _issuesKey,
    };
    final targetContext = key.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _selectCanonicalProperty() {
    PropertyRepository.instance.selectLegacyProperty(_property);
    feature.Property? canonicalProperty;

    for (final candidate in _propertyState.properties) {
      if (candidate.id == _property.id || candidate.name == _property.name) {
        canonicalProperty = candidate;
        break;
      }
    }

    if (canonicalProperty != null) {
      _propertyState.selectProperty(
        canonicalProperty.copyWith(selectedUnit: _buyerSelectedUnit),
      );
    } else {
      _propertyState.selectProperty(
        PropertyAdapter.fromLegacy(
          _property,
        ).copyWith(selectedUnit: _buyerSelectedUnit),
      );
    }
  }

  Future<void> _promptBuyerUnitSelection() async {
    final result = await showDialog<ProjectUnitRecord>(
      context: context,
      builder: (_) => _BuyerUnitDialog(
        projectId: _property.id,
        availableTowers: _detailBundle?.towers.isNotEmpty == true
            ? _detailBundle!.towers
            : _property.towersSummary,
        availableConfigs:
            _detailBundle?.inventoryConfigurations.isNotEmpty == true
                ? _detailBundle!.inventoryConfigurations
                : _property.inventoryConfigurations,
        initialUnit: _buyerSelectedUnit,
        gateway: _catalogueGateway,
      ),
    );

    if (!mounted || result == null) return;
    setState(() {
      _buyerSelectedUnit = result;
      _projectUnits = [
        result,
        ..._projectUnits.where((u) => u.unitId != result.unitId),
      ];
    });
    _selectCanonicalProperty();
  }

  HomeSureBadgeTone _regulatoryStatusTone(String status) {
    final normalized = status.trim().toUpperCase();
    if (normalized.contains('APPROVED') || normalized.contains('ACTIVE')) {
      return HomeSureBadgeTone.positive;
    }
    if (normalized.contains('REVOKED') ||
        normalized.contains('EXPIRED') ||
        normalized.contains('REJECTED')) {
      return HomeSureBadgeTone.critical;
    }
    return HomeSureBadgeTone.warning;
  }

  Widget _buildScoreTile(String title, int score, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HomeSureColors.surfaceWhite,
        borderRadius: BorderRadius.circular(HomeSureRadius.md),
        border: Border.all(color: HomeSureColors.borderDivider),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(HomeSureRadius.xs),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: HomeSureTypography.bodyMedium),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(HomeSureRadius.pill),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    minHeight: 6,
                    backgroundColor: HomeSureColors.surfaceSubtle,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '$score%',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyIdentityHeader() {
    final locationParts = [
      if (_property.locality.trim().isNotEmpty) _property.locality.trim(),
      if (_property.city.trim().isNotEmpty &&
          _property.city.trim().toLowerCase() !=
              _property.locality.trim().toLowerCase())
        _property.city.trim(),
    ];
    final locationText =
        locationParts.isEmpty ? 'Bengaluru' : locationParts.join(', ');
    final statusLabel = _property.regulatoryStatus.trim().isNotEmpty
        ? _property.regulatoryStatus.trim()
        : 'K-RERA Registered';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.circular(HomeSureRadius.xl),
        border: Border.all(color: HomeSureColors.champagneBronze),
        boxShadow: HomeSureShadows.cardElevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              HomeSureStatusBadge(
                label: _isCatalogueSummary
                    ? 'K-RERA Catalogue Summary'
                    : 'Deep K-RERA Dossier',
                tone: _isCatalogueSummary
                    ? HomeSureBadgeTone.warning
                    : HomeSureBadgeTone.teal,
                icon: _isCatalogueSummary
                    ? Icons.summarize_outlined
                    : Icons.verified_outlined,
              ),
              HomeSureStatusBadge(
                label: statusLabel,
                tone: _regulatoryStatusTone(statusLabel),
              ),
              if (_property.projectType.isNotEmpty)
                HomeSureStatusBadge(
                  label: _property.projectType,
                  tone: HomeSureBadgeTone.neutral,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _property.name,
            style: const TextStyle(
              color: HomeSureColors.champagneInk,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_property.builder} • $locationText',
            style: const TextStyle(
              color: HomeSureColors.slateDetailBody,
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
          if (_property.reraNumber.isNotEmpty ||
              _property.acknowledgementNumber.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HomeSureColors.midnightCard.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(HomeSureRadius.md),
                border: Border.all(color: HomeSureColors.borderSlate),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_property.reraNumber.isNotEmpty) ...[
                    const Text(
                      'K-RERA REGISTRATION NUMBER',
                      style: TextStyle(
                        color: HomeSureColors.champagneHighlight,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _property.reraNumber,
                      style: const TextStyle(
                        color: HomeSureColors.champagneInk,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                  if (_property.acknowledgementNumber.isNotEmpty) ...[
                    if (_property.reraNumber.isNotEmpty)
                      const SizedBox(height: 8),
                    const Text(
                      'ACKNOWLEDGEMENT NUMBER',
                      style: TextStyle(
                        color: HomeSureColors.champagneHighlight,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _property.acknowledgementNumber,
                      style: const TextStyle(
                        color: HomeSureColors.slateDetailBody,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCatalogueSummaryNotice() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HomeSureColors.statusWarningBg,
        borderRadius: BorderRadius.circular(HomeSureRadius.lg),
        border: Border.all(color: HomeSureColors.statusWarningBorder),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.summarize_outlined,
            color: HomeSureColors.statusWarningText,
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catalogue Summary Only — Detailed Regulatory Extraction Pending',
                  style: TextStyle(
                    color: HomeSureColors.statusWarningText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'This listing reflects core K-RERA catalogue registration '
                  'metadata (project title, builder, registration number, '
                  'taluk, and approval/completion dates). Full portal tabs, '
                  'uploaded documents, complaint filings, tower/unit details, '
                  'and a complete regulatory analysis or Property Health '
                  'assessment are not yet available for this project.',
                  style: TextStyle(
                    color: HomeSureColors.textPrimary,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntelligenceSummaryGrid() {
    if (_isCatalogueSummary) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HomeSureColors.surfaceWhite,
          borderRadius: BorderRadius.circular(HomeSureRadius.lg),
          border: Border.all(color: HomeSureColors.borderDivider),
          boxShadow: HomeSureShadows.cardSubtle,
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeSureSectionHeader(
              title: 'Catalogue Registration Summary',
              subtitle:
                  'Basic K-RERA directory fields indexed; deep portal dossier pending extraction.',
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: HomeSureMetricTile(
                    label: 'Portal Sections',
                    value: 'Pending',
                    sublabel: 'Detailed extraction pending',
                    icon: Icons.schedule_outlined,
                    accentColor: HomeSureColors.statusWarningText,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: HomeSureMetricTile(
                    label: 'Filing Documents',
                    value: 'Not Extracted',
                    sublabel: 'Documents not yet extracted',
                    icon: Icons.description_outlined,
                    accentColor: HomeSureColors.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: HomeSureMetricTile(
                    label: 'RERA Complaints',
                    value: 'Not Extracted',
                    sublabel: 'Complaints not yet verified',
                    icon: Icons.gavel_outlined,
                    accentColor: HomeSureColors.textSecondary,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: HomeSureMetricTile(
                    label: 'Record Depth',
                    value: 'Summary',
                    sublabel: 'Basic catalogue listing',
                    icon: Icons.summarize_outlined,
                    accentColor: HomeSureColors.statusWarningText,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final docs = _detailBundle?.documents ?? const [];
    final complaints = _detailBundle?.complaints ?? const [];
    final docCount =
        _property.regulatoryCounts['total_documents'] ?? docs.length;
    final complaintCount =
        _property.regulatoryCounts['total_complaints'] ?? complaints.length;

    final tabs = _property.tabObservations.values.toList();
    final availableTabsCount = tabs
        .where((t) => t.observationState == ObservationState.presentWithData)
        .length;
    final attentionTabsCount = tabs
        .where((t) => t.observationState != ObservationState.presentWithData)
        .length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HomeSureColors.surfaceWhite,
        borderRadius: BorderRadius.circular(HomeSureRadius.lg),
        border: Border.all(color: HomeSureColors.borderDivider),
        boxShadow: HomeSureShadows.cardSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeSureSectionHeader(
            title: 'Regulatory Intelligence Summary',
            subtitle:
                'Consolidated K-RERA snapshot across filings, documents, and complaints.',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: HomeSureMetricTile(
                  label: 'Portal Sections',
                  value: tabs.isEmpty
                      ? 'Verified'
                      : '$availableTabsCount / ${tabs.length}',
                  sublabel: 'Available in K-RERA',
                  icon: Icons.fact_check_outlined,
                  accentColor: HomeSureColors.statusPositiveText,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: HomeSureMetricTile(
                  label: 'Filing Documents',
                  value: '$docCount',
                  sublabel: 'Uploaded records',
                  icon: Icons.description_outlined,
                  accentColor: HomeSureColors.champagneHighlight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: HomeSureMetricTile(
                  label: 'RERA Complaints',
                  value: '$complaintCount',
                  sublabel: complaintCount == 0
                      ? 'None registered'
                      : 'Requires review',
                  icon: Icons.gavel_outlined,
                  accentColor: complaintCount == 0
                      ? HomeSureColors.champagneGold
                      : HomeSureColors.statusWarningText,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: HomeSureMetricTile(
                  label: 'Empty / Unshown Tabs',
                  value: '$attentionTabsCount',
                  sublabel: 'Portal gaps noted',
                  icon: Icons.info_outline_rounded,
                  accentColor: attentionTabsCount == 0
                      ? HomeSureColors.statusPositiveText
                      : HomeSureColors.statusWarningText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionNavigationBar() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: HomeSureColors.midnightCard,
        borderRadius: BorderRadius.circular(HomeSureRadius.lg),
        border: Border.all(color: HomeSureColors.borderSlate),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _PropertyDetailSection.values.map((section) {
          final selected = _activeSection == section;
          return ChoiceChip(
            key: ValueKey<String>('property-section-${section.name}'),
            label: Text(section.label),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) => _jumpToSection(section),
            selectedColor: HomeSureColors.midnightSelected,
            backgroundColor: HomeSureColors.midnightDetail,
            side: BorderSide(
              color: selected
                  ? HomeSureColors.champagneGold
                  : HomeSureColors.borderSlate,
              width: selected ? 1.4 : 1,
            ),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected
                  ? HomeSureColors.champagneHighlight
                  : HomeSureColors.slateMuted,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HomeSureRadius.pill),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Resolves the first available [RegulatoryMetric] from a list of canonical
  /// and legacy alias keys without emitting duplicate rows.
  RegulatoryMetric? _resolveMetric(List<String> candidateKeys) {
    for (final key in candidateKeys) {
      final metric = _property.summaryMetrics[key];
      if (metric != null) return metric;
    }
    return null;
  }

  Widget _buildMetricCardsCard({
    required String title,
    required String subtitle,
    required List<({List<String> keys, String label, String? fallback})> specs,
  }) {
    final rows = <Widget>[];
    for (final spec in specs) {
      final metric = _resolveMetric(spec.keys);
      final fallback = spec.fallback?.trim() ?? '';
      if (metric == null && fallback.isEmpty) continue;

      final bool isPresent = metric == null
          ? fallback.isNotEmpty
          : metric.observationState == ObservationState.presentWithData;
      final String displayValue = metric != null ? metric.formattedValue : fallback;

      rows.add(
        Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: HomeSureColors.borderDivider),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  spec.label,
                  style: HomeSureTypography.bodySecondary.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 6,
                child: isPresent
                    ? Text(
                        displayValue,
                        textAlign: TextAlign.right,
                        style: HomeSureTypography.bodyMedium,
                      )
                    : Align(
                        alignment: Alignment.centerRight,
                        child: HomeSureObservationBadge(
                          state: metric!.observationState,
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HomeSureColors.surfaceWhite,
        borderRadius: BorderRadius.circular(HomeSureRadius.lg),
        border: Border.all(color: HomeSureColors.borderDivider),
        boxShadow: HomeSureShadows.cardSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSureSectionHeader(title: title, subtitle: subtitle),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildOverviewDetailsSection() {
    return _buildMetricCardsCard(
      title: 'Project Overview',
      subtitle: 'Schedule, promoter entity, and site location summary.',
      specs: [
        (keys: const ['district'], label: 'District', fallback: null),
        (
          keys: const ['taluk'],
          label: 'Taluk / Locality',
          fallback: _property.locality.trim().isNotEmpty
              ? _property.locality.trim()
              : null,
        ),
        (
          keys: const ['project_start_date'],
          label: 'Project Start Date',
          fallback: _property.projectStartDate.trim().isNotEmpty
              ? _property.projectStartDate.trim()
              : null,
        ),
        (
          keys: const ['proposed_completion_date'],
          label: 'Proposed Completion Date',
          fallback: _property.proposedCompletionDate.trim().isNotEmpty
              ? _property.proposedCompletionDate.trim()
              : null,
        ),
        (
          keys: const ['project_address'],
          label: 'Registered Site Address',
          fallback: null,
        ),
        (
          keys: const ['project_description'],
          label: 'Project Description',
          fallback: null,
        ),
      ],
    );
  }

  Widget _buildLegalSection() {
    final bundleSections = _detailBundle?.sections ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetricCardsCard(
          title: 'Legal & Approvals',
          subtitle:
              'Statutory clearances, escrow banking, cost structure, and litigation disclosures.',
          specs: [
            if (_property.reraNumber.isEmpty)
              (
                keys: const ['registration_number'],
                label: 'K-RERA Registration No.',
                fallback: null,
              ),
            if (_property.acknowledgementNumber.isEmpty)
              (
                keys: const ['ack_number'],
                label: 'Acknowledgement No.',
                fallback: null,
              ),
            (
              keys: const ['regulatory_status'],
              label: 'K-RERA Portal Status',
              fallback: null,
            ),
            (
              keys: const ['registration_date'],
              label: 'Registration Approved On',
              fallback: null,
            ),
            (
              keys: const ['approving_authority'],
              label: 'Plan Approving Authority',
              fallback: null,
            ),
            (
              keys: const ['approved_plan_number'],
              label: 'Approved Plan Number',
              fallback: null,
            ),
            (
              keys: const ['plan_approval_date', 'plan_approval_date_iso'],
              label: 'Plan Approval Date',
              fallback: null,
            ),
            (
              keys: const ['land_litigation_flag'],
              label: 'Land Litigation Status',
              fallback: null,
            ),
            (
              keys: const [
                'total_project_cost_inr',
                'estimated_cost_inr',
                'estimated_cost_crore',
              ],
              label: 'Total Project Cost',
              fallback: null,
            ),
            (
              keys: const ['cost_of_land_inr'],
              label: 'Land Cost (INR)',
              fallback: null,
            ),
            (
              keys: const ['cost_of_construction_inr'],
              label: 'Construction Cost (INR)',
              fallback: null,
            ),
            (
              keys: const ['escrow_bank_name'],
              label: 'RERA Escrow Bank',
              fallback: null,
            ),
            (
              keys: const ['escrow_bank_branch'],
              label: 'Escrow Bank Branch',
              fallback: null,
            ),
            (
              keys: const ['escrow_ifsc_code'],
              label: 'Escrow IFSC Code',
              fallback: null,
            ),
          ],
        ),
        if (_property.tabObservations.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: HomeSureColors.surfaceWhite,
              borderRadius: BorderRadius.circular(HomeSureRadius.lg),
              border: Border.all(color: HomeSureColors.borderDivider),
              boxShadow: HomeSureShadows.cardSubtle,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HomeSureSectionHeader(
                  title: 'K-RERA Portal Tab Disclosures',
                  subtitle:
                      'Direct availability status of every official K-RERA section.',
                ),
                const SizedBox(height: 10),
                ..._property.tabObservations.values.map((tab) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            tab.label,
                            style: HomeSureTypography.bodyPrimary.copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        HomeSureObservationBadge(state: tab.observationState),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        if (bundleSections.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: HomeSureColors.surfaceWhite,
              borderRadius: BorderRadius.circular(HomeSureRadius.lg),
              border: Border.all(color: HomeSureColors.borderDivider),
              boxShadow: HomeSureShadows.cardSubtle,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeSureSectionHeader(
                  title: 'Detailed K-RERA Portal Filings',
                  subtitle:
                      '${bundleSections.length} structured regulatory sections from K-RERA.',
                ),
                const SizedBox(height: 8),
                ...bundleSections.take(12).map((sec) {
                  final subtitleParts = <String>[
                    sec.tabLabel,
                    if (sec.fieldCount > 0) '${sec.fieldCount} fields',
                    if (sec.tableRowCount > 0) '${sec.tableRowCount} rows',
                    if (sec.documentCount > 0) '${sec.documentCount} docs',
                  ];
                  return Material(
                    color: Colors.transparent,
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      title: Text(
                        sec.sectionLabel.isNotEmpty
                            ? sec.sectionLabel
                            : sec.tabLabel,
                        style: HomeSureTypography.bodyMedium.copyWith(
                          fontSize: 13.5,
                        ),
                      ),
                      subtitle: Text(
                        subtitleParts.join(' • '),
                        style: HomeSureTypography.caption,
                      ),
                      trailing: HomeSureObservationBadge(
                        state: sec.observationState,
                        showIcon: false,
                      ),
                      children: [
                        if (sec.fields.isEmpty && sec.emptyMessage != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              sec.emptyMessage!,
                              style: HomeSureTypography.caption,
                            ),
                          )
                        else
                          ...sec.fields.take(15).map((f) {
                            final keyLabel =
                                (f['raw_label'] ?? f['label'] ?? f['key'] ?? '')
                                    .toString();
                            final valLabel = (f['value'] ?? '').toString();
                            if (keyLabel.isEmpty && valLabel.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Text(
                                      keyLabel,
                                      style: HomeSureTypography.caption,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 6,
                                    child: Text(
                                      valLabel.isEmpty ? '—' : valLabel,
                                      textAlign: TextAlign.right,
                                      style: HomeSureTypography.bodySecondary
                                          .copyWith(
                                        color: HomeSureColors.champagneInk,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDevelopmentSection() {
    if (_isCatalogueSummary) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: HomeSureColors.surfaceWhite,
          borderRadius: BorderRadius.circular(HomeSureRadius.lg),
          border: Border.all(color: HomeSureColors.borderDivider),
          boxShadow: HomeSureShadows.cardSubtle,
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeSureSectionHeader(
              title: 'Development, Tower & Land Schedules',
              subtitle: 'Not yet extracted for this catalogue-summary listing.',
            ),
            SizedBox(height: 8),
            Text(
              'Detailed tower, land area, and apartment inventory disclosures '
              'have not been extracted from the K-RERA project modal yet.',
              style: HomeSureTypography.bodySecondary,
            ),
          ],
        ),
      );
    }

    final towers = _detailBundle?.towers.isNotEmpty == true
        ? _detailBundle!.towers
        : _property.towersSummary;
    final configs = _detailBundle?.inventoryConfigurations.isNotEmpty == true
        ? _detailBundle!.inventoryConfigurations
        : _property.inventoryConfigurations;
    final hierarchy = _property.unitHierarchyStatus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetricCardsCard(
          title: 'Development & Land Specifications',
          subtitle: 'Land area, built footprint, units, towers, and parking.',
          specs: const [
            (keys: ['project_sub_type'], label: 'Project Sub-Type', fallback: null),
            (
              keys: ['total_land_area_sq_m', 'total_area_of_land_sqm'],
              label: 'Total Land Area (Sq.M)',
              fallback: null,
            ),
            (
              keys: ['total_open_area_sq_m', 'total_open_area_sqm'],
              label: 'Total Open Area (Sq.M)',
              fallback: null,
            ),
            (
              keys: ['total_covered_area_sq_m', 'total_covered_area_sqm'],
              label: 'Total Covered Area (Sq.M)',
              fallback: null,
            ),
            (
              keys: ['total_carpet_area_sq_m'],
              label: 'Total Carpet Area (Sq.M)',
              fallback: null,
            ),
            (
              keys: ['carpet_area_range_sqm'],
              label: 'Carpet Area Range',
              fallback: null,
            ),
            (
              keys: [
                'total_units_inventories',
                'number_of_inventories',
                'total_inventory_units',
              ],
              label: 'Total Inventory / Units',
              fallback: null,
            ),
            (
              keys: [
                'total_towers_blocks',
                'no_of_towers',
                'number_of_towers',
              ],
              label: 'Towers / Blocks',
              fallback: null,
            ),
            (
              keys: ['covered_parking_count'],
              label: 'Covered Parking Spaces',
              fallback: null,
            ),
            (
              keys: ['open_parking_count'],
              label: 'Open Parking Spaces',
              fallback: null,
            ),
            (
              keys: ['parking_spaces', 'total_parking'],
              label: 'Total Parking Spaces',
              fallback: null,
            ),
            (keys: ['latitude'], label: 'Latitude', fallback: null),
            (keys: ['longitude'], label: 'Longitude', fallback: null),
            (
              keys: ['coordinate_source'],
              label: 'Coordinate Source',
              fallback: null,
            ),
          ],
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: HomeSureColors.surfaceWhite,
            borderRadius: BorderRadius.circular(HomeSureRadius.lg),
            border: Border.all(color: HomeSureColors.borderDivider),
            boxShadow: HomeSureShadows.cardSubtle,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Apartment / Unit & Tower Hierarchy',
                      style: HomeSureTypography.sectionTitle,
                    ),
                  ),
                  HomeSureObservationBadge(
                    state: hierarchy.inventoryConfigsState,
                    showIcon: false,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Towers in K-RERA: ${hierarchy.towersState.displayLabel} (${towers.length}) • '
                'Inventory Types: ${hierarchy.inventoryConfigsState.displayLabel} (${configs.length})',
                style: HomeSureTypography.caption,
              ),
              if (towers.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: towers.take(12).map((tower) {
                    final details = [
                      if (tower.totalFloors != null) '${tower.totalFloors}F',
                      if (tower.totalUnits != null) '${tower.totalUnits}U',
                    ].join(' · ');
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: HomeSureColors.midnightInteractive,
                        borderRadius: BorderRadius.circular(HomeSureRadius.sm),
                        border: Border.all(color: HomeSureColors.borderSlate),
                      ),
                      child: Text(
                        details.isEmpty
                            ? tower.towerName
                            : '${tower.towerName} ($details)',
                        style: HomeSureTypography.caption.copyWith(
                          color: HomeSureColors.champagneHighlight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (configs.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: configs.take(10).map((cfg) {
                    final countStr = cfg.numberOfInventory != null
                        ? ' (${cfg.numberOfInventory} units)'
                        : '';
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: HomeSureColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(HomeSureRadius.sm),
                        border: Border.all(color: HomeSureColors.borderDivider),
                      ),
                      child: Text(
                        '${cfg.typeOfInventory}$countStr',
                        style: HomeSureTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: HomeSureColors.textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (_buyerSelectedUnit != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: HomeSureColors.statusPositiveBg,
                    borderRadius: BorderRadius.circular(HomeSureRadius.md),
                    border: Border.all(
                      color: HomeSureColors.statusPositiveBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Evaluating Unit: ${_buyerSelectedUnit!.unitNumber}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: HomeSureColors.statusPositiveText,
                              ),
                            ),
                          ),
                          HomeSureStatusBadge(
                            label: _buyerSelectedUnit!.sourceType.displayLabel,
                            tone: HomeSureBadgeTone.positive,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (_buyerSelectedUnit!.towerName != null &&
                              _buyerSelectedUnit!.towerName!.isNotEmpty)
                            'Tower: ${_buyerSelectedUnit!.towerName}',
                          if (_buyerSelectedUnit!.floorNumber != null &&
                              _buyerSelectedUnit!.floorNumber!.isNotEmpty)
                            'Floor: ${_buyerSelectedUnit!.floorNumber}',
                          if (_buyerSelectedUnit!.unitConfiguration != null &&
                              _buyerSelectedUnit!.unitConfiguration!.isNotEmpty)
                            'Config: ${_buyerSelectedUnit!.unitConfiguration}',
                          if (_buyerSelectedUnit!.carpetAreaSqM != null)
                            'Carpet: ${_buyerSelectedUnit!.carpetAreaSqM} Sq.M',
                          'Source: ${_buyerSelectedUnit!.sourceType.displayLabel}',
                        ].join(' • '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: HomeSureColors.statusPositiveText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _promptBuyerUnitSelection,
                  icon: const Icon(Icons.meeting_room_outlined, size: 18),
                  label: Text(
                    _buyerSelectedUnit == null
                        ? 'Specify Apartment / Unit to Evaluate'
                        : 'Update Evaluated Apartment / Unit',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsSection() {
    if (_isCatalogueSummary) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: HomeSureColors.surfaceWhite,
          borderRadius: BorderRadius.circular(HomeSureRadius.lg),
          border: Border.all(color: HomeSureColors.borderDivider),
          boxShadow: HomeSureShadows.cardSubtle,
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeSureSectionHeader(
              title: 'Uploaded Regulatory Documents',
              subtitle: 'Not yet extracted for this catalogue-summary listing.',
            ),
            SizedBox(height: 8),
            Text(
              'Detailed K-RERA document links and regulatory filings have not '
              'been extracted yet. Absence of listed files here does not '
              'indicate zero filings on K-RERA.',
              style: HomeSureTypography.bodySecondary,
            ),
          ],
        ),
      );
    }

    final docs = _detailBundle?.documents ?? const [];
    final docCount =
        _property.regulatoryCounts['total_documents'] ?? docs.length;
    final visibleDocs =
        _showAllDocuments || docs.length <= 6 ? docs : docs.take(6).toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HomeSureColors.surfaceWhite,
        borderRadius: BorderRadius.circular(HomeSureRadius.lg),
        border: Border.all(color: HomeSureColors.borderDivider),
        boxShadow: HomeSureShadows.cardSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSureSectionHeader(
            title: 'Uploaded Regulatory Documents',
            subtitle: '$docCount document records indexed on K-RERA',
          ),
          if (_isLoadingDetailBundle) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              color: HomeSureColors.champagneGold,
              backgroundColor: HomeSureColors.surfaceSubtle,
            ),
          ],
          if (_detailBundleError != null) ...[
            const SizedBox(height: 10),
            Text(
              _detailBundleError!,
              style: const TextStyle(
                color: HomeSureColors.statusCriticalText,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (docs.isEmpty)
            Text(
              docCount > 0
                  ? '$docCount document references reported on K-RERA portal. Full file table unavailable offline.'
                  : 'No uploaded regulatory documents listed for this project on K-RERA.',
              style: HomeSureTypography.bodySecondary,
            )
          else ...[
            ...visibleDocs.map((d) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HomeSureColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(HomeSureRadius.sm),
                  border: Border.all(color: HomeSureColors.borderDivider),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      d.hasDownloadableFile
                          ? Icons.description_outlined
                          : Icons.file_present_outlined,
                      size: 18,
                      color: HomeSureColors.champagneHighlight,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.documentCategory,
                            style: HomeSureTypography.bodyMedium.copyWith(
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${d.sourceTab} > ${d.sourceSection}'
                            '${d.displayedFilename != null ? " (${d.displayedFilename})" : ""}'
                            '${d.approvalDate != null && d.approvalDate!.isNotEmpty ? " • Approved ${d.approvalDate}" : ""}',
                            style: HomeSureTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    HomeSureStatusBadge(
                      label: d.hasDownloadableFile ? 'On Portal' : 'Listed',
                      tone: d.hasDownloadableFile
                          ? HomeSureBadgeTone.positive
                          : HomeSureBadgeTone.neutral,
                    ),
                  ],
                ),
              );
            }),
            if (docs.length > 6)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _showAllDocuments = !_showAllDocuments;
                    });
                  },
                  child: Text(
                    _showAllDocuments
                        ? 'Show fewer documents'
                        : 'Show all ${docs.length} documents',
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildIssuesSection() {
    if (_isCatalogueSummary) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: HomeSureColors.surfaceWhite,
          borderRadius: BorderRadius.circular(HomeSureRadius.lg),
          border: Border.all(color: HomeSureColors.borderDivider),
          boxShadow: HomeSureShadows.cardSubtle,
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeSureSectionHeader(
              title: 'Complaints & Regulatory Issues',
              subtitle: 'Not yet verified — detailed extraction pending.',
            ),
            SizedBox(height: 8),
            Text(
              'K-RERA complaints and litigation disclosures have not been '
              'extracted yet for this catalogue-summary project. Absence of '
              'rows here does not indicate zero complaints.',
              style: HomeSureTypography.bodySecondary,
            ),
          ],
        ),
      );
    }

    final complaints = _detailBundle?.complaints ?? const [];
    final complaintCount =
        _property.regulatoryCounts['total_complaints'] ?? complaints.length;
    final visibleComplaints = _showAllComplaints || complaints.length <= 5
        ? complaints
        : complaints.take(5).toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HomeSureColors.surfaceWhite,
        borderRadius: BorderRadius.circular(HomeSureRadius.lg),
        border: Border.all(color: HomeSureColors.borderDivider),
        boxShadow: HomeSureShadows.cardSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSureSectionHeader(
            title: 'Complaints & Regulatory Issues',
            subtitle:
                'Registered K-RERA disputes ($complaintCount on record)',
          ),
          const SizedBox(height: 12),
          if (complaints.isEmpty)
            Text(
              complaintCount > 0
                  ? '$complaintCount registered K-RERA complaint(s) indicated in summary counts.'
                  : 'No registered K-RERA complaints found on this project.',
              style: HomeSureTypography.bodySecondary,
            )
          else ...[
            ...visibleComplaints.map((c) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HomeSureColors.statusWarningBg,
                  borderRadius: BorderRadius.circular(HomeSureRadius.sm),
                  border: Border.all(color: HomeSureColors.statusWarningBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.report_problem_outlined,
                      size: 18,
                      color: HomeSureColors.statusWarningText,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.complaintSubject ??
                                c.complaintNumber ??
                                'Registered Complaint',
                            style: HomeSureTypography.bodyMedium.copyWith(
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'No: ${c.complaintNumber ?? "N/A"} • Date: ${c.complaintDate ?? "N/A"} • Status: ${c.complaintStatus ?? "N/A"}',
                            style: HomeSureTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (complaints.length > 5)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _showAllComplaints = !_showAllComplaints;
                    });
                  },
                  child: Text(
                    _showAllComplaints
                        ? 'Show fewer complaints'
                        : 'Show all ${complaints.length} complaints',
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnassessedState() {
    final title = _isCatalogueSummary
        ? 'Property Health Assessment Unavailable (Catalogue Summary)'
        : 'Assessment pending';
    final description = _isCatalogueSummary
        ? 'Complete regulatory analysis and a K-RERA-backed Property Health '
            'assessment are unavailable until detailed portal extraction is '
            'completed for this project.'
        : 'No HomeSureAI scores are available for this project yet. '
            'Start the assessment to continue. Any scores or compliance '
            'findings must be based on supporting evidence and review.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HomeSureColors.statusWarningBg,
        borderRadius: BorderRadius.circular(HomeSureRadius.lg),
        border: Border.all(color: HomeSureColors.statusWarningBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.pending_actions_outlined,
                color: HomeSureColors.statusWarningText,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: HomeSureColors.statusWarningText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: HomeSureColors.textPrimary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCatalogueScores =
        !_isCatalogueSummary && _property.overallScore > 0;

    return Scaffold(
      backgroundColor: HomeSureColors.backgroundWarm,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: HomeSureColors.midnightHeader,
        title: const Text('Property Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KeyedSubtree(
                key: _overviewKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasCatalogueScores)
                      PropertyHeroCard(property: _property)
                    else
                      _buildPropertyIdentityHeader(),
                    if (_isCatalogueSummary) _buildCatalogueSummaryNotice(),
                    _buildIntelligenceSummaryGrid(),
                    _buildSectionNavigationBar(),
                    _buildOverviewDetailsSection(),
                  ],
                ),
              ),
              KeyedSubtree(
                key: _legalKey,
                child: _buildLegalSection(),
              ),
              KeyedSubtree(
                key: _developmentKey,
                child: _buildDevelopmentSection(),
              ),
              KeyedSubtree(
                key: _documentsKey,
                child: _buildDocumentsSection(),
              ),
              KeyedSubtree(
                key: _issuesKey,
                child: _buildIssuesSection(),
              ),
              const SizedBox(height: 18),
              if (hasCatalogueScores) ...[
                const Text(
                  'Property DNA',
                  style: HomeSureTypography.screenTitle,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Explore the available catalogue scores. These scores '
                  'are not a substitute for reviewing official documents '
                  'and project-specific evidence.',
                  style: HomeSureTypography.bodySecondary,
                ),
                const SizedBox(height: 16),
                _buildScoreTile(
                  'Legal Compliance',
                  _property.legalScore,
                  HomeSureColors.statusPositiveText,
                ),
                _buildScoreTile(
                  'Utilities',
                  _property.utilityScore,
                  HomeSureColors.statusWarningText,
                ),
                _buildScoreTile(
                  'Safety',
                  _property.safetyScore,
                  HomeSureColors.champagneHighlight,
                ),
                _buildScoreTile(
                  'Builder Reliability',
                  _property.builderScore,
                  HomeSureColors.champagneGold,
                ),
              ] else ...[
                _buildUnassessedState(),
              ],
              const SizedBox(height: 20),
              AppButton(
                text: _isCatalogueSummary
                    ? 'Assessment Unavailable (Catalogue Summary)'
                    : 'Start Assessment',
                icon: _isCatalogueSummary
                    ? Icons.lock_clock_outlined
                    : Icons.play_arrow_rounded,
                enabled: !_isCatalogueSummary,
                onPressed: () {
                  _selectCanonicalProperty();

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SureBotScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Always validate important project details against '
                  'official records and supporting documents.',
                  textAlign: TextAlign.center,
                  style: HomeSureTypography.caption,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuyerUnitDialog extends StatefulWidget {
  final String projectId;
  final List<ProjectTowerRecord> availableTowers;
  final List<InventoryConfiguration> availableConfigs;
  final ProjectUnitRecord? initialUnit;
  final PropertyCatalogueGateway gateway;

  const _BuyerUnitDialog({
    required this.projectId,
    required this.availableTowers,
    required this.availableConfigs,
    this.initialUnit,
    required this.gateway,
  });

  @override
  State<_BuyerUnitDialog> createState() => _BuyerUnitDialogState();
}

class _BuyerUnitDialogState extends State<_BuyerUnitDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _unitNumberCtrl;
  late final TextEditingController _towerCtrl;
  late final TextEditingController _floorCtrl;
  late final TextEditingController _configCtrl;
  late final TextEditingController _carpetCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _unitNumberCtrl = TextEditingController(
      text: widget.initialUnit?.unitNumber ?? '',
    );
    _towerCtrl = TextEditingController(
      text: widget.initialUnit?.towerName ?? '',
    );
    _floorCtrl = TextEditingController(
      text: widget.initialUnit?.floorNumber ?? '',
    );
    _configCtrl = TextEditingController(
      text: widget.initialUnit?.unitConfiguration ?? '',
    );
    _carpetCtrl = TextEditingController(
      text: widget.initialUnit?.carpetAreaSqM?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _unitNumberCtrl.dispose();
    _towerCtrl.dispose();
    _floorCtrl.dispose();
    _configCtrl.dispose();
    _carpetCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final carpet = double.tryParse(_carpetCtrl.text.trim());
      final saved = await widget.gateway.saveBuyerUnit(
        projectId: widget.projectId,
        unitNumber: _unitNumberCtrl.text.trim(),
        towerName: _towerCtrl.text.trim(),
        floorNumber: _floorCtrl.text.trim(),
        unitConfiguration: _configCtrl.text.trim(),
        carpetAreaSqM: carpet,
      );
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Specify Apartment / Unit'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _unitNumberCtrl,
                decoration: const InputDecoration(
                  labelText: 'Flat / Plot / Unit Number *',
                  hintText: 'e.g. Flat 402 or Plot 18',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter the unit number'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _towerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tower / Block (optional)',
                  hintText: 'e.g. Tower A / Block 1',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _floorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Floor Number (optional)',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _configCtrl,
                decoration: const InputDecoration(
                  labelText: 'Configuration (optional)',
                  hintText: 'e.g. 2 BHK, 3 BHK',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _carpetCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Carpet Area in Sq.M (optional)',
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Unit details entered here are recorded as Buyer-Provided evidence.',
                style: HomeSureTypography.caption,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: const Text('Save Unit'),
        ),
      ],
    );
  }
}
