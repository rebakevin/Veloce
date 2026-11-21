import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:veloce/core/domain/entities/favourite.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../../domain/entities/vehicle_card_data.dart';
import '../../domain/repositories/favourites_repository.dart';
import '../../domain/usecases/get_vehicle_detail.dart';
import '../../domain/usecases/toggle_favourite.dart';

part 'favourites_event.dart';
part 'favourites_state.dart';

/// One source for every heart and the Saved tab. A toggle updates the ids
/// immediately, then the Firestore stream reconciles the saved car list.
class FavouritesBloc extends Bloc<FavouritesEvent, FavouritesState> {
  FavouritesBloc({
    required this._repository,
    required this._toggle,
    required this._detail,
    required this._session,
  }) : super(const FavouritesLoading()) {
    on<FavouritesStarted>(_onStarted);
    on<FavouriteToggled>(_onToggled);
    on<_FavouritesSnapshot>(_onSnapshot);
    _authSubscription = _session.changes.listen(
      (_) => add(const FavouritesStarted()),
    );
  }

  final FavouritesRepository _repository;
  final ToggleFavourite _toggle;
  final GetVehicleDetail _detail;
  final AuthSession _session;
  StreamSubscription<Result<List<Favourite>>>? _favouritesSubscription;
  late final StreamSubscription<void> _authSubscription;

  /// Only the newest snapshot may emit, so interleaved hydrations stay ordered.
  int _snapshotGeneration = 0;

  /// Signed-in user the current ids and cars belong to.
  String? _userId;

  Future<void> _onStarted(
    FavouritesStarted event,
    Emitter<FavouritesState> emit,
  ) async {
    await _favouritesSubscription?.cancel();
    _favouritesSubscription = null;
    final userId = _session.currentUserId;
    final sameUser = userId == _userId;
    _userId = userId;
    // Invalidate hydrations still running for the previous user.
    _snapshotGeneration++;
    if (userId == null) {
      emit(const FavouritesLoaded());
      return;
    }
    // After an account switch the previous user's hearts must not show.
    emit(
      sameUser
          ? FavouritesLoading(
              favouriteIds: state.favouriteIds,
              cars: state.cars,
            )
          : const FavouritesLoading(),
    );
    _favouritesSubscription = _repository
        .watch(userId)
        .listen((result) => add(_FavouritesSnapshot(result)));
  }

  Future<void> _onSnapshot(
    _FavouritesSnapshot event,
    Emitter<FavouritesState> emit,
  ) async {
    if (event.result case Failure(:final failure)) {
      emit(
        FavouritesFailure(
          error: failure,
          favouriteIds: state.favouriteIds,
          cars: state.cars,
        ),
      );
      return;
    }
    final generation = ++_snapshotGeneration;
    final favourites = (event.result as Success<List<Favourite>>).value;
    final cards = <VehicleCardData>[];
    final ids = <String>{};
    final results = await Future.wait([
      for (final favourite in favourites) _detail(favourite.vehicleId),
    ]);
    if (isClosed || generation != _snapshotGeneration) return;
    final userId = _userId;
    for (var i = 0; i < favourites.length; i++) {
      final vehicleId = favourites[i].vehicleId;
      switch (results[i]) {
        case Success(value: final detail):
          cards.add(detail.card);
          ids.add(vehicleId);
        // A removed car is dropped from the ids too, so the count matches,
        // and its dangling favourite document is deleted.
        case Failure(failure: NotFoundFailure()):
          if (userId != null) {
            unawaited(
              _toggle(userId: userId, vehicleId: vehicleId, isFavourite: true),
            );
          }
        case Failure():
          ids.add(vehicleId);
      }
    }
    cards.sort((a, b) => a.vehicle.dailyPrice.compareTo(b.vehicle.dailyPrice));
    if (isClosed || generation != _snapshotGeneration) return;
    emit(FavouritesLoaded(favouriteIds: ids, cars: cards));
  }

  Future<void> _onToggled(
    FavouriteToggled event,
    Emitter<FavouritesState> emit,
  ) async {
    final userId = _session.currentUserId;
    if (userId == null) {
      emit(
        FavouritesFailure(
          error: const PermissionFailure('Sign in to save cars.'),
          favouriteIds: state.favouriteIds,
          cars: state.cars,
        ),
      );
      return;
    }
    final originalIds = state.favouriteIds;
    final wasFavourite = originalIds.contains(event.vehicleId);
    final optimistic = {...originalIds};
    if (wasFavourite) {
      optimistic.remove(event.vehicleId);
    } else {
      optimistic.add(event.vehicleId);
    }
    emit(FavouritesLoaded(favouriteIds: optimistic, cars: state.cars));
    final result = await _toggle(
      userId: userId,
      vehicleId: event.vehicleId,
      isFavourite: wasFavourite,
    );
    if (isClosed) return;
    if (result case Failure(:final failure)) {
      emit(
        FavouritesFailure(
          error: failure,
          favouriteIds: originalIds,
          cars: state.cars,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _authSubscription.cancel();
    await _favouritesSubscription?.cancel();
    return super.close();
  }
}
