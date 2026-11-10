import 'package:flutter/material.dart';

import '../../core/theme/homesure_components.dart';
import '../../core/theme/homesure_tokens.dart';
import '../../features/property/models/krera_project_models.dart';
import '../../features/property/models/property.dart' as feature;
import '../../features/property/models/property_adapter.dart';
import '../../features/property/services/property_repository.dart';
import '../../features/property/state/property_state.dart';
import '../../models/property.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/property/property_hero_card.dart';
import '../assessment/surebot_screen.dart';

enum _IntelligenceSectionFilter {
  overview('Overview'),
  regulatory('Regulatory'),
  development('Development'),
  documents('Documents'),
  complaints('Complaints'),
  locationLand('Location & Land'),
  myApartment('My Apartment');

  final String label;
  const _IntelligenceSectionFilter(this.label);
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

  late Property _property;
  ProjectRegulatoryDetailBundle? _detailBundle;
  List<ProjectUnitRecord> _projectUnits = const [];
  ProjectUnitRecord? _buyerSelectedUnit;
  bool _isLoadingDetailBundle = false;
  String? _detailBundleError;
  _IntelligenceSectionFilter _selectedFilter =
      _IntelligenceSectionFilter.overview;

  PropertyCatalogueGateway get _catalogueGateway =>
      widget.catalogueGateway ?? PropertyRepository.instance;

  @override
  void initState() {
    super.initState();
    _property = widget.property;
    _loadProjectDetailAndUnits();
  }

