import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class BottomNavBarItem {
  final IconData icon;
  final String label;

  const BottomNavBarItem({required this.icon, required this.label});
}

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
    final theme = Theme.of(context);
    final List<BottomNavBarItem> navItems = [
      const BottomNavBarItem(icon: Icons.home_outlined, label: 'Home'),
      const BottomNavBarItem(icon: Icons.calendar_today, label: 'Schedule'),
      const BottomNavBarItem(icon: Icons.hub_outlined, label: 'Hub'),
      const BottomNavBarItem(icon: Icons.bar_chart, label: 'Insight'),
      const BottomNavBarItem(icon: Icons.person_outline, label: 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark 
            ? const Color(0xFF1A1D24) 
            : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: theme.brightness == Brightness.light ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ] : null,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navItems.length, (index) {
                final bool isSelected = currentIndex == index;
                final item = navItems[index];
                
                return GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 200),
                        tween: Tween<double>(
                          begin: isSelected ? 1.0 : 0.9,
                          end: isSelected ? 1.1 : 1.0,
                        ),
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? AppColors.primary.withOpacity(0.1) 
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item.icon,
                                size: 24,
                                color: isSelected
                                    ? AppColors.primary
                                    : theme.textTheme.bodyMedium?.color?.withOpacity(0.5) ?? AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
