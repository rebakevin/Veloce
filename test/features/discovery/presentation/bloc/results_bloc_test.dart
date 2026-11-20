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
}
