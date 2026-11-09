enum Party {
  renter('renter', 'Renter'),
  veloce('veloce', 'Veloce'),
  owner('owner', 'Owner');

  const Party(this.key, this.label);

  /// Stable string stored in Firestore.
  final String key;
  final String label;

  static Party fromKey(String key) => values.firstWhere(
    (value) => value.key == key,
    orElse: () => throw ArgumentError.value(key, 'key', 'Unknown Party'),
  );
}
