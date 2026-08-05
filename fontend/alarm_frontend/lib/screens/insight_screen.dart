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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: const [
            SizedBox(height: 16),

            // Header Section
            Text(
              'Insights',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Last 7 days',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 24),

            // Sleep Analytics Card
            SleepAnalyticsCard(),

            SizedBox(height: 16),

            // Habit Learning Card
            HabitLearningCard(),

            SizedBox(height: 16),

            // Accuracy Score Card
            AccuracyScoreCard(),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
