import 'package:veloce/core/domain/entities/favourite.dart';
import 'package:veloce/core/error/result.dart';

/// Reads and writes `users/{uid}/favourites`.
abstract interface class FavouritesRepository {
  Stream<Result<List<Favourite>>> watch(String userId);

  Future<Result<void>> add({required String userId, required String vehicleId});

  Future<Result<void>> remove({
    required String userId,
    required String vehicleId,
  });
}
