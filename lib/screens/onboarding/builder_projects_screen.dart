import 'package:flutter/material.dart';

import '../../core/theme/homesure_components.dart';
import '../../core/theme/homesure_tokens.dart';
import '../../features/property/models/krera_project_models.dart';
import '../../features/property/models/property.dart' as feature;
import '../../features/property/models/property_adapter.dart';
import '../../features/property/services/property_repository.dart';
import '../../features/property/state/property_state.dart';
import '../../models/property.dart' as legacy;
import '../../widgets/common/app_search_field.dart';
import '../../widgets/property/property_card.dart';
import '../property/property_details_screen.dart';

class BuilderProjectsScreen extends StatefulWidget {
  final BuilderCatalogueEntry builder;
  final PropertyCatalogueGateway? catalogueGateway;

  const BuilderProjectsScreen({
    super.key,
    required this.builder,
    this.catalogueGateway,
  });

  @override
  State<BuilderProjectsScreen> createState() => _BuilderProjectsScreenState();
}

class _BuilderProjectsScreenState extends State<BuilderProjectsScreen> {
  final PropertyState _propertyState = PropertyState.instance;

  List<legacy.Property> _allBuilderProjects = [];
  List<legacy.Property> _filteredProjects = [];
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;

  PropertyCatalogueGateway get _catalogueGateway =>
      widget.catalogueGateway ?? PropertyRepository.instance;

  @override
  void initState() {
    super.initState();
    if (widget.builder.projects.isNotEmpty) {
      final initial = widget.builder.projects
          .map(PropertyRepository.propertyFromBuilderSummary)
          .toList();
      _allBuilderProjects = initial;
      _filteredProjects = initial;
      _isLoading = false;
    }
    _loadFullBuilderProjects();
  }

  Future<void> _loadFullBuilderProjects() async {
    try {
      final fullProjects = await _catalogueGateway.fetchProjectsForBuilder(
        widget.builder,
      );
      if (!mounted) return;
      if (fullProjects.isNotEmpty) {
        setState(() {
          _allBuilderProjects = fullProjects;
          _filteredProjects = PropertyRepository.filterBuilderProjects(
            fullProjects,
            searchQuery: _searchQuery,
          );
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      if (!mounted) return;
      if (_allBuilderProjects.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Unable to load projects for ${widget.builder.builderName}: $error';
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    final trimmed = value.trim();
    setState(() {
      _searchQuery = trimmed;
      _filteredProjects = PropertyRepository.filterBuilderProjects(
        _allBuilderProjects,
        searchQuery: trimmed,
      );
    });
  }

  void _selectAndOpenProperty(legacy.Property property) {
    PropertyRepository.instance.selectLegacyProperty(property);
    feature.Property? canonicalProperty;

    for (final candidate in _propertyState.properties) {
      if (candidate.id == property.id || candidate.name == property.name) {
        canonicalProperty = candidate;
        break;
      }
    }

    if (canonicalProperty != null) {
      _propertyState.selectProperty(canonicalProperty);
    } else {
      _propertyState.selectProperty(PropertyAdapter.fromLegacy(property));
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyDetailsScreen(
          property: property,
          catalogueGateway: widget.catalogueGateway,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final countLabel = _allBuilderProjects.length == 1
        ? '1 Registered Project'
        : '${_allBuilderProjects.length} Registered Projects';

    final localitiesSummary = widget.builder.localities.isNotEmpty
        ? widget.builder.localities.take(3).join(' • ')
        : 'Bengaluru';

    return Scaffold(
      backgroundColor: HomeSureColors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: HomeSureColors.surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        foregroundColor: HomeSureColors.textPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.builder.builderName,
              style: HomeSureTypography.sectionTitle,
            ),
            Text(
              countLabel,
              style: HomeSureTypography.caption,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: HomeSureColors.primaryNavy,
                  borderRadius: BorderRadius.circular(HomeSureRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.domain_verification_rounded,
                      color: Color(0xFF8CE0D8),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'K-RERA Coverage: $localitiesSummary',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppSearchField(
                hintText: 'Search projects by name, locality, or RERA...',
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select a Property',
                    style: HomeSureTypography.cardTitle,
                  ),
                  HomeSureStatusBadge(
                    label:
                        'Showing ${_filteredProjects.length} of ${_allBuilderProjects.length}',
                    tone: HomeSureBadgeTone.neutral,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(child: _buildProjectsList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectsList() {
    if (_isLoading && _filteredProjects.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: HomeSureColors.primaryNavy,
        ),
      );
    }

    if (_errorMessage != null && _filteredProjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: HomeSureColors.statusCriticalText,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: HomeSureColors.statusCriticalText,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _loadFullBuilderProjects,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredProjects.isEmpty) {
      return const Center(
        child: Text(
          'No matching properties found under this builder.',
          textAlign: TextAlign.center,
          style: HomeSureTypography.bodySecondary,
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredProjects.length,
      itemBuilder: (context, index) {
        final property = _filteredProjects[index];
        return PropertyCard(
          property: property,
          onTap: () => _selectAndOpenProperty(property),
        );
      },
    );
  }
}
