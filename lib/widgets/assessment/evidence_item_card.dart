import 'package:flutter/material.dart';

import '../../core/evidence/evidence.dart';
import 'evidence_status_chip.dart';

class EvidenceItemCard extends StatelessWidget {
  final Evidence evidence;
  final ValueChanged<EvidenceStatus>? onStatusChange;
  final VoidCallback? onDelete;

  const EvidenceItemCard({
    super.key,
    required this.evidence,
    this.onStatusChange,
    this.onDelete,
  });

  IconData get _icon {
    switch (evidence.type) {
      case EvidenceType.document:
        return Icons.description_outlined;

      case EvidenceType.photograph:
        return Icons.photo_camera_outlined;

      case EvidenceType.video:
        return Icons.videocam_outlined;

      case EvidenceType.manual:
        return Icons.edit_note_outlined;
    }
  }

  String get _typeLabel {
    switch (evidence.type) {
      case EvidenceType.document:
        return 'Document';

      case EvidenceType.photograph:
        return 'Photograph';

      case EvidenceType.video:
        return 'Video';

      case EvidenceType.manual:
        return 'Manual';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActions =
        onStatusChange != null || onDelete != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _icon,
              color: const Color(0xFF475569),
              size: 21,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evidence.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _typeLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                EvidenceStatusChip(
                  status: evidence.status,
                ),
                if (hasActions) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (onStatusChange != null)
                        OutlinedButton.icon(
                          onPressed: () {
                            onStatusChange!(
                              _nextStatus(evidence.status),
                            );
                          },
                          icon: const Icon(
                            Icons.sync,
                            size: 17,
                          ),
                          label: const Text(
                            'Update Status',
                          ),
                        ),
                      if (onDelete != null)
                        OutlinedButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 17,
                          ),
                          label: const Text(
                            'Delete',
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  EvidenceStatus _nextStatus(EvidenceStatus status) {
    switch (status) {
      case EvidenceStatus.notProvided:
        return EvidenceStatus.provided;

      case EvidenceStatus.provided:
        return EvidenceStatus.needsReview;

      case EvidenceStatus.needsReview:
        return EvidenceStatus.verified;

      case EvidenceStatus.verified:
        return EvidenceStatus.verified;

      case EvidenceStatus.rejected:
        return EvidenceStatus.provided;
    }
  }
}