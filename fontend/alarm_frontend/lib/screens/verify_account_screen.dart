import 'package:alarm_frontend/components/primary_button.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:flutter/material.dart';

class VerifyAccountScreen extends StatelessWidget {
  final VoidCallback? onContinue;
  final VoidCallback? onResend;

  const VerifyAccountScreen({
    super.key,
    this.onContinue,
    this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Text(
                'Verify Your Account',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading.copyWith(fontSize: 34),
              ),
              const SizedBox(height: 28),

              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CodeBox(),
                  _CodeBox(),
                  _CodeBox(),
                  _CodeBox(),
                ],
              ),

              const SizedBox(height: 28),
              Text(
                'A verification code has been\nsent to your email.',
                textAlign: TextAlign.center,
                style: AppTextStyles.subHeading.copyWith(height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Resend timer 20 secs',
                style: AppTextStyles.subHeading.copyWith(
                  fontSize: 14,
                  color: Color(0x3DD9B56D),
                ),
              ),

              const Spacer(),

              PrimaryButton(
                text: 'Verify',
                onPressed: onContinue ??
                    () {
                      Navigator.pushNamed(context, '/account-verified');
                    },
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: onResend,
                child: Text(
                  'Resend Code',
                  style: AppTextStyles.link,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xCCD9B56D),
          width: 1.4,
        ),
      ),
    );
  }
}