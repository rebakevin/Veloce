part of 'my_cars_bloc.dart';

sealed class MyCarsEvent extends Equatable {
  const MyCarsEvent();

  @override
  List<Object?> get props => [];
}

final class MyCarsStarted extends MyCarsEvent {
  const MyCarsStarted();
}

final class MyCarsStatusToggled extends MyCarsEvent {
  const MyCarsStatusToggled(this.vehicle);

  final Vehicle vehicle;

  @override
  List<Object?> get props => [vehicle];
}

final class MyCarsRemoveRequested extends MyCarsEvent {
  const MyCarsRemoveRequested(this.vehicleId);

  final String vehicleId;

  @override
  List<Object?> get props => [vehicleId];
}

final class MyCarsNoticeCleared extends MyCarsEvent {
  const MyCarsNoticeCleared();
}

/// Pull to refresh: reloads next rentals and photos for the cars on screen.
final class MyCarsRefreshRequested extends MyCarsEvent {
  const MyCarsRefreshRequested();
}
