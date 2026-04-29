class Validators {
  static final RegExp _emailRegex = RegExp(
    r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$",
  );
  static final RegExp _phoneRegex = RegExp(r'^[6-9]\d{9}$');

  static String? requiredField(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email';
    }

    return null;
  }

  static String? phone(String? value, {String fieldName = 'Phone'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    final normalized = value.trim().replaceAll(' ', '');
    if (!_phoneRegex.hasMatch(normalized)) {
      return '$fieldName must be a valid 10-digit mobile number';
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? number(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (double.tryParse(value.trim()) == null) {
      return '$fieldName must be numeric';
    }
    return null;
  }
}
