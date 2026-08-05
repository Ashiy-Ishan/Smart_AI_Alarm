import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/components/message_notification_tile.dart';
import 'package:alarm_frontend/components/message_warning_box.dart';
import 'package:alarm_frontend/models/message_notification_model.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  int? _selectedIndex;
  bool _isConfirming = false;

  final List<MessageNotificationModel> _notifications = const [
    MessageNotificationModel(
      icon: Icons.delete_outline_rounded,
      label: 'Clear Activity History',
      message: 'This wil remove all your saved activity data, Are you sure want to clear history ?',
    ),
    MessageNotificationModel(
      icon: Icons.bedtime_outlined,
      label: 'Clear Motion Logs',
      message: 'This will remove all motion log data. Are you sure you want to clear motion logs?',
    ),
    MessageNotificationModel(
      icon: Icons.mail_outline_rounded,
      label: 'Clear  Email Cache',
      message: 'This will clear all cached email data. Are you sure you want to proceed?',
    ),
    MessageNotificationModel(
      icon: Icons.hub_outlined,
      label: 'Clear AI Predictions',
      message: 'This will remove all stored AI prediction data. Are you sure you want to clear predictions?',
    ),
  ];

  void _onCancel() => setState(() => _selectedIndex = null);

  Future<void> _onConfirm() async {
    if (_selectedIndex == null) return;
    setState(() => _isConfirming = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _isConfirming = false;
      _selectedIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom top back arrow row
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),

              const SizedBox(height: 16),

              // Title Row: Message (white) + Mail Icon (gold)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Message',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.mail_outline_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Notifications Card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...List.generate(_notifications.length, (i) {
                      final item = _notifications[i];
                      final isLast = i == _notifications.length - 1;
                      final isSelected = _selectedIndex == i;
                      return Column(
                        children: [
                          MessageNotificationTile(
                            notification: item,
                            isSelected: isSelected,
                            onTap: () => setState(() => _selectedIndex = i),
                          ),
                          if (!isLast)
                            const Divider(
                              height: 1,
                              color: AppColors.border,
                              indent: 16,
                              endIndent: 16,
                            ),
                        ],
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Warning message
              MessageWarningBox(
                message: _selectedIndex != null ? _notifications[_selectedIndex!].message : null,
                isVisible: _selectedIndex != null,
              ),

              const Spacer(),

              // Cancel & Confirm Buttons row
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _onCancel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A2D35),
                          side: const BorderSide(color: Color(0xFF5A5F6B), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _selectedIndex != null ? _onConfirm : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isConfirming
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Confirm',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
