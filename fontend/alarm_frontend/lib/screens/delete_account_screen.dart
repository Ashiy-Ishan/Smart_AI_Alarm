import 'package:alarm_frontend/providers/user_provider.dart';
import 'package:alarm_frontend/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:alarm_frontend/components/warning_card.dart';
import 'package:alarm_frontend/components/icon_label_row.dart';
import 'package:provider/provider.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final TextEditingController _deleteController = TextEditingController();
  bool _isDeleting = false;

  bool get _canDelete => _deleteController.text.trim() == 'DELETE';

  final List<Map<String, dynamic>> _dataItems = const [
    {'icon': Icons.person_outline_rounded, 'label': 'Profile Information'},
    {'icon': Icons.history_rounded, 'label': 'Activity History'},
    {'icon': Icons.mail_outline_rounded, 'label': 'Connected Emails'},
    {'icon': Icons.calendar_today_outlined, 'label': 'Calendar Settings'},
    {'icon': Icons.lightbulb_outline, 'label': 'AI Insights'},
  ];

  Future<void> _onDeleteAccount() async {
    if (!_canDelete) return;

    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: const Text("Confirm Final Deletion"),
        content: Text(
          "Are you sure? This will permanently delete your account and all associated data.",
          style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8) ?? AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("DELETE", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        await Provider.of<UserProvider>(context, listen: false).deleteAccount(context);
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(AppRoutes.splash, (route) => false);
        }
      } catch (e) {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge?.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Delete Account', style: AppTextStyles.heading),
        titleSpacing: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 16),

          WarningCard(
            title: 'Delete Your Account',
            description: 'This action is permanent.\nAll your data will be erased.',
            borderColor: Colors.redAccent.withOpacity(0.3),
          ),

          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: List.generate(_dataItems.length, (i) {
                final item = _dataItems[i];
                return Column(
                  children: [
                    IconLabelRow(
                      icon: item['icon'] as IconData,
                      label: item['label'] as String,
                    ),
                    if (i != _dataItems.length - 1)
                      Divider(height: 1, color: theme.dividerColor, indent: 16, endIndent: 16),
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: 32),

          Text(
            "Type 'DELETE' to confirm:",
            style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),

          Container(
            height: 50,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _deleteController.text == 'DELETE' ? Colors.redAccent : theme.dividerColor,
              ),
            ),
            child: TextField(
              controller: _deleteController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.2),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              ),
            ),
          ),

          const SizedBox(height: 40),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: theme.dividerColor),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Cancel', 
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color, 
                        fontSize: 16, 
                        fontWeight: FontWeight.w600
                      )
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
                      backgroundColor: _canDelete ? Colors.redAccent : Colors.redAccent.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isDeleting
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Delete Account', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
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
