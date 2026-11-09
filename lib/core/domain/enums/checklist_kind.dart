enum ChecklistKind {
  pickup('pickup', 'Pickup'),
  returning('return', 'Return');

  const ChecklistKind(this.key, this.label);

  /// Stable string stored in Firestore.
  final String key;
  final String label;

  static ChecklistKind fromKey(String key) => values.firstWhere(
    (value) => value.key == key,
    orElse: () =>
        throw ArgumentError.value(key, 'key', 'Unknown ChecklistKind'),
  );
}
