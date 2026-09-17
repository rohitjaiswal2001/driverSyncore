class Validators {
  /// Strength rules for a password the user is choosing — registration and
  /// reset share this so both screens accept and reject exactly the same
  /// passwords. Not for the login field, which must accept whatever the
  /// account was created with.
  static String? validatePassword(String? val) {
    if (val == null || val.isEmpty) {
      return 'Enter password';
    }
    if (val.length < 8) {
      return 'Password must be at least 8 characters';
    }
    final hasUpper = RegExp(r'[A-Z]').hasMatch(val);
    final hasLower = RegExp(r'[a-z]').hasMatch(val);
    final hasDigit = RegExp(r'[0-9]').hasMatch(val);
    final hasSpecial = RegExp(
      r'[@$!%*?&^#()_\-+={}\[\]:;"<>,.?/~`|\\]',
    ).hasMatch(val);
    final missing = <String>[
      if (!hasUpper) 'one uppercase letter',
      if (!hasLower) 'one lowercase letter',
      if (!hasDigit) 'one number',
      if (!hasSpecial) 'one special character',
    ];
    if (missing.isNotEmpty) {
      return 'Password must contain ${_joinRequirements(missing)}.';
    }
    return null;
  }

  static String _joinRequirements(List<String> items) {
    if (items.length == 1) return items.first;
    if (items.length == 2) return '${items[0]} and ${items[1]}';
    return '${items.sublist(0, items.length - 1).join(', ')}, and ${items.last}';
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
