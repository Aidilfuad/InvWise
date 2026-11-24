class RegistrationRequestValidation {
  const RegistrationRequestValidation._();

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? confirmation({
    required String? password,
    required String? confirmation,
  }) {
    final requiredError = required(confirmation);
    if (requiredError != null) return requiredError;
    if (password != confirmation) return 'Passwords do not match.';
    return null;
  }
}
