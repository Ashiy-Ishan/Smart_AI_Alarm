import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';

import '../../services/api_service.dart';

class AlarmRingingScreen extends StatefulWidget {
  final String macAddress;
  final String hiddenUid;

  const AlarmRingingScreen({
    super.key,
    required this.macAddress,
    required this.hiddenUid,
  });

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen> {
  static int globalSnoozeCount = 0;
  late final DateTime _alarmOpenedAt;

  @override
  void initState() {
    super.initState();
    _alarmOpenedAt = DateTime.now();
  }

  void _stopAlarm(BuildContext context) async {
    Navigator.of(context).popUntil((route) => route.settings.name != 'alarm_ringing');
    try {
      FirebaseDatabase.instance
          .ref()
          .child('Users')
          .child(widget.hiddenUid)
          .child('Devices')
          .child(widget.macAddress)
          .update({
            'MobileStop': true, 
            'AlarmStatus': 'IDLE',
            'LastStopAt': ServerValue.timestamp,
          });

      // AI Data Collection
      final now = DateTime.now();
      final unlockDelayMinutes = now.difference(_alarmOpenedAt).inSeconds / 60.0;

      await ApiService.post('/alarms/outcome', {
        'user_id': widget.hiddenUid,
        'alarm_id': 'alarm_${now.millisecondsSinceEpoch}',
        'trigger_time': now.toUtc().toIso8601String(),
        'snooze_count': globalSnoozeCount,
        'unlock_delay': unlockDelayMinutes,
        'success': 1,
      });

      // Reset snooze count for the next day
      globalSnoozeCount = 0;
    } catch (e) {
      debugPrint("Error stopping alarm: $e");
    }
  }

  void _snoozeAlarm(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.settings.name != 'alarm_ringing');
    try {
      globalSnoozeCount++;
      
      final ref = FirebaseDatabase.instance
          .ref()
          .child('Users')
          .child(widget.hiddenUid)
          .child('Devices')
          .child(widget.macAddress);

      DateTime now = DateTime.now();
      DateTime snoozeTime = now.add(const Duration(minutes: 5));
      String snoozeTimeStr = DateFormat("HH:mm").format(snoozeTime);

      ref.update({
        'SnoozeUntil': snoozeTimeStr, 
        'AlarmStatus': 'SNOOZE',
        'MobileStop': true, 
      });
    } catch (e) {
      debugPrint("Error snoozing alarm: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withValues(alpha: 0.2),
                theme.scaffoldBackgroundColor,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "WAKE UP!",
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                DateFormat("HH:mm").format(DateTime.now()),
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 80,
                  fontWeight: FontWeight.w200,
                ),
              ),

              const SizedBox(height: 40),
              SizedBox(
                height: 250,
                child: Lottie.asset('assets/lotties/alarm.json'),
              ),
              const SizedBox(height: 60),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _snoozeAlarm(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.cardColor,
                          foregroundColor: theme.textTheme.bodyLarge?.color,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                          side: BorderSide(color: theme.dividerColor),
                        ),
                        child: const Text(
                          "SNOOZE",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _stopAlarm(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "STOP",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
