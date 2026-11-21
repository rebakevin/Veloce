/// Ids of the seeded documents (`tool/seed/seed.js`). The dev routes list opens
/// parameterised routes on these; real pages use the id of the item tapped.
abstract final class SeedIds {
  static const String booking = 'booking-confirmed';
  static const String pendingBooking = 'booking-pending';
  static const String car = 'car-1';
  static const String renter = 'renter1';
  static const String owner = 'owner1';
}
