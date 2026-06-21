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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom top back arrow row
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),

              const SizedBox(height: 16),

              // Title Header
              const Text(
                'Accuracy Score',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 24),

                    // Ring Gauge Circular Progress (92%)
                    const Center(
                      child: AccuracyRingGauge(
                        accuracy: 0.92,
                        label: 'Overall Accuracy',
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Key Metrics Table Card
                    AccuracyMetricsCard(items: _metrics),

                    const SizedBox(height: 14),

                    // Weekly Trend Pill
                    const WeeklyTrendCard(
                      label: 'Weekly Trend :',
                      trend: 'Up',
                    ),

                    const SizedBox(height: 14),

                    // AI Insight Paragraph
                    const AiInsightCard(
                      title: 'AI Insight:',
                      content:
                      'Weekday predictions are highly accurate, but weekend patterns are less consistent.',
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Bottom Action Buttons

            ],
          ),
        ),
      ),
    );
  }
}