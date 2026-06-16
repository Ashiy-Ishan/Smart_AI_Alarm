import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:alarm_frontend/components/gmail_scan_card.dart';
import 'package:alarm_frontend/components/agenda_timeline_item.dart';
import 'package:alarm_frontend/models/agenda_model.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
Agenda_model.dart-model
class AgendaModel {
  final String time;
  final String title;
  final String subtitle;

  const AgendaModel({
    required this.time,
    required this.title,
    required this.subtitle,
  });
}

Gmail_scan_card.dart
import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/screens/email_screen.dart';

class GmailScanCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const GmailScanCard({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const EmailScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Gmail M icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text(
                  'M',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

Agenda_timeline_item.dart
import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/models/agenda_model.dart';

class AgendaTimelineItem extends StatelessWidget {
  final AgendaModel agenda;

  const AgendaTimelineItem({
    super.key,
    required this.agenda,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time label
          SizedBox(
            width: 48,
            child: Text(
              agenda.time,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          // Gold left border accent
          Container(
            width: 3,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    agenda.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    agenda.subtitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


