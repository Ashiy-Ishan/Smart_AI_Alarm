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
  List<AgendaModel> _unifiedAgenda = []; 
  List<google_gmail.Message> _priorityItems = []; 
  bool _isLoading = true;
  bool _isGoogleLinked = true; 
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final linked = await _syncService.isLinked();
    if (!mounted) return;
    setState(() => _isGoogleLinked = linked);
    if (!linked) {
      setState(() => _isLoading = false);
      return;
    }
    final cachedAgenda = await _syncService.getCachedUnifiedAgenda();
    if (mounted && cachedAgenda.isNotEmpty) {
      setState(() {
        _unifiedAgenda = cachedAgenda;
        _isLoading = false;
      });
    }
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
<<<<<<< HEAD
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
=======
    final linked = await _syncService.isLinked();
    if (mounted) setState(() => _isGoogleLinked = linked);
    if (!linked) return;
    if (_unifiedAgenda.isEmpty) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _syncService.fetchUpcomingEvents(),
        _syncService.fetchPriorityMeetingEmails(),
      ]);
      final events = results[0] as List<google_calendar.Event>;
      final emails = results[1] as List<google_gmail.Message>;
      if (mounted) {
        final processedList = _processAndMergeData(events, emails);
        setState(() {
          _priorityItems = emails;
          _unifiedAgenda = processedList;
          _isLoading = false;
          _errorMessage = null;
        });
        _syncService.saveUnifiedAgenda(processedList);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Sync failed. Check connection.";
        });
      }
>>>>>>> origin/main
    }
  }

  List<AgendaModel> _processAndMergeData(List<google_calendar.Event> calendarEvents, List<google_gmail.Message> gmailMessages) {
    List<AgendaModel> mergedList = [];
    
    for (var event in calendarEvents) {
      DateTime? startTime = event.start?.dateTime ?? event.start?.date;
      DateTime? endTime = event.end?.dateTime ?? event.end?.date;
      if (startTime == null) continue;
      startTime = startTime.toLocal();
      endTime = endTime?.toLocal() ?? startTime.add(const Duration(hours: 1));
      
      bool isUpdated = (event.description?.toLowerCase().contains('rescheduled') ?? false) || 
                       (event.summary?.toLowerCase().contains('updated') ?? false);

      mergedList.add(AgendaModel(
        id: event.id ?? event.summary ?? "",
        time: DateFormat('HH:mm').format(startTime),
        endTime: DateFormat('HH:mm').format(endTime),
        title: event.summary ?? "No Title",
        subtitle: event.location ?? "No location",
        dateLabel: DateFormat('EEEE, MMM d').format(startTime),
        isUpdated: isUpdated,
        source: AgendaSource.googleCalendar,
        dateTime: startTime,
        originalTime: isUpdated ? "Previously" : null,
      ));
    }

    for (var msg in gmailMessages) {
      String subject = msg.payload?.headers?.firstWhere((h) => h.name == 'Subject', orElse: () => google_gmail.MessagePartHeader()).value ?? "";
      String snippet = msg.snippet ?? "";
      final timeRegex = RegExp(r'\b([01]?[0-9]|2[0-3]):[0-5][0-9]\b');
      final match = timeRegex.firstMatch("$subject $snippet");
      if (match != null) {
        String emailTimeStr = match.group(0)!;
        DateTime now = DateTime.now();
        final parts = emailTimeStr.split(':');
        DateTime emailDateTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));

        bool isDuplicate = false;
        int existingIndex = -1;
        for (int i = 0; i < mergedList.length; i++) {
          bool titleMatch = subject.toLowerCase().contains(mergedList[i].title.toLowerCase()) || mergedList[i].title.toLowerCase().contains(subject.toLowerCase());
          bool timeClose = mergedList[i].dateTime.difference(emailDateTime).inMinutes.abs() < 60;
          if (titleMatch && timeClose) {
            isDuplicate = true;
            existingIndex = i;
            break;
          }
        }

        if (isDuplicate) {
          final existing = mergedList[existingIndex];
          bool isNewerUpdate = subject.toLowerCase().contains('update') || subject.toLowerCase().contains('reschedule');
          if (isNewerUpdate && existing.time != emailTimeStr) {
            mergedList[existingIndex] = AgendaModel(
              id: existing.id,
              time: emailTimeStr,
              endTime: DateFormat('HH:mm').format(emailDateTime.add(const Duration(hours: 1))),
              title: existing.title,
              subtitle: "Update found in Gmail",
              dateLabel: existing.dateLabel,
              isUpdated: true,
              source: AgendaSource.gmail,
              dateTime: emailDateTime,
              originalTime: existing.time,
              originalEndTime: existing.endTime,
            );
          }
        } else {
          mergedList.add(AgendaModel(
            id: msg.id ?? subject,
            time: emailTimeStr,
            endTime: DateFormat('HH:mm').format(emailDateTime.add(const Duration(hours: 1))),
            title: subject,
            subtitle: "Detected from Gmail",
            dateLabel: "Today (Inbox)",
            source: AgendaSource.gmail,
            dateTime: emailDateTime,
            isUpdated: subject.toLowerCase().contains('update'),
          ));
        }
      }
    }
    mergedList.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return mergedList;
  }

  MeetingStatus _detectMeetingStatus(String text) {
    final lowerText = text.toLowerCase();
    if (lowerText.contains('cancel') || lowerText.contains('postpone')) return MeetingStatus.canceled;
    if (lowerText.contains('update') || lowerText.contains('reschedule') || lowerText.contains('changed')) return MeetingStatus.updated;
    if (lowerText.contains('schedule') || lowerText.contains('invite') || lowerText.contains('confirm')) return MeetingStatus.scheduled;
    return MeetingStatus.unknown;
  }

  String? _extractEmailBody(google_gmail.Message msg) {
    if (msg.payload?.parts != null) {
      try {
        final part = msg.payload!.parts!.firstWhere(
          (p) => p.mimeType == 'text/plain',
          orElse: () => msg.payload!.parts!.first,
        );
        return part.body?.data;
      } catch (e) {
        return msg.payload?.body?.data;
      }
    }
    return msg.payload?.body?.data;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
<<<<<<< HEAD

=======
>>>>>>> origin/main
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
<<<<<<< HEAD
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
=======
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Schedule', style: AppTextStyles.heading), const SizedBox(height: 2), Text(DateFormat('EEE, MMM d').format(DateTime.now()), style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppColors.textSecondary, fontSize: 13))]),
                  IconButton(onPressed: _fetchData, icon: const Icon(Icons.refresh, color: AppColors.primary, size: 26)),
>>>>>>> origin/main
                ],
              ),
              if (_errorMessage != null) Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
              const SizedBox(height: 24),
