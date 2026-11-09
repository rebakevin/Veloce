enum VehicleType {
  sedan('sedan', 'Sedan'),
  suv('suv', 'SUV'),
  hatchback('hatchback', 'Hatchback'),
  minivan('minivan', 'Minivan'),
  pickup('pickup', 'Pickup');

  const VehicleType(this.key, this.label);

  /// Stable string stored in Firestore.
  final String key;
  final String label;

  static VehicleType fromKey(String key) => values.firstWhere(
    (value) => value.key == key,
    orElse: () => throw ArgumentError.value(key, 'key', 'Unknown VehicleType'),
  );
}
