import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/components/sleep_analytics_card.dart';
import 'package:alarm_frontend/components/habit_learning_card.dart';
import 'package:alarm_frontend/components/accuracy_score_card.dart';

class InsightScreen extends StatelessWidget {
  const InsightScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

Sleeping_analytics_card.dart
import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class SleepAnalyticsCard extends StatelessWidget {
  const SleepAnalyticsCard({super.key});

  @override
  Widget build(BuildContext context) {
    const List<double> sleepValues = [6.0, 10.0, 5.0, 8.0, 9.0, 9.5, 10.5];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Sleep Analytics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '49h 12m Avg',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            width: double.infinity,
            child: CustomPaint(
              painter: _SleepChartPainter(sleepValues),
            ),
          ),
        ],
      ),
    );
  }
}

class _SleepChartPainter extends CustomPainter {
  final List<double> values;

  _SleepChartPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final double xMin = 30;
    final double xMax = size.width - 16;
    final double yMin = 16;
    final double yMax = size.height - 24;

    final double widthInterval = (xMax - xMin) / 6;

    final paintAxes = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final paintTicks = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw Y axis line
    canvas.drawLine(Offset(xMin, yMin - 8), Offset(xMin, yMax), paintAxes);

    // Draw X axis line
    canvas.drawLine(Offset(xMin, yMax), Offset(xMax + 8, yMax), paintAxes);

    // Draw Y Ticks and Labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    const int maxSleepVal = 16;
    for (int val = 2; val <= maxSleepVal; val += 2) {
      final double y = yMax - (val / maxSleepVal) * (yMax - yMin);
      canvas.drawLine(Offset(xMin - 4, y), Offset(xMin, y), paintTicks);

      textPainter.text = TextSpan(
        text: '$val',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 9,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(xMin - 16, y - 5));
    }

    // Draw "h" at the top of Y axis
    textPainter.text = const TextSpan(
      text: 'h',
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(xMin - 12, yMin - 16));

    // Draw X Ticks and Labels (Days 13 to 19)
    for (int i = 0; i < 7; i++) {
      final double x = xMin + i * widthInterval;
      canvas.drawLine(Offset(x, yMax), Offset(x, yMax + 4), paintTicks);

      textPainter.text = TextSpan(
        text: '${13 + i}',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 6, yMax + 8));
    }

    // Generate spline curve points
    final List<Offset> points = [];
    for (int i = 0; i < values.length; i++) {
      final double x = xMin + i * widthInterval;
      final double y = yMax - (values[i] / maxSleepVal) * (yMax - yMin);
      points.add(Offset(x, y));
    }

    // Draw Cubic Spline Path
    final Path path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final controlX = (p1.dx + p2.dx) / 2;
      path.cubicTo(controlX, p1.dy, controlX, p2.dy, p2.dx, p2.dy);
    }

    // Draw area gradient fill
    final Path fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, yMax);
    fillPath.lineTo(points.first.dx, yMax);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withOpacity(0.35),
          AppColors.primary.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTRB(xMin, yMin, xMax, yMax))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Draw curve stroke line
    final strokePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Habbit_learning_card.dart
