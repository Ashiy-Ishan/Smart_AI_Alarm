import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:alarm_frontend/models/notification_history_model.dart';

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
  }) async {
    await _addToHistory(title, body);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'alarm_high_importance',
          'Schedule Updates',
          channelDescription: 'Notifications for meeting changes',
          importance: Importance.max,
          priority: Priority.high,
        );

    await _localNotifications.show(
      id: DateTime.now().millisecond % 100000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
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
    if (user == null || user.email == null) return;

    final hiddenUid = _getHiddenUid(user.email!);
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
        await ref.update({'MobileStop': true, 'AlarmStatus': 'IDLE'});
      } else if (actionId == 'snooze_action') {
        String snoozeTimeStr = DateFormat(
          "HH:mm",
        ).format(DateTime.now().add(const Duration(minutes: 5)));
        await ref.update({
          'SnoozeUntil': snoozeTimeStr,
          'AlarmStatus': 'SNOOZE',
        });
      }
    }
  }

  String _getHiddenUid(String email) {
    String prefix = email
        .split('@')
        .first
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toLowerCase();
    String hash = email.hashCode.abs().toString();
    String suffix = hash.length > 4
        ? hash.substring(hash.length - 4)
        : hash.padLeft(4, '0');
    return "user_${prefix}_$suffix";
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
