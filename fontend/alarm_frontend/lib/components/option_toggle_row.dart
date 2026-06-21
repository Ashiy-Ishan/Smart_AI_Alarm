// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class OptionToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const OptionToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
        ),
        Transform.scale(
          scale: 0.85,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.black,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: AppColors.border,
          ),
        ),
      ],
    );
  }
}