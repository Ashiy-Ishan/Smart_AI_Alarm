import 'dart:async';
import 'package:alarm_frontend/firebase_options.dart';
import 'package:alarm_frontend/providers/user_provider.dart';
import 'package:alarm_frontend/providers/theme_provider.dart'; // added theme provider
import 'package:alarm_frontend/routes/app_router.dart';
import 'package:alarm_frontend/routes/app_routes.dart';
import 'package:alarm_frontend/screens/alarm/alarm_ringing_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:alarm_frontend/services/notification_service.dart';
import 'package:alarm_frontend/services/background_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  try {
    await dotenv.load(fileName: ".env");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await NotificationService().initialize();

    await AppBackgroundService.initializeService();
  } catch (e) {
    debugPrint("App init failed: $e");
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()), // added
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription? _alarmSubscription;
  String? _currentMac;
  bool _isAlarmShowing = false;
  DateTime? _lastDismissedTime;

  @override
  void initState() {
    super.initState();
    _setupAlarmListener();
  }



  void _setupAlarmListener() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      _alarmSubscription?.cancel();
      if (user != null) {
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
            _currentMac = devices.keys.first.toString();

            _alarmSubscription = FirebaseDatabase.instance
                .ref()
                .child('Users')
                .child(hiddenUid)
                .child('Devices')
                .child(_currentMac!)
                .child('AlarmStatus')
                .onValue
                .listen((event) {
                  final status = event.snapshot.value?.toString();

                  if (status == 'RINGING' && !_isAlarmShowing) {
                    final now = DateTime.now();
                    if (_lastDismissedTime != null &&
                        now.difference(_lastDismissedTime!).inSeconds < 5) {
                      debugPrint("Alarm RINGING ignored due to cooldown");
                      return;
                    }

                    _showAlarmOverlay(hiddenUid, _currentMac!);
                    NotificationService().showInstantNotification(
                      title: "Alarm Ringing!",
                      body: "Your Bedside Hub is ringing. Tap to stop or snooze.",
                      isAlarm: true,
                    );
                  } else if (status != 'RINGING' && _isAlarmShowing) {
                    _hideAlarmOverlay();
                  }
                });
          }
        }
      }
    });
  }

  void _showAlarmOverlay(String uid, String mac) {
    if (_isAlarmShowing) return;
    _isAlarmShowing = true;
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'alarm_ringing'),
        builder: (_) => AlarmRingingScreen(macAddress: mac, hiddenUid: uid),
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _isAlarmShowing = false);
      }
    });
  }

  void _hideAlarmOverlay() {
    if (!_isAlarmShowing) return;
    
    _lastDismissedTime = DateTime.now();
    _navigatorKey.currentState?.popUntil((route) {
      // Pop until we find a route that is NOT the alarm screen
      return route.settings.name != 'alarm_ringing';
    });
    
    setState(() {
      _isAlarmShowing = false;
    });
  }

  @override
  void dispose() {
    _alarmSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'AI Alarm App',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.currentTheme, // using dynamic theme
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
