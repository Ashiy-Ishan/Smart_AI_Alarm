class AuthPageModel {
  final String title;
  final String? subtitle;
  final String buttonText;
  final AuthPageType type;

  const AuthPageModel({
    required this.title,
    this.subtitle,
    required this.buttonText,
    required this.type,
  });

  factory AuthPageModel.login() {
    return const AuthPageModel(
      title: 'Welcome Back',
      buttonText: 'Log In',
      type: AuthPageType.login,
    );
  }

  factory AuthPageModel.signup() {
    return const AuthPageModel(
      title: 'Create Account',
      buttonText: 'Sign Up',
      type: AuthPageType.signup,
    );
  }

  factory AuthPageModel.resetPassword() {
    return const AuthPageModel(
      title: 'Reset Password',
      subtitle: 'Enter your email to receive a password reset link',
      buttonText: 'Send Link',
      type: AuthPageType.resetPassword,
    );
  }
}

enum AuthPageType {
  login,
  signup,
  resetPassword,
}