import 'package:get_it/get_it.dart';

import 'data/firestore_vehicle_repository.dart';
import 'domain/repositories/vehicle_repository.dart';
import 'domain/usecases/remove_vehicle.dart';
import 'domain/usecases/set_status.dart';

void registerVehicles(GetIt getIt) {
  getIt
    ..registerLazySingleton<VehicleRepository>(
      () => FirestoreVehicleRepository(firestore: getIt(), writes: getIt()),
    )
    ..registerFactory<SetStatus>(() => SetStatus(getIt(), getIt()))
    ..registerFactory<RemoveVehicle>(() => RemoveVehicle(getIt(), getIt()));
}
