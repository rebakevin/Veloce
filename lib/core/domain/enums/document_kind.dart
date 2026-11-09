enum DocumentKind {
  insurance('insurance', 'Insurance'),
  medical('medical', 'Medical certificate'),
  yellowPaper('yellowPaper', 'Yellow paper');

  const DocumentKind(this.key, this.label);

  /// Stable string stored in Firestore.
  final String key;
  final String label;

  static DocumentKind fromKey(String key) => values.firstWhere(
    (value) => value.key == key,
    orElse: () => throw ArgumentError.value(key, 'key', 'Unknown DocumentKind'),
  );
}
