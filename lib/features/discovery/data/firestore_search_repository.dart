import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veloce/core/constants/firestore_fields.dart';
import 'package:veloce/core/constants/firestore_paths.dart';
import 'package:veloce/core/data/models/calendar_block_model.dart';
import 'package:veloce/core/data/models/user_account_model.dart';
import 'package:veloce/core/data/models/vehicle_model.dart';
import 'package:veloce/core/data/models/vehicle_photo_model.dart';
import 'package:veloce/core/data/services/failure_mapper.dart';
import 'package:veloce/core/domain/entities/calendar_block.dart';
import 'package:veloce/core/domain/entities/user_account.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/entities/vehicle_photo.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../domain/entities/search_query.dart';
import '../domain/entities/vehicle_card_data.dart';
import '../domain/entities/vehicle_detail.dart';
import '../domain/entities/vehicle_filters.dart';
import '../domain/repositories/search_repository.dart';
import '../domain/services/availability_rules.dart';

/// Firestore implementation of the §4.5 search: one indexed query, then the
/// client-side filters and availability checks Firestore cannot combine.
///
/// Query shape (the index must match): collection `vehicles`,
/// `status == published`, `docsValidUntil >= today`, plus `neighbourhood ==
/// area` when an area is chosen. No `orderBy`; sorting is client-side.
class FirestoreSearchRepository implements SearchRepository {
  FirestoreSearchRepository({
    required this._firestore,
    required this._session,
    required this._clock,
    this.rules = const AvailabilityRules(),
  });

  static const Duration _timeout = Duration(seconds: 20);

  final FirebaseFirestore _firestore;
  final AuthSession _session;
  final Clock _clock;
  final AvailabilityRules rules;

  @override
  Future<Result<List<VehicleCardData>>> search({
    required SearchQuery query,
    required VehicleFilters filters,
  }) async {
    try {
      final today = rules.day(_clock.now());
      Query<Map<String, dynamic>> request = _firestore
          .collection(FirestorePaths.vehicles)
          .where(FirestoreFields.status, isEqualTo: VehicleStatus.published.key)
          .where(
            FirestoreFields.docsValidUntil,
            isGreaterThanOrEqualTo: Timestamp.fromDate(today),
          );
      final area = query.area;
      if (area != null) {
        request = request.where(FirestoreFields.neighbourhood, isEqualTo: area);
      }

      final snapshot = await request.get().timeout(_timeout);
      final candidates = <Vehicle>[];
      for (final doc in snapshot.docs) {
        final vehicle = VehicleModel.fromMap(doc.id, doc.data());
        if (vehicle.ownerId == _session.currentUserId) continue;
        if (!rules.isWithinWindow(vehicle, query.start, query.end)) continue;
        if (query.typeChip != null && vehicle.type != query.typeChip) continue;
        if (!filters.matches(vehicle)) continue;
        candidates.add(vehicle);
      }
      final results = await Future.wait(
        candidates.map((vehicle) => _cardIfFree(vehicle, query)),
      );
      final cards = results.nonNulls.toList();
      cards.sort(
        (a, b) => a.vehicle.dailyPrice.compareTo(b.vehicle.dailyPrice),
      );
      return Result.success(cards);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  Future<VehicleCardData?> _cardIfFree(
    Vehicle vehicle,
    SearchQuery query,
  ) async {
    final blocks = await _blocksFor(vehicle.id, query.start, query.end);
    if (!rules.isFree(blocks, query.start, query.end)) return null;
    final photos = await _photos(vehicle.id);
    return VehicleCardData(
      vehicle: vehicle,
      photoUrl: _primaryPhotoUrl(photos),
    );
  }

  @override
  Future<Result<VehicleDetail>> detail(String vehicleId) async {
    try {
      final snapshot = await _firestore
          .doc(FirestorePaths.vehicle(vehicleId))
          .get()
          .timeout(_timeout);
      final data = snapshot.data();
      if (data == null) {
        return const Result.failure(NotFoundFailure('This car was removed.'));
      }
      final vehicle = VehicleModel.fromMap(snapshot.id, data);
      final ownerResult = await _owner(vehicle.ownerId);
      if (ownerResult case Failure(:final failure)) {
        return Result.failure(failure);
      }
      final photos = await _photos(vehicleId);
      final blocks = await _allBlocks(vehicleId);
      return Result.success(
        VehicleDetail(
          vehicle: vehicle,
          photos: photos,
          owner: (ownerResult as Success<UserAccount>).value,
          blocks: blocks,
        ),
      );
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<List<VehicleCardData>>> ownerCars(String ownerId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.vehicles)
          .where(FirestoreFields.ownerId, isEqualTo: ownerId)
          .orderBy(FirestoreFields.createdAt, descending: true)
          .get()
          .timeout(_timeout);
      final today = rules.day(_clock.now());
      final cards = <VehicleCardData>[];
      for (final doc in snapshot.docs) {
        final vehicle = VehicleModel.fromMap(doc.id, doc.data());
        if (vehicle.status != VehicleStatus.published) continue;
        if (!rules.hasValidDocs(vehicle, today)) continue;
        final photos = await _photos(vehicle.id);
        cards.add(
          VehicleCardData(vehicle: vehicle, photoUrl: _primaryPhotoUrl(photos)),
        );
      }
      cards.sort(
        (a, b) => a.vehicle.dailyPrice.compareTo(b.vehicle.dailyPrice),
      );
      return Result.success(cards);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  Future<Result<UserAccount>> _owner(String ownerId) async {
    try {
      final snapshot = await _firestore
          .doc(FirestorePaths.user(ownerId))
          .get()
          .timeout(_timeout);
      final data = snapshot.data();
      if (data == null) {
        return const Result.failure(
          NotFoundFailure('The owner was not found.'),
        );
      }
      return Result.success(UserAccountModel.fromMap(snapshot.id, data));
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  Future<List<VehiclePhoto>> _photos(String vehicleId) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.vehicles)
        .doc(vehicleId)
        .collection(FirestorePaths.photos)
        .orderBy(FirestoreFields.order)
        .get()
        .timeout(_timeout);
    return [
      for (final doc in snapshot.docs)
        VehiclePhotoModel.fromMap(doc.id, doc.data()),
    ];
  }

  Future<List<CalendarBlock>> _blocksFor(
    String vehicleId,
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.calendarBlocks)
        .where(FirestoreFields.vehicleId, isEqualTo: vehicleId)
        .where(
          FirestoreFields.endDate,
          isGreaterThan: Timestamp.fromDate(rules.day(start)),
        )
        .get()
        .timeout(_timeout);
    final blocks = [
      for (final doc in snapshot.docs)
        CalendarBlockModel.fromMap(doc.id, doc.data()),
    ];
    return [
      for (final block in blocks)
        if (rules.blockOverlaps(block, start, end)) block,
    ];
  }

  Future<List<CalendarBlock>> _allBlocks(String vehicleId) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.calendarBlocks)
        .where(FirestoreFields.vehicleId, isEqualTo: vehicleId)
        .get()
        .timeout(_timeout);
    return [
      for (final doc in snapshot.docs)
        CalendarBlockModel.fromMap(doc.id, doc.data()),
    ];
  }

  String? _primaryPhotoUrl(List<VehiclePhoto> photos) {
    if (photos.isEmpty) return null;
    for (final photo in photos) {
      if (photo.isPrimary) return photo.url;
    }
    return photos.first.url;
  }
}
