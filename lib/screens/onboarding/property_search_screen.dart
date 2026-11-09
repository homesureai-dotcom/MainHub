import 'package:flutter/material.dart';

import '../../data/properties.dart';
import '../../models/property.dart' as legacy;
import '../../features/property/models/property.dart' as feature;
import '../../features/property/models/property_adapter.dart';
import '../../features/property/state/property_state.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_search_field.dart';
import '../../widgets/common/onboarding_scaffold.dart';
import '../../widgets/property/property_card.dart';
import '../property/property_details_screen.dart';
import '../../features/property_submission/services/property_submission_service.dart';
import 'my_property_requests_screen.dart';

class PropertySearchScreen extends StatefulWidget {
  final PropertySubmissionGateway? submissionGateway;

  const PropertySearchScreen({super.key, this.submissionGateway});

  @override
  State<PropertySearchScreen> createState() => _PropertySearchScreenState();
}

class _PropertySearchScreenState extends State<PropertySearchScreen> {
  final PropertyState propertyState = PropertyState.instance;

  List<legacy.Property> filteredProperties = properties;
  legacy.Property? selectedProperty;
  String searchQuery = '';
  bool isSubmitting = false;

  PropertySubmissionGateway get _submissionGateway =>
      widget.submissionGateway ?? PropertySubmissionService();

  @override
  void initState() {
    super.initState();

    final feature.Property? sharedProperty = propertyState.selectedProperty;

    if (sharedProperty == null) return;

    for (final property in properties) {
      if (property.id == sharedProperty.id ||
          property.name == sharedProperty.name) {
        selectedProperty = property;
        break;
      }
    }
  }

  void _search(String value) {
    final query = value.trim().toLowerCase();

    setState(() {
      searchQuery = query;

      filteredProperties = properties.where((property) {
        return property.name.toLowerCase().contains(query) ||
            property.builder.toLowerCase().contains(query) ||
            property.city.toLowerCase().contains(query) ||
            property.locality.toLowerCase().contains(query) ||
            property.reraNumber.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _persistSelectedProperty(legacy.Property property) {
    feature.Property? canonicalProperty;

    for (final candidate in propertyState.properties) {
      if (candidate.id == property.id || candidate.name == property.name) {
        canonicalProperty = candidate;
        break;
      }
    }

    if (canonicalProperty != null) {
      propertyState.selectProperty(canonicalProperty);
    } else {
      propertyState.selectProperty(PropertyAdapter.fromLegacy(property));
    }
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

  void _continue() {
    final property = selectedProperty;

    if (property == null) return;

    _persistSelectedProperty(property);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyDetailsScreen(property: property),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'Find Your Property',
      subtitle: 'Search projects by name, builder, locality or RERA number.',
      bottom: AppButton(
        text: 'Continue',
        enabled: selectedProperty != null,
        onPressed: _continue,
      ),
      child: Column(
        children: [
          AppSearchField(
            hintText: 'Project, builder, locality or RERA number',
            onChanged: _search,
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Projects in the catalogue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filteredProperties.isEmpty
                ? Center(
                    child: Text(
                      searchQuery.isEmpty
                          ? 'No projects available.'
                          : 'No matching project found.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredProperties.length,
                    itemBuilder: (context, index) {
                      final property = filteredProperties[index];

                      return PropertyCard(
                        property: property,
                        onTap: () {
                          setState(() {
                            selectedProperty = property;
                          });

                          _persistSelectedProperty(property);
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addManualProperty,
              icon: const Icon(Icons.add_home_outlined),
              label: const Text("My project isn't listed"),
            ),
          ),
          TextButton.icon(
            onPressed: _requestProjectAddition,
            icon: const Icon(Icons.playlist_add),
            label: const Text('Request catalogue addition'),
          ),
          TextButton.icon(
            onPressed: () {
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
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'A catalogue listing is not a guarantee of legal compliance.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
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
              TextFormField(
                controller: _builderController,
                decoration: const InputDecoration(labelText: 'Builder name'),
              ),
              TextFormField(
                controller: _localityController,
                decoration: const InputDecoration(labelText: 'Locality *'),
                validator: (value) =>
                    _validateRequired(value, 'Enter the locality'),
              ),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City *'),
                validator: (value) =>
                    _validateRequired(value, 'Enter the city'),
              ),
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
                style: TextStyle(fontSize: 12, color: Colors.grey),
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
