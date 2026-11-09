import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/firestore_paths.dart';
import '../../domain/entities/vehicle.dart';
import '../models/vehicle_model.dart';
import 'cached_document_lookup.dart';

/// Cached read-by-id and stream of [Vehicle] for cross-feature reads.
class VehicleLookup extends CachedDocumentLookup<Vehicle> {
  VehicleLookup(FirebaseFirestore firestore)
    : super(
        firestore: firestore,
        collection: FirestorePaths.vehicles,
        fromMap: VehicleModel.fromMap,
      );
}
