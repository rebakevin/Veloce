enum SubjectType {
  user('user', 'User'),
  vehicle('vehicle', 'Vehicle');

  const SubjectType(this.key, this.label);

  /// Stable string stored in Firestore.
  final String key;
  final String label;

  static SubjectType fromKey(String key) => values.firstWhere(
    (value) => value.key == key,
    orElse: () => throw ArgumentError.value(key, 'key', 'Unknown SubjectType'),
  );
}
