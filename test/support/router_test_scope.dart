import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/data/services/momo_gateway_sim.dart';
import 'package:veloce/core/data/services/preferences_service.dart';
import 'package:veloce/core/data/services/verification_sim.dart';
import 'package:veloce/core/domain/entities/contact.dart';
import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/core/widgets/app_messenger.dart';
import 'package:veloce/features/auth/auth.dart';
import 'package:veloce/features/auth/data/dev_sign_in.dart';
import 'package:veloce/features/profile/domain/entities/public_profile.dart';
import 'package:veloce/features/profile/presentation/bloc/accounts_bloc.dart';
import 'package:veloce/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:veloce/features/profile/presentation/bloc/public_profile_cubit.dart';
import 'package:veloce/features/profile/presentation/bloc/settings_cubit.dart';

import 'builders.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockLoginBloc extends MockBloc<LoginEvent, LoginState>
    implements LoginBloc {}

class MockRegisterBloc extends MockBloc<RegisterEvent, RegisterState>
    implements RegisterBloc {}

class MockForgotPasswordCubit extends MockCubit<ForgotPasswordState>
    implements ForgotPasswordCubit {}

class MockVerifyEmailCubit extends MockCubit<VerifyEmailState>
    implements VerifyEmailCubit {}

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class MockPublicProfileCubit extends MockCubit<PublicProfileState>
    implements PublicProfileCubit {
  /// The page calls `load()` on open; the state is already loaded.
  void stubLoad() => when(load).thenAnswer((_) async {});
}

class MockAccountsBloc extends MockBloc<AccountsEvent, AccountsState>
    implements AccountsBloc {}

class MockSettingsCubit extends MockCubit<SettingsState>
    implements SettingsCubit {}

class _MockPreferences extends Mock implements PreferencesService {}

class _MockDevSignIn extends Mock implements DevSignIn {}

class _MockMomo extends Mock implements MomoGatewaySim {}

class _MockVerification extends Mock implements VerificationSim {}

class _FixedClock implements Clock {
  @override
  DateTime now() => testNow;
}

/// The register flow bounces to the page of the bloc's step, so a deep link
/// only stays put when the bloc is at that step.
RegisterStep _registerStepFor(String path) => switch (path) {
  RouteNames.registerDetails => RegisterStep.details,
  RouteNames.registerVerify => RegisterStep.otp,
  RouteNames.registerWelcome => RegisterStep.done,
  _ => RegisterStep.role,
};

/// Everything the Phase 1 pages resolve from GetIt or read from context, held
/// in a loaded, idle state so any route can open without Firebase.
class RouterTestScope {
  RouterTestScope._(this.authBloc);

  final AuthBloc authBloc;
  final messenger = AppMessenger();
  final _getIt = GetIt.instance;

  /// Signed-out when [role] is null.
  static Future<RouterTestScope> create({
    required UserRole? role,
    required String path,
  }) async {
    final authBloc = MockAuthBloc();
    final account = role == null ? null : aUser(role: role);
    final AuthState state = account == null
        ? (path == RouteNames.splash
              ? const AuthUnknown()
              : const AuthUnauthenticated())
        : AuthAuthenticated(
            user: const AuthUser(
              uid: 'user-1',
              email: 'aline@example.com',
              emailVerified: true,
              displayName: 'Aline Uwase',
              provider: AuthProviderKind.password,
            ),
            account: account,
          );
    whenListen(authBloc, const Stream<AuthState>.empty(), initialState: state);

    final scope = RouterTestScope._(authBloc);
    await GetIt.instance.reset();
    scope._register(account?.role ?? UserRole.renter, path);
    return scope;
  }

  void _register(UserRole role, String path) {
    final preferences = _MockPreferences();
    when(() => preferences.onboardingSeen).thenReturn(true);
    when(() => preferences.notificationsEnabled).thenReturn(true);
    when(() => preferences.themeMode).thenReturn(ThemeMode.system);

    T idle<T extends BlocBase<S>, S>(T bloc, S state) {
      whenListen(bloc, const Stream<Never>.empty(), initialState: state);
      return bloc;
    }

    final ProfileState profile = ProfileLoaded(
      account: aUser(role: role),
      contact: Contact(
        userId: 'user-1',
        email: 'aline@example.com',
        phone: '+250788000000',
        dateOfBirth: DateTime(1995),
        authProvider: AuthProviderKind.password,
      ),
    );

    _getIt
      ..registerSingleton<AppMessenger>(messenger)
      ..registerSingleton<Clock>(_FixedClock())
      ..registerSingleton<PreferencesService>(preferences)
      ..registerSingleton<DevSignIn>(_MockDevSignIn())
      ..registerSingleton<MomoGatewaySim>(_MockMomo())
      ..registerSingleton<VerificationSim>(_MockVerification())
      ..registerFactory<LoginBloc>(
        () => idle(MockLoginBloc(), const LoginState()),
      )
      ..registerFactoryParam<RegisterBloc, AuthUser?, void>(
        (_, _) => idle(
          MockRegisterBloc(),
          RegisterState(step: _registerStepFor(path)),
        ),
      )
      ..registerFactory<ForgotPasswordCubit>(
        () => idle(MockForgotPasswordCubit(), const ForgotPasswordState()),
      )
      ..registerFactory<VerifyEmailCubit>(
        () => idle(MockVerifyEmailCubit(), const VerifyEmailState()),
      )
      ..registerFactory<ProfileBloc>(() => idle(MockProfileBloc(), profile))
      ..registerFactoryParam<PublicProfileCubit, String, void>(
        (id, _) => idle<MockPublicProfileCubit, PublicProfileState>(
          MockPublicProfileCubit()..stubLoad(),
          PublicProfileLoaded(
            PublicProfile(
              userId: id,
              name: 'Aline Uwase',
              photoUrl: null,
              ratingAvg: 4.5,
              ratingCount: 2,
              completedCount: 1,
            ),
          ),
        ),
      )
      ..registerFactory<AccountsBloc>(
        () => idle<MockAccountsBloc, AccountsState>(
          MockAccountsBloc(),
          const AccountsLoaded(accounts: [], currentUid: 'user-1'),
        ),
      )
      ..registerFactory<SettingsCubit>(
        () => idle(
          MockSettingsCubit(),
          const SettingsState(
            themeMode: ThemeMode.system,
            notificationsEnabled: true,
          ),
        ),
      );
  }

  /// The app shell the real [VeloceApp] builds, minus Firebase.
  Widget wrap(RouterConfig<Object> config) => BlocProvider<AuthBloc>.value(
    value: authBloc,
    child: MaterialApp.router(
      theme: AppTheme.light,
      scaffoldMessengerKey: messenger.key,
      routerConfig: config,
    ),
  );

  Future<void> dispose() => _getIt.reset();
}
