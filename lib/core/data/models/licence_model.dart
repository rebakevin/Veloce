import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/firestore_fields.dart';
import '../../domain/entities/licence.dart';
import 'wire.dart';

/// Maps [Licence] to and from the Firestore wire map.
abstract final class LicenceModel {
  static Licence fromMap(String docId, Map<String, dynamic> map) {
    final wire = WireReader('Licence', map);
    return Licence(
      userId: docId,
      number: wire.string(FirestoreFields.number),
      expiry: wire.dateTime(FirestoreFields.expiry),
      photoUrl: wire.string(FirestoreFields.photoUrl),
      active: wire.boolean(FirestoreFields.active),
    );
  }

  static Map<String, dynamic> toMap(Licence entity) => {
    FirestoreFields.number: entity.number,
    FirestoreFields.expiry: Timestamp.fromDate(entity.expiry),
    FirestoreFields.photoUrl: entity.photoUrl,
    FirestoreFields.active: entity.active,
  };
}
