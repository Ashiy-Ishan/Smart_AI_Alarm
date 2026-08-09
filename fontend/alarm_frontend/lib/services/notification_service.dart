import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

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
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
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
      _showLocalNotification(message);
    });

    String? token = await _fcm.getToken();
    Logger().i("FCM Token: $token");
  }

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
