import '../../constants/firestore_fields.dart';
import '../../domain/entities/owner_identity.dart';
import 'wire.dart';

/// Maps [OwnerIdentity] to and from the Firestore wire map.
abstract final class OwnerIdentityModel {
  static OwnerIdentity fromMap(String docId, Map<String, dynamic> map) {
    final wire = WireReader('OwnerIdentity', map);
    return OwnerIdentity(
      userId: docId,
      nationalIdNumber: wire.string(FirestoreFields.nationalIdNumber),
      photoUrl: wire.string(FirestoreFields.photoUrl),
    );
  }

  static Map<String, dynamic> toMap(OwnerIdentity entity) => {
    FirestoreFields.nationalIdNumber: entity.nationalIdNumber,
    FirestoreFields.photoUrl: entity.photoUrl,
  };
}
