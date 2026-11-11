import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

import 'data/firestore_profile_repository.dart';
import 'domain/repositories/profile_repository.dart';
import 'presentation/bloc/accounts_bloc.dart';
import 'presentation/bloc/profile_bloc.dart';
import 'presentation/bloc/public_profile_cubit.dart';
import 'presentation/bloc/settings_cubit.dart';

/// Registers the profile feature's dependencies. Owned by Phase 1.
void registerProfile(GetIt getIt) {
  getIt
    ..registerLazySingleton<ProfileRepository>(
      () => FirestoreProfileRepository(
        firestore: getIt<FirebaseFirestore>(),
        writes: getIt(),
        users: getIt(),
        storage: getIt(),
        verification: getIt(),
        session: getIt(),
        clock: getIt(),
      ),
    )
    ..registerFactory<ProfileBloc>(
      () => ProfileBloc(repository: getIt(), clock: getIt()),
    )
    ..registerFactoryParam<PublicProfileCubit, String, void>(
      (userId, _) => PublicProfileCubit(repository: getIt(), userId: userId),
    )
    ..registerFactory<AccountsBloc>(
      () => AccountsBloc(
        listAccounts: getIt(),
        linkCurrent: getIt(),
        switchAccount: getIt(),
        removeAccount: getIt(),
        session: getIt(),
      ),
    )
    ..registerFactory<SettingsCubit>(
      () => SettingsCubit(preferences: getIt(), themeCubit: getIt()),
    );
}
