enum NotificationType {
  requestReceived('request_received', 'Request received'),
  requestApproved('request_approved', 'Request approved'),
  requestDeclined('request_declined', 'Request declined'),
  requestExpired('request_expired', 'Request expired'),
  bookingCancelled('booking_cancelled', 'Booking cancelled'),
  paymentReceived('payment_received', 'Payment received'),
  paymentDeadline('payment_deadline', 'Payment deadline'),
  pickupConfirmed('pickup_confirmed', 'Pickup confirmed'),
  returnConfirmed('return_confirmed', 'Return confirmed'),
  claimChanged('claim_changed', 'Claim updated'),
  lateFeeApplied('late_fee_applied', 'Late fee applied'),
  reviewDue('review_due', 'Review due');

  const NotificationType(this.key, this.label);

  /// Stable string stored in Firestore.
  final String key;
  final String label;

  static NotificationType fromKey(String key) => values.firstWhere(
    (value) => value.key == key,
    orElse: () =>
        throw ArgumentError.value(key, 'key', 'Unknown NotificationType'),
  );
}
