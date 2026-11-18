import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:veloce/core/error/app_failure.dart';

import '../../domain/entities/search_query.dart';
import '../../domain/entities/vehicle_card_data.dart';
import '../../domain/entities/vehicle_filters.dart';
import '../../domain/usecases/search_vehicles.dart';

part 'results_event.dart';
part 'results_state.dart';

/// Loads the result list for one query. Filters and query changes reload; the
/// UI never filters or sorts a list itself.
class ResultsBloc extends Bloc<ResultsEvent, ResultsState> {
  ResultsBloc({
    required this._search,
    required SearchQuery initialQuery,
    required VehicleFilters initialFilters,
  }) : super(ResultsLoading(query: initialQuery, filters: initialFilters)) {
    on<ResultsStarted>(_onLoad);
    on<ResultsRefreshed>(_onLoad);
    on<ResultsFiltersChanged>(_onFiltersChanged);
    on<ResultsQueryChanged>(_onQueryChanged);
  }

  final SearchVehicles _search;

  Future<void> _onLoad(ResultsEvent event, Emitter<ResultsState> emit) =>
      _load(emit, state.query, state.filters);

  Future<void> _onFiltersChanged(
    ResultsFiltersChanged event,
    Emitter<ResultsState> emit,
  ) => _load(emit, state.query, event.filters);

  Future<void> _onQueryChanged(
    ResultsQueryChanged event,
    Emitter<ResultsState> emit,
  ) => _load(emit, event.query, state.filters);

  Future<void> _load(
    Emitter<ResultsState> emit,
    SearchQuery query,
    VehicleFilters filters,
  ) async {
    emit(ResultsLoading(query: query, filters: filters));
    final result = await _search(query: query, filters: filters);
    if (isClosed) return;
    result.when(
      success: (cars) => emit(
        cars.isEmpty
            ? ResultsEmpty(query: query, filters: filters)
            : ResultsLoaded(query: query, filters: filters, cars: cars),
      ),
      failure: (failure) =>
          emit(ResultsFailure(query: query, filters: filters, error: failure)),
    );
  }
}
