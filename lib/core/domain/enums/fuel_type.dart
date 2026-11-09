enum FuelType {
  petrol('petrol', 'Petrol'),
  diesel('diesel', 'Diesel'),
  hybrid('hybrid', 'Hybrid'),
  electric('electric', 'Electric');

  const FuelType(this.key, this.label);

  /// Stable string stored in Firestore.
  final String key;
  final String label;

  static FuelType fromKey(String key) => values.firstWhere(
    (value) => value.key == key,
    orElse: () => throw ArgumentError.value(key, 'key', 'Unknown FuelType'),
  );
}
