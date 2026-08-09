import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alarm_frontend/providers/user_provider.dart';
import 'package:alarm_frontend/routes/app_routes.dart';
import 'package:alarm_frontend/services/weather_service.dart';
import 'package:alarm_frontend/services/location_service.dart';
import 'package:alarm_frontend/services/background_service.dart';
import 'package:alarm_frontend/components/notification_history_modal.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();
  final TextEditingController _destinationController = TextEditingController();

  String temperature = "--°F";
  String weatherMain = "Loading...";
  String? _macAddress;
  String? _hiddenUid;
  StreamSubscription? _deviceSubscription;
  bool _isGettingLocation = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _setupDeviceListener();
    _loadSavedDestination();
    AppBackgroundService.requestOptimizationPermission();
  }

  @override
  void dispose() {
    _deviceSubscription?.cancel();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedDestination() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('destination_location') ?? "";
    setState(() => _destinationController.text = saved);
  }

  Future<void> _saveDestination(String address, double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('destination_location', address);
    await prefs.setDouble('destination_lat', lat);
    await prefs.setDouble('destination_lng', lng);
    
    setState(() => _destinationController.text = address);

    if (_macAddress != null && _hiddenUid != null) {
      await _rtdb.ref().child('Users').child(_hiddenUid!).child('Devices').child(_macAddress!).update({
        'DestinationLocation': address,
        'DestinationLat': lat,
        'DestinationLng': lng,
        'LocationUpdatedAt': DateTime.now().toUtc().toIso8601String(),
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    final locInfo = await _locationService.getCurrentLocationInfo();
    if (locInfo != null && mounted) {
      await _saveDestination(
        locInfo['address'],
        locInfo['lat'],
        locInfo['lng'],
      );
    }
    if (mounted) setState(() => _isGettingLocation = false);
  }

  String _getHiddenUid(String email) {
    String prefix = email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    String hash = email.hashCode.abs().toString();
    String suffix = hash.length > 4 ? hash.substring(hash.length - 4) : hash.padLeft(4, '0');
    return "user_${prefix}_$suffix";
  }

  void _setupDeviceListener() {
    final email = FirebaseAuth.instance.currentUser?.email ?? "";
    if (email.isEmpty) return;

    _hiddenUid = _getHiddenUid(email);
    
    _deviceSubscription = _rtdb.ref().child('Users').child(_hiddenUid!).child('Devices').onValue.listen((event) {
      if (event.snapshot.exists && mounted) {
        final devices = event.snapshot.value as Map<dynamic, dynamic>;
        if (devices.isNotEmpty) {
          setState(() => _macAddress = devices.keys.first.toString());
        }
      } else if (mounted) {
        setState(() => _macAddress = null);
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
      return ("Good Morning", "Have a great morning", "assets/lotties/morning.json");
    } else if (hour >= 12 && hour < 17) {
      return ("Good Afternoon", "Have a productive afternoon", "assets/lotties/day.json");
    } else if (hour >= 17 && hour < 21) {
      return ("Good Evening", "Enjoy your evening", "assets/lotties/night.json");
    } else {
      return ("Good Night", "Get some good rest", "assets/lotties/night.json");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userProvider = Provider.of<UserProvider>(context);
    final String fullName = userProvider.user?.fullName ?? "";
    final String firstName = fullName.isNotEmpty ? fullName.split(' ').first : "User";
    final (greeting, secondaryGreeting, lottieAsset) = _getTimeBasedData();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, 
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
                    Text("$greeting,\n$firstName", style: const TextStyle(fontSize: 26, height: 1.2, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(onPressed: _loadWeather, icon: const Icon(Icons.refresh, color: AppColors.primary)),
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
                if (_macAddress != null) _buildLiveAlarmCard() else _buildStaticAlarmPlaceholder(),
                const SizedBox(height: 20),
                _buildDestinationCard(),
                const SizedBox(height: 20),
                _buildSummaryCard(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildLiveAlarmCard() {
    return StreamBuilder(
      stream: _rtdb.ref().child('Users').child(_hiddenUid!).child('Devices').child(_macAddress!).onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        final data = snapshot.data?.snapshot.value as Map<dynamic, dynamic>? ?? {};
        final String alarmTime = data['AlarmTime'] ?? "07:00";
        final bool alarmEnabled = data['AlarmEnabled'] ?? false;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: alarmEnabled ? AppColors.primary : Theme.of(context).dividerColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Bedside Alarm", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _pickTime(context, alarmTime),
                    child: Text(alarmTime, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  ),
                  const Text("Mon - Sun", style: TextStyle(color: Colors.white38, fontSize: 11)),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Alarm", style: TextStyle(fontSize: 20)),
              const Text("No Device Connected", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          Switch(value: false, onChanged: null),
        ],
      ),
    );
  }

  Widget _buildDestinationCard() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Destination Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (_isGettingLocation)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
              else
                IconButton(
                  onPressed: _useCurrentLocation,
                  icon: const Icon(Icons.my_location, size: 18, color: AppColors.primary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: "Use Current Location",
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text("Used for AI commute time prediction", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          
          GestureDetector(
            onTap: () async {
              final LocationSuggestion? result = await showSearch<LocationSuggestion?>(
                context: context,
                delegate: LocationSearchDelegate(_locationService),
              );
              if (result != null && mounted) {
                _saveDestination(result.label, result.lat, result.lon);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 20, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _destinationController.text.isEmpty 
                        ? "Search for village, office or event..." 
                        : _destinationController.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: _destinationController.text.isEmpty 
                          ? theme.textTheme.bodyMedium?.color?.withOpacity(0.5) 
                          : theme.textTheme.bodyLarge?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(BuildContext context, String currentTime) async {
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, primary: AppColors.primary, surface: Theme.of(context).cardColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final formatted = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      _updateDevice('AlarmTime', formatted);
    }
  }

  void _updateDevice(String key, dynamic value) {
    if (_macAddress != null && _hiddenUid != null) {
      _rtdb.ref().child('Users').child(_hiddenUid!).child('Devices').child(_macAddress!).update({key: value});
    }
  }

  Widget _buildNotificationIcon() {
    return GestureDetector(
      onTap: () => NotificationHistoryModal.show(context),
      child: Container(
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(8),
        child: const Icon(Icons.notifications_none, color: AppColors.primary, size: 30),
      ),
    );
  }

  Widget _buildWeatherSection(String asset, String secondaryGreeting, String name) {
    return Column(
      children: [
        Center(
          child: SizedBox(
            height: 150,
            child: Lottie.asset(asset, fit: BoxFit.contain, errorBuilder: (_, _, _) => Lottie.asset('assets/lotties/home.json')),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("$secondaryGreeting,\n$name", style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w500)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(temperature, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                Text(weatherMain, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Next Event", style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 22, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text("9:30 AM", style: TextStyle(fontSize: 17)),
              const SizedBox(width: 10),
              const Text("•", style: TextStyle(color: AppColors.textSecondary, fontSize: 17)),
              const SizedBox(width: 10),
              const Text("Product Sync", style: TextStyle(fontSize: 17)),
            ],
          ),
          const SizedBox(height: 6),
          const Text("Tue, Nov 12 • 1hr 15m left", style: TextStyle(color: AppColors.primaryDark, fontSize: 15)),
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Today's Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text("8h Sleep"),
                const SizedBox(width: 30),
                const Text("|", style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(width: 30),
                const Text("1 Active Event"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LocationSearchDelegate extends SearchDelegate<LocationSuggestion?> {
  final LocationService locationService;

  LocationSearchDelegate(this.locationService);

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textTheme.bodyLarge?.color),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
        border: InputBorder.none,
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 18),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = "",
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => const SizedBox.shrink();

  @override
  Widget buildSuggestions(BuildContext context) {
    final theme = Theme.of(context);
    if (query.length < 2) {
      return Center(
        child: Text(
          "Start typing a village or city name",
          style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
        ),
      );
    }

    return FutureBuilder<List<LocationSuggestion>>(
      future: locationService.getSuggestions(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Search error. Please check your connection.",
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
          );
        }

        final suggestions = snapshot.data ?? [];
        if (suggestions.isEmpty) {
          return Center(
            child: Text(
              "No locations found.",
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
          );
        }

        return ListView.separated(
          itemCount: suggestions.length,
          separatorBuilder: (context, index) => Divider(height: 1, color: theme.dividerColor),
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return ListTile(
              leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
              title: Text(
                suggestion.label.split(',').first,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                suggestion.label,
                style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => close(context, suggestion),
            );
          },
        );
      },
    );
  }
}
