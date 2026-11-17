
import 'package:flutter/material.dart';

import '../../core/evidence/evidence_requirement.dart';
import '../../core/localization/app_locale_controller.dart';
import '../../core/theme/homesure_tokens.dart';

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
              border: Border.all(color: HomeSureColors.champagneBronze),
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
                  requirement.label,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: HomeSureColors.champagneInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _typeLabel(languageCode),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: HomeSureColors.slateMuted,
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
