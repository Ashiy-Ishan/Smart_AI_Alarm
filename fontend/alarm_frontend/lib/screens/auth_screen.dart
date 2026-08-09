import 'package:alarm_frontend/components/auth_text_field.dart';
import 'package:alarm_frontend/components/primary_button.dart';
import 'package:alarm_frontend/components/social_button.dart';
import 'package:alarm_frontend/data/auth_form_data.dart';
import 'package:alarm_frontend/models/auth_model_user.dart';
import 'package:alarm_frontend/models/auth_page_model.dart';
import 'package:alarm_frontend/providers/user_provider.dart';
import 'package:alarm_frontend/routes/app_routes.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:alarm_frontend/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthScreen extends StatefulWidget {
  final AuthPageModel initialPage;

  const AuthScreen({super.key, required this.initialPage});

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
        backgroundColor: Theme.of(context).cardColor,
        content: Text(
          message,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
      ),
    );
  }

  Future<void> handleLogin() async {
    if (!(formData.loginFormKey.currentState?.validate() ?? false)) {
      return;
    }

    final AuthUserModel user = formData.loginUser;

    if (user.password.isEmpty) {
      showMessage('Please fill all fields');
      return;
    }

    setState(() => isLoading = true);
    try {
      await Provider.of<UserProvider>(context, listen: false).signInWithEmailAndPassword(
        email: user.email,
        password: user.password,
        context: context,
      );

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true)
          .pushReplacementNamed(AppRoutes.main);
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> handleSignup() async {
    if (!(formData.signupFormKey.currentState?.validate() ?? false)) {
      return;
    }

    final AuthUserModel user = formData.signupUser;

    if (user.fullName.isEmpty ||
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
    try {
      await Provider.of<UserProvider>(context, listen: false).signUpWithEmailAndPassword(
        email: user.email,
        password: user.password,
        fullName: user.fullName,
        context: context,
      );

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true)
          .pushReplacementNamed(AppRoutes.verifyAccount);
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> handleResetPassword() async {
    if (!(formData.resetFormKey.currentState?.validate() ?? false)) {
      return;
    }

    final AuthUserModel user = formData.resetUser;

    setState(() => isLoading = true);
    try {
      await Provider.of<UserProvider>(context, listen: false).sendPasswordResetEmail(
        email: user.email,
        context: context,
      );
      
      if (mounted) {
        switchPage(AuthPageModel.login());
      }
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
    final theme = Theme.of(context);
    return Form(
      key: formData.loginFormKey,
      child: Column(
        key: const ValueKey('login'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 110),
          Center(child: Text(currentPage.title, style: AppTextStyles.heading)),
          const SizedBox(height: 55),
          AuthTextField(
            controller: formData.loginEmailController,
            hintText: 'Email address',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: 18),
          AuthTextField(
            controller: formData.loginPasswordController,
            hintText: 'Password',
            prefixIcon: Icons.lock_outline,
            obscureText: formData.loginObscure,
            validator: (value) =>
                Validators.validateRequired(value, 'Password'),
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
              child: Text(
                'Forgot Password ?',
                style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 15),
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
            child: Text('Or log in with', style: AppTextStyles.subHeading),
          ),
          const SizedBox(height: 22),
          SocialButton(
            text: 'Google',
            onPressed: () {
              Provider.of<UserProvider>(
                context,
                listen: false,
              ).signInWithGoogle(context);
            },
          ),
          const SizedBox(height: 24),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                Text(
                  "Don't have an account ? ",
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16),
                ),
                GestureDetector(
                  onTap: () => switchPage(AuthPageModel.signup()),
                  child: const Text('Sign Up', style: AppTextStyles.link),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupView() {
    final theme = Theme.of(context);
    return Form(
      key: formData.signupFormKey,
      child: Column(
        key: const ValueKey('signup'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 85),
          Center(child: Text(currentPage.title, style: AppTextStyles.heading)),
          const SizedBox(height: 45),
          AuthTextField(
            controller: formData.signupNameController,
            hintText: 'Full name',
            prefixIcon: Icons.person_outline,
            validator: (value) =>
                Validators.validateRequired(value, 'Full name'),
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: formData.signupEmailController,
            hintText: 'Email Address',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: formData.signupPasswordController,
            hintText: 'Password',
            prefixIcon: Icons.lock_outline,
            obscureText: formData.signupObscure,
            validator: (value) =>
                Validators.validateRequired(value, 'Password'),
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
            validator: (value) => Validators.validateConfirmPassword(
              value,
              formData.signupPasswordController.text,
            ),
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
              Text(
                'I agree to ',
                style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.termsAndConditions),
                child: const Text('terms and condition', style: AppTextStyles.link),
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
                Text(
                  'Already have an account? ',
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16),
                ),
                GestureDetector(
                  onTap: () => switchPage(AuthPageModel.login()),
                  child: const Text('Log in', style: AppTextStyles.link),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetPasswordView() {
    return Form(
      key: formData.resetFormKey,
      child: Column(
        key: const ValueKey('resetPassword'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 140),
          Center(child: Text(currentPage.title, style: AppTextStyles.heading)),
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
            validator: Validators.validateEmail,
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
              child: const Text('Back to Login', style: AppTextStyles.link),
            ),
          ),
        ],
      ),
    );
  }
}
