import 'package:alarm_frontend/screens/sleep_tracking_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/components/sleep_analytics_card.dart';
import 'package:alarm_frontend/components/habit_learning_card.dart';
import 'package:alarm_frontend/components/accuracy_score_card.dart';
import 'package:alarm_frontend/models/insight_data_model.dart';
import 'package:alarm_frontend/services/api_service.dart';

class InsightScreen extends StatefulWidget {
  const InsightScreen({super.key});

  @override
  State<InsightScreen> createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  InsightDataModel? _insights;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'You must be signed in to view insights.';
      });

      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final result = await ApiService.getInsights(user.uid, days: 7);

      if (!mounted) return;

      setState(() {
        _insights = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _openSleepTracking() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SleepTrackingScreen()),
    );

    // When the user comes back from Sleep Tracking,
    // reload the Insights data.
    if (!mounted) return;

    await _loadInsights();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadInsights,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                  color:
                      theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.7,
                      ) ??
                      AppColors.textSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 24),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadInsights,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (_insights != null) ...[
                SleepAnalyticsCard(sleep: _insights!.sleep),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _openSleepTracking,
                    icon: const Icon(Icons.bedtime_outlined),
                    label: const Text(
                      'Track Sleep',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                HabitLearningCard(habit: _insights!.habit),

                const SizedBox(height: 16),

                AccuracyScoreCard(accuracy: _insights!.accuracy),

                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
