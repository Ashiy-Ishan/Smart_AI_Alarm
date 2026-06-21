class Validators {
  static bool isValidGmail(String email) {
    final trimmedEmail = email.trim();
    final gmailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
    return gmailRegex.hasMatch(trimmedEmail);
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
  
  static String? validateConfirmPassword(
    String? value,
    String password,
  ) {
    if (value == null || value.trim().isEmpty) {
      return 'Confirm Password is required';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }
}