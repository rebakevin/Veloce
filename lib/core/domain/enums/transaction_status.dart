enum TransactionStatus {
  success('success', 'Success'),
  failed('failed', 'Failed');

  const TransactionStatus(this.key, this.label);

  /// Stable string stored in Firestore.
  final String key;
  final String label;

  static TransactionStatus fromKey(String key) => values.firstWhere(
    (value) => value.key == key,
    orElse: () =>
        throw ArgumentError.value(key, 'key', 'Unknown TransactionStatus'),
  );
}
