import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/components/accuracy_ring_gauge.dart';
import 'package:alarm_frontend/components/accuracy_metrics_card.dart';
import 'package:alarm_frontend/components/weekly_trend_card.dart';
import 'package:alarm_frontend/components/ai_insight_card.dart';
import 'package:alarm_frontend/models/accuracy_metric_model.dart';

class AccuracyScoreScreen extends StatefulWidget {
  const AccuracyScoreScreen({super.key});

  @override
  State<AccuracyScoreScreen> createState() => _AccuracyScoreScreenState();
}

class _AccuracyScoreScreenState extends State<AccuracyScoreScreen> {
  final List<AccuracyMetricModel> _metrics = const [
    AccuracyMetricModel(
      icon: Icons.wb_cloudy_outlined,
      label: 'Reminder Accuracy',
      value: '95%',
    ),
    AccuracyMetricModel(
      icon: Icons.bedtime_outlined,
      label: 'Sleep Prediction',
      value: '89%',
    ),
    AccuracyMetricModel(
      icon: Icons.directions_walk_rounded,
      label: 'Motion Detection',
      value: '91%',
    ),
    AccuracyMetricModel(
      icon: Icons.calendar_month_outlined,
      label: 'schedule Suggestions',
      value: '93%',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge?.color, size: 24),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Accuracy Score',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 24),

                    const Center(
                      child: AccuracyRingGauge(
                        accuracy: 0.92,
                        label: 'Overall Accuracy',
                      ),
                    ),

                    const SizedBox(height: 28),

                    AccuracyMetricsCard(items: _metrics),

                    const SizedBox(height: 14),

                    const WeeklyTrendCard(
                      label: 'Weekly Trend :',
                      trend: 'Up',
                    ),

                    const SizedBox(height: 14),

                    const AiInsightCard(
                      title: 'AI Insight:',
                      content:
                          'Weekday predictions are highly accurate, but weekend patterns are less consistent.',
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.cardColor,
                          side: BorderSide(color: theme.dividerColor, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'View Report',
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.cardColor,
                          side: BorderSide(color: theme.dividerColor, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Refresh Score',
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
