import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/firestore_fields.dart';
import '../../domain/entities/favourite.dart';
import 'wire.dart';

/// Maps [Favourite] to and from the Firestore wire map.
abstract final class FavouriteModel {
  static Favourite fromMap(String docId, Map<String, dynamic> map) {
    final wire = WireReader('Favourite', map);
    return Favourite(
      vehicleId: docId,
      userId: wire.string(FirestoreFields.userId),
      createdAt: wire.dateTime(FirestoreFields.createdAt),
    );
  }

  static Map<String, dynamic> toMap(Favourite entity) => {
    FirestoreFields.userId: entity.userId,
    FirestoreFields.createdAt: Timestamp.fromDate(entity.createdAt),
  };
}
