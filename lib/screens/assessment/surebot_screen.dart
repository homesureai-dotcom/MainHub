import 'package:flutter/material.dart';

import '../../features/surebot/models/surebot_context.dart';
import '../../widgets/assessment/surebot_avatar.dart';
import '../../widgets/common/app_button.dart';
import 'assessment_screen.dart';

class SureBotScreen extends StatelessWidget {
  final SureBotContext? sureBotContext;

  const SureBotScreen({
    super.key,
    this.sureBotContext,
  });

  bool get hasContext => sureBotContext != null;

  @override
  Widget build(BuildContext context) {
    if (hasContext) {
      return _buildContextualSureBot(context);
    }

    return _buildAssessmentOnboarding(context);
  }

  Widget _buildAssessmentOnboarding(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              const SureBotAvatar(),

              const SizedBox(height: 36),

              const Text(
                "Hi Vinod 👋",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                "I'm SureBot",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "I'll guide you through a quick Property Health Assessment.\n\n"
                "This takes less than 3 minutes.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.grey,
                  height: 1.6,
                ),
              ),

              const Spacer(),

              AppButton(
                text: "Let's Begin",
                icon: Icons.arrow_forward,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AssessmentScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextualSureBot(BuildContext context) {
    final data = sureBotContext!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("SureBot"),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: SureBotAvatar(),
              ),

              const SizedBox(height: 24),

              Text(
                "Hi Vinod 👋",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "I'm SureBot. I already have some context about your property.",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              _buildPropertyCard(data.property),

              const SizedBox(height: 16),

              _buildHealthCard(data.health),

              const SizedBox(height: 16),

              _buildEvidenceCard(data.evidence),

              if (data.currentPriority != null) ...[
                const SizedBox(height: 16),
                _buildPriorityCard(data.currentPriority!),
              ],

              const SizedBox(height: 24),

              const Text(
                "What can I help you understand?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),

              const SizedBox(height: 12),

              _buildQuestionChip(
                icon: Icons.health_and_safety_outlined,
                label: "Why is my property score what it is?",
              ),

              _buildQuestionChip(
                icon: Icons.warning_amber_outlined,
                label: "What should I address first?",
              ),

              _buildQuestionChip(
                icon: Icons.description_outlined,
                label: "Which documents need attention?",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyCard(
    SureBotPropertyContext property,
  ) {
    return _ContextCard(
      icon: Icons.home_outlined,
      title: property.name,
      children: [
        _FactRow(
          label: "Builder",
          value: property.builderName,
        ),
        _FactRow(
          label: "Location",
          value: "${property.city}, ${property.state}",
        ),
        _FactRow(
          label: "Property type",
          value: property.propertyType,
        ),
        _FactRow(
          label: "Year built",
          value: property.yearOfConstruction.toString(),
        ),
      ],
    );
  }

  Widget _buildHealthCard(
    SureBotHealthContext health,
  ) {
    final score = health.score?.round();

    return _ContextCard(
      icon: Icons.favorite_outline,
      title: "Property Health",
      children: [
        _FactRow(
          label: "PHI score",
          value: score?.toString() ?? "Not assessed",
        ),
        _FactRow(
          label: "Grade",
          value: health.grade ?? "Not assessed",
        ),
        _FactRow(
          label: "Assessment",
          value: health.hasAssessment
              ? (health.isComplete ? "Complete" : "In progress")
              : "Not started",
        ),
        _FactRow(
          label: "Questions evaluated",
          value:
              "${health.evaluatedQuestionCount}/${health.totalQuestionCount}",
        ),
        _FactRow(
          label: "Risks",
          value: health.riskCount.toString(),
        ),
      ],
    );
  }

  Widget _buildEvidenceCard(
    SureBotEvidenceContext evidence,
  ) {
    return _ContextCard(
      icon: Icons.verified_outlined,
      title: "Evidence",
      children: [
        _FactRow(
          label: "Coverage",
          value: "${evidence.coveragePercentage.round()}%",
        ),
        _FactRow(
          label: "Satisfied",
          value: evidence.satisfiedRequirements.toString(),
        ),
        _FactRow(
          label: "Missing",
          value: evidence.missingRequirements.toString(),
        ),
        _FactRow(
          label: "Needs review",
          value: evidence.needsReviewRequirements.toString(),
        ),
        _FactRow(
          label: "Rejected",
          value: evidence.rejectedRequirements.toString(),
        ),
      ],
    );
  }

  Widget _buildPriorityCard(
    SureBotPriorityContext priority,
  ) {
    return _ContextCard(
      icon: Icons.priority_high_outlined,
      title: "Current Priority",
      children: [
        Text(
          priority.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          priority.description,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            height: 1.5,
          ),
        ),

        if (priority.estimatedPHIGain > 0) ...[
          const SizedBox(height: 12),
          Text(
            "Potential PHI improvement: +${priority.estimatedPHIGain}",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2563EB),
            ),
          ),
        ],

        if (priority.requiredDocuments.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            "Required documents",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          ...priority.requiredDocuments.map(
            (document) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                "• $document",
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuestionChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 21,
            color: const Color(0xFF2563EB),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: Color(0xFF94A3B8),
          ),
        ],
      ),
    );
  }
}

class _ContextCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _ContextCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  final String label;
  final String value;

  const _FactRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }
}