// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class KeyStatusCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isUpdating;
  final VoidCallback onUpdatePassphrase;

  const KeyStatusCard({
    super.key,
    required this.controller,
    required this.isUpdating,
    required this.onUpdatePassphrase,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Status',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: const [
              Text('On-Device Keys: ',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text('System Managed',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'your keys for use on multiple devices.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          // Passphrase input
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: controller,
              obscureText: true,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Enter New Passphrase',
                hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Update Passphrase button
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: isUpdating ? null : onUpdatePassphrase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  elevation: 0,
                ),
                child: isUpdating
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
                    : const Text(
                  'Update Passphrase',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Important: Keep this safe.\nPassphrase cannot be recovered.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}