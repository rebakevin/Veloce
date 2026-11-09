enum ChecklistSide {
  owner('owner', 'Owner'),
  renter('renter', 'Renter');

  const ChecklistSide(this.key, this.label);

  /// Stable string stored in Firestore.
  final String key;
  final String label;

  static ChecklistSide fromKey(String key) => values.firstWhere(
    (value) => value.key == key,
    orElse: () =>
        throw ArgumentError.value(key, 'key', 'Unknown ChecklistSide'),
  );
}
