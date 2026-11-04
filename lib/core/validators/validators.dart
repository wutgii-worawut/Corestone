/// Why a form field is invalid. Screens map each value to a localized
/// message, so the checks stay pure.
enum FieldError { required, invalidEmail }

/// The email pattern from Skelter's `isEmailValid`.
final _email = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

FieldError? validateEmail(String email) {
  final value = email.trim();
  if (value.isEmpty) return FieldError.required;
  if (!_email.hasMatch(value)) return FieldError.invalidEmail;
  return null;
}

/// Sign-in only checks presence; the server owns the password policy.
FieldError? validatePassword(String password) =>
    password.isEmpty ? FieldError.required : null;
