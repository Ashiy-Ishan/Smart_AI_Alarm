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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateText,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              Text(
                endTime,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}