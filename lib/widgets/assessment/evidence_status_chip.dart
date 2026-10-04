import 'package:flutter/material.dart';

import '../../core/evidence/evidence.dart';
import '../common/app_status_chip.dart';

class EvidenceStatusChip extends StatelessWidget {
  final EvidenceStatus status;

  const EvidenceStatusChip({
    super.key,
    required this.status,
  });

  String get _label {
    switch (status) {
      case EvidenceStatus.notProvided:
        return 'Not Provided';

      case EvidenceStatus.provided:
        return 'Provided';

      case EvidenceStatus.verified:
        return 'Verified';

      case EvidenceStatus.needsReview:
        return 'Needs Review';

      case EvidenceStatus.rejected:
        return 'Rejected';
    }
  }

  StatusType get _statusType {
    switch (status) {
      case EvidenceStatus.notProvided:
        return StatusType.info;

      case EvidenceStatus.provided:
        return StatusType.warning;

      case EvidenceStatus.verified:
        return StatusType.success;

      case EvidenceStatus.needsReview:
        return StatusType.warning;

      case EvidenceStatus.rejected:
        return StatusType.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppStatusChip(
      label: _label,
      status: _statusType,
    );
  }
}