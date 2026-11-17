import 'package:get_it/get_it.dart';

import 'data/firestore_vehicle_repository.dart';
import 'domain/repositories/vehicle_repository.dart';
import 'domain/usecases/remove_vehicle.dart';
import 'domain/usecases/set_status.dart';
import 'domain/usecases/watch_owner_vehicles.dart';
import 'presentation/bloc/car_count_cubit.dart';
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
    ..registerFactory<MyCarsBloc>(
      () => MyCarsBloc(
        watchVehicles: getIt(),
        setStatus: getIt(),
        removeVehicle: getIt(),
      ),
    )
    ..registerFactory<CarCountCubit>(
      () => CarCountCubit(watchVehicles: getIt()),
    );
}