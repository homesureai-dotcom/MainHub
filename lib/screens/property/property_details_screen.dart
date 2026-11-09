import 'package:flutter/material.dart';

import '../../models/property.dart';
import '../../features/property/models/property_adapter.dart';
import '../../features/property/state/property_state.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/property/property_hero_card.dart';
import '../assessment/surebot_screen.dart';

class PropertyDetailsScreen extends StatelessWidget {
  final Property property;

  const PropertyDetailsScreen({super.key, required this.property});

  void _selectCanonicalProperty() {
    final propertyState = PropertyState.instance;

    for (final candidate in propertyState.properties) {
      if (candidate.id == property.id || candidate.name == property.name) {
        propertyState.selectProperty(candidate);
        return;
      }
    }

    propertyState.selectProperty(PropertyAdapter.fromLegacy(property));
  }

  Widget _buildScoreTile(String title, int score, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Text(
              '$score',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildPropertySummary() {
    final details = <Widget>[];

    if (property.builder.trim().isNotEmpty) {
      details.add(
        _buildDetailRow(Icons.business_outlined, 'Builder', property.builder),
      );
    }

    if (property.locality.trim().isNotEmpty) {
      details.add(
        _buildDetailRow(
          Icons.location_on_outlined,
          'Locality',
          property.locality,
        ),
      );
    }

    if (property.city.trim().isNotEmpty) {
      details.add(
        _buildDetailRow(Icons.location_city_outlined, 'City', property.city),
      );
    }

    if (property.reraNumber.trim().isNotEmpty) {
      details.add(
        _buildDetailRow(
          Icons.verified_outlined,
          'RERA number',
          property.reraNumber,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your selected project',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            property.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          if (details.isNotEmpty) ...[const SizedBox(height: 18), ...details],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'This project has not yet been verified or assessed '
                  'by HomeSureAI. Its inclusion here is not proof of '
                  'RERA validity or legal compliance.',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          SizedBox(
            width: 94,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnassessedState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pending_actions_outlined,
                color: Color(0xFFB45309),
                size: 24,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Assessment pending',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'No HomeSureAI scores are available for this project yet. '
            'Start the assessment to continue. Any scores or compliance '
            'findings must be based on supporting evidence and review.',
            style: TextStyle(
              color: Color(0xFF78350F),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bool hasCatalogueScores = false;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF8FAFC),
        title: const Text('Property Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasCatalogueScores)
                PropertyHeroCard(property: property)
              else
                _buildPropertySummary(),

              const SizedBox(height: 28),

              if (hasCatalogueScores) ...[
                const Text(
                  'Property DNA',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Explore the available catalogue scores. These scores '
                  'are not a substitute for reviewing official documents '
                  'and project-specific evidence.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                _buildScoreTile(
                  'Legal Compliance',
                  property.legalScore,
                  Colors.green,
                ),
                _buildScoreTile(
                  'Utilities',
                  property.utilityScore,
                  Colors.orange,
                ),
                _buildScoreTile('Safety', property.safetyScore, Colors.blue),
                _buildScoreTile(
                  'Builder Reliability',
                  property.builderScore,
                  Colors.purple,
                ),
              ] else ...[
                _buildUnassessedState(),
              ],

              const SizedBox(height: 28),

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
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
