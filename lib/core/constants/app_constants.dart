/// Business constants shared by validators, calculators and the rules docs.
abstract final class AppConstants {
  static const int platformFee = 2000;
  static const int minDailyPrice = 5000;
  static const int maxLongRates = 3;
  static const int minLongRateDays = 2;
  static const int minVehicleYear = 2005;
  static const int maxVehicleYear = 2026;
  static const int minAdultAge = 18;
  static const int minPasswordLength = 8;
  static const int nationalIdLength = 16;
  static const int momoDigits = 9;
  static const Duration pendingExpiry = Duration(hours: 24);
  static const Duration paymentWindow = Duration(hours: 24);
  static const double lateFeeMultiplier = 1.3;
  static const String supportEmail = 'r.kevin@alustudent.com';
}
