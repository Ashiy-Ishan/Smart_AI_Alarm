import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:alarm_frontend/components/activity_bar_chart_card.dart';
import 'package:alarm_frontend/components/sleep_progress_card.dart';
import 'package:alarm_frontend/components/motion_nav_card.dart';
import 'package:alarm_frontend/components/chevron_nav_tile.dart';
import 'activity_records_screen.dart';
import 'weekly_motion_report_screen.dart';
import 'export_motion_data_screen.dart';

class MotionLogScreen extends StatefulWidget {
  const MotionLogScreen({super.key});

  @override
  State<MotionLogScreen> createState() => _MotionLogScreenState();
}

class _MotionLogScreenState extends State<MotionLogScreen> {
  final List<double> _chartHeights = const [
    0.5,
    0.8,
    0.4,
    0.9,
    0.3,
    0.7,
    0.5,
    0.6,
    0.4,
    0.8,
    0.3,
    0.6,
  ];

  @override
  Widget build(BuildContext context) {
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
            Text('Motion log', style: AppTextStyles.heading),
            Text(
              'Mon, Nov 12',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        titleSpacing: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(
              Icons.wifi,
              color: AppColors.primary,
              size: 24,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 16),

          // Activity Chart Card
          ActivityBarChartCard(
            dateText: 'Mon, Nov 12',
            startTime: '07:15 AM',
            endTime: '09:15 AM',
            heights: _chartHeights,
          ),

          const SizedBox(height: 14),

          // Sleep Card
          const SleepProgressCard(
            title: 'Sleep',
            sleepTime: '10:04 PM',
            wakeTime: '10:03 PM',
            progressValue: 0.72,
            durationLabel: '7h 12m',
          ),

          const SizedBox(height: 14),

          // Activity Records nav card
          MotionNavCard(
            title: 'Activity Records',
            stats: const [
              MotionStat(value: '6h 45m', label: 'Move'),
              MotionStat(value: '8h 12m', label: 'Sleep'),
            ],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ActivityRecordsScreen()),
            ),
          ),

          const SizedBox(height: 14),

          // Weekly Motion Report nav tile
          ChevronNavTile(
            title: 'Weekly Motion Report',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WeeklyMotionReportScreen()),
            ),
          ),

          const SizedBox(height: 14),

          // Export Motion Data nav tile
          ChevronNavTile(
            title: 'Export Motion Data',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExportMotionDataScreen()),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}