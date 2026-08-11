import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class SyncStatusCard extends StatelessWidget {
  final String statusText;
  final VoidCallback? onTap;

  const SyncStatusCard({super.key, required this.statusText, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.sync_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Text(
              statusText,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color:
                  theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5) ??
                  AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
