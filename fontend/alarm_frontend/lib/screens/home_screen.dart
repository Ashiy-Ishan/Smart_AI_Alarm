import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alarm_frontend/providers/user_provider.dart';
import 'package:alarm_frontend/routes/app_routes.dart';
import 'package:alarm_frontend/services/weather_service.dart';
import 'package:alarm_frontend/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  final WeatherService _weatherService = WeatherService();

  String temperature = "--°F";
  String weatherMain = "Loading...";
  String? _macAddress;
  String? _hiddenUid;
  StreamSubscription? _deviceSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _setupDeviceListener();
  }

  @override
  void dispose() {
    _deviceSubscription?.cancel();
    super.dispose();
  }

  Future<void> _testBackend() async {
    try {
      final result = await ApiService.checkHealth();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backend connected: ${result['status']}')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backend connection failed: $e')));
    }
  }

  // Consistent UID generation logic
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

  // New: Real-time listener for the user's device link
  void _setupDeviceListener() {
    final email = FirebaseAuth.instance.currentUser?.email ?? "";
    if (email.isEmpty) return;

    _hiddenUid = _getHiddenUid(email);

    // Listen to the User's Devices node directly
    _deviceSubscription = _rtdb
        .ref()
        .child('Users')
        .child(_hiddenUid!)
        .child('Devices')
        .onValue
        .listen((event) {
          if (event.snapshot.exists && mounted) {
            final devices = event.snapshot.value as Map<dynamic, dynamic>;
            if (devices.isNotEmpty) {
              setState(() {
                _macAddress = devices.keys.first.toString();
              });
            }
          } else if (mounted) {
            setState(() {
              _macAddress = null;
            });
          }
        });
  }

  Future<void> _loadWeather() async {
    final weatherData = await _weatherService.fetchWeather();
    if (weatherData != null && mounted) {
      setState(() {
        double temp = weatherData['main']['temp'].toDouble();
        temperature = "${temp.round()}°F";
        weatherMain = weatherData['weather'][0]['main'];
      });
    }
  }

  (String greeting, String secondary, String asset) _getTimeBasedData() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return (
        "Good Morning",
        "Have a great morning",
        "assets/lotties/morning.json",
      );
    } else if (hour >= 12 && hour < 17) {
      return (
        "Good Afternoon",
        "Have a productive afternoon",
        "assets/lotties/day.json",
      );
    } else if (hour >= 17 && hour < 21) {
      return (
        "Good Evening",
        "Enjoy your evening",
        "assets/lotties/night.json",
      );
    } else {
      return ("Good Night", "Get some good rest", "assets/lotties/night.json");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userProvider = Provider.of<UserProvider>(context);
    final String fullName = userProvider.user?.fullName ?? "";
    final String firstName = fullName.isNotEmpty
        ? fullName.split(' ').first
        : "User";

    final (greeting, secondaryGreeting, lottieAsset) = _getTimeBasedData();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: MediaQuery.of(context).padding.top + 10,
            bottom: MediaQuery.of(context).padding.bottom + 80,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$greeting,\n$firstName",
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      height: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _loadWeather,
                        icon: const Icon(
                          Icons.refresh,
                          color: AppColors.primary,
                        ),
                      ),
                      _buildNotificationIcon(),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _buildWeatherSection(lottieAsset, secondaryGreeting, firstName),
              const SizedBox(height: 30),
              _buildNextEventCard(),
              const SizedBox(height: 20),

              // LIVE ALARM CARD FROM RTDB
              if (_macAddress != null)
                _buildLiveAlarmCard()
              else
                _buildStaticAlarmPlaceholder(),

              const SizedBox(height: 20),
              _buildSummaryCard(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _testBackend,
                child: const Text('Test Backend'),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveAlarmCard() {
    return StreamBuilder(
      stream: _rtdb
          .ref()
          .child('Users')
          .child(_hiddenUid!)
          .child('Devices')
          .child(_macAddress!)
          .onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        final data =
            snapshot.data?.snapshot.value as Map<dynamic, dynamic>? ?? {};
        final String alarmTime = data['AlarmTime'] ?? "07:00";
        final bool alarmEnabled = data['AlarmEnabled'] ?? false;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: alarmEnabled ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Bedside Alarm",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _pickTime(context, alarmTime),
                    child: Text(
                      alarmTime,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Text(
                    "Mon - Sun",
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
              Switch(
                value: alarmEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: (val) => _updateDevice('AlarmEnabled', val),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStaticAlarmPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Alarm",
                style: TextStyle(color: AppColors.textPrimary, fontSize: 20),
              ),
              Text(
                "No Device Connected",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          Switch(value: false, onChanged: null),
        ],
      ),
    );
  }

  Future<void> _pickTime(BuildContext context, String currentTime) async {
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: Colors.black,
            surface: AppColors.card,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final formatted =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      _updateDevice('AlarmTime', formatted);
    }
  }

  void _updateDevice(String key, dynamic value) {
    if (_macAddress != null && _hiddenUid != null) {
      _rtdb
          .ref()
          .child('Users')
          .child(_hiddenUid!)
          .child('Devices')
          .child(_macAddress!)
          .update({key: value});
    }
  }

  Widget _buildNotificationIcon() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: const Icon(
        Icons.notifications_none,
        color: AppColors.primary,
        size: 30,
      ),
    );
  }

  Widget _buildWeatherSection(
    String asset,
    String secondaryGreeting,
    String name,
  ) {
    return Column(
      children: [
        Center(
          child: SizedBox(
            height: 150,
            child: Lottie.asset(
              asset,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  Lottie.asset('assets/lotties/home.json'),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "$secondaryGreeting,\n$name",
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  temperature,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  weatherMain,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNextEventCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Next Event",
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 22, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                "9:30 AM",
                style: TextStyle(color: AppColors.textPrimary, fontSize: 17),
              ),
              SizedBox(width: 10),
              Text(
                "•",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 17),
              ),
              SizedBox(width: 10),
              Text(
                "Product Sync",
                style: TextStyle(color: AppColors.textPrimary, fontSize: 17),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            "Tue, Nov 12 • 1hr 15m left",
            style: TextStyle(color: AppColors.primaryDark, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.todaySummary),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Summary",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text(
                  "8h Sleep",
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                SizedBox(width: 30),
                Text("|", style: TextStyle(color: AppColors.textSecondary)),
                SizedBox(width: 30),
                Text(
                  "1 Active Event",
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
