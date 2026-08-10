import 'package:alarm_frontend/components/glow_bg.dart';
import 'package:alarm_frontend/components/primary_button.dart';
import 'package:alarm_frontend/routes/app_routes.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:flutter/material.dart';

class AccountVerifiedScreen extends StatelessWidget {
  final VoidCallback? onContinue;

  const AccountVerifiedScreen({super.key, this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const GlowBackground(
            size: 320,
            blurRadius: 140,
            spreadRadius: 28,
            alignment: Alignment.center,
            glowColor: Color(0x30D9B56D),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const Spacer(),
                  Text(
                    'Account Verified!',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Welcome aboard! Your account is\nnow active.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subHeading.copyWith(
                      height: 1.5,
                      color: const Color(0xF2B8B8B8),
                    ),
                  ),
                  const SizedBox(height: 56),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const GlowBackground(
                        size: 180,
                        blurRadius: 100,
                        spreadRadius: 16,
                        alignment: Alignment.center,
                        glowColor: Color(0x40D9B56D),
                      ),
                      const Icon(
                        Icons.check_rounded,
                        size: 200,
                        color: AppColors.primary,
                        shadows: [
                          Shadow(color: Color(0x59D9B56D), blurRadius: 300),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Start Exploring',
                    style: AppTextStyles.subHeading.copyWith(
                      fontSize: 16,
                      color: const Color(0xCCB8B8B8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    text: 'Continue',
                    onPressed:
                        onContinue ??
                        () {
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pushReplacementNamed(AppRoutes.main);
                        },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
