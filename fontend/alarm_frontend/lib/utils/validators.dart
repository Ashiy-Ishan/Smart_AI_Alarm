class Validators {
  // general email validation to allow any valid domain
  static bool isValidEmail(String email) {
    final trimmedEmail = email.trim();
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(trimmedEmail);
  }

  // legacy gmail validator (kept for compatibility if needed elsewhere)
  static bool isValidGmail(String email) {
    final trimmedEmail = email.trim();
    final gmailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
    return gmailRegex.hasMatch(trimmedEmail);
  }

  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email is required';
    }
    if (!isValidEmail(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validateGmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email is required';
    }
    if (!isValidGmail(email)) {
      return 'Please enter a valid Gmail address';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.trim().isEmpty) {
      return 'Confirm Password is required';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }
}
