/// Supabase Storage buckets (see `tool/supabase/storage.sql`).
enum StorageBucket {
  carMedia('car-media', 'Car media'),
  userDocs('user-docs', 'User documents'),
  checklistMedia('checklist-media', 'Checklist media'),
  receipts('receipts', 'Receipts');

  const StorageBucket(this.key, this.label);

  /// Bucket name in Supabase.
  final String key;
  final String label;

  static StorageBucket fromKey(String key) => values.firstWhere(
    (value) => value.key == key,
    orElse: () =>
        throw ArgumentError.value(key, 'key', 'Unknown StorageBucket'),
  );
}
