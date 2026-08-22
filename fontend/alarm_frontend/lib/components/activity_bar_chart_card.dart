import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class ActivityBarChartCard extends StatelessWidget {
  final String dateText;
  final String startTime;
  final String endTime;
  final List<double> heights;

  const ActivityBarChartCard({
    super.key,
    required this.dateText,
    required this.startTime,
    required this.endTime,
    required this.heights,
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
          Text(
            dateText,
            style: TextStyle(
              color:
                  theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
                  AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: heights.map((h) {
                return Container(
                  width: 10,
                  height: 36 * h,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                startTime,
                style: TextStyle(
                  color:
                      theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.7,
                      ) ??
                      AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                endTime,
                style: TextStyle(
                  color:
                      theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.7,
                      ) ??
                      AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
