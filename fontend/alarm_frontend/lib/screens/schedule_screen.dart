import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:alarm_frontend/components/gmail_scan_card.dart';
import 'package:alarm_frontend/components/agenda_timeline_item.dart';
import 'package:alarm_frontend/models/agenda_model.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    const List<AgendaModel> agenda = [
      AgendaModel(
        time: '08:00',
        title: 'Workout',
        subtitle: 'Tenm row 12 month',
      ),
      AgendaModel(
        time: '09:30',
        title: 'Team Sync',
        subtitle: 'Temstrow 12:00pm',
      ),
      AgendaModel(
        time: '11:30',
        title: 'Client Call',
        subtitle: 'Terrnrrow 12:00pm',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Schedule', style: AppTextStyles.heading),
                    SizedBox(height: 2),
                    Text(
                      'Tue, Nov 12',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                const Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.primary,
                  size: 26,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Gmail Priority Scan
            const Text(
              'Gmail Priority Scan',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            // Email cards — both navigate to EmailScreen
            const GmailScanCard(
              title: '3 Emails',
              subtitle: "Mark 'Urgent',tommorro....",
            ),
            const SizedBox(height: 10),
            const GmailScanCard(
              title: 'Sarah',
              subtitle: "Sarah 'Update',so daw",
            ),

            const SizedBox(height: 24),

            // Synced Agenda
            const Text(
              'Synced Agenda',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            // Timeline items
            ...agenda.map((item) => AgendaTimelineItem(agenda: item)),

            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
    );
  }
}
