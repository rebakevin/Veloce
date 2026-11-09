enum BookingStatus {
  pending('pending', 'Pending approval'),
  approved('approved', 'Approved'),
  declined('declined', 'Declined'),
  cancelled('cancelled', 'Cancelled'),
  expired('expired', 'Expired'),
  confirmed('confirmed', 'Confirmed'),
  active('active', 'Active'),
  returning('return', 'Return inspection'),
  review('review', 'Claim review'),
  completed('completed', 'Completed');

  const BookingStatus(this.key, this.label);

  /// Stable string stored in Firestore.
  final String key;
  final String label;

  static BookingStatus fromKey(String key) => values.firstWhere(
    (value) => value.key == key,
    orElse: () =>
        throw ArgumentError.value(key, 'key', 'Unknown BookingStatus'),
  );
}
