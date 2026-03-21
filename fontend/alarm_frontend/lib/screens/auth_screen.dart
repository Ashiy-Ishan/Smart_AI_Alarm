import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:alarm_frontend/components/auth_text_field.dart';
import 'package:alarm_frontend/components/primary_button.dart';
import 'package:alarm_frontend/components/social_button.dart';
import 'package:alarm_frontend/data/auth_form_data.dart';
import 'package:alarm_frontend/models/auth_model_user.dart';
import 'package:alarm_frontend/models/auth_page_model.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  final AuthPageModel initialPage;

  const AuthScreen({
    super.key,
    required this.initialPage,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthFormData formData = AuthFormData();

  late AuthPageModel currentPage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    currentPage = widget.initialPage;
  }

  @override
  void dispose() {
    formData.dispose();
    super.dispose();
  }

  void switchPage(AuthPageModel page) {
    setState(() {
      currentPage = page;
    });
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.card,
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Future<void> handleLogin() async {
    final AuthUserModel user = formData.loginUser;

    if (user.email.isEmpty || user.password.isEmpty) {
      showMessage('Please fill all fields');
      return;
    }

    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => isLoading = false);

    debugPrint('Login Email: ${user.email}');
    debugPrint('Login Password: ${user.password}');
  }

  Future<void> handleSignup() async {
    final AuthUserModel user = formData.signupUser;

    if (user.fullName.isEmpty ||
        user.email.isEmpty ||
        user.password.isEmpty ||
        user.confirmPassword.isEmpty) {
      showMessage('Please fill all fields');
      return;
    }

    if (!formData.agreeToTerms) {
      showMessage('Please agree to the terms');
      return;
    }

    if (user.password != user.confirmPassword) {
      showMessage('Passwords do not match');
      return;
    }

    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => isLoading = false);

    debugPrint('Signup Name: ${user.fullName}');
    debugPrint('Signup Email: ${user.email}');
    debugPrint('Signup Password: ${user.password}');
  }

  Future<void> handleResetPassword() async {
    final AuthUserModel user = formData.resetUser;

    if (user.email.isEmpty) {
      showMessage('Please enter your email');
      return;
    }

    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => isLoading = false);

    debugPrint('Reset Email: ${user.email}');
    showMessage('Password reset link sent');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildCurrentView(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (currentPage.type) {
      case AuthPageType.login:
        return _buildLoginView();
      case AuthPageType.signup:
        return _buildSignupView();
      case AuthPageType.resetPassword:
        return _buildResetPasswordView();
    }
  }

  Widget _buildLoginView() {
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 110),
        Center(
          child: Text(
            currentPage.title,
            style: AppTextStyles.heading,
          ),
        ),
        const SizedBox(height: 55),
        AuthTextField(
          controller: formData.loginEmailController,
          hintText: 'Email address',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 18),
        AuthTextField(
          controller: formData.loginPasswordController,
          hintText: 'Password',
          prefixIcon: Icons.lock_outline,
          obscureText: formData.loginObscure,
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                formData.loginObscure = !formData.loginObscure;
              });
            },
            icon: Icon(
              formData.loginObscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => switchPage(AuthPageModel.resetPassword()),
            child: const Text(
              'Forgot Password ?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          text: currentPage.buttonText,
          onPressed: handleLogin,
          isLoading: isLoading,
        ),
        const SizedBox(height: 34),
        const Center(
          child: Text(
            'Or log in with',
            style: AppTextStyles.subHeading,
          ),
        ),
        const SizedBox(height: 22),
        SocialButton(
          text: 'Google',
          onPressed: () {
            debugPrint('Google login');
          },
        ),
        const SizedBox(height: 24),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [
              const Text(
                "Don't have an account ? ",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
              GestureDetector(
                onTap: () => switchPage(AuthPageModel.signup()),
                child: const Text(
                  'Sign Up',
                  style: AppTextStyles.link,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignupView() {
    return Column(
      key: const ValueKey('signup'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 85),
        Center(
          child: Text(
            currentPage.title,
            style: AppTextStyles.heading,
          ),
        ),
        const SizedBox(height: 45),
        AuthTextField(
          controller: formData.signupNameController,
          hintText: 'Full name',
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: formData.signupEmailController,
          hintText: 'Email Address',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: formData.signupPasswordController,
          hintText: 'Password',
          prefixIcon: Icons.lock_outline,
          obscureText: formData.signupObscure,
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                formData.signupObscure = !formData.signupObscure;
              });
            },
            icon: Icon(
              formData.signupObscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: formData.signupConfirmPasswordController,
          hintText: 'Confirm Password',
          prefixIcon: Icons.lock_outline,
          obscureText: formData.signupConfirmObscure,
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                formData.signupConfirmObscure =
                    !formData.signupConfirmObscure;
              });
            },
            icon: Icon(
              formData.signupConfirmObscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: formData.agreeToTerms,
                activeColor: AppColors.primary,
                checkColor: Colors.black,
                side: const BorderSide(color: AppColors.primary),
                onChanged: (value) {
                  setState(() {
                    formData.agreeToTerms = value ?? false;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'I agree to ',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
            const Text(
              'terms',
              style: AppTextStyles.link,
            ),
          ],
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          text: currentPage.buttonText,
          onPressed: handleSignup,
          isLoading: isLoading,
        ),
        const SizedBox(height: 24),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [
              const Text(
                'Already have an account? ',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
              GestureDetector(
                onTap: () => switchPage(AuthPageModel.login()),
                child: const Text(
                  'Log in',
                  style: AppTextStyles.link,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResetPasswordView() {
    return Column(
      key: const ValueKey('resetPassword'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 140),
        Center(
          child: Text(
            currentPage.title,
            style: AppTextStyles.heading,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            currentPage.subtitle ?? '',
            textAlign: TextAlign.center,
            style: AppTextStyles.subHeading,
          ),
        ),
        const SizedBox(height: 42),
        AuthTextField(
          controller: formData.resetEmailController,
          hintText: 'Email address',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          text: currentPage.buttonText,
          onPressed: handleResetPassword,
          isLoading: isLoading,
        ),
        const SizedBox(height: 22),
        Center(
          child: GestureDetector(
            onTap: () => switchPage(AuthPageModel.login()),
            child: const Text(
              'Back to Login',
              style: AppTextStyles.link,
            ),
          ),
        ),
      ],
    );
  }
}