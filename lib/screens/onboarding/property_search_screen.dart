import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/theme/homesure_components.dart';
import '../../core/theme/homesure_tokens.dart';
import '../../features/property/models/krera_project_models.dart';
import '../../features/property/services/property_repository.dart';
import '../../features/property_submission/services/property_submission_service.dart';
import '../../widgets/common/app_search_field.dart';
import '../../widgets/property/builder_card.dart';
import 'builder_projects_screen.dart';
import 'my_property_requests_screen.dart';

class PropertySearchScreen extends StatefulWidget {
  final PropertySubmissionGateway? submissionGateway;
  final PropertyCatalogueGateway? catalogueGateway;

  const PropertySearchScreen({
    super.key,
    this.submissionGateway,
    this.catalogueGateway,
  });

  @override
  State<PropertySearchScreen> createState() => _PropertySearchScreenState();
}

class _PropertySearchScreenState extends State<PropertySearchScreen> {
  List<BuilderCatalogueEntry> filteredBuilders = [];
  String searchQuery = '';
  bool isLoadingCatalogue = true;
  String? catalogueError;
  bool isSubmitting = false;
  Timer? _searchDebounce;

  PropertySubmissionGateway get _submissionGateway =>
      widget.submissionGateway ?? PropertySubmissionService();

  PropertyCatalogueGateway get _catalogueGateway =>
      widget.catalogueGateway ?? PropertyRepository.instance;

