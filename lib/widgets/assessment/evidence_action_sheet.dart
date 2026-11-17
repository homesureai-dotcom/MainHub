import 'package:flutter/material.dart';

import '../../core/evidence/evidence.dart';
import '../../core/theme/homesure_tokens.dart';

class EvidenceActionSheet {
  const EvidenceActionSheet._();

  static Future<EvidenceType?> show(
    BuildContext context,
  ) {
    return showModalBottomSheet<EvidenceType>(
      context: context,
      backgroundColor: HomeSureColors.midnightCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        side: BorderSide(color: HomeSureColors.borderSlate),
      ),
      builder: (_) {
        return const _EvidenceActionSheetContent();
      },
    );
  }
}

class _EvidenceActionSheetContent extends StatelessWidget {
  const _EvidenceActionSheetContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          24,
          20,
          24,
          24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: HomeSureColors.borderInput,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Add Evidence',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: HomeSureColors.champagneInk,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Choose how you want to provide supporting evidence.',
              style: TextStyle(
                fontSize: 14,
                color: HomeSureColors.slateMuted,
                height: 1.45,
              ),
            ),

            const SizedBox(height: 20),

            _EvidenceAction(
              icon: Icons.description_outlined,
              title: 'Document',
              subtitle: 'Add a supporting document',
              onTap: () {
                Navigator.pop(
                  context,
                  EvidenceType.document,
                );
              },
            ),

            const SizedBox(height: 10),

            _EvidenceAction(
              icon: Icons.photo_camera_outlined,
              title: 'Photograph',
              subtitle: 'Add a supporting photograph',
              onTap: () {
                Navigator.pop(
                  context,
                  EvidenceType.photograph,
                );
              },
            ),

            const SizedBox(height: 10),

            _EvidenceAction(
              icon: Icons.videocam_outlined,
              title: 'Video',
              subtitle: 'Add a supporting video',
              onTap: () {
                Navigator.pop(
                  context,
                  EvidenceType.video,
                );
              },
            ),

            const SizedBox(height: 10),

            _EvidenceAction(
              icon: Icons.edit_note_outlined,
              title: 'Manual Entry',
              subtitle: 'Add evidence details manually',
              onTap: () {
                Navigator.pop(
                  context,
                  EvidenceType.manual,
                );
              },
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvidenceAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _EvidenceAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: HomeSureColors.midnightDetail,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: HomeSureColors.borderSlate,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: HomeSureColors.midnightSand,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: HomeSureColors.champagneBronze),
              ),
              child: Icon(
                icon,
                color: HomeSureColors.champagneHighlight,
                size: 21,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: HomeSureColors.champagneInk,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: HomeSureColors.slateMuted,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color: HomeSureColors.champagneHighlight,
            ),
          ],
        ),
      ),
    );
  }
}