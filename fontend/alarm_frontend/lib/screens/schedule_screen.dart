import 'package:alarm_frontend/services/google_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:alarm_frontend/components/gmail_scan_card.dart';
import 'package:alarm_frontend/components/agenda_timeline_item.dart';
import 'package:alarm_frontend/models/agenda_model.dart';
import 'package:googleapis/calendar/v3.dart' as google_calendar;
import 'package:googleapis/gmail/v1.dart' as google_gmail;
import 'package:intl/intl.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final GoogleSyncService _syncService = GoogleSyncService();
  List<google_calendar.Event> _events = [];
  List<google_gmail.Message> _emails = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _syncService.fetchUpcomingEvents(),
      _syncService.fetchLatestEmails(),
    ]);

    if (mounted) {
      setState(() {
        _events = results[0] as List<google_calendar.Event>;
        _emails = results[1] as List<google_gmail.Message>;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Schedule', style: AppTextStyles.heading),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('EEE, MMM d').format(DateTime.now()),
                        style: TextStyle(
                          color:
                              theme.textTheme.bodyMedium?.color?.withValues(
                                alpha: 0.7,
                              ) ??
                              AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _fetchData,
                    icon: const Icon(
                      Icons.refresh,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'Gmail Priority Scan',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 12),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_emails.isEmpty)
                const GmailScanCard(
                  title: 'No Emails',
                  subtitle: 'You are all caught up!',
                )
              else
                ..._emails.take(2).map((msg) {
                  String from = "Unknown";
                  if (msg.payload?.headers != null) {
                    from =
                        msg.payload!.headers!
                            .firstWhere(
                              (h) => h.name == 'From',
                              orElse: () => google_gmail.MessagePartHeader(),
                            )
                            .value ??
                        "Unknown";
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GmailScanCard(
                      title: from.split('<').first.trim(),
                      subtitle: msg.snippet ?? "No snippet available",
                    ),
                  );
                }),

              const SizedBox(height: 24),

              const Text(
                'Synced Agenda',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 12),

              if (_isLoading)
                const SizedBox.shrink()
              else if (_events.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      "No events scheduled",
                      style: TextStyle(
                        color:
                            theme.textTheme.bodyMedium?.color?.withValues(
                              alpha: 0.6,
                            ) ??
                            AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                ..._events.map((event) {
                  String time = "All Day";
                  if (event.start?.dateTime != null) {
                    time = DateFormat(
                      'HH:mm',
                    ).format(event.start!.dateTime!.toLocal());
                  }
                  return AgendaTimelineItem(
                    agenda: AgendaModel(
                      time: time,
                      title: event.summary ?? "No Title",
                      subtitle: event.location ?? "No location",
                    ),
                  );
                }),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchData,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.sync, color: Colors.black, size: 28),
      ),
    );
  }
}
