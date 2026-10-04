import 'package:flutter/material.dart';

import '../../core/evidence/evidence.dart';

class EvidenceActionSheet {
  const EvidenceActionSheet._();

  static Future<EvidenceType?> show(
    BuildContext context,
  ) {
    return showModalBottomSheet<EvidenceType>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
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
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Add Evidence',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Choose how you want to provide supporting evidence.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blueGrey,
                height: 1.5,
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
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
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
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color: Colors.blueGrey,
            ),
          ],
        ),
      ),
    );
  }
}