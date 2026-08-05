// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class CustomCheckboxTile extends StatelessWidget {
  final String label;
  final bool isChecked;
  final ValueChanged<bool> onChanged;
  final double size;
  final double borderRadius;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const CustomCheckboxTile({
    super.key,
    required this.label,
    required this.isChecked,
    required this.onChanged,
    this.size = 20.0,
    this.borderRadius = 4.0,
    this.fontSize = 14.0,
    this.padding = const EdgeInsets.only(bottom: 10),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isChecked),
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: isChecked
                    ? AppColors.primary.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: isChecked ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: isChecked
                  ? Icon(Icons.check, color: AppColors.primary, size: size - 7)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: isChecked ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: fontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}