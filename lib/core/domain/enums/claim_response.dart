enum ClaimResponse {
  none('none', 'No response'),
  agreed('agreed', 'Agreed'),
  disputed('disputed', 'Disputed');

  const ClaimResponse(this.key, this.label);

  /// Stable string stored in Firestore.
  final String key;
  final String label;

  static ClaimResponse fromKey(String key) => values.firstWhere(
    (value) => value.key == key,
    orElse: () =>
        throw ArgumentError.value(key, 'key', 'Unknown ClaimResponse'),
  );
}
