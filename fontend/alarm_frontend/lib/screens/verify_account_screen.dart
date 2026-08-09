import 'dart:async';

import 'package:alarm_frontend/components/primary_button.dart';
import 'package:alarm_frontend/routes/app_routes.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:flutter/material.dart';

class VerifyAccountScreen extends StatefulWidget {
  final VoidCallback? onContinue;
  final VoidCallback? onResend;

  const VerifyAccountScreen({super.key, this.onContinue, this.onResend});

  @override
  State<VerifyAccountScreen> createState() => _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends State<VerifyAccountScreen> {
  final _controllers = List.generate(4, (_) => TextEditingController());
  final _focusNodes = List.generate(4, (_) => FocusNode());

  bool _hasNavigated = false;
  int _secondsLeft = 20;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();

    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  bool get _isCodeComplete =>
      _controllers.every((controller) => controller.text.trim().isNotEmpty);

  void _startResendTimer() {
    _timer?.cancel();

    setState(() {
      _secondsLeft = 20;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _goToVerifiedScreen() {
    if (_hasNavigated) return;
    _hasNavigated = true;

    if (widget.onContinue != null) {
      widget.onContinue!();
      return;
    }

    Navigator.pushNamed(context, AppRoutes.accountVerified);
  }

  void _onCodeChanged(int index, String value) {
    if (value.length > 1) {
      _controllers[index].text = value[value.length - 1];
      _controllers[index].selection = const TextSelection.collapsed(offset: 1);
    }

    if (value.isNotEmpty && index < _focusNodes.length - 1) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    }

    if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }

    if (_isCodeComplete) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _goToVerifiedScreen();
        }
      });
    }
  }

  void _handleResend() {
    if (_secondsLeft != 0) return;

    if (widget.onResend != null) {
      widget.onResend!();
    }

    _startResendTimer();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Verification code resent')));
  }

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  4,
                  (index) => _CodeBox(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    onChanged: (value) => _onCodeChanged(index, value),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'A verification code has been\nsent to your email.',
                textAlign: TextAlign.center,
                style: AppTextStyles.subHeading.copyWith(height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Resend timer $_secondsLeft secs',
                style: AppTextStyles.subHeading.copyWith(
                  fontSize: 14,
                  color: const Color(0x66D9B56D),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Verify',
                onPressed: _isCodeComplete
                    ? _goToVerifiedScreen
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all code boxes'),
                          ),
                        );
                      },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _secondsLeft == 0 ? _handleResend : null,
                child: Text(
                  'Resend Code',
                  style: AppTextStyles.link.copyWith(
                    color: _secondsLeft == 0
                        ? AppColors.primary
                        : const Color(0x80D9B56D),
                  ),
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
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _CodeBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: AppTextStyles.heading.copyWith(
          fontSize: 22,
          color: AppColors.primary,
        ),
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xCCD9B56D), width: 1.4),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
          ),
        ),
      ),
    );
  }
}
