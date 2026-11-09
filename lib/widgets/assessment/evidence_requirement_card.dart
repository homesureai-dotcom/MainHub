
import 'package:flutter/material.dart';

import '../../core/evidence/evidence_requirement.dart';
import '../../core/localization/app_locale_controller.dart';

class EvidenceRequirementCard extends StatelessWidget {
  final EvidenceRequirement requirement;

  const EvidenceRequirementCard({
    super.key,
    required this.requirement,
  });

  IconData get _icon {
    if (requirement.isDocument) {
      return Icons.description_outlined;
    }

    if (requirement.isPhotograph) {
      return Icons.photo_camera_outlined;
    }

    if (requirement.isVideo) {
      return Icons.videocam_outlined;
    }

    return Icons.edit_note_outlined;
  }

  String _typeLabel(String languageCode) {
    const labels = <String, Map<String, String>>{
      'en': {
        'document': 'Document',
        'photograph': 'Photograph',
        'video': 'Video',
        'manual': 'Manual',
      },
      'hi': {
        'document': 'दस्तावेज़',
        'photograph': 'फोटोग्राफ',
        'video': 'वीडियो',
        'manual': 'मैन्युअल',
      },
      'kn': {
        'document': 'ದಾಖಲೆ',
        'photograph': 'ಛಾಯಾಚಿತ್ರ',
        'video': 'ವೀಡಿಯೊ',
        'manual': 'ಕೈಯಾರೆ ನಮೂದಿಸಿದ ಮಾಹಿತಿ',
      },
      'te': {
        'document': 'పత్రం',
        'photograph': 'ఫోటో',
        'video': 'వీడియో',
        'manual': 'మాన్యువల్',
      },
      'ta': {
        'document': 'ஆவணம்',
        'photograph': 'புகைப்படம்',
        'video': 'காணொளி',
        'manual': 'கைமுறை',
      },
      'ml': {
        'document': 'രേഖ',
        'photograph': 'ഫോട്ടോ',
        'video': 'വീഡിയോ',
        'manual': 'മാനുവൽ',
      },
    };

    final languageLabels = labels[languageCode] ?? labels['en']!;
    if (requirement.isDocument) {
      return languageLabels['document']!;
    }
    if (requirement.isPhotograph) {
      return languageLabels['photograph']!;
    }
    if (requirement.isVideo) {
      return languageLabels['video']!;
    }
    return languageLabels['manual']!;
  }

  @override
  Widget build(BuildContext context) {
    final languageCode =
        AppLocaleController.instance.languageCode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
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
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _icon,
              color: const Color(0xFF2563EB),
              size: 21,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  requirement.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _typeLabel(languageCode),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
