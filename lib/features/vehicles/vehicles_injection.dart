import 'package:get_it/get_it.dart';

import 'data/firestore_vehicle_repository.dart';
import 'domain/repositories/vehicle_repository.dart';
import 'domain/usecases/find_next_rentals.dart';
import 'domain/usecases/load_vehicle_draft.dart';
import 'domain/usecases/publish_vehicle.dart';
import 'domain/usecases/recompute_docs_valid_until.dart';
import 'domain/usecases/remove_vehicle.dart';
import 'domain/usecases/set_availability.dart';
import 'domain/usecases/set_status.dart';
import 'domain/usecases/update_vehicle.dart';
import 'domain/usecases/upsert_document.dart';
import 'domain/usecases/verify_document.dart';
import 'domain/usecases/watch_availability.dart';
import 'domain/usecases/watch_owner_vehicles.dart';
import 'presentation/bloc/availability_bloc.dart';
import 'presentation/bloc/car_count_cubit.dart';
import 'presentation/bloc/car_wizard_bloc.dart';
import 'presentation/bloc/documents_bloc.dart';
import 'presentation/bloc/my_cars_bloc.dart';

void registerVehicles(GetIt getIt) {
  getIt
    ..registerLazySingleton<VehicleRepository>(
      () => FirestoreVehicleRepository(firestore: getIt(), writes: getIt()),
    )
    ..registerFactory<SetStatus>(() => SetStatus(getIt(), getIt()))
    ..registerFactory<RemoveVehicle>(() => RemoveVehicle(getIt(), getIt()))
    ..registerFactory<WatchOwnerVehicles>(
      () => WatchOwnerVehicles(getIt(), getIt()),
    )
    ..registerFactory<FindNextRentals>(() => FindNextRentals(getIt(), getIt()))
    ..registerFactory<MyCarsBloc>(
      () => MyCarsBloc(
        watchVehicles: getIt(),
        setStatus: getIt(),
        removeVehicle: getIt(),
        findNextRentals: getIt(),
      ),
    )
    ..registerFactory<CarCountCubit>(
      () => CarCountCubit(watchVehicles: getIt()),
    )
    ..registerFactory<VerifyDocument>(() => VerifyDocument(getIt()))
    ..registerFactory<PublishVehicle>(
      () => PublishVehicle(getIt(), getIt(), getIt(), getIt()),
    )
    ..registerFactory<SetAvailability>(() => SetAvailability(getIt(), getIt()))
    ..registerFactory<WatchAvailability>(
      () => WatchAvailability(getIt(), getIt()),
    )
    ..registerFactory<AvailabilityBloc>(
      () => AvailabilityBloc(
        watchAvailability: getIt(),
        setAvailability: getIt(),
      ),
    )
    ..registerFactory<UpdateVehicle>(
      () => UpdateVehicle(getIt(), getIt(), getIt()),
    )
    ..registerFactory<LoadVehicleDraft>(
      () => LoadVehicleDraft(getIt(), getIt()),
    )
    ..registerFactory<RecomputeDocsValidUntil>(
      () => const RecomputeDocsValidUntil(),
    )
    ..registerFactory<UpsertDocument>(
      () => UpsertDocument(getIt(), getIt(), getIt(), getIt(), getIt()),
    )
    ..registerFactory<DocumentsBloc>(
      () => DocumentsBloc(
        vehicles: getIt(),
        upsertDocument: getIt(),
        setStatus: getIt(),
        clock: getIt(),
      ),
    )
    ..registerFactory<CarWizardBloc>(
      () => CarWizardBloc(
        verifyDocument: getIt(),
        publishVehicle: getIt(),
        updateVehicle: getIt(),
        loadVehicleDraft: getIt(),
      ),
    );
}
