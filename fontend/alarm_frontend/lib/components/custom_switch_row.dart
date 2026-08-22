import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class CustomSwitchRow extends StatelessWidget {
  final String label;
  final String? badge;
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomSwitchRow({
    super.key,
    required this.label,
    this.badge,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Text(
              badge!,
              style: TextStyle(
                color:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
                    AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          const Spacer(),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.black,
              activeTrackColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
