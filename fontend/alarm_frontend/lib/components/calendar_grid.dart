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
    final theme = Theme.of(context);
    final daysInMonth = _daysInMonth(month);
    final firstWeekday = _firstWeekdayOfMonth(month);
    final totalCells = firstWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => SizedBox(
              width: 36,
              child: Center(
                child: Text(
                  d,
                  style: TextStyle(
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
                          color: isSelected ? Colors.black : theme.textTheme.bodyLarge?.color,
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