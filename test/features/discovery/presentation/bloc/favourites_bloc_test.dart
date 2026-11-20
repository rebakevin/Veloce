import 'package:flutter_test/flutter_test.dart';

import 'package:veloce/features/discovery/domain/usecases/get_vehicle_detail.dart';
import 'package:veloce/features/discovery/domain/usecases/toggle_favourite.dart';
import 'package:veloce/features/discovery/presentation/bloc/favourites_bloc.dart';

import '../../support/discovery_fakes.dart';

void main() {
  late FakeFavouritesRepository repository;
  late FavouritesBloc bloc;

  setUp(() {
    repository = FakeFavouritesRepository();
    bloc = FavouritesBloc(
      repository: repository,
      toggle: ToggleFavourite(repository),
      detail: GetVehicleDetail(FakeSearchRepository()),
      session: FakeAuthSession(),
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
}
