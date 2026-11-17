import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/data/services/booking_lookup.dart';
import 'package:veloce/core/data/services/firebase_auth_session.dart';
import 'package:veloce/core/data/services/user_lookup.dart';
import 'package:veloce/core/data/services/vehicle_lookup.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/domain/services/verification_provider.dart';

import 'data/dev_sign_in.dart';
import 'data/firebase_auth_data_source.dart';
import 'data/firebase_auth_repository.dart';
import 'data/firestore_registration_store.dart';
import 'data/secure_linked_account_store.dart';
import 'domain/email_verification_gate.dart';
import 'domain/entities/auth_user.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/linked_account_store.dart';
import 'domain/repositories/registration_store.dart';
import 'domain/usecases/complete_google_registration.dart';
import 'domain/usecases/link_current_account.dart';
import 'domain/usecases/list_linked_accounts.dart';
import 'domain/usecases/login_with_email.dart';
import 'domain/usecases/observe_auth_state.dart';
import 'domain/usecases/register_with_email.dart';
import 'domain/usecases/reload_auth_user.dart';
import 'domain/usecases/remove_linked_account.dart';
import 'domain/usecases/send_email_verification.dart';
import 'domain/usecases/send_password_reset.dart';
import 'domain/usecases/sign_in_with_google.dart';
import 'domain/usecases/sign_out.dart';
import 'domain/usecases/submit_identity_document.dart';
import 'domain/usecases/switch_account.dart';
import 'presentation/bloc/auth_bloc.dart';
import 'presentation/bloc/forgot_password_cubit.dart';
import 'presentation/bloc/login_bloc.dart';
import 'presentation/bloc/register_bloc.dart';
import 'presentation/bloc/verify_email_cubit.dart';

/// Registers the auth feature's dependencies. Owned by Phase 1.
void registerAuth(GetIt getIt) {
  getIt
    ..registerLazySingleton<DevSignIn>(() => DevSignIn(getIt<FirebaseAuth>()))
    ..registerLazySingleton<FirebaseAuthDataSource>(
      () => FirebaseAuthDataSource(auth: getIt<FirebaseAuth>()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => FirebaseAuthRepository(getIt()),
    )
    ..registerLazySingleton<RegistrationStore>(
      () => FirestoreRegistrationStore(
        writes: getIt(),
        audit: getIt(),
        users: getIt(),
        session: getIt<FirebaseAuthSession>(),
        clock: getIt(),
      ),
    )
    ..registerLazySingleton<LinkedAccountStore>(
      () => const SecureLinkedAccountStore(FlutterSecureStorage()),
    )
    ..registerLazySingleton<SubmitIdentityDocument>(
      () => SubmitIdentityDocument(storage: getIt(), verification: getIt()),
    )
    ..registerLazySingleton<RegisterWithEmail>(
      () => RegisterWithEmail(
        auth: getIt(),
        store: getIt(),
        submitDocument: getIt(),
        clock: getIt(),
      ),
    )
    ..registerLazySingleton<CompleteGoogleRegistration>(
      () => CompleteGoogleRegistration(
        auth: getIt(),
        store: getIt(),
        submitDocument: getIt(),
        clock: getIt(),
      ),
    )
    ..registerLazySingleton<LoginWithEmail>(() => LoginWithEmail(getIt()))
    ..registerLazySingleton<SignInWithGoogle>(
      () => SignInWithGoogle(auth: getIt(), store: getIt()),
    )
    ..registerLazySingleton<SendPasswordReset>(() => SendPasswordReset(getIt()))
    ..registerLazySingleton<SendEmailVerification>(
      () => SendEmailVerification(getIt()),
    )
    ..registerLazySingleton<ReloadAuthUser>(() => ReloadAuthUser(getIt()))
    ..registerLazySingleton<SignOut>(() => SignOut(getIt()))
    ..registerLazySingleton<ObserveAuthState>(() => ObserveAuthState(getIt()))
    ..registerLazySingleton<ListLinkedAccounts>(
      () => ListLinkedAccounts(getIt()),
    )
    ..registerLazySingleton<LinkCurrentAccount>(
      () =>
          LinkCurrentAccount(auth: getIt(), profiles: getIt(), store: getIt()),
    )
    ..registerLazySingleton<SwitchAccount>(
      () => SwitchAccount(auth: getIt(), store: getIt()),
    )
    ..registerLazySingleton<RemoveLinkedAccount>(
      () => RemoveLinkedAccount(getIt()),
    )
    ..registerLazySingleton<EmailVerificationGate>(
      () => EmailVerificationGate(getIt<AuthSession>()),
    )
    ..registerLazySingleton<AuthBloc>(
      () => AuthBloc(
        observe: getIt(),
        profiles: getIt(),
        signOut: getIt(),
        reloadUser: getIt(),
        clearCaches: () {
          getIt<UserLookup>().clear();
          getIt<VehicleLookup>().clear();
          getIt<BookingLookup>().clear();
        },
      ),
    )
    ..registerFactory<LoginBloc>(
      () => LoginBloc(
        loginWithEmail: getIt(),
        signInWithGoogle: getIt(),
        linkCurrentAccount: getIt(),
      ),
    )
    ..registerFactoryParam<RegisterBloc, AuthUser?, void>(
      (googleUser, _) => RegisterBloc(
        registerWithEmail: getIt(),
        completeGoogle: getIt(),
        linkCurrentAccount: getIt(),
        verification: getIt<VerificationProvider>(),
        clock: getIt<Clock>(),
        googleUser: googleUser,
      ),
    )
    ..registerFactory<ForgotPasswordCubit>(() => ForgotPasswordCubit(getIt()))
    ..registerFactory<VerifyEmailCubit>(
      () => VerifyEmailCubit(sendVerification: getIt(), reloadUser: getIt()),
    );
}
