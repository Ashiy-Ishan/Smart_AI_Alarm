// TODO Implement this library.
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