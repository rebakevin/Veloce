import 'package:flutter_test/flutter_test.dart';

import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/discovery/domain/usecases/get_vehicle_detail.dart';
import 'package:veloce/features/discovery/domain/usecases/toggle_favourite.dart';
import 'package:veloce/features/discovery/presentation/bloc/favourites_bloc.dart';

import '../../support/discovery_fakes.dart';

void main() {
  late FakeAuthSession session;
  late FakeFavouritesRepository repository;
  late FavouritesBloc bloc;
  late FakeSearchRepository search;

  setUp(() {
    repository = FakeFavouritesRepository();
    search = FakeSearchRepository();
    session = FakeAuthSession();
    bloc = FavouritesBloc(
      repository: repository,
      toggle: ToggleFavourite(repository),
      detail: GetVehicleDetail(search),
      session: session,
    );
  });

  tearDown(() async {
    await bloc.close();
    await repository.close();
  });

  test('starts empty when the renter has no favourites', () async {
    bloc.add(const FavouritesStarted());
    await pumpEventQueue();
    expect(bloc.state, isA<FavouritesLoaded>());
    expect(bloc.state.favouriteIds, isEmpty);
    expect(bloc.state.cars, isEmpty);
  });

  test('toggling adds the car and hydrates the saved list', () async {
    bloc.add(const FavouritesStarted());
    await pumpEventQueue();
    bloc.add(const FavouriteToggled('car-1'));
    await pumpEventQueue();
    expect(bloc.state, isA<FavouritesLoaded>());
    expect(bloc.state.contains('car-1'), isTrue);
    expect(bloc.state.cars, hasLength(1));
  });

  test('toggling again removes the car', () async {
    bloc.add(const FavouritesStarted());
    await pumpEventQueue();
    bloc.add(const FavouriteToggled('car-1'));
    await pumpEventQueue();
    bloc.add(const FavouriteToggled('car-1'));
    await pumpEventQueue();
    expect(bloc.state.contains('car-1'), isFalse);
    expect(bloc.state.cars, isEmpty);
  });

  test('a removed car leaves the ids so the count matches the list', () async {
    search.detailResult = const Result.failure(NotFoundFailure('Removed.'));
    bloc.add(const FavouritesStarted());
    await pumpEventQueue();
    bloc.add(const FavouriteToggled('car-1'));
    await pumpEventQueue();
    expect(bloc.state.cars, isEmpty);
    expect(bloc.state.favouriteIds, isEmpty);
  });

  test('an account switch clears the previous renter hearts at once', () async {
    bloc.add(const FavouritesStarted());
    await pumpEventQueue();
    bloc.add(const FavouriteToggled('car-1'));
    await pumpEventQueue();
    expect(bloc.state.contains('car-1'), isTrue);

    final seen = <FavouritesState>[];
    final subscription = bloc.stream.listen(seen.add);
    session.switchTo('renter-2');
    await pumpEventQueue();
    await subscription.cancel();

    expect(seen.first, isA<FavouritesLoading>());
    expect(seen.first.favouriteIds, isEmpty);
    expect(seen.first.cars, isEmpty);
  });

  test('a removed car has its dangling favourite deleted', () async {
    search.detailResult = const Result.failure(NotFoundFailure('Removed.'));
    bloc.add(const FavouritesStarted());
    await pumpEventQueue();
    bloc.add(const FavouriteToggled('car-1'));
    await pumpEventQueue();
    expect(repository.removedIds, contains('car-1'));
  });
}
