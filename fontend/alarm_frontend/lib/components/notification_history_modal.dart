import 'package:flutter/material.dart';
import 'package:alarm_frontend/services/notification_service.dart';
import 'package:alarm_frontend/models/notification_history_model.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:intl/intl.dart';

class NotificationHistoryModal extends StatelessWidget {
  const NotificationHistoryModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const NotificationHistoryModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recent Activity",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () async {
                    await NotificationService().clearHistory();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text(
                    "Clear All",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: FutureBuilder<List<NotificationHistoryModel>>(
              future: NotificationService().getHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final history = snapshot.data ?? [];
                if (history.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: theme.dividerColor,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "No recent notifications",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  itemCount: history.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return _buildNotificationItem(context, item);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationHistoryModel item,
  ) {
    final theme = Theme.of(context);
    final timeStr = DateFormat('HH:mm').format(item.timestamp);
    final dateStr = DateFormat('MMM d').format(item.timestamp);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon based on content
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(color: theme.dividerColor, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dateStr,
                  style: TextStyle(color: theme.dividerColor, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
