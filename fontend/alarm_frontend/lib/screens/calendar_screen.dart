import 'package:alarm_frontend/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:alarm_frontend/components/calendar_grid.dart';
import 'package:alarm_frontend/components/upcoming_event_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _selectedDay = DateTime.now().day;

  final DateTime _currentMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  List<Map<String, dynamic>> _events = [];

  bool _isLoading = true;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('User is not logged in');
      }

      final response = await ApiService.get(
        '/calendar/events/${user.uid}?hours_ahead=168',
      );

      final List<dynamic> eventData = response['events'] ?? [];

      if (!mounted) return;

      setState(() {
        _events = eventData
            .map((event) => Map<String, dynamic>.from(event))
            .toList();

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Calendar backend error: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to load calendar events.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            Navigator.of(context).pop();
          },
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

            Text(
              DateFormat('MMMM yyyy').format(DateTime.now()),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 16),

            CalendarGrid(
              month: _currentMonth,
              selectedDay: _selectedDay,
              onDaySelected: (day) {
                setState(() {
                  _selectedDay = day;
                });
              },
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upcoming Events',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (_errorMessage != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else if (_events.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No upcoming events found.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ..._events.map(_buildEventItem),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(Map<String, dynamic> event) {
    String timeText = 'All Day';

    final dynamic start = event['start'];

    if (start != null) {
      try {
        DateTime? dateTime;

        if (start is String) {
          dateTime = DateTime.tryParse(start);
        } else if (start is Map) {
          final dynamic dateTimeValue = start['dateTime'];

          final dynamic dateValue = start['date'];

          if (dateTimeValue != null) {
            dateTime = DateTime.tryParse(dateTimeValue.toString());
          } else if (dateValue != null) {
            timeText = 'All Day';
          }
        }

        if (dateTime != null) {
          timeText = DateFormat('jm').format(dateTime.toLocal());
        }
      } catch (e) {
        debugPrint('Calendar event parsing error: $e');
      }
    }

    return UpcomingEventItem(
      icon: Icons.calendar_today,
      title: event['summary']?.toString() ?? 'No Title',
      time: timeText,
    );
  }
}
