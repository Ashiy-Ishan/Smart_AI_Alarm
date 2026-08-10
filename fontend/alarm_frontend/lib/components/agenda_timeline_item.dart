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
    
    return IntrinsicHeight(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              agenda.time,
              style: TextStyle(
                color:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
                    AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
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
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
          if (showDate && agenda.dateLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    agenda.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    agenda.subtitle,
                    style: TextStyle(
                      color:
                          theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.7,
                          ) ??
                          AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    agenda.dateLabel!,
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. LEFT SIDE: TIME HISTORY
                SizedBox(
                  width: 65,
                  child: Column(
                    children: [
                      // Current / New Time
                      Text(
                        "${agenda.time}\n${agenda.endTime}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, height: 1.2),
                      ),
                      
                      // PREVIOUS TIME (If updated) - Grayed and Strikethrough
                      if (agenda.isUpdated && agenda.originalTime != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          "Was:\n${agenda.originalTime}",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
                            fontSize: 9,
                            height: 1.1
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // 2. TIMELINE BAR
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: agenda.isUpdated ? Colors.orangeAccent : (agenda.source == AgendaSource.googleCalendar ? AppColors.primary : const Color(0xFF4A90E2)),
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.scaffoldBackgroundColor, width: 2.5),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isLast ? Colors.transparent : theme.dividerColor.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 14),
                
                // 3. EVENT CARD
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        // If updated, show the "PREVIOUS" slot block as a ghost
                        if (agenda.isUpdated && agenda.originalTime != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.history, size: 12, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  "Original Schedule: ${agenda.originalTime} - ${agenda.originalEndTime ?? ''}",
                                  style: const TextStyle(fontSize: 10, color: Colors.grey, decoration: TextDecoration.lineThrough),
                                ),
                              ],
                            ),
                          ),

                        // NEW / CURRENT Schedule Block
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: agenda.isUpdated ? Colors.orangeAccent.withOpacity(0.05) : theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: agenda.isUpdated ? Colors.orangeAccent : (agenda.source == AgendaSource.googleCalendar ? AppColors.primary.withOpacity(0.5) : const Color(0xFF4A90E2).withOpacity(0.5)),
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
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                  ),
                                  Icon(
                                    agenda.source == AgendaSource.googleCalendar ? Icons.calendar_today : Icons.mail_outline,
                                    size: 14,
                                    color: agenda.isUpdated ? Colors.orangeAccent : (agenda.source == AgendaSource.googleCalendar ? AppColors.primary : const Color(0xFF4A90E2)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                agenda.subtitle,
                                style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 12),
                              ),
                              if (agenda.isUpdated) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orangeAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    "NEW SCHEDULE CONFIRMED",
                                    style: TextStyle(color: Colors.orangeAccent, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ]
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
      ),
    );
  }
}
