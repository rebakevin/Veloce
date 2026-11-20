part of 'results_bloc.dart';

sealed class ResultsState extends Equatable {
  const ResultsState({required this.query, required this.filters});

  final SearchQuery query;
  final VehicleFilters filters;

  @override
  List<Object?> get props => [query, filters];
}

final class ResultsLoading extends ResultsState {
  const ResultsLoading({required super.query, required super.filters});
}

final class ResultsEmpty extends ResultsState {
  const ResultsEmpty({required super.query, required super.filters});
}

final class ResultsLoaded extends ResultsState {
  const ResultsLoaded({
    required super.query,
    required super.filters,
    required this.cars,
  });

  final List<VehicleCardData> cars;

  @override
  List<Object?> get props => [...super.props, cars];
}

final class ResultsFailure extends ResultsState {
  const ResultsFailure({
    required super.query,
    required super.filters,
    required this.error,
  });

  final AppFailure error;

  @override
  List<Object?> get props => [...super.props, error];
}
