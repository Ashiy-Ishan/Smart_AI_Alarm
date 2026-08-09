import 'package:alarm_frontend/components/glow_bg.dart';
import 'package:alarm_frontend/components/primary_button.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:alarm_frontend/services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StopAlarmScreen extends StatefulWidget {
  final String alarmId;
  final String timeText;
  final String dateText;
  final VoidCallback? onSnooze;
  final VoidCallback? onStop;

  const StopAlarmScreen({
    super.key,
    required this.alarmId,
    this.timeText = '06:18',
    this.dateText = 'Nov 12 Monday',
    this.onSnooze,
    this.onStop,
  });

  @override
  State<StopAlarmScreen> createState() => _StopAlarmScreenState();
}

class _StopAlarmScreenState extends State<StopAlarmScreen> {
  int _snoozeCount = 0;

  Future<void> _sendAlarmOutcome() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User is not logged in')));

      return;
    }

    try {
      await ApiService.post('/alarms/outcome', {
        'user_id': user.uid,
        'alarm_id': widget.alarmId,
        'trigger_time': DateTime.now().toUtc().toIso8601String(),

        'snooze_count': _snoozeCount,
        'unlock_delay': 0.0,
        'success': 1,

        'weather_severity': 0.0,
        'traffic_condition': 0.0,
        'room_temp': 27.0,

        'alarm_type': 'custom',
        'is_holiday': 0,
        'buffer_minutes': 0.0,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarm outcome saved to backend')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save alarm outcome: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const GlowBackground(
            size: 300,
            blurRadius: 130,
            spreadRadius: 18,
            alignment: Alignment.center,
            glowColor: Color(0x36D9B56D),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(
                children: [
                  const SizedBox(height: 18),

                  Text(
                    'Alarm',
                    style: AppTextStyles.subHeading.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0x8FB8B8B8),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Text(
                    widget.timeText,
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 84,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      height: 1,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    widget.dateText,
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 80),

                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const GlowBackground(
                        size: 180,
                        blurRadius: 95,
                        spreadRadius: 12,
                        alignment: Alignment.center,
                        glowColor: Color(0x52D9B56D),
                      ),
                      Container(
                        width: 170,
                        height: 170,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.alarm,
                          size: 110,
                          color: AppColors.primary,
                          shadows: [
                            Shadow(color: Color(0x59D9B56D), blurRadius: 24),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 150),

                  PrimaryButton(
                    text: 'Snooze',
                    onPressed: () {
                      setState(() {
                        _snoozeCount++;
                      });

                      if (widget.onSnooze != null) {
                        widget.onSnooze!();
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Alarm snoozed $_snoozeCount time(s)'),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 55),

                  SizedBox(
                    width: 190,
                    height: 60,
                    child: OutlinedButton(
                      onPressed: () async {
                        if (widget.onStop != null) {
                          widget.onStop!();
                        }

                        await _sendAlarmOutcome();
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF23262F),
                        side: const BorderSide(
                          color: AppColors.primary,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        'Stop',
                        style: AppTextStyles.button.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
