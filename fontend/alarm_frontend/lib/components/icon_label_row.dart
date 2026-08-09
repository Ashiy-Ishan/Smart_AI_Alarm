import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class IconLabelRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;

  const IconLabelRow({
    super.key,
    required this.icon,
    required this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
