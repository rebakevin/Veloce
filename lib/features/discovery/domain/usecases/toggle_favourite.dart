import 'package:veloce/core/error/result.dart';

import '../repositories/favourites_repository.dart';

class ToggleFavourite {
  const ToggleFavourite(this._repository);

  final FavouritesRepository _repository;

  Future<Result<void>> call({
    required String userId,
    required String vehicleId,
    required bool isFavourite,
  }) {
    return isFavourite
        ? _repository.remove(userId: userId, vehicleId: vehicleId)
        : _repository.add(userId: userId, vehicleId: vehicleId);
  }
}
