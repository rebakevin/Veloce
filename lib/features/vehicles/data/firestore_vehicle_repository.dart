import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veloce/core/constants/firestore_fields.dart';
import 'package:veloce/core/constants/firestore_paths.dart';
import 'package:veloce/core/data/models/booking_model.dart';
import 'package:veloce/core/data/models/vehicle_document_model.dart';
import 'package:veloce/core/data/models/vehicle_model.dart';
import 'package:veloce/core/data/models/vehicle_photo_model.dart';
import 'package:veloce/core/data/services/failure_mapper.dart';
import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/entities/vehicle_document.dart';
import 'package:veloce/core/domain/entities/vehicle_photo.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';
import 'package:veloce/core/domain/services/atomic_write.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../domain/entities/publish_request.dart';
import '../domain/repositories/vehicle_repository.dart';

class FirestoreVehicleRepository implements VehicleRepository {
  const FirestoreVehicleRepository({
    required this._firestore,
    required this._writes,
    required this._session,
  });

  static const Duration _timeout = Duration(seconds: 20);

  final FirebaseFirestore _firestore;
  final AtomicWriteFactory _writes;
  final AuthSession _session;

  @override
  Stream<Result<List<Vehicle>>> watchOwnerVehicles(String ownerId) async* {
    try {
      final snapshots = _firestore
          .collection(FirestorePaths.vehicles)
          .where(FirestoreFields.ownerId, isEqualTo: ownerId)
          .snapshots();
      await for (final snapshot in snapshots) {
        yield Result.success(
          snapshot.docs
              .map((doc) => VehicleModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
      }
    } on Object catch (error, stackTrace) {
      yield Result.failure(mapToFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<List<Booking>>> bookingsOf(String vehicleId) async {
    // The bookings read rule (`isParty`) only holds for a query that is also
    // filtered by the signed-in owner.
    final ownerId = _session.currentUserId;
    if (ownerId == null) {
      return const Result.failure(
        PermissionFailure('Sign in to see your bookings.'),
      );
    }
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.bookings)
          .where(FirestoreFields.vehicleId, isEqualTo: vehicleId)
          .where(FirestoreFields.ownerId, isEqualTo: ownerId)
          .get()
          .timeout(_timeout);
      return Result.success(
        snapshot.docs
            .map((doc) => BookingModel.fromMap(doc.id, doc.data()))
            .toList(),
      );
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<String>> publish(PublishRequest request) async {
    try {
      final write = _writes.begin();
      final id = write.newId(FirestorePaths.vehicles);
      final vehiclePath = FirestorePaths.vehicle(id);
      final photosPath = '$vehiclePath/${FirestorePaths.photos}';
      final documentsPath = '$vehiclePath/${FirestorePaths.documents}';

      write.set(
        vehiclePath,
        VehicleModel.toMap(request.vehicle.copyWith(id: id)),
      );
      for (final photo in request.photos) {
        write.set(
          '$photosPath/${write.newId(photosPath)}',
          VehiclePhotoModel.toMap(photo.copyWith(vehicleId: id)),
        );
      }
      for (final document in request.documents) {
        write.set(
          '$documentsPath/${document.kind.key}',
          VehicleDocumentModel.toMap(document.copyWith(vehicleId: id)),
        );
      }
      await write.commit().timeout(_timeout);
      return Result.success(id);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> setStatus(String vehicleId, VehicleStatus status) async {
    try {
      final write = _writes.begin()
        ..update(FirestorePaths.vehicle(vehicleId), {
          FirestoreFields.status: status.key,
        });
      await write.commit().timeout(_timeout);
      return const Result.success(null);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> remove(String vehicleId) async {
    try {
      final vehiclePath = FirestorePaths.vehicle(vehicleId);
      final photos = await _firestore
          .collection('$vehiclePath/${FirestorePaths.photos}')
          .get()
          .timeout(_timeout);
      final documents = await _firestore
          .collection('$vehiclePath/${FirestorePaths.documents}')
          .get()
          .timeout(_timeout);

      final write = _writes.begin();
      for (final doc in [...photos.docs, ...documents.docs]) {
        write.delete(doc.reference.path);
      }
      write.delete(vehiclePath);
      await write.commit().timeout(_timeout);
      return const Result.success(null);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  @override
  Stream<Result<Vehicle>> watchVehicle(String vehicleId) async* {
    try {
      final snapshots = _firestore
          .doc(FirestorePaths.vehicle(vehicleId))
          .snapshots();
      await for (final snapshot in snapshots) {
        final data = snapshot.data();
        yield data == null
            ? Result.failure(
                mapToFailure(
                  StateError('vehicle not found'),
                  StackTrace.current,
                ),
              )
            : Result.success(VehicleModel.fromMap(snapshot.id, data));
      }
    } on Object catch (error, stackTrace) {
      yield Result.failure(mapToFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<List<VehiclePhoto>>> photosOf(String vehicleId) async {
    try {
      final snapshot = await _firestore
          .collection(
            '${FirestorePaths.vehicle(vehicleId)}/${FirestorePaths.photos}',
          )
          .get()
          .timeout(_timeout);
      return Result.success(
        snapshot.docs
            .map((doc) => VehiclePhotoModel.fromMap(doc.id, doc.data()))
            .toList(),
      );
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<List<VehicleDocument>>> documentsOf(String vehicleId) async {
    try {
      final snapshot = await _firestore
          .collection(
            '${FirestorePaths.vehicle(vehicleId)}/${FirestorePaths.documents}',
          )
          .get()
          .timeout(_timeout);
      return Result.success(
        snapshot.docs
            .map((doc) => VehicleDocumentModel.fromMap(doc.id, doc.data()))
            .toList(),
      );
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> update(
    Vehicle vehicle,
    List<VehiclePhoto> photos,
  ) async {
    try {
      final vehiclePath = FirestorePaths.vehicle(vehicle.id);
      final photosPath = '$vehiclePath/${FirestorePaths.photos}';
      final existing = await _firestore
          .collection(photosPath)
          .get()
          .timeout(_timeout);

      final fields = VehicleModel.toMap(vehicle)
        ..remove(FirestoreFields.ownerId)
        ..remove(FirestoreFields.createdAt)
        ..remove(FirestoreFields.ratingAvg)
        ..remove(FirestoreFields.ratingCount);
      final write = _writes.begin()..update(vehiclePath, fields);
      for (final doc in existing.docs) {
        write.delete(doc.reference.path);
      }
      for (final photo in photos) {
        write.set(
          '$photosPath/${write.newId(photosPath)}',
          VehiclePhotoModel.toMap(photo.copyWith(vehicleId: vehicle.id)),
        );
      }
      await write.commit().timeout(_timeout);
      return const Result.success(null);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> setAvailability(
    String vehicleId,
    DateTime? from,
    DateTime? to,
  ) async {
    try {
      final write = _writes.begin()
        ..update(FirestorePaths.vehicle(vehicleId), {
          FirestoreFields.availableFrom: from == null
              ? null
              : Timestamp.fromDate(from),
          FirestoreFields.availableTo: to == null
              ? null
              : Timestamp.fromDate(to),
        });
      await write.commit().timeout(_timeout);
      return const Result.success(null);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> upsertDocument(
    VehicleDocument document, {
    required DateTime? docsValidUntil,
    required VehicleStatus status,
  }) async {
    try {
      final vehiclePath = FirestorePaths.vehicle(document.vehicleId);
      final write = _writes.begin()
        ..set(
          '$vehiclePath/${FirestorePaths.documents}/${document.kind.key}',
          VehicleDocumentModel.toMap(document),
        )
        ..update(vehiclePath, {
          FirestoreFields.docsValidUntil: docsValidUntil == null
              ? null
              : Timestamp.fromDate(docsValidUntil),
          FirestoreFields.status: status.key,
        });
      await write.commit().timeout(_timeout);
      return const Result.success(null);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }
}
