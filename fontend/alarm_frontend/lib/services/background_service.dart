import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:alarm_frontend/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:alarm_frontend/services/google_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AppBackgroundService {
  static Future<void> requestOptimizationPermission() async {
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'alarm_background_service',
      'Alarm Service',
      description: 'Keeps the alarm system and gmail scanner active',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'alarm_background_service',
        initialNotificationTitle: 'Smart Alarm Scanner',
        initialNotificationContent: 'Monitoring for important updates...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    await service.startService();
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Background Firebase Init failed: $e");
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Listen to Firebase for Real-time Device Status updates
  bool isDeviceSubscribed = false;
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (user != null && !isDeviceSubscribed) {
      isDeviceSubscribed = true;
      final hiddenUid = user.uid;
      final devicesSnapshot = await FirebaseDatabase.instance
          .ref()
          .child('Users')
          .child(hiddenUid)
          .child('Devices')
          .get();

      if (devicesSnapshot.exists) {
        final devices = devicesSnapshot.value as Map<dynamic, dynamic>;
        if (devices.isNotEmpty) {
          final mac = devices.keys.first.toString();

          FirebaseDatabase.instance
              .ref()
              .child('Users')
              .child(hiddenUid)
              .child('Devices')
              .child(mac)
              .onValue
              .listen((event) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.reload();
                final bool showDeviceStatus =
                    prefs.getBool('notif_device_status') ?? false;

                if (service is AndroidServiceInstance &&
                    await service.isForegroundService()) {
                  final FlutterLocalNotificationsPlugin
                  flutterLocalNotificationsPlugin =
                      FlutterLocalNotificationsPlugin();
                  if (showDeviceStatus && event.snapshot.value != null) {
                    final data = event.snapshot.value as Map<dynamic, dynamic>;
                    final temp = data['Temperature']?.toString() ?? '--';
                    final hum = data['Humidity']?.toString() ?? '--';
                    final light = data['LightStatus']?.toString() ?? '--';
                    final status = data['AlarmStatus']?.toString() ?? 'IDLE';

                    flutterLocalNotificationsPlugin.show(
                      id: 888,
                      title: 'Device Status: $status',
                      body: 'Temp: $temp°C | Hum: $hum% | Light: $light',
                      notificationDetails: const NotificationDetails(
                        android: AndroidNotificationDetails(
                          'alarm_background_service',
                          'Alarm Service',
                          icon: '@mipmap/ic_launcher',
                          ongoing: true,
                        ),
                      ),
                    );
                  } else {
                    flutterLocalNotificationsPlugin.show(
                      id: 888,
                      title: 'Smart Alarm Scanner',
                      body: 'Monitoring for important updates...',
                      notificationDetails: const NotificationDetails(
                        android: AndroidNotificationDetails(
                          'alarm_background_service',
                          'Alarm Service',
                          icon: '@mipmap/ic_launcher',
                          ongoing: true,
                        ),
                      ),
                    );
                  }
                }
              });
        }
      }
    }
  });

  // Background Loop
  Timer.periodic(const Duration(minutes: 15), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.reload();
        final bool monitorMeetings = prefs.getBool('notif_meetings') ?? true;

        if (monitorMeetings) {
          try {
            // Perform silent sync for professional gmails
            await GoogleSyncService().fetchPriorityMeetingEmails();
            service.invoke('update', {
              "status": "synced",
              "time": DateTime.now().toIso8601String(),
            });
          } catch (e) {
            debugPrint("Background Gmail Scan Failed: $e");
          }
        }
      }
    }
  });

  Timer.periodic(const Duration(seconds: 30), (timer) async {
    service.invoke('update', {"status": "active"});
  });
}
