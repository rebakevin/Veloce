import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/domain/services/media_storage.dart';
import 'package:veloce/features/handover/data/firestore_handover_repository.dart';
import 'package:veloce/features/handover/data/firestore_repair_expense_repository.dart';
import 'package:veloce/features/handover/domain/repositories/handover_repository.dart';
import 'package:veloce/features/handover/domain/repositories/repair_expense_repository.dart';

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

  getIt.registerLazySingleton<RepairExpenseRepository>(
    () => FirestoreRepairExpenseRepository(
      firestore: getIt<FirebaseFirestore>(),
      mediaStorage: getIt<MediaStorage>(),
      clock: getIt<Clock>(),
    ),
  );
}
