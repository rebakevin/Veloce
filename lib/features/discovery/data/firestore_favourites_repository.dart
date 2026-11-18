import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:veloce/core/constants/firestore_paths.dart';
import 'package:veloce/core/data/models/favourite_model.dart';
import 'package:veloce/core/data/services/failure_mapper.dart';
import 'package:veloce/core/domain/entities/favourite.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/error/result.dart';

import '../domain/repositories/favourites_repository.dart';

/// Favourites live at `users/{uid}/favourites/{vehicleId}`.
class FirestoreFavouritesRepository implements FavouritesRepository {
  const FirestoreFavouritesRepository({
    required this._firestore,
    required this._clock,
  });

  static const Duration _timeout = Duration(seconds: 20);

  final FirebaseFirestore _firestore;
  final Clock _clock;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore
          .collection(FirestorePaths.users)
          .doc(userId)
          .collection(FirestorePaths.favourites);

  @override
  Stream<Result<List<Favourite>>> watch(String userId) {
    return _collection(userId)
        .snapshots()
        .map<Result<List<Favourite>>>((snapshot) {
          try {
            return Result.success([
              for (final doc in snapshot.docs)
                FavouriteModel.fromMap(doc.id, doc.data()),
            ]);
          } on Object catch (error, stackTrace) {
            return Result.failure(mapToFailure(error, stackTrace));
          }
        })
        .handleError(
          (Object error, StackTrace stackTrace) =>
              Result<List<Favourite>>.failure(mapToFailure(error, stackTrace)),
        );
  }

  @override
  Future<Result<void>> add({
    required String userId,
    required String vehicleId,
  }) async {
    try {
      final favourite = Favourite(
        vehicleId: vehicleId,
        userId: userId,
        createdAt: _clock.now(),
      );
      await _collection(userId)
          .doc(vehicleId)
          .set(FavouriteModel.toMap(favourite))
          .timeout(_timeout);
      return const Result.success(null);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> remove({
    required String userId,
    required String vehicleId,
  }) async {
    try {
      await _collection(userId).doc(vehicleId).delete().timeout(_timeout);
      return const Result.success(null);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }
}
