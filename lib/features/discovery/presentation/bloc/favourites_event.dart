part of 'favourites_bloc.dart';

sealed class FavouritesEvent {
  const FavouritesEvent();
}

final class FavouritesStarted extends FavouritesEvent {
  const FavouritesStarted();
}

final class FavouriteToggled extends FavouritesEvent {
  const FavouriteToggled(this.vehicleId);

  final String vehicleId;
}

final class _FavouritesSnapshot extends FavouritesEvent {
  const _FavouritesSnapshot(this.result);

  final Result<List<Favourite>> result;
}
