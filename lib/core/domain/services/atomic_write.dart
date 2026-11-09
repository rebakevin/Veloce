/// One atomic write (a Firestore batch). Domain code only passes it between the
/// writers; the data layer owns the implementation. Values in the maps are
/// wire values (Firestore `Timestamp`, `FieldValue`) and stay opaque here.
abstract interface class AtomicWrite {
  /// A fresh document id, so a retried write produces the same result.
  String newId(String collectionPath);

  void set(String documentPath, Map<String, dynamic> data);

  void update(String documentPath, Map<String, dynamic> data);

  void delete(String documentPath);

  Future<void> commit();
}

/// Starts [AtomicWrite]s. Repositories use this instead of the SDK.
abstract interface class AtomicWriteFactory {
  AtomicWrite begin();
}
