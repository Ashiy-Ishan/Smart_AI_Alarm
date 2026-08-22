import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class ActivityStatLine extends StatelessWidget {
  final String label;
  final String value;
  final double bottomPadding;

  const ActivityStatLine({
    super.key,
    required this.label,
    required this.value,
    this.bottomPadding = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 6),
          Text(
            value,
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
