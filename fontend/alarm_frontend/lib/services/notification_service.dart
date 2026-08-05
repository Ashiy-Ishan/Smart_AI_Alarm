import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Configures and displays the app's local notifications.
class NotificationService {
  NotificationService._();

  static final NotificationService _instance = NotificationService._();

  factory NotificationService() => _instance;

  static const _channel = AndroidNotificationChannel(
    'alarm_alerts',
    'Alarm alerts',
    description: 'Notifications displayed when an alarm starts ringing.',
    importance: Importance.max,
    playSound: true,
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(settings);
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_channel);
    await android?.requestNotificationsPermission();
    _initialized = true;
  }

  Future<void> showAlarm({
    required String title,
    required String body,
  }) async {
    await initialize();
    await _plugin.show(
      1001,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_alerts',
          'Alarm alerts',
          channelDescription: 'Notifications displayed when an alarm starts ringing.',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
    );
  }

  Future<void> cancelAlarm() => _plugin.cancel(1001);
}
