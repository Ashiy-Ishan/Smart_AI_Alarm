import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class WeeklyChartItem {
  final String label;
  final double value;

  const WeeklyChartItem({required this.label, required this.value});
}

class WeeklyBarChart extends StatelessWidget {
  final List<WeeklyChartItem> items;
  final String highlightLabel;

  const WeeklyBarChart({
    super.key,
    required this.items,
    this.highlightLabel = 'Thu',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: items.map((d) {
            final isHighlighted = d.label == highlightLabel;
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 28,
                  height: 56 * d.value,
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items
              .map((d) => Text(
                    d.label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}