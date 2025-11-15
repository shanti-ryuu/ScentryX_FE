String? validateRequired(String? value, {String fieldName = 'Field'}) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  return null;
}

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Email is required';
  }
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  if (!emailRegex.hasMatch(value.trim())) {
    return 'Enter a valid email';
  }
  return null;
}

String? validatePassword(String? value, {int minLength = 6}) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }
  if (value.length < minLength) {
    return 'Password must be at least $minLength characters';
  }
  return null;
}

String? validatePhone(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  final phoneRegex = RegExp(r'^[0-9+\-() ]{6,}$');
  if (!phoneRegex.hasMatch(value.trim())) {
    return 'Enter a valid phone number';
  }
  return null;
}
