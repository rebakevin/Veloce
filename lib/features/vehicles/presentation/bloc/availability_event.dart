part of 'availability_bloc.dart';

sealed class AvailabilityEvent extends Equatable {
  const AvailabilityEvent();

  @override
  List<Object?> get props => [];
}

final class AvailabilityStarted extends AvailabilityEvent {
  const AvailabilityStarted(this.vehicleId);

  final String vehicleId;

  @override
  List<Object?> get props => [vehicleId];
}

final class AvailabilityRangeChanged extends AvailabilityEvent {
  const AvailabilityRangeChanged(this.from, this.to);

  final DateTime from;
  final DateTime to;

  @override
  List<Object?> get props => [from, to];
}

final class AvailabilitySaved extends AvailabilityEvent {
  const AvailabilitySaved();
}

final class AvailabilityNoticeCleared extends AvailabilityEvent {
  const AvailabilityNoticeCleared();
}
