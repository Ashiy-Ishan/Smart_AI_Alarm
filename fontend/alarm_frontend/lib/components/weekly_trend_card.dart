import 'package:flutter/material.dart';

class WeeklyTrendCard extends StatelessWidget {
  final String label;
  final String trend;

  const WeeklyTrendCard({
    super.key,
    required this.label,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.arrow_upward_rounded,
            color: Color(0xFF8CE8B3),
            size: 22,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            "+12%", // trend text from example
            style: TextStyle(
              color: Color(0xFF8CE8B3),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}