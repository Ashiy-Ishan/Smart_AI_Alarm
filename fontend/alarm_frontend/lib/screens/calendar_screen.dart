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
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
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
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  else if (_events.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text("No upcoming events found.", style: TextStyle(color: AppColors.textSecondary))))
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
