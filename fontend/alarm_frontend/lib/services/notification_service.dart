import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Define high importance channel for Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'alarm_high_importance', // id
    'High Importance Alarm Notifications', // title
    description: 'This channel is used for important alarm notifications.', // description
    importance: Importance.max,
  );

  Future<void> initialize() async {
    // 1. Request permissions for Android 13+ and iOS
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Setup local notifications
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    
    await _localNotifications.initialize(settings:initSettings);

    // 3. Create the notification channel on Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 4. Foreground listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    String? token = await _fcm.getToken();
    print("FCM Token: $token");
  }

  void _showLocalNotification(RemoteMessage message) async {
    // Use the high importance channel
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title ?? "Alarm Notification",
      body: message.notification?.body ?? "Check your smart alarm device.",
      notificationDetails: platformDetails,
    );
  }
}
