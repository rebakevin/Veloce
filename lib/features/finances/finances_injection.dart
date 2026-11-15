import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/data/services/booking_lookup.dart';
import 'package:veloce/core/data/services/vehicle_lookup.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/domain/services/clock.dart';

import 'data/repositories/firestore_finances_repository.dart';
import 'domain/repositories/finances_repository.dart';
import 'presentation/bloc/finances_bloc.dart';
import 'presentation/bloc/renter_payments_cubit.dart';

/// Registers the finances feature's dependencies. Owned by Phase 6.
void registerFinances(GetIt getIt) {
  getIt
    ..registerLazySingleton<FinancesRepository>(
      () => FirestoreFinancesRepository(
        firestore: getIt<FirebaseFirestore>(),
        vehicleLookup: getIt<VehicleLookup>(),
        bookingLookup: getIt<BookingLookup>(),
        clock: getIt<Clock>(),
      ),
    )
    ..registerFactory<FinancesBloc>(
      () => FinancesBloc(
        repository: getIt<FinancesRepository>(),
        session: getIt<AuthSession>(),
        vehicleLookup: getIt<VehicleLookup>(),
      ),
    )
    ..registerFactory<RenterPaymentsCubit>(
      () => RenterPaymentsCubit(
        repository: getIt<FinancesRepository>(),
        session: getIt<AuthSession>(),
      ),
    );
}
