import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/features/discovery/domain/entities/vehicle_card_data.dart';
import 'package:veloce/features/discovery/domain/usecases/get_vehicle_detail.dart';
import 'package:veloce/features/discovery/domain/usecases/toggle_favourite.dart';
import 'package:veloce/features/discovery/presentation/bloc/favourites_bloc.dart';
import 'package:veloce/features/discovery/presentation/widgets/car_card.dart';

import '../../../../support/builders.dart';
import '../../support/discovery_fakes.dart';

void main() {
  testWidgets('the heart and Saved count update from one FavouritesBloc', (
    tester,
  ) async {
    final repository = FakeFavouritesRepository();
    final bloc = FavouritesBloc(
      repository: repository,
      toggle: ToggleFavourite(repository),
      detail: GetVehicleDetail(FakeSearchRepository()),
      session: FakeAuthSession(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: BlocProvider<FavouritesBloc>.value(
            value: bloc,
            child: BlocBuilder<FavouritesBloc, FavouritesState>(
              builder: (context, state) => SingleChildScrollView(
                child: Column(
                  children: [
                    CarCard(
                      car: VehicleCardData(vehicle: aVehicle()),
                      isFavourite: state.contains('car-1'),
                      onFavourite: () => context.read<FavouritesBloc>().add(
                        const FavouriteToggled('car-1'),
                      ),
                      onTap: () {},
                    ),
                    Text('Saved ${state.favouriteIds.length}'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    bloc.add(const FavouritesStarted());
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(find.text('Saved 0'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border_rounded));
    await tester.pump();

    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.text('Saved 1'), findsOneWidget);

    unawaited(bloc.close());
    unawaited(repository.close());
  });
}
