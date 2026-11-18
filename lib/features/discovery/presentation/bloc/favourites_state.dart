part of 'favourites_bloc.dart';

sealed class FavouritesState extends Equatable {
  const FavouritesState({this.favouriteIds = const {}, this.cars = const []});

  final Set<String> favouriteIds;
  final List<VehicleCardData> cars;

  bool contains(String vehicleId) => favouriteIds.contains(vehicleId);

  @override
  List<Object?> get props => [favouriteIds, cars];
}

final class FavouritesLoading extends FavouritesState {
  const FavouritesLoading({super.favouriteIds, super.cars});
}

final class FavouritesLoaded extends FavouritesState {
  const FavouritesLoaded({super.favouriteIds, super.cars});
}

final class FavouritesFailure extends FavouritesState {
  const FavouritesFailure({
    required this.error,
    super.favouriteIds,
    super.cars,
  });

  final AppFailure error;

  @override
  List<Object?> get props => [...super.props, error];
}
