import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/firestore_fields.dart';
import '../../domain/entities/contact.dart';
import '../../domain/enums/auth_provider_kind.dart';
import 'wire.dart';

/// Maps [Contact] to and from the Firestore wire map.
abstract final class ContactModel {
  static Contact fromMap(String docId, Map<String, dynamic> map) {
    final wire = WireReader('Contact', map);
    return Contact(
      userId: docId,
      email: wire.string(FirestoreFields.email),
      phone: wire.string(FirestoreFields.phone),
      dateOfBirth: wire.dateTime(FirestoreFields.dateOfBirth),
      authProvider: wire.enumValue(
        FirestoreFields.authProvider,
        AuthProviderKind.fromKey,
      ),
    );
  }

  static Map<String, dynamic> toMap(Contact entity) => {
    FirestoreFields.email: entity.email,
    FirestoreFields.phone: entity.phone,
    FirestoreFields.dateOfBirth: Timestamp.fromDate(entity.dateOfBirth),
    FirestoreFields.authProvider: entity.authProvider.key,
  };
}
