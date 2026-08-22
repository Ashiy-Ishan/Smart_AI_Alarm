import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class HubMotionRow extends StatelessWidget {
  final String time;
  final String event;

  const HubMotionRow({super.key, required this.time, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          time,
          style: TextStyle(
            color:
                theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
                AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          event,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
