import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class SleepProgressCard extends StatelessWidget {
  final String title;
  final String sleepTime;
  final String wakeTime;
  final double progressValue;
  final String durationLabel;

  const SleepProgressCard({
    super.key,
    required this.title,
    required this.sleepTime,
    required this.wakeTime,
    required this.progressValue,
    required this.durationLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              Text(
                sleepTime,
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppColors.textSecondary, 
                  fontSize: 13
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            wakeTime,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppColors.textSecondary, 
              fontSize: 12
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: theme.dividerColor,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                durationLabel,
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppColors.textSecondary, 
                  fontSize: 12
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}