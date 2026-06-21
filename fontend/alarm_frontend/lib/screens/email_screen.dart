import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:alarm_frontend/components/custom_search_bar.dart';
import 'package:alarm_frontend/components/pill_toggle_button.dart';
import 'package:alarm_frontend/components/email_card.dart';
import 'package:alarm_frontend/models/email_model.dart';
import 'main_screen.dart';

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showInbox = true;

  final List<EmailModel> _emails = const [
    EmailModel(
      name: 'Mark Urgent',
      time: 'tomorrow 9 AM',
      preview: 'Review presentation',
      isNew: true,
      isUrgent: true,
      icon: Icons.notifications_active_outlined,
    ),
    EmailModel(
      name: 'Sarah',
      time: '1h',
      preview: 'Update: 10AM',
      isNew: false,
      isUrgent: false,
      icon: Icons.lightbulb_outline,
    ),
  ];

  final List<Map<String, dynamic>> _folders = [
    {'label': 'Important', 'icon': Icons.star_border_rounded, 'count': null},
    {'label': 'Unread', 'icon': Icons.mail_outline_rounded, 'count': null},
    {'label': 'Sent Mail', 'icon': Icons.send_outlined, 'count': null},
    {'label': 'Drafts', 'icon': Icons.edit_note_rounded, 'count': 9},
    {'label': 'Spam', 'icon': Icons.warning_amber_rounded, 'count': null},
    {'label': 'Trash', 'icon': Icons.delete_outline_rounded, 'count': null},
  ];

  void _goToSchedule() {
    MainScreen.globalKey.currentState?.changeTab(1);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _goToSchedule,
          ),
          title: Text('Email', style: AppTextStyles.heading),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(
                Icons.mail_outline_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            CustomSearchBar(
              controller: _searchController,
              hintText: 'Search email...',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                PillToggleButton(
                  label: 'Inbox',
                  isActive: _showInbox,
                  onTap: () => setState(() => _showInbox = true),
                ),
                const SizedBox(width: 10),
                PillToggleButton(
                  label: 'Unread',
                  isActive: !_showInbox,
                  onTap: () => setState(() => _showInbox = false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._emails.map((email) {
              return EmailCard(
                email: email,
              );
            }),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: _folders.asMap().entries.map((entry) {
                  final i = entry.key;
                  final folder = entry.value;
                  return Column(
                    children: [
                      ListTile(
                        dense: true,
                        leading: Icon(
                          folder['icon'] as IconData,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        title: Text(
                          folder['label'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (folder['count'] != null)
                              Text(
                                '${folder['count']}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                          ],
                        ),
                        onTap: () {},
                      ),
                      if (i < _folders.length - 1)
                        const Divider(
                          height: 1,
                          color: AppColors.border,
                          indent: 16,
                          endIndent: 16,
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {},
                child: Text('Mark All Read', style: AppTextStyles.button),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}