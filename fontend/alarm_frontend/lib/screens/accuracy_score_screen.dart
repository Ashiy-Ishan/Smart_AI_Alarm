import 'package:alarm_frontend/models/model_accuracy.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alarm_frontend/components/accuracy_ring_gauge.dart';
import 'package:alarm_frontend/components/accuracy_metrics_card.dart';
import 'package:alarm_frontend/components/weekly_trend_card.dart';
import 'package:alarm_frontend/components/ai_insight_card.dart';
import 'package:alarm_frontend/models/accuracy_metric_model.dart';
import 'package:alarm_frontend/services/api_service.dart';

class AccuracyScoreScreen extends StatefulWidget {
  const AccuracyScoreScreen({super.key});

  @override
  State<AccuracyScoreScreen> createState() => _AccuracyScoreScreenState();
}

class _AccuracyScoreScreenState extends State<AccuracyScoreScreen> {
  ModelAccuracy? _accuracy;

  bool _loading = true;
  bool _refreshing = false;

  String? _error;

  @override
  void initState() {
    super.initState();

    _loadAccuracy();
  }

  Future<void> _loadAccuracy() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _loading = false;
        _error = 'You must be signed in to view model accuracy.';
      });

      return;
    }

    try {
      final result = await ApiService.getModelAccuracy(user.uid);

      if (!mounted) return;

      setState(() {
        _accuracy = result;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _refreshScore() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('You must be signed in.');

      return;
    }

    setState(() {
      _refreshing = true;
      _error = null;
    });

    try {
      final result = await ApiService.retrainModel(user.uid);

      if (!mounted) return;

      setState(() {
        _accuracy = result;
        _refreshing = false;
      });

      if (result.trained) {
        _showMessage('AI model retrained successfully.');
      } else {
        _showMessage(result.message ?? 'More alarm data is required.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _refreshing = false;
      });

      _showMessage('Unable to refresh score.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<AccuracyMetricModel> _buildMetrics() {
    final accuracy = _accuracy;

    if (accuracy == null) {
      return const [];
    }

    return [
      AccuracyMetricModel(
        icon: Icons.analytics_outlined,
        label: 'R² Score',
        value: accuracy.r2 == null ? '--' : accuracy.r2!.toStringAsFixed(3),
      ),
      AccuracyMetricModel(
        icon: Icons.timer_outlined,
        label: 'Mean Absolute Error',
        value: accuracy.mae == null
            ? '--'
            : '${accuracy.mae!.toStringAsFixed(2)} min',
      ),
      AccuracyMetricModel(
        icon: Icons.insights_outlined,
        label: 'RMSE',
        value: accuracy.rmse == null
            ? '--'
            : '${accuracy.rmse!.toStringAsFixed(2)} min',
      ),
      AccuracyMetricModel(
        icon: Icons.dataset_outlined,
        label: 'Training Samples',
        value: accuracy.sampleCount.toString(),
      ),
    ];
  }

  String _buildInsight() {
    final accuracy = _accuracy;

    if (accuracy == null || !accuracy.trained) {
      return accuracy?.message ??
          'Complete more alarms to give the AI enough data to learn your wake-up behaviour.';
    }

    final r2 = accuracy.r2 ?? 0;

    if (r2 >= 0.9) {
      return 'Your AI model is learning your alarm behaviour very well. Predictions currently show a strong fit with your historical data.';
    }

    if (r2 >= 0.7) {
      return 'Your AI model is performing well. More completed alarm sessions can further improve personalized buffer predictions.';
    }

    if (r2 >= 0.4) {
      return 'The AI is beginning to learn your routine, but your alarm behaviour still varies. More training data should improve predictions.';
    }

    return 'Your routine currently has high variation. Keep using the alarm normally so the AI can learn a more reliable personalized pattern.';
  }

  void _showReport() {
    final accuracy = _accuracy;

    if (accuracy == null || !accuracy.trained) {
      _showMessage(accuracy?.message ?? 'No trained model is available.');

      return;
    }

    final trainedAt = accuracy.trainedAt?.toLocal();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('AI Model Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _reportRow(
                'Accuracy Score',
                '${(accuracy.accuracyScore ?? 0).toStringAsFixed(1)}%',
              ),
              _reportRow('R² Score', (accuracy.r2 ?? 0).toStringAsFixed(4)),
              _reportRow(
                'MAE',
                '${(accuracy.mae ?? 0).toStringAsFixed(2)} min',
              ),
              _reportRow(
                'RMSE',
                '${(accuracy.rmse ?? 0).toStringAsFixed(2)} min',
              ),
              _reportRow('Training Samples', '${accuracy.sampleCount}'),
              _reportRow(
                'Last Trained',
                trainedAt == null
                    ? 'Unknown'
                    : '${trainedAt.year}-'
                          '${trainedAt.month.toString().padLeft(2, '0')}-'
                          '${trainedAt.day.toString().padLeft(2, '0')} '
                          '${trainedAt.hour.toString().padLeft(2, '0')}:'
                          '${trainedAt.minute.toString().padLeft(2, '0')}',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _reportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 20),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

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
                  icon: Icon(
                    Icons.arrow_back,
                    color: theme.textTheme.bodyLarge?.color,
                    size: 24,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Accuracy Score',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              Expanded(child: _buildBody()),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _showReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.cardColor,
                          side: BorderSide(
                            color: theme.dividerColor,
                            width: 1.5,
                          ),
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
                        onPressed: _refreshing ? null : _refreshScore,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.cardColor,
                          side: BorderSide(
                            color: theme.dividerColor,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _refreshing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
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

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAccuracy,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final accuracy = _accuracy;

    if (accuracy == null) {
      return const Center(child: Text('No accuracy data available.'));
    }

    if (!accuracy.trained) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.model_training_outlined, size: 64),

              const SizedBox(height: 16),

              const Text(
                'AI is still learning',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Text(
                accuracy.message ?? 'More alarm history is required.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                'Training samples: '
                '${accuracy.sampleCount}',
              ),
            ],
          ),
        ),
      );
    }

    final percentage = (accuracy.accuracyScore ?? 0).clamp(0.0, 100.0);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 8),

        Center(
          child: AccuracyRingGauge(
            accuracy: percentage / 100,
            label: 'Overall Accuracy',
          ),
        ),

        const SizedBox(height: 28),

        AccuracyMetricsCard(items: _buildMetrics()),

        const SizedBox(height: 14),

        WeeklyTrendCard(
          label: 'Training Data :',
          trend: '${accuracy.sampleCount} samples',
        ),

        const SizedBox(height: 14),

        AiInsightCard(title: 'AI Insight:', content: _buildInsight()),

        const SizedBox(height: 24),
      ],
    );
  }
}
