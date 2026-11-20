import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

import 'package:veloce/core/data/services/booking_lookup.dart';
import 'package:veloce/core/domain/services/clock.dart';

import 'data/firestore_favourites_repository.dart';
import 'data/firestore_request_repository.dart';
import 'data/firestore_search_repository.dart';
import 'domain/entities/booking_request_draft.dart';
import 'domain/entities/car_detail_args.dart';
import 'domain/repositories/favourites_repository.dart';
import 'domain/repositories/request_repository.dart';
import 'domain/repositories/search_repository.dart';
import 'domain/usecases/create_booking_request.dart';
import 'domain/usecases/get_vehicle_detail.dart';
import 'domain/usecases/search_vehicles.dart';
import 'domain/usecases/toggle_favourite.dart';
import 'presentation/bloc/booking_requested_cubit.dart';
import 'presentation/bloc/car_detail_bloc.dart';
import 'presentation/bloc/favourites_bloc.dart';
import 'presentation/bloc/owner_cars_cubit.dart';
import 'presentation/bloc/request_bloc.dart';
import 'presentation/bloc/search_cubit.dart';

/// Registers the discovery feature's dependencies. Owned by Phase 3.
void registerDiscovery(GetIt getIt) {
  getIt
    ..registerLazySingleton<SearchRepository>(
      () => FirestoreSearchRepository(
        firestore: getIt<FirebaseFirestore>(),
        session: getIt(),
        clock: getIt(),
      ),
    )
    ..registerLazySingleton<FavouritesRepository>(
      () => FirestoreFavouritesRepository(
        firestore: getIt<FirebaseFirestore>(),
        clock: getIt(),
      ),
    )
    ..registerLazySingleton<RequestRepository>(
      () => FirestoreRequestRepository(
        firestore: getIt<FirebaseFirestore>(),
        writes: getIt(),
        audit: getIt(),
        notifications: getIt(),
        clock: getIt(),
      ),
    )
    ..registerLazySingleton<SearchVehicles>(() => SearchVehicles(getIt()))
    ..registerLazySingleton<GetVehicleDetail>(() => GetVehicleDetail(getIt()))
    ..registerLazySingleton<ToggleFavourite>(() => ToggleFavourite(getIt()))
    ..registerLazySingleton<CreateBookingRequest>(
      () => CreateBookingRequest(
        search: getIt(),
        requests: getIt(),
        pendingReviews: getIt(),
        emailGate: getIt(),
        pricing: getIt(),
        clock: getIt(),
      ),
    )
    ..registerLazySingleton<SearchCubit>(
      () => SearchCubit(preferences: getIt()),
    )
    ..registerLazySingleton<FavouritesBloc>(
      () => FavouritesBloc(
        repository: getIt(),
        toggle: getIt(),
        detail: getIt(),
        session: getIt(),
      )..add(const FavouritesStarted()),
    )
    ..registerFactoryParam<CarDetailBloc, String, CarDetailArgs?>(
      (vehicleId, args) => CarDetailBloc(
        getDetail: getIt(),
        session: getIt(),
        pricing: getIt(),
        clock: getIt<Clock>(),
        vehicleId: vehicleId,
        initialStart: args?.start,
        initialEnd: args?.end,
      ),
    )
    ..registerFactoryParam<RequestBloc, BookingRequestDraft, void>(
      (draft, _) =>
          RequestBloc(createRequest: getIt(), session: getIt(), draft: draft),
    )
    ..registerFactoryParam<OwnerCarsCubit, String, void>(
      (ownerId, _) => OwnerCarsCubit(repository: getIt(), ownerId: ownerId),
    )
    ..registerFactoryParam<BookingRequestedCubit, String, void>(
      (bookingId, _) => BookingRequestedCubit(
        bookings: getIt<BookingLookup>(),
        bookingId: bookingId,
      ),
    );
}
