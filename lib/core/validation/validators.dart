import '../constants/app_constants.dart';

/// Form validators. Each returns a user-facing message, or `null` when valid.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _phone = RegExp(r'^07[2389]\d{7}$');
  static final RegExp _momoDigits = RegExp(r'^7[2389]\d{7}$');
  static final RegExp _nationalId = RegExp(r'^\d{16}$');
  static final RegExp _plate = RegExp(r'^R[A-Z]{2} ?\d{3} ?[A-Z]$');

  static String? requiredText(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required.';
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your email address.';
    if (!_email.hasMatch(text)) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Enter a password.';
    if (text.length < AppConstants.minPasswordLength) {
      return 'Use at least ${AppConstants.minPasswordLength} characters.';
    }
    if (!text.contains(RegExp('[A-Za-z]')) || !text.contains(RegExp('[0-9]'))) {
      return 'Use at least one letter and one number.';
    }
    return null;
  }

  /// Rwandan mobile number, e.g. `0788123456`.
  static String? phone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your phone number.';
    if (!_phone.hasMatch(text)) {
      return 'Enter a valid Rwandan number, like 0788123456.';
    }
    return null;
  }

  /// MoMo number typed without the leading 0, e.g. `788123456`.
  static String? momoNumber(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your MoMo number.';
    if (!_momoDigits.hasMatch(text)) {
      return 'Enter the ${AppConstants.momoDigits} digits after 0, like 788123456.';
    }
    return null;
  }

  static String? dateOfBirth(DateTime? value, {required DateTime now}) {
    if (value == null) return 'Choose your date of birth.';
    final eighteenth = DateTime(
      value.year + AppConstants.minAdultAge,
      value.month,
      value.day,
    );
    if (eighteenth.isAfter(now)) {
      return 'You must be at least ${AppConstants.minAdultAge} years old.';
    }
    return null;
  }

  static String? nationalId(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your National ID number.';
    if (!_nationalId.hasMatch(text)) {
      return 'A National ID has ${AppConstants.nationalIdLength} digits.';
    }
    return null;
  }

  static String? licenceNumber(String? value) =>
      requiredText(value, field: 'Licence number');

  static String? licenceExpiry(DateTime? value, {required DateTime now}) {
    if (value == null) return 'Choose the licence expiry date.';
    if (!value.isAfter(now)) return 'This licence has expired.';
    return null;
  }

  /// Rwandan plate such as `RAB 123 A`.
  static String? plate(String? value) {
    final text = value?.trim().toUpperCase() ?? '';
    if (text.isEmpty) return 'Enter the number plate.';
    if (!_plate.hasMatch(text)) return 'Use a plate like RAB 123 A.';
    return null;
  }

  static String? vehicleYear(int? value) {
    if (value == null) return 'Enter the year.';
    if (value < AppConstants.minVehicleYear ||
        value > AppConstants.maxVehicleYear) {
      return 'Year must be ${AppConstants.minVehicleYear} to '
          '${AppConstants.maxVehicleYear}.';
    }
    return null;
  }

  static String? dailyPrice(int? value) {
    if (value == null) return 'Enter the daily price.';
    if (value < AppConstants.minDailyPrice) {
      return 'The price must be at least RWF ${AppConstants.minDailyPrice}.';
    }
    return null;
  }

  static String? cautionFee(int? value) {
    if (value == null) return 'Enter the caution fee.';
    if (value < 0) return 'The caution fee cannot be negative.';
    return null;
  }

  static String? rating(int? value) {
    if (value == null || value < 1 || value > 5) {
      return 'Choose a rating from 1 to 5.';
    }
    return null;
  }
}
