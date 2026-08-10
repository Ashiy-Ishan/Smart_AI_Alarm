import 'package:alarm_frontend/models/sleep_insight_model.dart';
import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class SleepAnalyticsCard extends StatelessWidget {
  final SleepInsightModel sleep;
  const SleepAnalyticsCard({super.key, required this.sleep});

  String _formatAverageSleep() {
    final average = sleep.averageSleepHours;
    if (average == null) {
      return '--';
    }
    final hours = average.floor();
    final minutes = ((average - hours) * 60).round();
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m Avg';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final values = sleep.daily.map((item) => item.hours).toList();

    return Container(
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
              Text(
                'Sleep Analytics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                sleep.available ? _formatAverageSleep() : '--',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          if (!sleep.available)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  sleep.message ?? 'No sleep data available yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ),
            )
          else ...[
            Row(
              children: [
                Text(
                  '${sleep.sessionCount} sessions',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.7,
                    ),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Trend: ${sleep.trend}',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.7,
                    ),
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              width: double.infinity,
              child: CustomPaint(
                painter: _SleepChartPainter(
                  values,
                  theme.dividerColor,
                  theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6) ??
                      AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SleepChartPainter extends CustomPainter {
  final List<double> values;
  final Color borderColor;
  final Color textColor;

  _SleepChartPainter(this.values, this.borderColor, this.textColor);

  @override
  void paint(Canvas canvas, Size size) {
    final double xMin = 30;
    final double xMax = size.width - 16;
    final double yMin = 16;
    final double yMax = size.height - 24;

    final int pointCount = values.length;
    final double widthInterval = pointCount > 1
        ? (xMax - xMin) / (pointCount - 1)
        : 0;

    final paintAxes = Paint()
      ..color = borderColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final paintTicks = Paint()
      ..color = borderColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(xMin, yMin - 8), Offset(xMin, yMax), paintAxes);

    canvas.drawLine(Offset(xMin, yMax), Offset(xMax + 8, yMax), paintAxes);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    const double maxSleepVal = 12.0;
    for (int val = 2; val <= maxSleepVal; val += 2) {
      final double y = yMax - (val / maxSleepVal) * (yMax - yMin);
      canvas.drawLine(Offset(xMin - 4, y), Offset(xMin, y), paintTicks);

      textPainter.text = TextSpan(
        text: '$val',
        style: TextStyle(color: textColor, fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(xMin - 16, y - 5));
    }

    textPainter.text = TextSpan(
      text: 'h',
      style: TextStyle(
        color: textColor,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(xMin - 12, yMin - 16));

    final points = <Offset>[];

    for (int i = 0; i < pointCount; i++) {
      final double x = xMin + i * widthInterval;
      final double normalized = values[i].clamp(0.0, maxSleepVal).toDouble();
      final double y = yMax - (normalized / maxSleepVal) * (yMax - yMin);
      points.add(Offset(x, y));
      canvas.drawLine(Offset(x, yMax), Offset(x, yMax + 4), paintTicks);

      textPainter.text = TextSpan(
        text: '${i + 1}',
        style: TextStyle(color: textColor, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 3, yMax + 8));
    }

    if (points.length == 1) {
      canvas.drawCircle(points.first, 3, Paint()..color = AppColors.primary);
      return;
    }

    final Path path = Path();
    path.moveTo(points.first.dx, points.first.dy);
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
          AppColors.primary.withValues(alpha: 0.35),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTRB(xMin, yMin, xMax, yMax))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _SleepChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.textColor != textColor;
  }
}
