import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/models/habit_insight_model.dart';

class HabitLearningCard extends StatelessWidget {
  final HabitInsightModel habit;
  const HabitLearningCard({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userValues = habit.daily
        .map((item) => item.actualBufferMinutes)
        .toList();
    final aiValues = habit.daily.map((item) => item.aiBufferMinutes).toList();
    final userAverage = habit.averageActualBuffer;
    final aiAverage = habit.averageAiBuffer;

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
          const Text(
            'Habit Learning',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (!habit.available)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  habit.message ?? 'More alarm history is required.',
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    userAverage == null
                        ? 'User Actual: --'
                        : 'User Actual: '
                              '${userAverage.toStringAsFixed(0)}m Avg',
                    style: TextStyle(
                      color:
                          theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.7,
                          ) ??
                          AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  aiAverage == null
                      ? 'AI Predict: --'
                      : 'AI Predict: '
                            '${aiAverage.toStringAsFixed(0)}m Avg',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Trend: ${habit.trend} • '
              'Error: '
              '${habit.averageErrorMinutes?.toStringAsFixed(1) ?? '--'} min',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.65,
                ),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              width: double.infinity,
              child: CustomPaint(
                painter: _HabitChartPainter(
                  userValues: userValues,
                  aiValues: aiValues,
                  borderColor: theme.dividerColor,
                  textColor:
                      theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.6,
                      ) ??
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

class _HabitChartPainter extends CustomPainter {
  final List<double> userValues;
  final List<double> aiValues;
  final Color borderColor;
  final Color textColor;

  _HabitChartPainter({
    required this.userValues,
    required this.aiValues,
    required this.borderColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (userValues.isEmpty || aiValues.isEmpty) {
      return;
    }
    final int count = userValues.length < aiValues.length
        ? userValues.length
        : aiValues.length;
    if (count == 0) {
      return;
    }
    final double xMin = 30;
    final double xMax = size.width - 16;
    final double yMin = 16;
    final double yMax = size.height - 24;

    final double widthInterval = count > 1 ? (xMax - xMin) / (count - 1) : 0.0;

    final allValues = [...userValues.take(count), ...aiValues.take(count)];
    double maxValue = allValues.fold(
      0.0,
      (previous, element) => element > previous ? element : previous,
    );
    maxValue = (maxValue + 5).clamp(30.0, 120.0).toDouble();

    final paintAxes = Paint()
      ..color = borderColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final paintGrid = Paint()
      ..color = borderColor.withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(xMin, yMin - 8), Offset(xMin, yMax), paintAxes);
    canvas.drawLine(Offset(xMin, yMax), Offset(xMax + 8, yMax), paintAxes);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final ySteps = [
      maxValue * 0.25,
      maxValue * 0.50,
      maxValue * 0.75,
      maxValue,
    ];
    for (final value in ySteps) {
      final y = yMax - (value / maxValue) * (yMax - yMin);
      textPainter.text = TextSpan(
        text: value.round().toString(),
        style: TextStyle(color: textColor, fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(xMin - 24, y - 5));
    }
    for (int i = 0; i < count; i++) {
      final x = xMin + i * widthInterval;
      canvas.drawLine(Offset(x, yMin - 4), Offset(x, yMax), paintGrid);
      textPainter.text = TextSpan(
        text: '${i + 1}',
        style: TextStyle(color: textColor, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 3, yMax + 8));
    }
    void drawCurve({
      required List<double> data,
      required Color color,
      required double opacity,
    }) {
      final points = <Offset>[];
      for (int i = 0; i < count; i++) {
        final x = xMin + i * widthInterval;
        final normalized = data[i].clamp(0.0, maxValue).toDouble();
        final y = yMax - (normalized / maxValue) * (yMax - yMin);
        points.add(Offset(x, y));
      }
      if (points.length == 1) {
        canvas.drawCircle(points.first, 3, Paint()..color = color);
        return;
      }
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final controlX = (p1.dx + p2.dx) / 2;
        path.cubicTo(controlX, p1.dy, controlX, p2.dy, p2.dx, p2.dy);
      }
      final fillPath = Path.from(path);
      fillPath.lineTo(points.last.dx, yMax);
      fillPath.lineTo(points.first.dx, yMax);
      fillPath.close();
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
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

    drawCurve(
      data: userValues,
      color: textColor.withValues(alpha: 0.8),
      opacity: 0.18,
    );
    drawCurve(data: aiValues, color: AppColors.primary, opacity: 0.28);
  }

  @override
  bool shouldRepaint(covariant _HabitChartPainter oldDelegate) {
    return oldDelegate.userValues != userValues ||
        oldDelegate.aiValues != aiValues ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.textColor != textColor;
  }
}
