import 'package:get_it/get_it.dart';
import 'package:veloce/features/handover/data/firestore_handover_repository.dart';
import 'package:veloce/features/handover/domain/repositories/handover_repository.dart';

void registerHandover(GetIt getIt) {
  getIt.registerLazySingleton<HandoverRepository>(
    () => FirestoreHandoverRepository(
      firestore: getIt(),
      writes: getIt(),
      session: getIt(),
      clock: getIt(),
      stateMachine: getIt(),
      ledger: getIt(),
      audit: getIt(),
      notifications: getIt(),
    ),
  );
}