import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class HabitLearningCard extends StatelessWidget {
  const HabitLearningCard({super.key});

  @override
  Widget build(BuildContext context) {
    const List<double> userValues = [12.0, 18.0, 21.0, 20.0, 17.0, 19.0, 15.0];
    const List<double> aiValues = [9.0, 17.0, 20.0, 17.5, 16.5, 17.0, 15.0];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Habit Learning',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'User Predict: 21m Avg',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'AI Predict: 23m Avg',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            width: double.infinity,
            child: CustomPaint(
              painter: _HabitChartPainter(
                userValues: userValues,
                aiValues: aiValues,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitChartPainter extends CustomPainter {
  final List<double> userValues;
  final List<double> aiValues;

  _HabitChartPainter({
    required this.userValues,
    required this.aiValues,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double xMin = 30;
    final double xMax = size.width - 16;
    final double yMin = 16;
    final double yMax = size.height - 24;

    final double widthInterval = (xMax - xMin) / 6;

    final paintAxes = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final paintTicks = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final paintGrid = Paint()
      ..color = AppColors.border.withOpacity(0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw Y axis line
    canvas.drawLine(Offset(xMin, yMin - 8), Offset(xMin, yMax), paintAxes);

    // Draw X axis line
    canvas.drawLine(Offset(xMin, yMax), Offset(xMax + 8, yMax), paintAxes);

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw Y Ticks, Labels, and horizontal grid lines for [12, 18, 24, 30]
    const List<int> yLabels = [12, 18, 24, 30];
    const double maxVal = 30.0;
    for (final val in yLabels) {
      final double y = yMax - (val / maxVal) * (yMax - yMin);
      canvas.drawLine(Offset(xMin - 4, y), Offset(xMin, y), paintTicks);

      textPainter.text = TextSpan(
        text: '$val',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 9,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(xMin - 16, y - 5));
    }

    // Draw X Ticks, Labels, and vertical grid lines (Days 13 to 19)
    for (int i = 0; i < 7; i++) {
      final double x = xMin + i * widthInterval;
      canvas.drawLine(Offset(x, yMax), Offset(x, yMax + 4), paintTicks);

      // Draw background vertical grid line
      canvas.drawLine(Offset(x, yMin - 4), Offset(x, yMax), paintGrid);

      textPainter.text = TextSpan(
        text: '${13 + i}',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 6, yMax + 8));
    }

    // Helper to generate and paint a curve
    void drawCurve({
      required List<double> data,
      required Color color,
      required double opacity,
    }) {
      final List<Offset> points = [];
      for (int i = 0; i < data.length; i++) {
        final double x = xMin + i * widthInterval;
        final double y = yMax - (data[i] / maxVal) * (yMax - yMin);
        points.add(Offset(x, y));
      }

      final Path path = Path();
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final controlX = (p1.dx + p2.dx) / 2;
        path.cubicTo(controlX, p1.dy, controlX, p2.dy, p2.dx, p2.dy);
      }

      final Path fillPath = Path.from(path);
      fillPath.lineTo(points.last.dx, yMax);
      fillPath.lineTo(points.first.dx, yMax);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTRB(xMin, yMin, xMax, yMax))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);

      final strokePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, strokePaint);
    }

    // 1. Draw User Predict Wave (light gray/white)
    drawCurve(
      data: userValues,
      color: const Color(0xFFC5C6CA),
      opacity: 0.18,
    );

    // 2. Draw AI Predict Wave (gold)
    drawCurve(
      data: aiValues,
      color: AppColors.primary,
      opacity: 0.28,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Accuracy_score_card.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/screens/accuracy_score_screen.dart';

class AccuracyScoreCard extends StatelessWidget {
  const AccuracyScoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AccuracyScoreScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Accuracy Score',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Left metrics: 88% + High (green)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '88%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'High',
                        style: TextStyle(
                          color: Color(0xFF8CE8B3),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                  ),
                ),

                // Right circular speedometer gauge
                Column(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 70,
                      child: CustomPaint(
                        painter: _GaugePainter(0.88),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Predictive Model',
                      style: TextStyle(
                        color: AppColors.textSecondary,
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

  _GaugePainter(this.accuracy);

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height - 4;
    final double radius = size.width / 2 - 10;

    final paintTrack = Paint()
      ..color = const Color(0xFF2C2F36)
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintActive = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw background arc (180 degrees)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      pi,
      pi,
      false,
      paintTrack,
    );

    // Draw foreground active arc (88%)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      pi,
      pi * accuracy,
      false,
      paintActive,
    );

    // Draw needle
    final needleAngle = pi + (pi * accuracy);
    final double needleLength = radius - 8;

    final double needleX = centerX + needleLength * cos(needleAngle);
    final double needleY = centerY + needleLength * sin(needleAngle);

    final needlePaint = Paint()
      ..color = const Color(0xFFE4E6EB)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(centerX, centerY), Offset(needleX, needleY), needlePaint);

    // Draw needle pin base center circle
    final pinPaint = Paint()
      ..color = const Color(0xFFE4E6EB)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), 6.0, pinPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
