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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Status',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('On-Device Keys: ',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppColors.textSecondary, 
                    fontSize: 13
                  )),
              const Text('System Managed',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'your keys for use on multiple devices.',
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppColors.textSecondary, 
              fontSize: 13
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: TextField(
              controller: controller,
              obscureText: true,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter New Passphrase',
                hintStyle: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5) ?? AppColors.textSecondary, 
                  fontSize: 13
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),
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
          Text(
            'Important: Keep this safe.\nPassphrase cannot be recovered.',
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5) ?? AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}