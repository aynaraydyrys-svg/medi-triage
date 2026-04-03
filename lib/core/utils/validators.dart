class Validators {
  static String? requiredField(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Invalid email';
    }
    final parts = trimmed.split('@');
    if (parts.length != 2 || parts.first.isEmpty || parts.last.isEmpty) {
      return 'Invalid email';
    }
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) {
      return 'Enter password';
    }
    if (text.length < 6) {
      return 'Password 6+';
    }
    return null;
  }
}
