import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:alarm_frontend/components/calendar_grid.dart';
import 'package:alarm_frontend/components/upcoming_event_item.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _selectedDay = 2;
  final DateTime _currentMonth = DateTime(2026, 3);

  final List<Map<String, dynamic>> _upcomingEvents = [
    {
      'icon': Icons.directions_walk_outlined,
      'title': 'Workout',
      'time': '',
    },
    {
      'icon': Icons.sync_outlined,
      'title': 'Team Sync',
      'time': 'Tomorrow',
    },
    {
      'icon': Icons.call_outlined,
      'title': 'Client call',
      'time': 'Tomorrow',
    },
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
        title: const Text('Calendar', style: AppTextStyles.heading),
        titleSpacing: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(
              Icons.calendar_month_outlined,
              color: AppColors.primary,
              size: 26,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 4),

          // Month Label
          const Text(
            'March 2026',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 16),

          // Calendar Card (Grid)
          CalendarGrid(
            month: _currentMonth,
            selectedDay: _selectedDay,
            onDaySelected: (day) => setState(() => _selectedDay = day),
          ),

          const SizedBox(height: 20),

          // Upcoming Events Card
          Container(
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
                  'Upcoming Events',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                ..._upcomingEvents.map((event) {
                  return UpcomingEventItem(
                    icon: event['icon'] as IconData,
                    title: event['title'] as String,
                    time: event['time'] as String,
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
