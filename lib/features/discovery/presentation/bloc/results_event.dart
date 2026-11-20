part of 'results_bloc.dart';

sealed class ResultsEvent {
  const ResultsEvent();
}

final class ResultsStarted extends ResultsEvent {
  const ResultsStarted();
}

final class ResultsRefreshed extends ResultsEvent {
  const ResultsRefreshed();
}

final class ResultsFiltersChanged extends ResultsEvent {
  const ResultsFiltersChanged(this.filters);

  final VehicleFilters filters;
}

final class ResultsQueryChanged extends ResultsEvent {
  const ResultsQueryChanged(this.query);

  final SearchQuery query;
}
