import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      Icons.home_outlined,
      Icons.calendar_today,
      Icons.hub_outlined,
      Icons.bar_chart,
      Icons.person_outline,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(color: const Color(0xFF1A1D24)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          return GestureDetector(
            onTap: () => onTap(index),
            child: Icon(
              items[index],
              size: 26,
              color: currentIndex == index
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          );
        }),
      ),
    );
  }
}
