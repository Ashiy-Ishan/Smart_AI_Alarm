import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class ChevronNavTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const ChevronNavTile({
    super.key,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5) ?? AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}