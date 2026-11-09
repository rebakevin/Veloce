enum VehicleStatus {
  published('published', 'Published'),
  paused('paused', 'Paused');

  const VehicleStatus(this.key, this.label);

  /// Stable string stored in Firestore.
  final String key;
  final String label;

  static VehicleStatus fromKey(String key) => values.firstWhere(
    (value) => value.key == key,
    orElse: () =>
        throw ArgumentError.value(key, 'key', 'Unknown VehicleStatus'),
  );
}
