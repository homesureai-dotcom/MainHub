import 'package:flutter/material.dart';

class AddEvidenceButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AddEvidenceButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(
          Icons.add_a_photo_outlined,
          size: 21,
        ),
        label: const Text(
          'Add Evidence',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2563EB),
          side: const BorderSide(
            color: Color(0xFFBFDBFE),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}