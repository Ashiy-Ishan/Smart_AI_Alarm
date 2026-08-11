import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationControlScreen extends StatefulWidget {
  const NotificationControlScreen({super.key});

  @override
  State<NotificationControlScreen> createState() =>
      _NotificationControlScreenState();
}

class _NotificationControlScreenState extends State<NotificationControlScreen> {
  bool _meetingUpdates = true;
  bool _alarmAdjustments = true;
  bool _hardwareStatus = true;
  bool _healthInsights = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _meetingUpdates = prefs.getBool('notif_meetings') ?? true;
      _alarmAdjustments = prefs.getBool('notif_alarms') ?? true;
      _hardwareStatus = prefs.getBool('notif_hardware') ?? true;
      _healthInsights = prefs.getBool('notif_health') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notification Control', style: AppTextStyles.heading),
        titleSpacing: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  "Select which activities should trigger background notifications, even when the app is closed.",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                _buildControlCard(
                  title: "Meeting Updates",
                  subtitle:
                      "Notify me about rescheduled or canceled meetings found in Gmail.",
                  icon: Icons.event_note,
                  value: _meetingUpdates,
                  onChanged: (v) {
                    setState(() => _meetingUpdates = v);
                    _saveSetting('notif_meetings', v);
                  },
                ),
                const SizedBox(height: 16),
                _buildControlCard(
                  title: "Alarm Adjustments",
                  subtitle:
                      "Notify when AI changes alarm buffer based on weather or traffic.",
                  icon: Icons.alarm_on,
                  value: _alarmAdjustments,
                  onChanged: (v) {
                    setState(() => _alarmAdjustments = v);
                    _saveSetting('notif_alarms', v);
                  },
                ),
                const SizedBox(height: 16),
                _buildControlCard(
                  title: "Hardware Status",
                  subtitle:
                      "Alert me if the Bedside Hub goes offline or encounters an error.",
                  icon: Icons.router_outlined,
                  value: _hardwareStatus,
                  onChanged: (v) {
                    setState(() => _hardwareStatus = v);
                    _saveSetting('notif_hardware', v);
                  },
                ),
                const SizedBox(height: 16),
                _buildControlCard(
                  title: "Daily Insights",
                  subtitle:
                      "Receive a morning summary of your sleep and activity patterns.",
                  icon: Icons.lightbulb_outline,
                  value: _healthInsights,
                  onChanged: (v) {
                    setState(() => _healthInsights = v);
                    _saveSetting('notif_health', v);
                  },
                ),
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    "Background services use low-power scanning to preserve battery.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildControlCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
