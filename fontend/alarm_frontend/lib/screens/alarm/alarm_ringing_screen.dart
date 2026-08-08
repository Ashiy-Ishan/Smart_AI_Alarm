import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';

class AlarmRingingScreen extends StatelessWidget {
  final String macAddress;
  final String hiddenUid;

  const AlarmRingingScreen({
    super.key,
    required this.macAddress,
    required this.hiddenUid,
  });

  void _stopAlarm() {
    // stop the alarm in cloud - the background listener will automatically close this screen
    FirebaseDatabase.instance
        .ref()
        .child('Users')
        .child(hiddenUid)
        .child('Devices')
        .child(macAddress)
        .update({
          'MobileStop': true, 
          'AlarmStatus': 'IDLE'
        });
  }

  void _snoozeAlarm() async {
    final ref = FirebaseDatabase.instance
        .ref()
        .child('Users')
        .child(hiddenUid)
        .child('Devices')
        .child(macAddress);

    DateTime now = DateTime.now();
    DateTime snoozeTime = now.add(const Duration(minutes: 5));
    String snoozeTimeStr = DateFormat("HH:mm").format(snoozeTime);

    // update snooze in cloud - listener will handle closing the screen
    await ref.update({
      'SnoozeUntil': snoozeTimeStr,
      'AlarmStatus': 'SNOOZE'
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // user cannot dismiss this screen with back button
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withOpacity(0.2),
                AppColors.background,
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
                style: const TextStyle(
                  color: AppColors.textPrimary,
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
                        onPressed: _snoozeAlarm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.card,
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text("SNOOZE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _stopAlarm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text("STOP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
