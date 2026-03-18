import 'package:alarm_frontend/models/auth_model_user.dart';
import 'package:flutter/material.dart';

class AuthFormData {
  final TextEditingController loginEmailController = TextEditingController();
  final TextEditingController loginPasswordController = TextEditingController();

  final TextEditingController signupNameController = TextEditingController();
  final TextEditingController signupEmailController = TextEditingController();
  final TextEditingController signupPasswordController = TextEditingController();
  final TextEditingController signupConfirmPasswordController =
      TextEditingController();

  final TextEditingController resetEmailController = TextEditingController();

  bool loginObscure = true;
  bool signupObscure = true;
  bool signupConfirmObscure = true;
  bool agreeToTerms = false;

  AuthUserModel get loginUser {
    return AuthUserModel(
      email: loginEmailController.text.trim(),
      password: loginPasswordController.text.trim(),
    );
  }

  AuthUserModel get signupUser {
    return AuthUserModel(
      fullName: signupNameController.text.trim(),
      email: signupEmailController.text.trim(),
      password: signupPasswordController.text.trim(),
      confirmPassword: signupConfirmPasswordController.text.trim(),
    );
  }

  AuthUserModel get resetUser {
    return AuthUserModel(
      email: resetEmailController.text.trim(),
    );
  }

  void dispose() {
    loginEmailController.dispose();
    loginPasswordController.dispose();
    signupNameController.dispose();
    signupEmailController.dispose();
    signupPasswordController.dispose();
    signupConfirmPasswordController.dispose();
    resetEmailController.dispose();
  }
}