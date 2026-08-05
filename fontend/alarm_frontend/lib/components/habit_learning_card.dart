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
      ..color = AppColors.border.withValues(alpha: 0.35)
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
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0.0),
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
