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
    // Wait a brief moment for Firebase to initialize the user state
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (userProvider.isAuthenticated) {
      // User is already logged in, go straight to main screen
      Navigator.pushReplacementNamed(context, AppRoutes.main);
    }
    // If not authenticated, we stay on this screen and let them click "Get Started"
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 100,
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Lottie.asset('assets/lotties/alarm.json'),
                  const SizedBox(height: 5),
                  const Text(
                    'Smarter Wake-Ups,\nBetter Days.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(flex: 1),
                  PrimaryButton(
                    text: 'Get Started',
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.auth);
                    },
                  ),
                  const Spacer(flex: 2),
                  const Text(
                    'SUSL POWERED',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
