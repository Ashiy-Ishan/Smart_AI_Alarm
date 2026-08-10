<<<<<<< HEAD
import 'package:alarm_frontend/services/google_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:alarm_frontend/components/calendar_grid.dart';
import 'package:alarm_frontend/components/upcoming_event_item.dart';
import 'package:googleapis/calendar/v3.dart' as google_calendar;
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _selectedDay = DateTime.now().day;
  late DateTime _selectedDate;
  late DateTime _currentMonth;
  final GoogleSyncService _syncService = GoogleSyncService();
  List<google_calendar.Event> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _currentMonth = DateTime(now.year, now.month);
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    try {
      final monthStart = DateTime(_currentMonth.year, _currentMonth.month);
      final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      final events = await _syncService.fetchEvents(
        timeMin: monthStart,
        timeMax: nextMonth,
      );
      if (!mounted ||
          _currentMonth.year != monthStart.year ||
          _currentMonth.month != monthStart.month) {
        return;
      }
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int offset) {
    final nextMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + offset,
    );
    final now = DateTime.now();
    setState(() {
      _currentMonth = nextMonth;
      _selectedDate = nextMonth.year == now.year && nextMonth.month == now.month
          ? DateTime(now.year, now.month, now.day)
          : nextMonth;
      _selectedDay = _selectedDate.day;
      _events = [];
    });
    _fetchEvents();
  }

  bool _eventOccursOn(google_calendar.Event event, DateTime date) {
    final isAllDay = event.start?.dateTime == null;
    final start = isAllDay
        ? event.start?.date
        : event.start?.dateTime?.toLocal();
    final end = isAllDay ? event.end?.date : event.end?.dateTime?.toLocal();
    if (start == null) return false;

    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final eventEnd =
        end ??
        start.add(
          isAllDay ? const Duration(days: 1) : const Duration(microseconds: 1),
        );
    return start.isBefore(dayEnd) && eventEnd.isAfter(dayStart);
  }

  List<google_calendar.Event> get _selectedEvents {
    return _events
        .where((event) => _eventOccursOn(event, _selectedDate))
        .toList();
  }

  String _eventTime(google_calendar.Event event) {
    final start = event.start?.dateTime?.toLocal();
    final end = event.end?.dateTime?.toLocal();
    if (start == null) return 'All day';
    if (end == null) return DateFormat.jm().format(start);
    return '${DateFormat.jm().format(start)} – ${DateFormat.jm().format(end)}';
  }

  Widget _monthHeader() {
    return Row(
      children: [
        IconButton(
          tooltip: 'Previous month',
          onPressed: () => _changeMonth(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            DateFormat('MMMM yyyy').format(_currentMonth),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          onPressed: () => _changeMonth(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _eventsContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (_selectedEvents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No events for this day.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return Column(children: _selectedEvents.map(_buildEventItem).toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge?.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Calendar', style: AppTextStyles.heading),
        titleSpacing: 0,
        actions: [
          IconButton(
            onPressed: _fetchEvents,
            icon: const Icon(Icons.refresh, color: AppColors.primary, size: 26),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchEvents,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 4),
            _monthHeader(),
            const SizedBox(height: 8),
            CalendarGrid(
              month: _currentMonth,
              selectedDay: _selectedDay,
              onDaySelected: (day) {
                setState(() {
                  _selectedDay = day;
                  _selectedDate = DateTime(
                    _currentMonth.year,
                    _currentMonth.month,
                    day,
                  );
                });
              },
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Events on ${DateFormat('EEE, MMM d').format(_selectedDate)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _eventsContent(),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(google_calendar.Event event) {
    return UpcomingEventItem(
      icon: Icons.calendar_today,
      title: event.summary?.trim().isNotEmpty == true
          ? event.summary!
          : 'Untitled event',
      time: _eventTime(event),
    );
  }
}
=======
import 'package:alarm_frontend/services/google_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:alarm_frontend/components/calendar_grid.dart';
import 'package:alarm_frontend/components/upcoming_event_item.dart';
import 'package:googleapis/calendar/v3.dart' as google_calendar;
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final GoogleSyncService _syncService = GoogleSyncService();
  int _selectedDay = DateTime.now().day;
  final DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<google_calendar.Event> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
  }

  Future<void> _loadCachedData() async {
    final cached = await _syncService.getCachedEvents();
    if (cached.isNotEmpty && mounted) {
      setState(() {
        _events = cached;
        _isLoading = false;
      });
    }
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    if (!mounted) return;
    if (_events.isEmpty) setState(() => _isLoading = true);
    
    final events = await _syncService.fetchUpcomingEvents();
    if (mounted) {
      setState(() {
        _events = events;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge?.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Calendar', style: AppTextStyles.heading),
        titleSpacing: 0,
        actions: [
          IconButton(onPressed: _fetchEvents, icon: const Icon(Icons.refresh, color: AppColors.primary, size: 26)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchEvents,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 4),
            Text(DateFormat('MMMM yyyy').format(DateTime.now()), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            CalendarGrid(
              month: _currentMonth,
              selectedDay: _selectedDay,
              onDaySelected: (day) => setState(() => _selectedDay = day),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Upcoming Events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 14),
                  if (_isLoading && _events.isEmpty)
                    const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  else if (_events.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text("No upcoming events found.")))
                  else
                    ..._events.map((event) => _buildEventItem(event)),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(google_calendar.Event event) {
    String timeStr = "All Day";
    if (event.start?.dateTime != null) {
      timeStr = DateFormat('jm').format(event.start!.dateTime!.toLocal());
    }
    return UpcomingEventItem(icon: Icons.calendar_today, title: event.summary ?? "No Title", time: timeStr);
  }
}
>>>>>>> origin/main
