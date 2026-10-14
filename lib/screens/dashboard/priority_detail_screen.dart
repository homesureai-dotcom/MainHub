import 'package:flutter/material.dart';

import '../../core/evidence/evidence_repository.dart';
import '../../core/evidence/evidence_validation_result.dart';
import '../../core/phs/phs_categories.dart';
import '../../features/dashboard/models/dashboard_priority.dart';
import '../../features/dashboard/models/priority_evidence_context.dart';
import '../../features/dashboard/services/priority_evidence_resolver.dart';
import '../../models/property_health/recommendation.dart';

class PriorityDetailScreen extends StatefulWidget {
  final DashboardPriority priority;
  final EvidenceRepository? evidenceRepository;

  const PriorityDetailScreen({
    super.key,
    required this.priority,
    this.evidenceRepository,
  });

  @override
  State<PriorityDetailScreen> createState() =>
      _PriorityDetailScreenState();
}

class _PriorityDetailScreenState
    extends State<PriorityDetailScreen> {
  List<PriorityEvidenceContext> _evidenceContexts =
      const [];

  bool _isLoadingEvidence = false;

  @override
  void initState() {
    super.initState();
    _loadEvidence();
  }

  @override
  void didUpdateWidget(
    covariant PriorityDetailScreen oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.priority != widget.priority ||
        oldWidget.evidenceRepository !=
            widget.evidenceRepository) {
      _loadEvidence();
    }
  }

  Future<void> _loadEvidence() async {
    final repository = widget.evidenceRepository;

    if (repository == null ||
        widget.priority.requiredDocuments.isEmpty) {
      if (!mounted) return;

      setState(() {
        _evidenceContexts = const [];
        _isLoadingEvidence = false;
      });

      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingEvidence = true;
      });
    }

    final resolver = PriorityEvidenceResolver(
      repository: repository,
    );

    final contexts = await resolver.resolve(
      widget.priority,
    );

    if (!mounted) return;

    setState(() {
      _evidenceContexts = contexts;
      _isLoadingEvidence = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final priority = widget.priority;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Priority Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _PriorityHeader(
                priority: priority,
              ),
              const SizedBox(height: 20),
              _DescriptionCard(
                description: priority.description,
              ),
              if (priority.estimatedPHIGain > 0) ...[
                const SizedBox(height: 20),
                _PHIImpactCard(
                  estimatedPHIGain:
                      priority.estimatedPHIGain,
                ),
              ],
              if (priority.category != null) ...[
                const SizedBox(height: 20),
                _CategoryCard(
                  category: priority.category!,
                ),
              ],
              if (priority.requiredDocuments.isNotEmpty) ...[
                const SizedBox(height: 20),
                _RequiredDocumentsCard(
                  documents:
                      priority.requiredDocuments,
                ),
              ],
              if (widget.evidenceRepository != null &&
                  priority.requiredDocuments.isNotEmpty) ...[
                const SizedBox(height: 20),
                if (_isLoadingEvidence)
                  const _EvidenceLoadingCard()
                else
                  _EvidenceCard(
                    contexts: _evidenceContexts,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityHeader extends StatelessWidget {
  final DashboardPriority priority;

  const _PriorityHeader({
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          priority.title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        _PriorityBadge(
          priority: priority.priority,
        ),
      ],
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  final String description;

  const _DescriptionCard({
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'What needs your attention',
      child: Text(
        description,
        style: TextStyle(
          fontSize: 15,
          height: 1.45,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }
}

class _PHIImpactCard extends StatelessWidget {
  final int estimatedPHIGain;

  const _PHIImpactCard({
    required this.estimatedPHIGain,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Potential PHI impact',
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Text(
                '+$estimatedPHIGain',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 7),
              const Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Text(
                  'PHI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Potential improvement',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Completing this action may improve your '
            'Property Health Index by up to '
            '$estimatedPHIGain points based on the '
            'current assessment recommendation.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final PHSCategory category;

  const _CategoryCard({
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Property Health category',
      child: Text(
        category.displayName,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RequiredDocumentsCard
    extends StatelessWidget {
  final List<String> documents;

  const _RequiredDocumentsCard({
    required this.documents,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Required documents',
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          for (var index = 0;
              index < documents.length;
              index++) ...[
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding:
                      EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.description_outlined,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    documents[index],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (index < documents.length - 1)
              const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  final List<PriorityEvidenceContext> contexts;

  const _EvidenceCard({
    required this.contexts,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Evidence',
      child: contexts.isEmpty
          ? Text(
              'No matching evidence requirements '
              'were found for this priority.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.grey.shade700,
              ),
            )
          : Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                for (var index = 0;
                    index < contexts.length;
                    index++) ...[
                  _EvidenceRequirementItem(
                    context: contexts[index],
                  ),
                  if (index < contexts.length - 1)
                    const SizedBox(height: 14),
                ],
              ],
            ),
    );
  }
}

class _EvidenceRequirementItem
    extends StatelessWidget {
  final PriorityEvidenceContext context;

  const _EvidenceRequirementItem({
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  this.context.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _EvidenceStatusBadge(
                status: this.context.status,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            this.context.message,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceStatusBadge
    extends StatelessWidget {
  final EvidenceValidationStatus status;

  const _EvidenceStatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _backgroundColor,
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: _foregroundColor,
        ),
      ),
    );
  }

  String get _label {
    switch (status) {
      case EvidenceValidationStatus.missing:
        return 'MISSING';
      case EvidenceValidationStatus.provided:
        return 'PROVIDED';
      case EvidenceValidationStatus.satisfied:
        return 'SATISFIED';
      case EvidenceValidationStatus.needsReview:
        return 'NEEDS REVIEW';
      case EvidenceValidationStatus.rejected:
        return 'REJECTED';
    }
  }

  Color get _foregroundColor {
    switch (status) {
      case EvidenceValidationStatus.missing:
        return Colors.red.shade700;
      case EvidenceValidationStatus.provided:
        return Colors.orange.shade800;
      case EvidenceValidationStatus.satisfied:
        return Colors.green.shade700;
      case EvidenceValidationStatus.needsReview:
        return Colors.orange.shade800;
      case EvidenceValidationStatus.rejected:
        return Colors.red.shade700;
    }
  }

  Color get _backgroundColor {
    switch (status) {
      case EvidenceValidationStatus.missing:
        return Colors.red.shade50;
      case EvidenceValidationStatus.provided:
        return Colors.orange.shade50;
      case EvidenceValidationStatus.satisfied:
        return Colors.green.shade50;
      case EvidenceValidationStatus.needsReview:
        return Colors.orange.shade50;
      case EvidenceValidationStatus.rejected:
        return Colors.red.shade50;
    }
  }
}

class _EvidenceLoadingCard
    extends StatelessWidget {
  const _EvidenceLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'Evidence',
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 8,
        ),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final RecommendationPriority priority;

  const _PriorityBadge({
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _backgroundColor,
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: _foregroundColor,
        ),
      ),
    );
  }

  String get _label {
    switch (priority) {
      case RecommendationPriority.critical:
        return 'CRITICAL';
      case RecommendationPriority.high:
        return 'HIGH';
      case RecommendationPriority.medium:
        return 'MEDIUM';
      case RecommendationPriority.low:
        return 'LOW';
    }
  }

  Color get _foregroundColor {
    switch (priority) {
      case RecommendationPriority.critical:
        return Colors.red.shade700;
      case RecommendationPriority.high:
        return Colors.orange.shade800;
      case RecommendationPriority.medium:
        return Colors.blue.shade700;
      case RecommendationPriority.low:
        return Colors.green.shade700;
    }
  }

  Color get _backgroundColor {
    switch (priority) {
      case RecommendationPriority.critical:
        return Colors.red.shade50;
      case RecommendationPriority.high:
        return Colors.orange.shade50;
      case RecommendationPriority.medium:
        return Colors.blue.shade50;
      case RecommendationPriority.low:
        return Colors.green.shade50;
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}