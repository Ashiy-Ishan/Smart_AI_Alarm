import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:flutter/material.dart';

class GlowBackground extends StatelessWidget {
  final double size;
  final double blurRadius;
  final double spreadRadius;
  final double opacity;
  final Alignment alignment;

  const GlowBackground({
    super.key,
    this.size = 240,
    this.blurRadius = 120,
    this.spreadRadius = 20,
    this.opacity = 0.22,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(opacity),
                blurRadius: blurRadius,
                spreadRadius: spreadRadius,
              ),
            ],
          ),
        ),
      ),
    );
  }
}