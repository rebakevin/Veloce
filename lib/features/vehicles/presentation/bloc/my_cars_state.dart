part of 'my_cars_bloc.dart';

sealed class MyCarsState extends Equatable {
  const MyCarsState();

  @override
  List<Object?> get props => [];
}

final class MyCarsLoading extends MyCarsState {
  const MyCarsLoading();
}

final class MyCarsEmpty extends MyCarsState {
  const MyCarsEmpty();
}

final class MyCarsLoaded extends MyCarsState {
  const MyCarsLoaded(
    this.vehicles, {
    this.nextRentals = const {},
    this.primaryPhotos = const {},
    this.expiredIds = const {},
    this.refreshCount = 0,
    this.notice,
  });

  final List<Vehicle> vehicles;
  final Map<String, Booking> nextRentals;

  /// Main photo url per vehicle id.
  final Map<String, String> primaryPhotos;

  /// Ids of cars whose required papers have lapsed.
  final Set<String> expiredIds;
  final String? notice;

  /// Bumped by every pull to refresh so the state always changes and the
  /// refresh indicator can finish.
  final int refreshCount;

  MyCarsLoaded withNotice(String message) => MyCarsLoaded(
    vehicles,
    nextRentals: nextRentals,
    primaryPhotos: primaryPhotos,
    expiredIds: expiredIds,
    refreshCount: refreshCount,
    notice: message,
  );

  MyCarsLoaded withoutNotice() => MyCarsLoaded(
    vehicles,
    nextRentals: nextRentals,
    primaryPhotos: primaryPhotos,
    expiredIds: expiredIds,
    refreshCount: refreshCount,
  );

  @override
  List<Object?> get props => [
    vehicles,
    nextRentals,
    primaryPhotos,
    expiredIds,
    refreshCount,
    notice,
  ];
}

final class MyCarsFailure extends MyCarsState {
  const MyCarsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
