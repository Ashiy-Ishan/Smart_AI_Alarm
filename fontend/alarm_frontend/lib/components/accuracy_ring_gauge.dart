import 'dart:math';
import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';

class AccuracyRingGauge extends StatelessWidget {
  final double accuracy; // e.g. 0.92
  final String label;

  const AccuracyRingGauge({
    super.key,
    required this.accuracy,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      height: 190,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 176,
            height: 176,
            child: CustomPaint(
              painter: _RingPainter(accuracy),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(accuracy * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFC5C6CA),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double accuracy;

  _RingPainter(this.accuracy);

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.width / 2 - 8;

    final paintTrack = Paint()
      ..color = const Color(0xFF2C2F36)
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke;

    final paintActive = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw full background circle
    canvas.drawCircle(Offset(centerX, centerY), radius, paintTrack);

    // Draw active progress arc (starting from top: -pi / 2)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      -pi / 2,
      2 * pi * accuracy,
      false,
      paintActive,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}