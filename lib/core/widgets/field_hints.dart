import '../constants/app_constants.dart';

/// Placeholder texts for form fields, shared so the same field reads the same
/// on every screen. A field's `hint` is required, so no input is left blank.
abstract final class FieldHints {
  static const String fullName = 'e.g. Aline Uwase';
  static const String email = 'name@example.com';
  static const String password = 'Enter your password';
  static const String newPassword =
      'At least ${AppConstants.minPasswordLength} characters';
  static const String phone = '0788123456';
  static const String nationalId = '${AppConstants.nationalIdLength} digits';
  static const String licenceNumber = 'e.g. RW123456';
  static const String verificationCode = '6-digit code';
}
