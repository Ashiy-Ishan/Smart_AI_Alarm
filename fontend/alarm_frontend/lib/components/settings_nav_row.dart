import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class SettingsNavRow extends StatelessWidget {
  final String label;
  final String? badge;
  final VoidCallback? onTap;

  const SettingsNavRow({
    super.key,
    required this.label,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            const Spacer(),
            if (badge != null) ...[
              Text(
                badge!,
                style: TextStyle(
                  color:
                      theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.7,
                      ) ??
                      AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(
              Icons.chevron_right,
              color:
                  theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5) ??
                  AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
