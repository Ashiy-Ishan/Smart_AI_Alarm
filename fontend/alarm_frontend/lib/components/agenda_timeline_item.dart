import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/models/agenda_model.dart';

class AgendaTimelineItem extends StatelessWidget {
  final AgendaModel agenda;
  final bool showDate;
  final bool isLast;

  const AgendaTimelineItem({
    super.key,
    required this.agenda,
    this.showDate = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // =====================================================
        // DATE LABEL
        // =====================================================
        if (showDate && agenda.dateLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  agenda.dateLabel!,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

        // =====================================================
        // TIMELINE ROW
        // =====================================================
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // =================================================
              // LEFT SIDE - TIME
              // =================================================
              SizedBox(
                width: 65,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      agenda.endTime.isNotEmpty
                          ? '${agenda.time}\n${agenda.endTime}'
                          : agenda.time,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),

                    if (agenda.isUpdated && agenda.originalTime != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Was:\n${agenda.originalTime}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.3,
                          ),
                          fontSize: 9,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // =================================================
              // TIMELINE BAR
              // =================================================
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _timelineColor(),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 2.5,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Container(
                      width: 2,
                      color: isLast
                          ? Colors.transparent
                          : theme.dividerColor.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 14),

              // =================================================
              // EVENT CONTENT
              // =================================================
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===========================================
                      // ORIGINAL SCHEDULE
                      // ===========================================
                      if (agenda.isUpdated && agenda.originalTime != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.history,
                                size: 12,
                                color: Colors.grey,
                              ),

                              const SizedBox(width: 8),

                              Expanded(
                                child: Text(
                                  agenda.originalEndTime != null &&
                                          agenda.originalEndTime!.isNotEmpty
                                      ? 'Original Schedule: '
                                            '${agenda.originalTime} - '
                                            '${agenda.originalEndTime}'
                                      : 'Original Schedule: '
                                            '${agenda.originalTime}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ===========================================
                      // CURRENT EVENT CARD
                      // ===========================================
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: agenda.isUpdated
                              ? Colors.orangeAccent.withValues(alpha: 0.05)
                              : theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _borderColor(),
                            width: agenda.isUpdated ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    agenda.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),

                                Icon(
                                  agenda.source == AgendaSource.googleCalendar
                                      ? Icons.calendar_today
                                      : Icons.mail_outline,
                                  size: 14,
                                  color: _timelineColor(),
                                ),
                              ],
                            ),

                            const SizedBox(height: 4),

                            Text(
                              agenda.subtitle,
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),

                            if (agenda.isUpdated) ...[
                              const SizedBox(height: 10),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orangeAccent.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'NEW SCHEDULE CONFIRMED',
                                  style: TextStyle(
                                    color: Colors.orangeAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // COLORS
  // =========================================================

  Color _timelineColor() {
    if (agenda.isUpdated) {
      return Colors.orangeAccent;
    }

    if (agenda.source == AgendaSource.googleCalendar) {
      return AppColors.primary;
    }

    return const Color(0xFF4A90E2);
  }

  Color _borderColor() {
    if (agenda.isUpdated) {
      return Colors.orangeAccent;
    }

    if (agenda.source == AgendaSource.googleCalendar) {
      return AppColors.primary.withValues(alpha: 0.5);
    }

    return const Color(0xFF4A90E2).withValues(alpha: 0.5);
  }
}
