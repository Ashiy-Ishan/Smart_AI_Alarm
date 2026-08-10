import 'dart:math';
import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/models/model_accuracy.dart';
import 'package:alarm_frontend/screens/accuracy_score_screen.dart';

class AccuracyScoreCard extends StatelessWidget {
  final ModelAccuracy accuracy;
  const AccuracyScoreCard({super.key, required this.accuracy});

  String _getLabel(double score) {
    if (!accuracy.trained) {
      return 'Learning';
    }
    if (score >= 80) {
      return 'High';
    }
    if (score >= 50) {
      return 'Moderate';
    }
    return 'Low';
  }

  Color _getLabelColor(double score) {
    if (!accuracy.trained) {
      return AppColors.textSecondary;
    }
    if (score >= 80) {
      return const Color(0xFF8CE8B3);
    }
    if (score >= 50) {
      return AppColors.primary;
    }
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = (accuracy.accuracyScore ?? 0.0).clamp(0.0, 100.0).toDouble();
    final fraction = score / 100.0;
    final label = _getLabel(score);
    final labelColor = _getLabelColor(score);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AccuracyScoreScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Accuracy Score',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.textTheme.bodyLarge?.color,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        accuracy.trained
                            ? '${score.toStringAsFixed(0)}%'
                            : '--',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          color: labelColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Text(
                        accuracy.trained
                            ? '${accuracy.sampleCount} training samples'
                            : accuracy.message ?? 'More data needed',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.65,
                          ),
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                  ),
                ),

                Column(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 70,
                      child: CustomPaint(
                        painter: _GaugePainter(fraction, theme.dividerColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Predictive Model',
                      style: TextStyle(
                        color:
                            theme.textTheme.bodyMedium?.color?.withValues(
                              alpha: 0.7,
                            ) ??
                            AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double accuracy;
  final Color trackColor;
  _GaugePainter(this.accuracy, this.trackColor);
  @override
  void paint(Canvas canvas, Size size) {
    final safeAccuracy = accuracy.clamp(0.0, 1.0).toDouble();
    final centerX = size.width / 2;
    final centerY = size.height - 4;
    final radius = size.width / 2 - 10;
    final paintTrack = Paint()
      ..color = trackColor
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final paintActive = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      pi,
      pi,
      false,
      paintTrack,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      pi,
      pi * safeAccuracy,
      false,
      paintActive,
    );
    final needleAngle = pi + (pi * safeAccuracy);
    final needleLength = radius - 8;
    final needleX = centerX + needleLength * cos(needleAngle);
    final needleY = centerY + needleLength * sin(needleAngle);
    final needlePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(needleX, needleY),
      needlePaint,
    );
    final pinPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), 6.0, pinPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.accuracy != accuracy ||
        oldDelegate.trackColor != trackColor;
  }
}
