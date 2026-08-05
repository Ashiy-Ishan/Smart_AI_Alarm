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
          AppColors.primary.withValues(alpha: 0.35),
          AppColors.primary.withValues(alpha: 0.0),
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
