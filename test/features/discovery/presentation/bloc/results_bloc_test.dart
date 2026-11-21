import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/discovery/domain/entities/search_query.dart';
import 'package:veloce/features/discovery/domain/entities/vehicle_card_data.dart';
import 'package:veloce/features/discovery/domain/entities/vehicle_filters.dart';
import 'package:veloce/features/discovery/domain/usecases/search_vehicles.dart';
import 'package:veloce/features/discovery/presentation/bloc/results_bloc.dart';

import '../../../../support/builders.dart';
import '../../support/discovery_fakes.dart';

/// Completes each search only when the test says so, to force an overlap.
class _GatedSearchRepository extends FakeSearchRepository {
  final List<Completer<Result<List<VehicleCardData>>>> gates = [];

  @override
  Future<Result<List<VehicleCardData>>> search({
    required SearchQuery query,
    required VehicleFilters filters,
  }) {
    final gate = Completer<Result<List<VehicleCardData>>>();
    gates.add(gate);
    return gate.future;
  }
}

void main() {
  final query = SearchQuery(
    start: testNow,
    end: testNow.add(const Duration(days: 3)),
  );

  test('loads an empty result', () async {
    final repository = FakeSearchRepository();
    final bloc = ResultsBloc(
      search: SearchVehicles(repository),
      initialQuery: query,
      initialFilters: VehicleFilters.none,
    )..add(const ResultsStarted());
    await pumpEventQueue();
    expect(bloc.state, isA<ResultsEmpty>());
    await bloc.close();
  });

  test('loads cars and keeps the query and filters', () async {
    final repository = FakeSearchRepository(
      searchResult: Result.success([VehicleCardData(vehicle: aVehicle())]),
    );
    final bloc = ResultsBloc(
      search: SearchVehicles(repository),
      initialQuery: query,
      initialFilters: VehicleFilters.none,
    )..add(const ResultsStarted());
    await pumpEventQueue();
    expect(bloc.state, isA<ResultsLoaded>());
    expect((bloc.state as ResultsLoaded).cars, hasLength(1));
    await bloc.close();
  });

  test('reports a failure and retries', () async {
    final repository = FakeSearchRepository(
      searchResult: const Result.failure(NetworkFailure()),
    );
    final bloc = ResultsBloc(
      search: SearchVehicles(repository),
      initialQuery: query,
      initialFilters: VehicleFilters.none,
    )..add(const ResultsStarted());
    await pumpEventQueue();
    expect(bloc.state, isA<ResultsFailure>());
    bloc.add(const ResultsRefreshed());
    await pumpEventQueue();
    expect(bloc.state, isA<ResultsFailure>());
    await bloc.close();
  });

  test('filters and queries reload through the repository', () async {
    final repository = FakeSearchRepository();
    final bloc = ResultsBloc(
      search: SearchVehicles(repository),
      initialQuery: query,
      initialFilters: VehicleFilters.none,
    )..add(const ResultsStarted());
    await pumpEventQueue();
    bloc.add(const ResultsFiltersChanged(VehicleFilters(minPrice: 50000)));
    await pumpEventQueue();
    expect(repository.lastFilters?.minPrice, 50000);
    final other = SearchQuery(
      start: testNow.add(const Duration(days: 2)),
      end: testNow.add(const Duration(days: 4)),
    );
    bloc.add(ResultsQueryChanged(other));
    await pumpEventQueue();
    expect(repository.lastQuery, other);
    await bloc.close();
  });

  blocTest<ResultsBloc, ResultsState>(
    'emits loading before a loaded state',
    build: () => ResultsBloc(
      search: SearchVehicles(FakeSearchRepository()),
      initialQuery: query,
      initialFilters: VehicleFilters.none,
    ),
    act: (bloc) => bloc.add(const ResultsStarted()),
    expect: () => [isA<ResultsLoading>(), isA<ResultsEmpty>()],
  );

  test('a slow older search cannot overwrite the newest one', () async {
    final repository = _GatedSearchRepository();
    final bloc = ResultsBloc(
      search: SearchVehicles(repository),
      initialQuery: query,
      initialFilters: VehicleFilters.none,
    )..add(const ResultsStarted());
    await pumpEventQueue();
    bloc.add(const ResultsFiltersChanged(VehicleFilters(minPrice: 50000)));
    await pumpEventQueue();
    expect(repository.gates, hasLength(2));
    repository.gates[1].complete(
      Result.success([VehicleCardData(vehicle: aVehicle(id: 'new'))]),
    );
    await pumpEventQueue();
    repository.gates[0].complete(
      Result.success([VehicleCardData(vehicle: aVehicle(id: 'old'))]),
    );
    await pumpEventQueue();
    final state = bloc.state as ResultsLoaded;
    expect(state.cars.single.vehicle.id, 'new');
    expect(state.filters.minPrice, 50000);
    await bloc.close();
  });
}
