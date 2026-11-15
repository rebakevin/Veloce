import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/data/services/preferences_service.dart';
import 'package:veloce/core/domain/services/atomic_write.dart';
import 'package:veloce/core/domain/services/auth_session.dart';

import 'data/repositories/firestore_notifications_repository.dart';
import 'domain/repositories/notifications_repository.dart';
import 'presentation/bloc/notifications_bloc.dart';

/// Registers the notifications feature's dependencies. Owned by Phase 6.
void registerNotifications(GetIt getIt) {
  getIt
    ..registerLazySingleton<NotificationsRepository>(
      () => FirestoreNotificationsRepository(
        firestore: getIt<FirebaseFirestore>(),
        writes: getIt<AtomicWriteFactory>(),
      ),
    )
    ..registerLazySingleton<NotificationsBloc>(
      () => NotificationsBloc(
        repository: getIt<NotificationsRepository>(),
        session: getIt<AuthSession>(),
        preferences: getIt<PreferencesService>(),
      ),
    );
}