  Future<void> _loadProjectDetailAndUnits() async {
    if (_property.id.isEmpty) return;

    setState(() {
      _isLoadingDetailBundle = true;
      _detailBundleError = null;
    });

    try {
      final hydrated = await _catalogueGateway.fetchProjectById(_property.id);
      final bundle = await _catalogueGateway.fetchProjectRegulatoryDetail(
        _property.id,
      );
      final units = await _catalogueGateway.fetchProjectUnits(_property.id);

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
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingDetailBundle = false;
        _detailBundleError = 'Unable to load extended K-RERA details: $error';
      });
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
        color: HomeSureColors.primaryNavy,
        borderRadius: BorderRadius.circular(HomeSureRadius.xl),
        boxShadow: HomeSureShadows.cardElevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              const HomeSureStatusBadge(
                label: 'Official K-RERA Record',
                tone: HomeSureBadgeTone.teal,
                icon: Icons.verified_outlined,
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
              color: Colors.white,
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
              color: Color(0xFFD0DCEB),
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
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(HomeSureRadius.md),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_property.reraNumber.isNotEmpty) ...[
                    const Text(
                      'K-RERA REGISTRATION NUMBER',
                      style: TextStyle(
                        color: Color(0xFF9FB3C8),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _property.reraNumber,
                      style: const TextStyle(
                        color: Colors.white,
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
                        color: Color(0xFF9FB3C8),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _property.acknowledgementNumber,
                      style: const TextStyle(
                        color: Color(0xFFBDD0E4),
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

  Widget _buildIntelligenceSummaryGrid() {
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
      margin: const EdgeInsets.only(top: 16),
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
                'Live snapshot of official K-RERA filings, disclosures, and registered complaints.',
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
                  accentColor: HomeSureColors.primaryNavy,
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
                      ? HomeSureColors.accentTealDark
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
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _IntelligenceSectionFilter.values.map((section) {
            final selected = _selectedFilter == section;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(section.label),
                selected: selected,
                showCheckmark: false,
                onSelected: (_) {
                  setState(() {
                    _selectedFilter = section;
                  });
                },
                selectedColor: HomeSureColors.primaryNavy,
                backgroundColor: HomeSureColors.surfaceWhite,
                side: BorderSide(
                  color: selected
                      ? HomeSureColors.primaryNavy
                      : HomeSureColors.borderDivider,
                ),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : HomeSureColors.textPrimary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(HomeSureRadius.pill),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryMetricsSection() {
    if (_property.summaryMetrics.isEmpty) {
      return const SizedBox.shrink();
    }

    const regulatoryKeys = <MapEntry<String, String>>[
      MapEntry('registration_number', 'K-RERA Registration No.'),
      MapEntry('ack_number', 'Acknowledgement No.'),
      MapEntry('regulatory_status', 'K-RERA Portal Status'),
      MapEntry('registration_date', 'Registration Approved On'),
      MapEntry('proposed_completion_date', 'Proposed Completion Date'),
      MapEntry('estimated_cost_inr', 'Estimated Project Cost (INR)'),
      MapEntry('estimated_cost_crore', 'Estimated Project Cost'),
      MapEntry('approving_authority', 'Plan Approving Authority'),
      MapEntry('approved_plan_number', 'Approved Plan Number'),
      MapEntry('plan_approval_date_iso', 'Plan Approval Date'),
      MapEntry('plan_approval_date', 'Plan Approval Date'),
      MapEntry('land_litigation_flag', 'Land Litigation Status'),
    ];

    const developmentAndLandKeys = <MapEntry<String, String>>[
      MapEntry('project_sub_type', 'Project Sub-Type'),
      MapEntry('total_land_area_sq_m', 'Total Land Area (Sq.M)'),
      MapEntry('total_area_of_land_sqm', 'Total Land Area (Sq.M)'),
      MapEntry('total_open_area_sq_m', 'Total Open Area (Sq.M)'),
      MapEntry('total_open_area_sqm', 'Total Open Area (Sq.M)'),
      MapEntry('total_covered_area_sq_m', 'Total Covered Area (Sq.M)'),
      MapEntry('total_covered_area_sqm', 'Total Covered Area (Sq.M)'),
      MapEntry('total_carpet_area_sq_m', 'Total Carpet Area (Sq.M)'),
      MapEntry('carpet_area_range_sqm', 'Carpet Area Range'),
      MapEntry('number_of_inventories', 'Total Inventory / Units'),
      MapEntry('total_inventory_units', 'Total Inventory / Units'),
      MapEntry('no_of_towers', 'Number of Towers / Blocks'),
      MapEntry('number_of_towers', 'Number of Towers / Blocks'),
      MapEntry('parking_spaces', 'Total Parking Spaces'),
      MapEntry('total_parking', 'Total Parking Spaces'),
      MapEntry('district', 'District'),
      MapEntry('taluk', 'Taluk'),
      MapEntry('latitude', 'Latitude'),
      MapEntry('longitude', 'Longitude'),
      MapEntry('coordinate_source', 'Location Coordinates'),
    ];

    final List<MapEntry<String, String>> activeKeys;
    if (_selectedFilter == _IntelligenceSectionFilter.regulatory) {
      activeKeys = regulatoryKeys;
    } else if (_selectedFilter == _IntelligenceSectionFilter.development ||
        _selectedFilter == _IntelligenceSectionFilter.locationLand) {
      activeKeys = developmentAndLandKeys;
    } else {
      activeKeys = [...regulatoryKeys, ...developmentAndLandKeys];
    }

    final rows = <Widget>[];
    for (final item in activeKeys) {
      final metric = _property.summaryMetrics[item.key];
      if (metric == null) continue;
      final isPresent =
          metric.observationState == ObservationState.presentWithData;
      rows.add(
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
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
                  item.value,
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
                        metric.formattedValue,
                        textAlign: TextAlign.right,
                        style: HomeSureTypography.bodyMedium,
                      )
                    : Align(
                        alignment: Alignment.centerRight,
                        child: HomeSureObservationBadge(
                          state: metric.observationState,
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
      margin: const EdgeInsets.only(top: 16),
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
          const Text(
            'Official K-RERA Project Disclosures',
            style: HomeSureTypography.sectionTitle,
          ),
          const SizedBox(height: 4),
          const Text(
            'Extracted directly from K-RERA tabs. Missing portal fields are shown with their exact observation state.',
            style: HomeSureTypography.caption,
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildUnitHierarchySection() {
    final configs = _detailBundle?.inventoryConfigurations.isNotEmpty == true
        ? _detailBundle!.inventoryConfigurations
        : _property.inventoryConfigurations;
    final towers = _detailBundle?.towers.isNotEmpty == true
        ? _detailBundle!.towers
        : _property.towersSummary;
    final hierarchy = _property.unitHierarchyStatus;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
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
                border: Border.all(color: HomeSureColors.statusPositiveBorder),
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
    );
  }

  Widget _buildPortalTabsAndEvidenceSection() {
    if (_property.tabObservations.isEmpty && _detailBundle == null) {
      return const SizedBox.shrink();
    }

    final docs = _detailBundle?.documents ?? const [];
    final complaints = _detailBundle?.complaints ?? const [];
    final docCount =
        _property.regulatoryCounts['total_documents'] ?? docs.length;
    final complaintCount =
        _property.regulatoryCounts['total_complaints'] ?? complaints.length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
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
          const Text(
            'K-RERA Portal Evidence & Tab Observations',
            style: HomeSureTypography.sectionTitle,
          ),
          const SizedBox(height: 4),
          Text(
            'Regulatory Documents: $docCount • Registered Portal Complaints: $complaintCount',
            style: HomeSureTypography.bodySecondary,
          ),
          if (_property.tabObservations.isNotEmpty) ...[
            const SizedBox(height: 12),
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
          if (_isLoadingDetailBundle) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              color: HomeSureColors.accentTeal,
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
          if (docs.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            Material(
              color: Colors.transparent,
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                initiallyExpanded:
                    _selectedFilter == _IntelligenceSectionFilter.documents,
                title: Text(
                  'Uploaded Regulatory Documents (${docs.length})',
                  style: HomeSureTypography.bodyMedium,
                ),
                children: docs.take(25).map((d) {
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
                          color: HomeSureColors.primaryNavy,
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
                                '${d.displayedFilename != null ? " (${d.displayedFilename})" : ""}',
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
                }).toList(),
              ),
            ),
          ],
          if (complaints.isNotEmpty) ...[
            const Divider(),
            Material(
              color: Colors.transparent,
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                initiallyExpanded:
                    _selectedFilter == _IntelligenceSectionFilter.complaints,
                title: Text(
                  'K-RERA Complaints (${complaints.length})',
                  style: HomeSureTypography.bodyMedium,
                ),
                children: complaints.take(20).map((c) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: HomeSureColors.statusWarningBg,
                      borderRadius: BorderRadius.circular(HomeSureRadius.sm),
                      border: Border.all(
                        color: HomeSureColors.statusWarningBorder,
                      ),
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
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnassessedState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HomeSureColors.statusWarningBg,
        borderRadius: BorderRadius.circular(HomeSureRadius.lg),
        border: Border.all(color: HomeSureColors.statusWarningBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pending_actions_outlined,
                color: HomeSureColors.statusWarningText,
                size: 22,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Assessment pending',
                  style: TextStyle(
                    color: HomeSureColors.statusWarningText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'No HomeSureAI scores are available for this project yet. '
            'Start the assessment to continue. Any scores or compliance '
            'findings must be based on supporting evidence and review.',
            style: TextStyle(
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
    final bool hasCatalogueScores = _property.overallScore > 0;

    return Scaffold(
      backgroundColor: HomeSureColors.backgroundWarm,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: HomeSureColors.surfaceWhite,
        title: const Text('Property Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasCatalogueScores)
                PropertyHeroCard(property: _property)
              else
                _buildPropertyIdentityHeader(),

              _buildIntelligenceSummaryGrid(),

              _buildSectionNavigationBar(),

              _buildSummaryMetricsSection(),

              _buildUnitHierarchySection(),

              _buildPortalTabsAndEvidenceSection(),

              const SizedBox(height: 20),

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
                  HomeSureColors.primaryNavy,
                ),
                _buildScoreTile(
                  'Builder Reliability',
                  _property.builderScore,
                  HomeSureColors.accentTealDark,
                ),
              ] else ...[
                _buildUnassessedState(),
              ],

              const SizedBox(height: 20),

              AppButton(
                text: 'Start Assessment',
                icon: Icons.play_arrow_rounded,
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
