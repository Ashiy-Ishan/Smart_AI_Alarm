import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/components/sleep_analytics_card.dart';
import 'package:alarm_frontend/components/habit_learning_card.dart';
import 'package:alarm_frontend/components/accuracy_score_card.dart';

class InsightScreen extends StatefulWidget {
  const InsightScreen({super.key});

  @override
  State<InsightScreen> createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 16),

            const Text(
              'Insights',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Last 7 days',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppColors.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 24),

            const SleepAnalyticsCard(),

            const SizedBox(height: 16),

            const HabitLearningCard(),

            const SizedBox(height: 16),

            const AccuracyScoreCard(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
