import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alarm_frontend/components/notification_history_modal.dart';
import 'package:alarm_frontend/models/today_summary_model.dart';
import 'package:alarm_frontend/providers/user_provider.dart';
import 'package:alarm_frontend/routes/app_routes.dart';
import 'package:alarm_frontend/services/api_service.dart';
import 'package:alarm_frontend/services/background_service.dart';
import 'package:alarm_frontend/services/location_service.dart';
import 'package:alarm_frontend/services/weather_service.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;

  final WeatherService _weatherService = WeatherService();

  final LocationService _locationService = LocationService();

  final TextEditingController _destinationController = TextEditingController();

  // =========================================================
  // WEATHER
  // =========================================================

  String temperature = '--°F';
  String weatherMain = 'Loading...';

  // =========================================================
  // FIREBASE DEVICE
  // =========================================================

  String? _macAddress;
  String? _hiddenUid;

  StreamSubscription? _deviceSubscription;

  // =========================================================
  // DESTINATION
  // =========================================================

  bool _isGettingLocation = false;

  // =========================================================
  // NEXT EVENT
  // =========================================================

  Map<String, dynamic>? _nextEvent;

  bool _isLoadingEvent = true;

  String? _eventError;

  // =========================================================
  // TODAY SUMMARY
  // =========================================================

  TodaySummaryModel? _todaySummary;

  bool _isLoadingSummary = true;

  String? _summaryError;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _loadWeather();

    _setupDeviceListener();

    _loadSavedDestination();

    _loadHomeBackendData();

    AppBackgroundService.requestOptimizationPermission();
  }

  @override
  void dispose() {
    _deviceSubscription?.cancel();

    _destinationController.dispose();

    super.dispose();
  }

  // =========================================================
  // HOME BACKEND
  // =========================================================

  Future<void> _loadHomeBackendData() async {
    await Future.wait([_loadNextEvent(), _loadTodaySummary()]);
  }

  // =========================================================
  // NEXT CALENDAR EVENT
  // =========================================================

  Future<void> _loadNextEvent() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _nextEvent = null;
        _eventError = 'User is not logged in';
        _isLoadingEvent = false;
      });

      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingEvent = true;
        _eventError = null;
      });
    }

    try {
      final status = await ApiService.get('/calendar/status/${user.uid}');

      if (!mounted) return;

      if (status['connected'] != true) {
        setState(() {
          _nextEvent = null;
          _eventError = 'not_connected';
          _isLoadingEvent = false;
        });

        return;
      }

      final response = await ApiService.get(
        '/calendar/events/${user.uid}?hours_ahead=24',
      );

      if (!mounted) return;

      final rawEvents = (response['events'] as List?) ?? [];

      setState(() {
        if (rawEvents.isNotEmpty) {
          _nextEvent = Map<String, dynamic>.from(rawEvents.first);
        } else {
          _nextEvent = null;
        }

        _eventError = null;
        _isLoadingEvent = false;
      });
    } catch (e) {
      debugPrint('Home next event error: $e');

      if (!mounted) return;

      setState(() {
        _nextEvent = null;
        _eventError = 'Unable to load next event';
        _isLoadingEvent = false;
      });
    }
  }

  // =========================================================
  // TODAY SUMMARY
  // =========================================================

  Future<void> _loadTodaySummary() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _todaySummary = null;
        _summaryError = 'User is not logged in';
        _isLoadingSummary = false;
      });

      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingSummary = true;
        _summaryError = null;
      });
    }

    try {
      final result = await ApiService.getTodaySummary(user.uid);

      if (!mounted) return;

      setState(() {
        _todaySummary = result;
        _summaryError = null;
        _isLoadingSummary = false;
      });
    } catch (e) {
      debugPrint('Home today summary error: $e');

      if (!mounted) return;

      setState(() {
        _todaySummary = null;
        _summaryError = 'Unable to load today summary';
        _isLoadingSummary = false;
      });
    }
  }

  // =========================================================
  // DESTINATION
  // =========================================================

  Future<void> _loadSavedDestination() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getString('destination_location') ?? '';

    if (!mounted) return;

    setState(() {
      _destinationController.text = saved;
    });
  }

  Future<void> _saveDestination(String address, double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('destination_location', address);

    await prefs.setDouble('destination_lat', lat);

    await prefs.setDouble('destination_lng', lng);

    if (mounted) {
      setState(() {
        _destinationController.text = address;
      });
    }

    if (_macAddress != null && _hiddenUid != null) {
      await _rtdb
          .ref()
          .child('Users')
          .child(_hiddenUid!)
          .child('Devices')
          .child(_macAddress!)
          .update({
            'DestinationLocation': address,
            'DestinationLat': lat,
            'DestinationLng': lng,
            'LocationUpdatedAt': DateTime.now().toUtc().toIso8601String(),
          });
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_isGettingLocation) return;

    setState(() {
      _isGettingLocation = true;
    });

    try {
      final locInfo = await _locationService.getCurrentLocationInfo();

      if (locInfo != null && mounted) {
        await _saveDestination(
          locInfo['address'],
          locInfo['lat'],
          locInfo['lng'],
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  // =========================================================
  // DEVICE LISTENER
  // =========================================================

  String _getHiddenUid(String email) {
    final prefix = email
        .split('@')
        .first
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toLowerCase();

    final hash = email.hashCode.abs().toString();

    final suffix = hash.length > 4
        ? hash.substring(hash.length - 4)
        : hash.padLeft(4, '0');

    return 'user_${prefix}_$suffix';
  }

  void _setupDeviceListener() {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    if (email.isEmpty) return;

    _hiddenUid = _getHiddenUid(email);

    _deviceSubscription = _rtdb
        .ref()
        .child('Users')
        .child(_hiddenUid!)
        .child('Devices')
        .onValue
        .listen((event) {
          if (!mounted) return;

          if (event.snapshot.exists) {
            final raw = event.snapshot.value;

            if (raw is Map<dynamic, dynamic> && raw.isNotEmpty) {
              setState(() {
                _macAddress = raw.keys.first.toString();
              });

              return;
            }
          }

          setState(() {
            _macAddress = null;
          });
        });
  }

  // =========================================================
  // WEATHER
  // =========================================================

  Future<void> _loadWeather() async {
    try {
      final weatherData = await _weatherService.fetchWeather();

      if (weatherData != null && mounted) {
        final temp = (weatherData['main']['temp'] as num).toDouble();

        setState(() {
          temperature = '${temp.round()}°F';

          weatherMain = weatherData['weather'][0]['main'].toString();
        });
      }
    } catch (e) {
      debugPrint('Weather load error: $e');
    }
  }

  // =========================================================
  // REFRESH
  // =========================================================

  Future<void> _refreshHome() async {
    await Future.wait([_loadWeather(), _loadHomeBackendData()]);
  }

  // =========================================================
  // GREETING
  // =========================================================

  (String greeting, String secondary, String asset) _getTimeBasedData() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return (
        'Good Morning',
        'Have a great morning',
        'assets/lotties/morning.json',
      );
    }

    if (hour >= 12 && hour < 17) {
      return (
        'Good Afternoon',
        'Have a productive afternoon',
        'assets/lotties/day.json',
      );
    }

    if (hour >= 17 && hour < 21) {
      return (
        'Good Evening',
        'Enjoy your evening',
        'assets/lotties/night.json',
      );
    }

    return ('Good Night', 'Get some good rest', 'assets/lotties/night.json');
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final userProvider = Provider.of<UserProvider>(context);

    final fullName = userProvider.user?.fullName ?? '';

    final firstName = fullName.isNotEmpty ? fullName.split(' ').first : 'User';

    final (greeting, secondaryGreeting, lottieAsset) = _getTimeBasedData();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: RefreshIndicator(
        color: AppColors.primary,

        onRefresh: _refreshHome,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

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
                    Expanded(
                      child: Text(
                        '$greeting,\n$firstName',

                        style: const TextStyle(
                          fontSize: 26,
                          height: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Row(
                      children: [
                        IconButton(
                          onPressed: _refreshHome,

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

                if (_macAddress != null)
                  _buildLiveAlarmCard()
                else
                  _buildStaticAlarmPlaceholder(),

                const SizedBox(height: 20),

                _buildDestinationCard(),

                const SizedBox(height: 20),

                _buildSummaryCard(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // WEATHER UI
  // =========================================================

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

              errorBuilder: (_, __, ___) {
                return Lottie.asset('assets/lotties/home.json');
              },
            ),
          ),
        ),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          crossAxisAlignment: CrossAxisAlignment.end,

          children: [
            Text(
              '$secondaryGreeting,\n$name',

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

  // =========================================================
  // NEXT EVENT
  // =========================================================

  Widget _buildNextEventCard() {
    final theme = Theme.of(context);

    if (_isLoadingEvent) {
      return _loadingCard(primaryBorder: true);
    }

    if (_eventError == 'not_connected') {
      return Container(
        width: double.infinity,

        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(
          color: theme.cardColor,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(color: theme.dividerColor),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Next Event',

              style: TextStyle(
                color: AppColors.primary,

                fontSize: 20,

                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Connect Google Calendar to see your next event.',

              style: TextStyle(color: AppColors.textSecondary),
            ),

            const SizedBox(height: 8),

            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.calendar);
              },

              child: const Text('Connect Calendar'),
            ),
          ],
        ),
      );
    }

    if (_eventError != null) {
      return _errorCard(_eventError!, _loadNextEvent);
    }

    if (_nextEvent == null) {
      return Container(
        width: double.infinity,

        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(
          color: theme.cardColor,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(color: theme.dividerColor),
        ),

        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              'Next Event',

              style: TextStyle(
                color: AppColors.primary,

                fontSize: 20,

                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text(
              'No upcoming events',

              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final start = DateTime.tryParse(
      _nextEvent!['start_time']?.toString() ?? '',
    )?.toLocal();

    final end = DateTime.tryParse(
      _nextEvent!['end_time']?.toString() ?? '',
    )?.toLocal();

    final rawTitle = _nextEvent!['summary']?.toString().trim();

    final title = rawTitle == null || rawTitle.isEmpty
        ? 'Untitled event'
        : rawTitle;

    final timeText = start != null ? DateFormat.jm().format(start) : '—';

    final dateText = start != null
        ? DateFormat('EEE, MMM d').format(start)
        : '';

    String remainingText = '';

    if (start != null) {
      final difference = start.difference(DateTime.now());

      if (!difference.isNegative) {
        final hours = difference.inHours;

        final minutes = difference.inMinutes.remainder(60);

        if (hours > 0) {
          remainingText = '${hours}h ${minutes}m left';
        } else {
          remainingText = '$minutes min left';
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: theme.cardColor,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: AppColors.primary),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'Next Event',

            style: TextStyle(
              color: AppColors.primary,

              fontSize: 20,

              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(
                Icons.calendar_today,

                size: 22,

                color: AppColors.primary,
              ),

              const SizedBox(width: 8),

              Text(timeText, style: const TextStyle(fontSize: 17)),

              const SizedBox(width: 10),

              const Text(
                '•',

                style: TextStyle(color: AppColors.textSecondary, fontSize: 17),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  title,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(fontSize: 17),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            remainingText.isEmpty ? dateText : '$dateText • $remainingText',

            style: const TextStyle(color: AppColors.primaryDark, fontSize: 15),
          ),

          if (end != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),

              child: Text(
                'Ends ${DateFormat.jm().format(end)}',

                style: const TextStyle(
                  color: AppColors.textSecondary,

                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // FIREBASE ALARM
  // =========================================================

  Widget _buildLiveAlarmCard() {
    return StreamBuilder<DatabaseEvent>(
      stream: _rtdb
          .ref()
          .child('Users')
          .child(_hiddenUid!)
          .child('Devices')
          .child(_macAddress!)
          .onValue,

      builder: (context, snapshot) {
        final raw = snapshot.data?.snapshot.value;

        final data = raw is Map<dynamic, dynamic> ? raw : <dynamic, dynamic>{};

        final alarmTime = data['AlarmTime']?.toString() ?? '07:00';

        final alarmEnabled = data['AlarmEnabled'] == true;

        return Container(
          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,

            borderRadius: BorderRadius.circular(16),

            border: Border.all(
              color: alarmEnabled
                  ? AppColors.primary
                  : Theme.of(context).dividerColor,
            ),
          ),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    'Bedside Alarm',

                    style: TextStyle(
                      color: AppColors.textSecondary,

                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 4),

                  GestureDetector(
                    onTap: () {
                      _pickTime(context, alarmTime);
                    },

                    child: Text(
                      alarmTime,

                      style: const TextStyle(
                        fontSize: 28,

                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const Text(
                    'Mon - Sun',

                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),

              Switch(
                value: alarmEnabled,

                activeThumbColor: AppColors.primary,

                onChanged: (value) {
                  _updateDevice('AlarmEnabled', value);
                },
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

      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text('Alarm', style: TextStyle(fontSize: 20)),

              Text(
                'No Device Connected',

                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),

          Switch(value: false, onChanged: null),
        ],
      ),
    );
  }

  // =========================================================
  // DESTINATION CARD
  // =========================================================

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
              const Expanded(
                child: Text(
                  'Destination Location',

                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),

              if (_isGettingLocation)
                const SizedBox(
                  width: 18,
                  height: 18,

                  child: CircularProgressIndicator(
                    strokeWidth: 2,

                    color: AppColors.primary,
                  ),
                )
              else
                IconButton(
                  onPressed: _useCurrentLocation,

                  icon: const Icon(
                    Icons.my_location,

                    size: 18,

                    color: AppColors.primary,
                  ),

                  tooltip: 'Use Current Location',
                ),
            ],
          ),

          const SizedBox(height: 4),

          const Text(
            'Used for AI commute time prediction',

            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),

          const SizedBox(height: 12),

          GestureDetector(
            onTap: () async {
              final result = await showSearch<LocationSuggestion?>(
                context: context,

                delegate: LocationSearchDelegate(_locationService),
              );

              if (result != null && mounted) {
                await _saveDestination(result.label, result.lat, result.lon);
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
                  const Icon(
                    Icons.location_on_outlined,

                    size: 20,

                    color: AppColors.primary,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      _destinationController.text.isEmpty
                          ? 'Search for village, office or event...'
                          : _destinationController.text,

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(
                        fontSize: 14,

                        color: _destinationController.text.isEmpty
                            ? theme.textTheme.bodyMedium?.color?.withValues(
                                alpha: 0.5,
                              )
                            : theme.textTheme.bodyLarge?.color,
                      ),
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

  // =========================================================
  // TODAY SUMMARY CARD
  // =========================================================

  Widget _buildSummaryCard() {
    final theme = Theme.of(context);

    if (_isLoadingSummary) {
      return _loadingCard();
    }

    if (_summaryError != null) {
      return _errorCard(_summaryError!, _loadTodaySummary);
    }

    final sleep = _todaySummary?.sleep;

    String sleepText = 'No Sleep Data';

    if (sleep?.available == true && sleep?.durationHours != null) {
      sleepText = '${sleep!.durationHours!.toStringAsFixed(1)}h Sleep';
    }

    String eventText;

    if (_isLoadingEvent) {
      eventText = 'Loading Events';
    } else if (_eventError != null) {
      eventText = 'Events Unavailable';
    } else if (_nextEvent != null) {
      eventText = '1 Active Event';
    } else {
      eventText = '0 Active Events';
    }

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.todaySummary);
      },

      borderRadius: BorderRadius.circular(16),

      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: theme.cardColor,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(color: theme.dividerColor),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                Text(
                  "Today's Summary",

                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),

                Icon(
                  Icons.arrow_forward_ios,

                  color: AppColors.textSecondary,

                  size: 18,
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Flexible(child: Text(sleepText)),

                const SizedBox(width: 20),

                const Text(
                  '|',

                  style: TextStyle(color: AppColors.textSecondary),
                ),

                const SizedBox(width: 20),

                Flexible(child: Text(eventText)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // NOTIFICATION BUTTON
  // =========================================================

  Widget _buildNotificationIcon() {
    return GestureDetector(
      onTap: () {
        NotificationHistoryModal.show(context);
      },

      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,

          borderRadius: BorderRadius.circular(12),
        ),

        padding: const EdgeInsets.all(8),

        child: const Icon(
          Icons.notifications_none,

          color: AppColors.primary,

          size: 30,
        ),
      ),
    );
  }

  // =========================================================
  // ALARM HELPERS
  // =========================================================

  Future<void> _pickTime(BuildContext context, String currentTime) async {
    final parts = currentTime.split(':');

    if (parts.length < 2) {
      return;
    }

    final hour = int.tryParse(parts[0]);

    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return;
    }

    final picked = await showTimePicker(
      context: context,

      initialTime: TimeOfDay(hour: hour, minute: minute),

      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,

              primary: AppColors.primary,

              surface: Theme.of(context).cardColor,
            ),
          ),

          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:'
          '${picked.minute.toString().padLeft(2, '0')}';

      await _updateDevice('AlarmTime', formatted);
    }
  }

  Future<void> _updateDevice(String key, dynamic value) async {
    if (_macAddress == null || _hiddenUid == null) {
      return;
    }

    await _rtdb
        .ref()
        .child('Users')
        .child(_hiddenUid!)
        .child('Devices')
        .child(_macAddress!)
        .update({key: value});
  }

  // =========================================================
  // GENERIC STATE CARDS
  // =========================================================

  Widget _loadingCard({bool primaryBorder = false}) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(28),

      decoration: BoxDecoration(
        color: theme.cardColor,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: primaryBorder ? AppColors.primary : theme.dividerColor,
        ),
      ),

      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _errorCard(String message, Future<void> Function() retry) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: theme.cardColor,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: theme.dividerColor),
      ),

      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),

          const SizedBox(width: 10),

          Expanded(child: Text(message)),

          IconButton(
            onPressed: () {
              retry();
            },

            icon: const Icon(Icons.refresh, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// LOCATION SEARCH
// =============================================================

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
        hintStyle: TextStyle(
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
        ),

        border: InputBorder.none,
      ),

      textTheme: theme.textTheme.copyWith(
        titleLarge: TextStyle(
          color: theme.textTheme.bodyLarge?.color,

          fontSize: 18,
        ),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),

          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),

      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSuggestionList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSuggestionList(context);
  }

  Widget _buildSuggestionList(BuildContext context) {
    final theme = Theme.of(context);

    if (query.trim().length < 2) {
      return Center(
        child: Text(
          'Start typing a village or city name',

          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return FutureBuilder<List<LocationSuggestion>>(
      future: locationService.getSuggestions(query),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Search error. Please check your connection.',

              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
          );
        }

        final suggestions = snapshot.data ?? [];

        if (suggestions.isEmpty) {
          return Center(
            child: Text(
              'No locations found.',

              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
          );
        }

        return ListView.separated(
          itemCount: suggestions.length,

          separatorBuilder: (context, index) {
            return Divider(height: 1, color: theme.dividerColor);
          },

          itemBuilder: (context, index) {
            final suggestion = suggestions[index];

            return ListTile(
              leading: const Icon(
                Icons.location_on_outlined,

                color: AppColors.primary,
              ),

              title: Text(
                suggestion.label.split(',').first,

                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,

                  fontWeight: FontWeight.bold,
                ),
              ),

              subtitle: Text(
                suggestion.label,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),

              onTap: () {
                close(context, suggestion);
              },
            );
          },
        );
      },
    );
  }
}