  @override
  void initState() {
    super.initState();
    _loadBuilders(query: '');
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadBuilders({required String query}) async {
    if (!mounted) return;
    setState(() {
      isLoadingCatalogue = true;
      catalogueError = null;
    });

    try {
      final results = await _catalogueGateway.fetchBuilders(
        searchQuery: query,
      );
      if (!mounted) return;

      setState(() {
        filteredBuilders = results;
        isLoadingCatalogue = false;
        catalogueError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        filteredBuilders = [];
        isLoadingCatalogue = false;
        catalogueError = 'Unable to load K-RERA builder catalogue: $error';
      });
    }
  }

  void _search(String value) {
    final query = value.trim();
    setState(() {
      searchQuery = query;
    });

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 180), () {
      _loadBuilders(query: query);
    });
  }

  void _openBuilderProjects(BuilderCatalogueEntry builder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuilderProjectsScreen(
          builder: builder,
          catalogueGateway: widget.catalogueGateway,
        ),
      ),
    );
  }

  Future<Map<String, String>?> _showPropertyForm({required bool requestOnly}) {
    return showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _PropertyFormDialog(requestOnly: requestOnly),
    );
  }

  Future<void> _addManualProperty() async {
    final details = await _showPropertyForm(requestOnly: false);

    if (!mounted || details == null || isSubmitting) return;

    setState(() => isSubmitting = true);

    try {
      await _submissionGateway.submitProperty(
        name: details['name']!,
        builder: details['builder']!,
        locality: details['locality']!,
        city: details['city']!,
        reraNumber: details['rera']!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Property submitted for review. You can start an assessment '
            'after HomeSureAI approves it.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not submit property: $error'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  Future<void> _requestProjectAddition() async {
    final details = await _showPropertyForm(requestOnly: true);

    if (!mounted || details == null || isSubmitting) return;

    setState(() => isSubmitting = true);

    try {
      await _submissionGateway.submitProperty(
        name: details['name']!,
        builder: details['builder']!,
        locality: details['locality']!,
        city: details['city']!,
        reraNumber: details['rera']!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catalogue addition request submitted for review.'),
          duration: Duration(seconds: 5),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not submit request: $error'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  void _showUnlistedPropertySheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: HomeSureColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(HomeSureRadius.xl),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Property or Builder Not Listed?',
                  style: HomeSureTypography.sectionTitle,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Submit your project details or check the status of your existing requests.',
                  style: HomeSureTypography.bodySecondary,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _addManualProperty();
                    },
                    icon: const Icon(Icons.add_home_outlined),
                    label: const Text("My project isn't listed"),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _requestProjectAddition();
                    },
                    icon: const Icon(Icons.playlist_add),
                    label: const Text('Request catalogue addition'),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const MyPropertyRequestsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('My Property Requests'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBuildersBody() {
    if (isLoadingCatalogue) {
      return const Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: HomeSureColors.primaryNavy,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (catalogueError != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: HomeSureColors.statusCriticalText,
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                catalogueError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: HomeSureColors.statusCriticalText,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _loadBuilders(query: searchQuery),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredBuilders.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                searchQuery.isEmpty
                    ? 'No builders available.'
                    : 'No matching builder found for "$searchQuery".',
                textAlign: TextAlign.center,
                style: HomeSureTypography.bodySecondary,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _addManualProperty,
                icon: const Icon(Icons.add_home_outlined),
                label: const Text("My project isn't listed"),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredBuilders.length,
      itemBuilder: (context, index) {
        final builder = filteredBuilders[index];
        return BuilderCard(
          builder: builder,
          onTap: () => _openBuilderProjects(builder),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeSureColors.backgroundWarm,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Find Your Property',
                      style: HomeSureTypography.screenTitle,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showUnlistedPropertySheet,
                    style: TextButton.styleFrom(
                      foregroundColor: HomeSureColors.accentTealDark,
                      backgroundColor: HomeSureColors.accentTealTint,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          HomeSureRadius.pill,
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.add_home_outlined, size: 15),
                    label: const Text(
                      'Not listed?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Start with the builder behind your project.',
                style: HomeSureTypography.bodySecondary,
              ),
              const SizedBox(height: 12),
              AppSearchField(
                hintText: 'Search builders (e.g. Godrej, Prestige, Brigade)...',
                onChanged: _search,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Builders in the catalogue',
                    style: HomeSureTypography.cardTitle,
                  ),
                  if (!isLoadingCatalogue)
                    HomeSureStatusBadge(
                      label: '${filteredBuilders.length} Builders',
                      tone: HomeSureBadgeTone.navy,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(child: _buildBuildersBody()),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertyFormDialog extends StatefulWidget {
  final bool requestOnly;

  const _PropertyFormDialog({required this.requestOnly});

  @override
  State<_PropertyFormDialog> createState() => _PropertyFormDialogState();
}

class _PropertyFormDialogState extends State<_PropertyFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _builderController;
  late final TextEditingController _localityController;
  late final TextEditingController _cityController;
  late final TextEditingController _reraController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _builderController = TextEditingController();
    _localityController = TextEditingController();
    _cityController = TextEditingController(text: 'Bengaluru');
    _reraController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _builderController.dispose();
    _localityController.dispose();
    _cityController.dispose();
    _reraController.dispose();

    super.dispose();
  }

  String? _validateRequired(String? value, String errorMessage) {
    if (value == null || value.trim().isEmpty) {
      return errorMessage;
    }

    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(context).pop(<String, String>{
      'name': _nameController.text.trim(),
      'builder': _builderController.text.trim(),
      'locality': _localityController.text.trim(),
      'city': _cityController.text.trim(),
      'rera': _reraController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.requestOnly
            ? 'Request a project addition'
            : 'Enter your property',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Project name *'),
                validator: (value) =>
                    _validateRequired(value, 'Enter the project name'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _builderController,
                decoration: const InputDecoration(labelText: 'Builder name'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _localityController,
                decoration: const InputDecoration(labelText: 'Locality *'),
                validator: (value) =>
                    _validateRequired(value, 'Enter the locality'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City *'),
                validator: (value) =>
                    _validateRequired(value, 'Enter the city'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _reraController,
                decoration: const InputDecoration(
                  labelText: 'RERA registration number (optional)',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Catalogue inclusion does not establish legal compliance. '
                'Project details must be independently reviewed.',
                style: HomeSureTypography.caption,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.requestOnly ? 'Submit request' : 'Use property'),
        ),
      ],
    );
  }
}
