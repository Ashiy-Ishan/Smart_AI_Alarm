import 'package:alarm_frontend/providers/user_provider.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/components/primary_button.dart';
import 'package:alarm_frontend/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Wait until UserProvider is initialized or max 3 seconds
    int attempts = 0;
    while (!userProvider.isInitialized && attempts < 30) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    // Give another 1s for splash to look nice
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (userProvider.isAuthenticated) {
      Navigator.pushReplacementNamed(context, AppRoutes.main);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(), // Prevent manual scroll on splash
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Spacing
                      const SizedBox.shrink(),

                      // Center Content Group
                      Column(
                        children: [
                          // Dynamic Lottie size based on screen height
                          SizedBox(
                            height: constraints.maxHeight * 0.35,
                            child: Lottie.asset(
                              'assets/lotties/alarm.json',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Smarter Wake-Ups,\nBetter Days.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),

                      // Bottom Actions Group
                      Column(
                        children: [
                          PrimaryButton(
                            text: 'Get Started',
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.auth);
                            },
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'SUSL POWERED',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          // Added extra padding for different system nav bars
                          SizedBox(height: MediaQuery.of(context).padding.bottom > 0 ? 10 : 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
