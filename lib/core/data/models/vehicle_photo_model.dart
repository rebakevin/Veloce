import '../../constants/firestore_fields.dart';
import '../../domain/entities/vehicle_photo.dart';
import 'wire.dart';

/// Maps [VehiclePhoto] to and from the Firestore wire map.
abstract final class VehiclePhotoModel {
  static VehiclePhoto fromMap(String docId, Map<String, dynamic> map) {
    final wire = WireReader('VehiclePhoto', map);
    return VehiclePhoto(
      id: docId,
      vehicleId: wire.string(FirestoreFields.vehicleId),
      url: wire.string(FirestoreFields.url),
      order: wire.integer(FirestoreFields.order),
      isPrimary: wire.boolean(FirestoreFields.isPrimary),
    );
  }

  static Map<String, dynamic> toMap(VehiclePhoto entity) => {
    FirestoreFields.vehicleId: entity.vehicleId,
    FirestoreFields.url: entity.url,
    FirestoreFields.order: entity.order,
    FirestoreFields.isPrimary: entity.isPrimary,
  };
}
