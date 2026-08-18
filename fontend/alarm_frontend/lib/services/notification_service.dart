import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:alarm_frontend/models/notification_history_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(
  NotificationResponse response,
) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Background Firebase Init failed: $e");
  }

  final String? actionId = response.actionId;
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final hiddenUid = user.uid;
  final devicesSnapshot = await FirebaseDatabase.instance
      .ref()
      .child('Users')
      .child(hiddenUid)
      .child('Devices')
      .get();

  if (devicesSnapshot.exists) {
    final devices = devicesSnapshot.value as Map<dynamic, dynamic>;
    if (devices.isEmpty) return;
    final mac = devices.keys.first.toString();
    final ref = FirebaseDatabase.instance
        .ref()
        .child('Users')
        .child(hiddenUid)
        .child('Devices')
        .child(mac);

    if (actionId == 'stop_action') {
      await ref.update({
        'MobileStop': true,
        'AlarmStatus': 'IDLE',
        'LastStopAt': ServerValue.timestamp,
      });
    } else if (actionId == 'snooze_action') {
      String snoozeTimeStr = DateFormat(
        "HH:mm",
      ).format(DateTime.now().add(const Duration(minutes: 5)));
      await ref.update({
        'SnoozeUntil': snoozeTimeStr,
        'AlarmStatus': 'SNOOZE',
        'MobileStop': true,
      });
    }
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'alarm_high_importance',
    'High Importance Alarm Notifications',
    description: 'Channel for critical alarm alerts',
    importance: Importance.max,
    playSound: true,
  );

  Future<void> initialize() async {
    try {
      await _fcm.requestPermission(alert: true, badge: true, sound: true);

      const AndroidInitializationSettings androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosInit =
          DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
        onDidReceiveBackgroundNotificationResponse:
            onDidReceiveBackgroundNotificationResponse,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _addToHistory(
          message.notification?.title ?? "Notification",
          message.notification?.body ?? "",
        );
        _showLocalNotification(message);
      });

      if (!kIsWeb) {
        String? token = await _fcm.getToken().catchError((e) {
          debugPrint("FCM Token retrieval failed: $e");
          return null;
        });
        if (token != null) debugPrint("FCM Token: $token");
      }
    } catch (e) {
      debugPrint("Notification Service Init Warning: $e");
    }
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    bool isAlarm = false,
  }) async {
    await _addToHistory(title, body);

    final List<AndroidNotificationAction>? actions = isAlarm
        ? [
            const AndroidNotificationAction(
              'snooze_action',
              'SNOOZE',
              showsUserInterface: true,
            ),
            const AndroidNotificationAction(
              'stop_action',
              'STOP',
              showsUserInterface: true,
            ),
          ]
        : null;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: isAlarm,
          category: isAlarm ? AndroidNotificationCategory.alarm : null,
          icon: '@mipmap/ic_launcher',
          actions: actions,
        );

    await _localNotifications.show(
      id: isAlarm ? 999 : DateTime.now().millisecond % 100000,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  // --- Notification History Logic ---

  Future<void> _addToHistory(String title, String body) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyStrings =
        prefs.getStringList('notif_history') ?? [];

    final newItem = NotificationHistoryModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
    );

    historyStrings.insert(0, jsonEncode(newItem.toJson()));

    if (historyStrings.length > 20) {
      historyStrings.removeRange(20, historyStrings.length);
    }

    await prefs.setStringList('notif_history', historyStrings);
  }

  Future<List<NotificationHistoryModel>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyStrings =
        prefs.getStringList('notif_history') ?? [];
    return historyStrings
        .map((s) => NotificationHistoryModel.fromJson(jsonDecode(s)))
        .toList();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notif_history');
  }

  // --- Existing Logic ---

  void _onDidReceiveNotificationResponse(NotificationResponse response) async {
    final String? actionId = response.actionId;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final hiddenUid = user.uid;
    final devicesSnapshot = await FirebaseDatabase.instance
        .ref()
        .child('Users')
        .child(hiddenUid)
        .child('Devices')
        .get();

    if (devicesSnapshot.exists) {
      final devices = devicesSnapshot.value as Map<dynamic, dynamic>;
      if (devices.isEmpty) return;
      final mac = devices.keys.first.toString();
      final ref = FirebaseDatabase.instance
          .ref()
          .child('Users')
          .child(hiddenUid)
          .child('Devices')
          .child(mac);

      if (actionId == 'stop_action') {
        await ref.update({
          'MobileStop': true,
          'AlarmStatus': 'IDLE',
          'LastStopAt': ServerValue.timestamp,
        });
      } else if (actionId == 'snooze_action') {
        String snoozeTimeStr = DateFormat(
          "HH:mm",
        ).format(DateTime.now().add(const Duration(minutes: 5)));
        await ref.update({
          'SnoozeUntil': snoozeTimeStr,
          'AlarmStatus': 'SNOOZE',
          'MobileStop': true,
        });
      }
    }
  }

  void _showLocalNotification(RemoteMessage message) async {
    final List<AndroidNotificationAction> androidActions = [
      const AndroidNotificationAction(
        'snooze_action',
        'SNOOZE',
        showsUserInterface: true,
      ),
      const AndroidNotificationAction(
        'stop_action',
        'STOP',
        showsUserInterface: true,
      ),
    ];

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher', // Explicitly set the small icon
          actions: androidActions,
        );

    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title ?? "Alarm Ringing!",
      body: message.notification?.body ?? "Check your smart alarm device.",
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }
}
