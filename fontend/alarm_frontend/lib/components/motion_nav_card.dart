import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class MotionStat {
  final String value;
  final String label;

  const MotionStat({required this.value, required this.label});
}

class MotionNavCard extends StatelessWidget {
  final String title;
  final List<MotionStat> stats;
  final VoidCallback onTap;

  const MotionNavCard({
    super.key,
    required this.title,
    required this.stats,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5) ?? AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...stats.map((stat) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Text(
                      stat.value,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      stat.label,
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}