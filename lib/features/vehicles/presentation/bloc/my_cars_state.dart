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
  const MyCarsLoaded(this.vehicles, {this.notice});

  final List<Vehicle> vehicles;
  final String? notice;

  @override
  List<Object?> get props => [vehicles, notice];
}

final class MyCarsFailure extends MyCarsState {
  const MyCarsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
