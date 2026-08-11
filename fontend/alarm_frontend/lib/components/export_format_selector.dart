import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class ExportFormatSelector extends StatelessWidget {
  final List<String> formats;
  final String selectedFormat;
  final ValueChanged<String> onFormatChanged;

  const ExportFormatSelector({
    super.key,
    required this.formats,
    required this.selectedFormat,
    required this.onFormatChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: formats.map((format) {
        final isSelected = selectedFormat == format;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GestureDetector(
              onTap: () => onFormatChanged(format),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : theme.dividerColor,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  format,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.black
                        : theme.textTheme.bodyMedium?.color?.withValues(
                                alpha: 0.7,
                              ) ??
                              AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
