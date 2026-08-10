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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              shape: BoxShape.circle,
              border: Border.all(color: theme.dividerColor),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          if (time.isNotEmpty)
            Text(
              time,
              style: TextStyle(
                color:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
                    AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }
}
