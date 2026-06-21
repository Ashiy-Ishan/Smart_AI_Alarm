// TODO Implement this library.
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