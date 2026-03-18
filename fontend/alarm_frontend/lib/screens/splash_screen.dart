import 'package:alarm_frontend/components/app_colors.dart';
import 'package:alarm_frontend/components/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              SizedBox(height: 150),
              // Lottie in the middle
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

              SizedBox(height: 50),

              PrimaryButton(
                text: 'Get Started',
                onPressed: () {
                  //Navigator.push(
                  //context,
                   //MaterialPageRoute(
                    //builder: (_) => const AuthScreen(),
                   //initialPage: AuthPageModel.login(),
                  //),
                  //);
                },
              ),

              const SizedBox(height: 110),

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
    );
  }
}
