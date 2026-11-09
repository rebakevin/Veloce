import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/firestore_fields.dart';
import '../../domain/entities/vehicle_document.dart';
import '../../domain/enums/document_kind.dart';
import 'wire.dart';

/// Maps [VehicleDocument] to and from the Firestore wire map.
abstract final class VehicleDocumentModel {
  static VehicleDocument fromMap(String docId, Map<String, dynamic> map) {
    final wire = WireReader('VehicleDocument', map);
    return VehicleDocument(
      kind: DocumentKind.fromKey(docId),
      vehicleId: wire.string(FirestoreFields.vehicleId),
      number: wire.string(FirestoreFields.number),
      expiry: wire.dateTime(FirestoreFields.expiry),
      photoUrl: wire.string(FirestoreFields.photoUrl),
      verified: wire.boolean(FirestoreFields.verified),
    );
  }

  static Map<String, dynamic> toMap(VehicleDocument entity) => {
    FirestoreFields.vehicleId: entity.vehicleId,
    FirestoreFields.number: entity.number,
    FirestoreFields.expiry: Timestamp.fromDate(entity.expiry),
    FirestoreFields.photoUrl: entity.photoUrl,
    FirestoreFields.verified: entity.verified,
  };
}
