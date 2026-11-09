enum AuthProviderKind {
  password('password', 'Email and password'),
  google('google', 'Google');

  const AuthProviderKind(this.key, this.label);

  /// Stable string stored in Firestore.
  final String key;
  final String label;

  static AuthProviderKind fromKey(String key) => values.firstWhere(
    (value) => value.key == key,
    orElse: () =>
        throw ArgumentError.value(key, 'key', 'Unknown AuthProviderKind'),
  );
}
