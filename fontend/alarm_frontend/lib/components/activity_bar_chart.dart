// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class ActivityBarChart extends StatelessWidget {
  final List<double> heights;
  final double maxHeight;
  final double barWidth;

  const ActivityBarChart({
    super.key,
    this.heights = const [0.5, 0.8, 0.4, 0.9, 0.3, 0.7, 0.5, 0.6, 0.4, 0.8, 0.3, 0.6],
    this.maxHeight = 44.0,
    this.barWidth = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: heights.map((h) {
        return Container(
          width: barWidth,
          height: maxHeight * h,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }).toList(),
    );
  }
}