import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:alarm_frontend/components/sync_status_card.dart';
import 'package:alarm_frontend/components/custom_switch_row.dart';
import 'package:alarm_frontend/components/settings_nav_row.dart';
import 'main_screen.dart';

class GmailScreen extends StatefulWidget {
  const GmailScreen({super.key});

  @override
  State<GmailScreen> createState() => _GmailScreenState();
}

class _GmailScreenState extends State<GmailScreen> {
  bool _priorityFilter = true;
  bool _inboxAlerts = true;
  bool _sentMail = true;

  void _goToProfile() {
    MainScreen.globalKey.currentState?.changeTab(4);
    Navigator.of(context).pop();
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      color: AppColors.border,
      indent: 16,
      endIndent: 16,
    );
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
            onPressed: _goToProfile,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Gmail', style: AppTextStyles.heading),
              const Text('alexr@gmail.com', style: AppTextStyles.subHeading),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Sync status card
            const SyncStatusCard(
              statusText: 'Synced just now',
            ),

            const SizedBox(height: 20),

            // Notification Settings section
            const Text(
              'Notification Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  CustomSwitchRow(
                    label: 'Priority Filter',
                    badge: '9 unread',
                    value: _priorityFilter,
                    onChanged: (v) => setState(() => _priorityFilter = v),
                  ),
                  _divider(),
                  CustomSwitchRow(
                    label: 'Inbox Alerts',
                    value: _inboxAlerts,
                    onChanged: (v) => setState(() => _inboxAlerts = v),
                  ),
                  _divider(),
                  CustomSwitchRow(
                    label: 'Sent Mail',
                    value: _sentMail,
                    onChanged: (v) => setState(() => _sentMail = v),
                  ),
                  _divider(),
                  const SettingsNavRow(
                    label: 'Spam',
                    badge: '9',
                  ),
                  _divider(),
                  const SettingsNavRow(
                    label: 'Trash',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Data Usage section
            const Text(
              'Data Usage',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Sync Data: 8MB',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
Sync_status_card.dart-com
import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class SyncStatusCard extends StatelessWidget {
  final String statusText;
  final VoidCallback? onTap;

  const SyncStatusCard({
    super.key,
    required this.statusText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.sync_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Text(
              statusText,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

Setting_nav_row.dart-com
import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class SettingsNavRow extends StatelessWidget {
  final String label;
  final String? badge;
  final VoidCallback? onTap;

  const SettingsNavRow({
    super.key,
    required this.label,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const Spacer(),
            if (badge != null) ...[
              Text(
                badge!,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

Custom_switch_row.dart-com
import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class CustomSwitchRow extends StatelessWidget {
  final String label;
  final String? badge;
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomSwitchRow({
    super.key,
    required this.label,
    this.badge,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Text(
              badge!,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
          const Spacer(),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.black,
              activeTrackColor: AppColors.primary,
              inactiveThumbColor: AppColors.textSecondary,
              inactiveTrackColor: AppColors.border,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}


