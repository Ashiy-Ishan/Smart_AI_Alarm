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
            padding: const EdgeInsets.only(right: 16),
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
Upcoming_event_item.dart-com
import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class UpcomingEventItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;

  const UpcomingEventItem({
    super.key,
    required this.icon,
    required this.title,
    this.time = '',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (time.isNotEmpty)
            Text(
              time,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }
}

Calendar_grid.dart-com
import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class CalendarGrid extends StatelessWidget {
  final DateTime month;
  final int selectedDay;
  final ValueChanged<int> onDaySelected;

  const CalendarGrid({
    super.key,
    required this.month,
    required this.selectedDay,
    required this.onDaySelected,
  });

  int _daysInMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0).day;

  int _firstWeekdayOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1).weekday % 7;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = _daysInMonth(month);
    final firstWeekday = _firstWeekdayOfMonth(month);
    final totalCells = firstWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => SizedBox(
                      width: 36,
                      child: Center(
                        child: Text(
                          d,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),

          // Calendar grid
          ...List.generate(rows, (rowIdx) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (colIdx) {
                  final cellIdx = rowIdx * 7 + colIdx;
                  final day = cellIdx - firstWeekday + 1;
                  if (day < 1 || day > daysInMonth) {
                    return const SizedBox(width: 36, height: 36);
                  }
                  final isSelected = day == selectedDay;
                  return GestureDetector(
                    onTap: () => onDaySelected(day),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color: isSelected ? Colors.black : AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }
}


