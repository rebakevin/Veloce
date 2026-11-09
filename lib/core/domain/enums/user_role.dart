enum UserRole {
  renter('renter', 'Renter'),
  owner('owner', 'Car owner');

  const UserRole(this.key, this.label);

  /// Stable string stored in Firestore.
  final String key;
  final String label;

  static UserRole fromKey(String key) => values.firstWhere(
    (value) => value.key == key,
    orElse: () => throw ArgumentError.value(key, 'key', 'Unknown UserRole'),
  );
}
