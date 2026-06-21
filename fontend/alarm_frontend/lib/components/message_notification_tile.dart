// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/models/message_notification_model.dart';

class MessageNotificationTile extends StatelessWidget {
  final MessageNotificationModel notification;
  final bool isSelected;
  final VoidCallback onTap;

  const MessageNotificationTile({
    super.key,
    required this.notification,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: isSelected ? AppColors.primary.withOpacity(0.04) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              notification.icon,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                notification.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFFC5C6CA),
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}