enum Transmission {
  automatic('automatic', 'Automatic'),
  manual('manual', 'Manual');

  const Transmission(this.key, this.label);

  /// Stable string stored in Firestore.
  final String key;
  final String label;

  static Transmission fromKey(String key) => values.firstWhere(
    (value) => value.key == key,
    orElse: () => throw ArgumentError.value(key, 'key', 'Unknown Transmission'),
  );
}
