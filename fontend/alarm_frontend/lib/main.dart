import 'dart:async';
import 'package:alarm_frontend/firebase_options.dart';
import 'package:alarm_frontend/providers/user_provider.dart';
import 'package:alarm_frontend/providers/theme_provider.dart'; // added theme provider
import 'package:alarm_frontend/routes/app_router.dart';
import 'package:alarm_frontend/routes/app_routes.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/screens/alarm/alarm_ringing_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:alarm_frontend/services/notification_service.dart';
import 'package:alarm_frontend/services/background_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
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

  @override
  void initState() {
    super.initState();
    _setupAlarmListener();
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

  void _setupAlarmListener() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      _alarmSubscription?.cancel();
      if (user != null && user.email != null) {
        final hiddenUid = _getHiddenUid(user.email!);

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
                    _showAlarmOverlay(hiddenUid, _currentMac!);
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
    _isAlarmShowing = true;
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => AlarmRingingScreen(macAddress: mac, hiddenUid: uid),
      ),
    );
  }

  void _hideAlarmOverlay() {
    _isAlarmShowing = false;
    if (_navigatorKey.currentState?.canPop() ?? false) {
      _navigatorKey.currentState?.pop();
    }
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
