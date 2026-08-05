import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class HubStatusCard extends StatelessWidget {
  final bool isOnline;
  final String statusText;

  const HubStatusCard({
    super.key,
    this.isOnline = true,
    this.statusText = 'Hub online Status',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFF4CAF50) : Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}