import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/firestore_fields.dart';
import '../../domain/entities/user_account.dart';
import '../../domain/enums/user_role.dart';
import 'wire.dart';

/// Maps [UserAccount] to and from the Firestore wire map.
abstract final class UserAccountModel {
  static UserAccount fromMap(String docId, Map<String, dynamic> map) {
    final wire = WireReader('UserAccount', map);
    return UserAccount(
      id: docId,
      role: wire.enumValue(FirestoreFields.role, UserRole.fromKey),
      name: wire.string(FirestoreFields.name),
      photoUrl: wire.optionalString(FirestoreFields.photoUrl),
      verified: wire.boolean(FirestoreFields.verified),
      ratingAvg: wire.decimal(FirestoreFields.ratingAvg),
      ratingCount: wire.integer(FirestoreFields.ratingCount),
      completedCount: wire.integer(FirestoreFields.completedCount),
      createdAt: wire.dateTime(FirestoreFields.createdAt),
    );
  }

  static Map<String, dynamic> toMap(UserAccount entity) => {
    FirestoreFields.role: entity.role.key,
    FirestoreFields.name: entity.name,
    FirestoreFields.photoUrl: entity.photoUrl,
    FirestoreFields.verified: entity.verified,
    FirestoreFields.ratingAvg: entity.ratingAvg,
    FirestoreFields.ratingCount: entity.ratingCount,
    FirestoreFields.completedCount: entity.completedCount,
    FirestoreFields.createdAt: Timestamp.fromDate(entity.createdAt),
  };
}
