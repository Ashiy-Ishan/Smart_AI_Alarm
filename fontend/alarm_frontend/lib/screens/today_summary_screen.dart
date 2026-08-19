import 'package:alarm_frontend/services/google_sync_service.dart';
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

      final syncService = GoogleSyncService();
      final isLinked = await syncService.isLinked();

      if (isLinked) {
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

        final googleEvents = await syncService.fetchEvents(
          timeMin: startOfDay,
          timeMax: endOfDay,
          maxResults: 50,
        );

        if (!mounted) return;

        if (googleEvents.isNotEmpty) {
          final events = googleEvents.map<EventModel>((event) {
            final start = event.start?.dateTime?.toLocal() ??
                event.start?.date?.toLocal();
            final end =
                event.end?.dateTime?.toLocal() ?? event.end?.date?.toLocal();

            return EventModel(
              time: start != null ? DateFormat.jm().format(start) : '—',
              title: event.summary?.trim().isNotEmpty == true
                  ? event.summary!
                  : 'Untitled event',
              extra: event.location,
              rightTime: end != null ? DateFormat.jm().format(end) : null,
            );
          }).toList();

          setState(() {
            _events = events;
            _eventsError = null;
            _isLoadingEvents = false;
          });
          return;
        }
      }

      final status = await ApiService.get('/calendar/status/${user.uid}');

      if (!mounted) return;

      if (status?['connected'] != true) {
        setState(() {
          _eventsError = isLinked ? null : 'not_connected';

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

      final now = DateTime.now();
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final events = rawEvents.map<EventModel?>((event) {
        final map = Map<String, dynamic>.from(event);

        final start = DateTime.tryParse(
          map['start_time']?.toString() ?? '',
        )?.toLocal();

        if (start == null || start.isAfter(endOfDay)) return null;

        final end = DateTime.tryParse(
          map['end_time']?.toString() ?? '',
        )?.toLocal();

        final rawTitle = map['summary']?.toString().trim();

        return EventModel(
          time: DateFormat.jm().format(start),
          title: rawTitle != null && rawTitle.isNotEmpty
              ? rawTitle
              : 'Untitled event',
          extra: map['location']?.toString(),
          rightTime: end != null ? DateFormat.jm().format(end) : null,
        );
      }).where((e) => e != null).cast<EventModel>().toList();

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
