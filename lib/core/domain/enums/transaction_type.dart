enum TransactionType {
  charge('charge', 'Payment'),
  release('release', 'Rental fee released'),
  platformFee('platform_fee', 'Platform fee'),
  refund('refund', 'Refund'),
  claimDeduction('claim_deduction', 'Claim deduction'),
  lateFee('late_fee', 'Late fee'),
  payout('payout', 'Payout');

  const TransactionType(this.key, this.label);

  /// Stable string stored in Firestore.
  final String key;
  final String label;

  static TransactionType fromKey(String key) => values.firstWhere(
    (value) => value.key == key,
    orElse: () =>
        throw ArgumentError.value(key, 'key', 'Unknown TransactionType'),
  );
}
