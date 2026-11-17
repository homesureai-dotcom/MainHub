import 'package:flutter/material.dart';

import '../../core/evidence/evidence.dart';
import '../../core/theme/homesure_tokens.dart';
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HomeSureColors.midnightDetail,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: HomeSureColors.borderSlate,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: HomeSureColors.midnightInteractive,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _icon,
              color: HomeSureColors.champagneHighlight,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evidence.name,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: HomeSureColors.champagneInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _typeLabel,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: HomeSureColors.slateMuted,
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