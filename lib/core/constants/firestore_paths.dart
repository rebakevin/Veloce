/// Collection and document paths. No string literals for paths elsewhere.
abstract final class FirestorePaths {
  static const String users = 'users';
  static const String vehicles = 'vehicles';
  static const String bookings = 'bookings';
  static const String calendarBlocks = 'calendarBlocks';
  static const String renterLocks = 'renterLocks';
  static const String transactions = 'transactions';
  static const String cautionClaims = 'cautionClaims';
  static const String repairExpenses = 'repairExpenses';
  static const String reviews = 'reviews';
  static const String notifications = 'notifications';
  static const String auditLogs = 'auditLogs';

  // Sub-collections.
  static const String privateDocs = 'private';
  static const String favourites = 'favourites';
  static const String photos = 'photos';
  static const String documents = 'documents';
  static const String checklistEntries = 'checklistEntries';
  static const String checklistMedia = 'checklistMedia';

  // Fixed document ids inside `users/{uid}/private`.
  static const String contactDoc = 'contact';
  static const String licenceDoc = 'licence';
  static const String identityDoc = 'identity';
  static const String payoutDoc = 'payout';

  static String user(String uid) => '$users/$uid';
  static String userPrivate(String uid, String doc) =>
      '$users/$uid/$privateDocs/$doc';
  static String favourite(String uid, String vehicleId) =>
      '$users/$uid/$favourites/$vehicleId';
  static String vehicle(String vehicleId) => '$vehicles/$vehicleId';
  static String booking(String bookingId) => '$bookings/$bookingId';
  static String bookingPrivate(String bookingId, String side) =>
      '$bookings/$bookingId/$privateDocs/$side';
}
