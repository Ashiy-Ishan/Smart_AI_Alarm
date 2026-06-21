import 'package:flutter/material.dart';

class GlowBackground extends StatelessWidget {
  final double size;
  final double blurRadius;
  final double spreadRadius;
  final Alignment alignment;
  final Color glowColor;

  const GlowBackground({
    super.key,
    this.size = 240,
    this.blurRadius = 120,
    this.spreadRadius = 20,
    this.glowColor = const Color(0x3DD9B56D),
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
                color: glowColor,
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
