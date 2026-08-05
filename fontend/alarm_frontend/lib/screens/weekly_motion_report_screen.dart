import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:alarm_frontend/components/weekly_bar_chart.dart';
import 'package:alarm_frontend/components/weekly_report_stat_row.dart';
import 'package:alarm_frontend/components/weekly_insight_row.dart';
import 'package:alarm_frontend/components/report_section_card.dart';

class WeeklyMotionReportScreen extends StatelessWidget {
  const WeeklyMotionReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const List<WeeklyChartItem> weeklyData = [
      WeeklyChartItem(label: 'Sun', value: 0.4),
      WeeklyChartItem(label: 'Mon', value: 0.7),
      WeeklyChartItem(label: 'Tue', value: 0.5),
      WeeklyChartItem(label: 'Wed', value: 0.9),
      WeeklyChartItem(label: 'Thu', value: 1.0),
      WeeklyChartItem(label: 'Fri', value: 0.6),
      WeeklyChartItem(label: 'Sat', value: 0.3),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Weekly Motion Report', style: AppTextStyles.heading),
            Text(
              'Nov 5 - Nov 12',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        titleSpacing: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 16),

          // Weekly Activity Overview Card
          ReportSectionCard(
            title: 'Weekly Activity Overview',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 14),
                WeeklyBarChart(
                  items: weeklyData,
                  highlightLabel: 'Thu',
                ),
                SizedBox(height: 14),
                WeeklyReportStatRow(label: 'Total Active Time:', value: '45h 30m'),
                WeeklyReportStatRow(label: 'Peak Day:', value: 'Thursday (8h 15m)'),
                WeeklyReportStatRow(label: 'Lowest Day:', value: 'Sunday (4h 30m)'),
                WeeklyReportStatRow(label: 'Average Daily:', value: '6h 30m'),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Weekly Sleep Summary Card
          ReportSectionCard(
            title: 'Weekly Sleep Summary',
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
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      '7h 12m',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const WeeklyReportStatRow(label: 'Total Sleep:', value: '56h 45m'),
                const WeeklyReportStatRow(label: 'Average Per Night:', value: '8h 06m'),
                const WeeklyReportStatRow(label: 'Deep Sleep:', value: '24h 30m'),
                const WeeklyReportStatRow(label: 'Light Sleep:', value: '30h 15m'),
                const WeeklyReportStatRow(label: 'Awake:', value: '2h 00m'),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Weekly Insights Card
          ReportSectionCard(
            title: 'Weekly Insights',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 12),
                WeeklyInsightRow(
                  icon: Icons.trending_up_rounded,
                  text: 'Activity increased by 12% compared to last week.',
                ),
                WeeklyInsightRow(
                  icon: Icons.bedtime_outlined,
                  text: 'Sleep consistency improved — 6 out of 7 nights above 7h.',
                ),
                WeeklyInsightRow(
                  icon: Icons.warning_amber_outlined,
                  text: 'Sunday activity was significantly lower than average.',
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
