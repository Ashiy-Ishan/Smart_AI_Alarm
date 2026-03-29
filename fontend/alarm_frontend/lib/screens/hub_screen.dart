import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class HubScreen extends StatelessWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const Center(
        child: Text("Hub Screen"),
      ),
    );
  }
}