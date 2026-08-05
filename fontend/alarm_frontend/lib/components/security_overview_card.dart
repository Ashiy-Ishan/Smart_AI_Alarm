import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class SecurityOverviewCard extends StatelessWidget {
  final bool isEncryptionActive;

  const SecurityOverviewCard({
    super.key,
    this.isEncryptionActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Shield icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.primary,
              size: 42,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Data Security Overview',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your personal data are protected\nwith end-to-end encryption.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Encryption Status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: AppColors.primary,
                  size: 14,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Encryption Status: ',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              Text(
                isEncryptionActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: isEncryptionActive ? AppColors.primary : Colors.redAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
