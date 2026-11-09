enum ClaimStatus {
  open('open', 'Open'),
  settled('settled', 'Settled'),
  refunded('refunded', 'Refunded');

  const ClaimStatus(this.key, this.label);

  /// Stable string stored in Firestore.
  final String key;
  final String label;

  static ClaimStatus fromKey(String key) => values.firstWhere(
    (value) => value.key == key,
    orElse: () => throw ArgumentError.value(key, 'key', 'Unknown ClaimStatus'),
  );
}
