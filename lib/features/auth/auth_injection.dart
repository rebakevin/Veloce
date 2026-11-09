import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import 'data/dev_sign_in.dart';

/// Registers the auth feature's dependencies. Owned by Phase 1.
void registerAuth(GetIt getIt) {
  getIt.registerLazySingleton<DevSignIn>(
    () => DevSignIn(getIt<FirebaseAuth>()),
  );
}
