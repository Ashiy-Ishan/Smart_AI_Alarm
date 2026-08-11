import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:alarm_frontend/components/activity_section_card.dart';
import 'package:alarm_frontend/components/activity_bar_chart.dart';
import 'package:alarm_frontend/components/activity_stat_line.dart';

class ActivityRecordsScreen extends StatelessWidget {
  const ActivityRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge?.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Activity Records', style: AppTextStyles.heading),
            Text(
              'Mon, Nov 12',
              style: TextStyle(
                color:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
                    AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        titleSpacing: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 16),

          ActivitySectionCard(
            title: 'Movement Analysis',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const SizedBox(height: 44, child: ActivityBarChart()),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '07:15 AM',
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
                      '09:15 AM',
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
                const SizedBox(height: 14),
                const ActivityStatLine(
                  label: 'Total Active Time:',
                  value: '6h 45m',
                ),
                const ActivityStatLine(label: 'Morning:', value: '2h 30m'),
                const ActivityStatLine(label: 'Afternoon:', value: '3h 15m'),
                const ActivityStatLine(label: 'Evening:', value: '1h 00m'),
              ],
            ),
          ),

          const SizedBox(height: 14),

          ActivitySectionCard(
            title: 'Sleep Analysis',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.72,
                          backgroundColor: theme.dividerColor,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '7h 12m',
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
                const SizedBox(height: 14),
                const ActivityStatLine(label: 'Total Sleep:', value: '8h 12m'),
                const ActivityStatLine(label: 'Deep Sleep:', value: '3h 45m'),
                const ActivityStatLine(label: 'Light Sleep:', value: '4h 27m'),
                const ActivityStatLine(label: 'Awake:', value: '14m'),
              ],
            ),
          ),

          const SizedBox(height: 14),

          ActivitySectionCard(
            title: 'Daily Summary',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const ActivityStatLine(label: 'Motion Events:', value: '48'),
                const ActivityStatLine(label: 'Active Periods:', value: '6'),
                const ActivityStatLine(label: 'Rest Periods:', value: '3'),
                const ActivityStatLine(
                  label: 'Peak Activity:',
                  value: '08:30 AM',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
