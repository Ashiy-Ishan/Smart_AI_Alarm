import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class InsightScreen extends StatelessWidget {
  const InsightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const Center(
        child: Text(
          "Insight Screen",
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
