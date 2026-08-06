class Validators {
  /// Validates a password based on:
  /// - At least one capital letter (A-Z)
  /// - At least one small letter (a-z)
  /// - At least one number (0-9)
  /// - At least one special character
  static String? validatePassword(String? val) {
    if (val == null || val.isEmpty) {
      return 'Enter your password';
    }
    if (val.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(val)) {
      return 'Password must contain at least one capital letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(val)) {
      return 'Password must contain at least one small letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(val)) {
      return 'Password must contain at least one number';
    }
    // Match any character that is NOT a lowercase/uppercase letter, digit, or whitespace
    if (!RegExp(r'[^a-zA-Z0-9\s]').hasMatch(val)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  /// Validates email address format
  static String? validateEmail(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Enter email address';
    }
    if (val.contains(' ')) {
      return 'Email address cannot contain spaces';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(val.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates name fields (First Name / Last Name)
  static String? validateName(String? val, {required String fieldName}) {
    if (val == null || val.trim().isEmpty) {
      return 'Enter your ${fieldName.toLowerCase()}';
    }
    final trimmed = val.trim();
    if (RegExp(r'[0-9]').hasMatch(trimmed)) {
      return '$fieldName cannot contain numerical characters';
    }
    if (RegExp(r'[^a-zA-Z\s]').hasMatch(trimmed)) {
      return '$fieldName cannot contain special characters';
    }
    if (trimmed.length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    if (trimmed.length > 50) {
      return '$fieldName cannot exceed 50 characters';
    }
    return null;
  }

  static String? validateFirstName(String? val) {
    return validateName(val, fieldName: 'First name');
  }

  static String? validateLastName(String? val) {
    return validateName(val, fieldName: 'Last name');
  }
}

