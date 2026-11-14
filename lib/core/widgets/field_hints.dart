import '../constants/app_constants.dart';

/// Placeholder texts for form fields, shared so the same field reads the same
/// on every screen. A field's `hint` is required, so no input is left blank.
abstract final class FieldHints {
  static const String fullName = 'e.g. Aline Uwase';
  static const String email = 'name@example.com';
  static const String password = 'Enter your password';
  static const String newPassword =
      'At least ${AppConstants.minPasswordLength} characters';
  static const String phone = '10 digits, starting with 07';
  static const String momoNumber = '9 digits after the 0';
  static const String plate = '3 letters starting with R, 3 digits, 1 letter';
  static const String nationalId = '${AppConstants.nationalIdLength} digits';
  static const String licenceNumber = 'As printed on your licence';
  static const String verificationCode = '6-digit code';
}
