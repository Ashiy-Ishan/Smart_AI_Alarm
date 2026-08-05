import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:alarm_frontend/components/warning_card.dart';
import 'package:alarm_frontend/components/icon_label_row.dart';
import 'package:alarm_frontend/components/password_field.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final TextEditingController _deleteController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isDeleting = false;

  bool get _canDelete =>
      _deleteController.text.trim() == 'DELETE' &&
      _passwordController.text.isNotEmpty;

  final List<Map<String, dynamic>> _dataItems = const [
    {'icon': Icons.person_outline_rounded, 'label': 'Profile Information'},
    {'icon': Icons.history_rounded, 'label': 'Activity History'},
    {'icon': Icons.mail_outline_rounded, 'label': 'Connected Emails'},
    {'icon': Icons.calendar_today_outlined, 'label': 'Calendar Settings'},
    {'icon': Icons.lightbulb_outline, 'label': 'AI Insights'},
  ];

  Future<void> _onDeleteAccount() async {
    if (!_canDelete) return;
    setState(() => _isDeleting = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isDeleting = false);
  }

  void _onCancel() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Delete Account', style: AppTextStyles.heading),
        titleSpacing: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 16),

          // Warning Card
          WarningCard(
            title: 'Delete Your Account',
            description: 'This action is permanent.\nAll your data will be erased.',
            borderColor: AppColors.primary.withOpacity(0.5),
          ),

          const SizedBox(height: 14),

          // Data items card
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: List.generate(_dataItems.length, (i) {
                final item = _dataItems[i];
                final isLast = i == _dataItems.length - 1;
                return Column(
                  children: [
                    IconLabelRow(
                      icon: item['icon'] as IconData,
                      label: item['label'] as String,
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
            ),
          ),

          const SizedBox(height: 20),

          // Type DELETE label
          const Text(
            "Type 'DELETE' to confirm:",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // DELETE input
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _deleteController.text.isNotEmpty &&
                        _deleteController.text != 'DELETE'
                    ? Colors.redAccent
                    : _deleteController.text == 'DELETE'
                        ? AppColors.primary
                        : AppColors.border,
              ),
            ),
            child: TextField(
              controller: _deleteController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Password input
          PasswordField(
            controller: _passwordController,
          ),

          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _onCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A3F4B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
                    onPressed: _canDelete && !_isDeleting ? _onDeleteAccount : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canDelete
                          ? Colors.redAccent
                          : Colors.redAccent.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isDeleting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Delete Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
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
    );
  }
}
