import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:alarm_frontend/components/event_card.dart';
import 'package:alarm_frontend/models/event_model.dart';
import 'package:alarm_frontend/models/today_summary_model.dart';

import 'package:alarm_frontend/routes/app_routes.dart';
import 'package:alarm_frontend/services/api_service.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class TodaySummaryScreen extends StatefulWidget {
  const TodaySummaryScreen({super.key});

  @override
  State<TodaySummaryScreen> createState() => _TodaySummaryScreenState();
}

class _TodaySummaryScreenState extends State<TodaySummaryScreen> {
  TodaySummaryModel? _summary;

  bool _isLoadingSummary = true;
  String? _summaryError;

  List<EventModel> _events = [];

  bool _isLoadingEvents = true;

  String? _eventsError;

  @override
  void initState() {
    super.initState();

    _loadTodaySummary();
    _loadTodayEvents();
  }

  // =========================================================
  // TODAY SUMMARY
  // =========================================================

  Future<void> _loadTodaySummary() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _summaryError = 'User is not logged in.';
        _isLoadingSummary = false;
      });

      return;
    }

    setState(() {
      _isLoadingSummary = true;
      _summaryError = null;
    });

    try {
      final result = await ApiService.getTodaySummary(user.uid);

      if (!mounted) return;

      setState(() {
        _summary = result;

        _summaryError = null;

        _isLoadingSummary = false;
      });
    } catch (e) {
      debugPrint('Today summary fetch failed: $e');

      if (!mounted) return;

      setState(() {
        _summaryError = 'Unable to load today summary';

        _isLoadingSummary = false;
      });
    }
  }

  // =========================================================
  // GOOGLE CALENDAR
  // =========================================================

  Future<void> _loadTodayEvents() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('User is not logged in');
      }

      final status = await ApiService.get('/calendar/status/${user.uid}');

      if (!mounted) return;

      if (status?['connected'] != true) {
        setState(() {
          _eventsError = 'not_connected';

          _isLoadingEvents = false;
        });

        return;
      }

      final response = await ApiService.get(
        '/calendar/events/${user.uid}'
        '?hours_ahead=24',
      );

      if (!mounted) return;

      final rawEvents = (response?['events'] as List?) ?? [];

      final events = rawEvents.map<EventModel>((event) {
        final map = Map<String, dynamic>.from(event);

        final start = DateTime.tryParse(
          map['start_time']?.toString() ?? '',
        )?.toLocal();

        final end = DateTime.tryParse(
          map['end_time']?.toString() ?? '',
        )?.toLocal();

        final rawTitle = map['summary']?.toString().trim();

        return EventModel(
          time: start != null ? DateFormat.jm().format(start) : '—',

          title: rawTitle != null && rawTitle.isNotEmpty
              ? rawTitle
              : 'Untitled event',

          extra: map['location']?.toString(),

          rightTime: end != null ? DateFormat.jm().format(end) : null,
        );
      }).toList();

      setState(() {
        _events = events;

        _eventsError = null;

        _isLoadingEvents = false;
      });
    } catch (e) {
      debugPrint('Calendar events fetch failed: $e');

      if (!mounted) return;

      setState(() {
        _eventsError = 'Unable to load today\'s events';

        _isLoadingEvents = false;
      });
    }
  }

  // =========================================================
  // REFRESH EVERYTHING
  // =========================================================

  Future<void> _refreshAll() async {
    await Future.wait([_loadTodaySummary(), _loadTodayEvents()]);
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textTheme.bodyLarge?.color),
        title: const Text(
          'Today’s Summary',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,

          color: AppColors.primary,

          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),

            child: Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Divider(color: theme.dividerColor),

                  const SizedBox(height: 32),

                  // ======================================
                  // TODAY EVENTS
                  // ======================================
                  const Text(
                    'Today’s Events',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 15),

                  _buildEventsSection(theme),

                  const SizedBox(height: 20),

                  Divider(color: theme.dividerColor),

                  const SizedBox(height: 20),

                  // ======================================
                  // ACTIVITY SUMMARY
                  // ======================================
                  const Text(
                    'Activity Summary',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 15),

                  _buildSensorCard(theme),

                  const SizedBox(height: 15),

                  _buildMovementCard(theme),

                  const SizedBox(height: 20),

                  Divider(color: theme.dividerColor),

                  const SizedBox(height: 20),

                  // ======================================
                  // HEALTH INSIGHTS
                  // ======================================
                  const Text(
                    'Health Insights',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Container(height: 4, width: 40, color: AppColors.primary),

                  const SizedBox(height: 20),

                  _buildHealthInsight(theme),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // EVENTS
  // =========================================================

  Widget _buildEventsSection(ThemeData theme) {
    if (_isLoadingEvents) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_eventsError == 'not_connected') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Connect Google Calendar to see today\'s events.',
            style: TextStyle(color: AppColors.textSecondary),
          ),

          const SizedBox(height: 10),

          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.calendar);
            },
            child: const Text(
              'Connect Calendar',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      );
    }

    if (_eventsError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                _eventsError!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),

            IconButton(
              onPressed: () {
                setState(() {
                  _isLoadingEvents = true;
                });

                _loadTodayEvents();
              },
              icon: const Icon(Icons.refresh, color: AppColors.primary),
            ),
          ],
        ),
      );
    }

    if (_events.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: const Text(
          'No events scheduled for today',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,

      physics: const NeverScrollableScrollPhysics(),

      itemCount: _events.length,

      itemBuilder: (context, index) {
        return EventCard(event: _events[index]);
      },
    );
  }

  // =========================================================
  // SENSOR CARD
  // =========================================================

  Widget _buildSensorCard(ThemeData theme) {
    if (_isLoadingSummary) {
      return _loadingCard(theme);
    }

    if (_summaryError != null) {
      return _errorCard(theme, _summaryError!);
    }

    final activity = _summary?.activity;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _activityItem(
            icon: Icons.thermostat,
            value: activity?.roomTemperature != null
                ? '${activity!.roomTemperature!.toStringAsFixed(1)}°C'
                : '--',
            label: 'Temperature',
          ),

          _activityItem(
            icon: Icons.water_drop_outlined,
            value: activity?.humidity != null
                ? '${activity!.humidity!.toStringAsFixed(0)}%'
                : '--',
            label: 'Humidity',
          ),

          _activityItem(
            icon: Icons.directions_walk,
            value: activity?.available == true
                ? activity!.motionDetected
                      ? 'Detected'
                      : 'Still'
                : '--',
            label: 'Motion',
          ),
        ],
      ),
    );
  }

  // =========================================================
  // MOVEMENT CARD
  // =========================================================

  Widget _buildMovementCard(ThemeData theme) {
    if (_isLoadingSummary) {
      return _loadingCard(theme);
    }

    if (_summaryError != null) {
      return _errorCard(theme, _summaryError!);
    }

    final activity = _summary?.activity;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _metricItem(
            value: activity?.steps != null ? '${activity!.steps}' : '--',
            label: 'Steps',
          ),

          _metricItem(
            value: activity?.available == true
                ? '${activity!.movementMinutes.toStringAsFixed(0)} min'
                : '--',
            label: 'Movement',
          ),

          _metricItem(
            value: activity?.calories != null
                ? '${activity!.calories!.toStringAsFixed(0)}'
                : '--',
            label: 'Cal',
          ),
        ],
      ),
    );
  }

  // =========================================================
  // HEALTH INSIGHT
  // =========================================================

  Widget _buildHealthInsight(ThemeData theme) {
    if (_isLoadingSummary) {
      return _loadingCard(theme);
    }

    if (_summaryError != null) {
      return _errorCard(theme, _summaryError!);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.health_and_safety_outlined,
            color: AppColors.primary,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              _summary?.healthInsight ?? 'No health insight available yet.',
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SMALL COMPONENTS
  // =========================================================

  Widget _activityItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),

          const SizedBox(height: 5),

          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricItem({required String value, required String label}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _loadingCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _errorCard(ThemeData theme, String message) {
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

          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),

          IconButton(
            onPressed: _loadTodaySummary,
            icon: const Icon(Icons.refresh, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
