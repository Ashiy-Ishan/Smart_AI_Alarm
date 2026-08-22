import 'package:flutter_test/flutter_test.dart';
import 'package:alarm_frontend/models/auth_page_model.dart';

void main() {
  group('AuthPageModel', () {
    test('login factory should set correct values', () {
      final model = AuthPageModel.login();
      expect(model.title, 'Welcome Back');
      expect(model.buttonText, 'Log In');
      expect(model.type, AuthPageType.login);
      expect(model.subtitle, isNull);
    });

    test('signup factory should set correct values', () {
      final model = AuthPageModel.signup();
      expect(model.title, 'Create Account');
      expect(model.buttonText, 'Sign Up');
      expect(model.type, AuthPageType.signup);
      expect(model.subtitle, isNull);
    });

    test('resetPassword factory should set correct values', () {
      final model = AuthPageModel.resetPassword();
      expect(model.title, 'Reset Password');
      expect(model.buttonText, 'Send Link');
      expect(model.type, AuthPageType.resetPassword);
      expect(model.subtitle, 'Enter your email to receive a password reset link');
    });

    test('custom constructor should initialize correctly', () {
      const model = AuthPageModel(
        title: 'Custom Title',
        subtitle: 'Custom Subtitle',
        buttonText: 'Submit',
        type: AuthPageType.login,
      );

      expect(model.title, 'Custom Title');
      expect(model.subtitle, 'Custom Subtitle');
      expect(model.buttonText, 'Submit');
      expect(model.type, AuthPageType.login);
    });
  });
}