<<<<<<< HEAD

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
=======
              if (!_isGoogleLinked) _buildLinkRequiredUI() else ...[
                const Text('Professional Priority Scan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (_isLoading && _priorityItems.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())) else if (_priorityItems.isEmpty) const GmailScanCard(title: 'All Caught Up', subtitle: 'No new professional updates found.') else ..._priorityItems.take(3).map((item) {
                  final snippet = item.snippet ?? "";
                  final from = item.payload?.headers?.firstWhere((h) => h.name == 'From', orElse: () => google_gmail.MessagePartHeader()).value ?? "Unknown";
                  final subject = item.payload?.headers?.firstWhere((h) => h.name == 'Subject', orElse: () => google_gmail.MessagePartHeader()).value ?? "";
>>>>>>> origin/main
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10), 
                    child: GmailScanCard(
                      title: subject.isNotEmpty ? subject : from, 
                      subtitle: snippet.isNotEmpty ? snippet : "No details", 
                      status: _detectMeetingStatus("$subject $snippet"),
                      fullBody: _extractEmailBody(item),
                    )
                  );
                }),
<<<<<<< HEAD

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

=======
                const SizedBox(height: 24),
                const Text('Synced Agenda', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (_isLoading && _unifiedAgenda.isEmpty) const SizedBox.shrink() else if (_unifiedAgenda.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No events scheduled", style: TextStyle(color: Colors.grey)))) else ..._buildAgendaWidgets(),
              ],
>>>>>>> origin/main
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _fetchData, backgroundColor: AppColors.primary, child: const Icon(Icons.sync, color: Colors.black, size: 28)),
    );
  }

  Widget _buildLinkRequiredUI() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withOpacity(0.3))),
      child: Column(
        children: [
          const Icon(Icons.link_off, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text("Google Services Not Linked", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text("Connect your Google account to sync your calendar agenda.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () async { final account = await _syncService.linkAccount(); if (account != null) _loadInitialData(); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: const Text("Connect Google Account", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  List<Widget> _buildAgendaWidgets() {
    List<Widget> widgets = [];
    String? lastDate;
    for (int i = 0; i < _unifiedAgenda.length; i++) {
      final agenda = _unifiedAgenda[i];
      bool showDate = agenda.dateLabel != lastDate;
      lastDate = agenda.dateLabel;
      widgets.add(AgendaTimelineItem(showDate: showDate, agenda: agenda, isLast: i == _unifiedAgenda.length - 1));
    }
    return widgets;
  }
}
