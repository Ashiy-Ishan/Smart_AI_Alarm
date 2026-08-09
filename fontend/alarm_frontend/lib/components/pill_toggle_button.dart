import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class PillToggleButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const PillToggleButton({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? theme.cardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.dividerColor),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isActive 
                ? theme.textTheme.bodyLarge?.color 
                : theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}