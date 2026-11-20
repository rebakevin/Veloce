import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/data/services/booking_lookup.dart';
import 'package:veloce/core/data/services/momo_gateway_sim.dart';
import 'package:veloce/core/data/services/preferences_service.dart';
import 'package:veloce/core/data/services/verification_sim.dart';
import 'package:veloce/core/domain/entities/contact.dart';
import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/domain/services/pricing_calculator.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/core/widgets/app_messenger.dart';
import 'package:veloce/features/auth/auth.dart';
import 'package:veloce/features/auth/data/dev_sign_in.dart';
import 'package:veloce/features/discovery/domain/entities/car_detail_args.dart';
import 'package:veloce/features/discovery/domain/repositories/search_repository.dart';
import 'package:veloce/features/discovery/domain/usecases/get_vehicle_detail.dart';
import 'package:veloce/features/discovery/domain/usecases/search_vehicles.dart';
import 'package:veloce/features/discovery/presentation/bloc/booking_requested_cubit.dart';
import 'package:veloce/features/discovery/presentation/bloc/car_detail_bloc.dart';
import 'package:veloce/features/discovery/presentation/bloc/favourites_bloc.dart';
import 'package:veloce/features/discovery/presentation/bloc/owner_cars_cubit.dart';
import 'package:veloce/features/discovery/presentation/bloc/search_cubit.dart';
import 'package:veloce/features/profile/domain/entities/public_profile.dart';
import 'package:veloce/features/profile/presentation/bloc/accounts_bloc.dart';
import 'package:veloce/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:veloce/features/profile/presentation/bloc/public_profile_cubit.dart';
import 'package:veloce/features/profile/presentation/bloc/settings_cubit.dart';
import 'package:veloce/features/vehicles/presentation/bloc/availability_bloc.dart';
import 'package:veloce/features/vehicles/presentation/bloc/car_count_cubit.dart';
import 'package:veloce/features/vehicles/presentation/bloc/car_wizard_bloc.dart';
import 'package:veloce/features/vehicles/presentation/bloc/documents_bloc.dart';
import 'package:veloce/features/vehicles/presentation/bloc/my_cars_bloc.dart';

import '../features/discovery/support/discovery_fakes.dart';
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

class MockFavouritesBloc extends MockBloc<FavouritesEvent, FavouritesState>
    implements FavouritesBloc {}

class _MockPreferences extends Mock implements PreferencesService {}

class _MockDevSignIn extends Mock implements DevSignIn {}

class _MockMomo extends Mock implements MomoGatewaySim {}

class _MockVerification extends Mock implements VerificationSim {}

class _MockBookingLookup extends Mock implements BookingLookup {}

class _FixedClock implements Clock {
  @override
  DateTime now() => testNow;
}

class MockMyCarsBloc extends MockBloc<MyCarsEvent, MyCarsState>
    implements MyCarsBloc {}

class MockCarCountCubit extends MockCubit<CarCountState>
    implements CarCountCubit {}

class MockCarWizardBloc extends MockBloc<CarWizardEvent, CarWizardState>
    implements CarWizardBloc {}

class MockAvailabilityBloc
    extends MockBloc<AvailabilityEvent, AvailabilityState>
    implements AvailabilityBloc {}

class MockDocumentsBloc extends MockBloc<DocumentsEvent, DocumentsState>
    implements DocumentsBloc {}

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
    when(() => preferences.lastSearchArea).thenReturn(null);
    when(() => preferences.lastTypeChip).thenReturn(null);

    final discoveryRepository = FakeSearchRepository(
      searchResult: Result.success([aVehicleCard()]),
      ownerCarsResult: const Result.success([]),
    );
    final bookingLookup = _MockBookingLookup();
    when(() => bookingLookup.byId(any()))
        .thenAnswer((_) async => Result.success(aBooking()));

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
      ..registerSingleton<SearchRepository>(discoveryRepository)
      ..registerLazySingleton<SearchVehicles>(
        () => SearchVehicles(discoveryRepository),
      )
      ..registerLazySingleton<PricingCalculator>(
        () => const PricingCalculator(),
      )
      ..registerLazySingleton<AuthSession>(
        () => FakeAuthSession(userId: 'user-1', role: role),
      )
      ..registerSingleton<BookingLookup>(bookingLookup)
      ..registerLazySingleton<SearchCubit>(
        () => SearchCubit(preferences: preferences),
      )
      ..registerLazySingleton<FavouritesBloc>(
        () => idle<MockFavouritesBloc, FavouritesState>(
          MockFavouritesBloc(),
          const FavouritesLoaded(),
        ),
      )
      ..registerFactoryParam<CarDetailBloc, String, CarDetailArgs?>(
        (vehicleId, args) => CarDetailBloc(
          getDetail: GetVehicleDetail(discoveryRepository),
          session: _getIt<AuthSession>(),
          pricing: _getIt<PricingCalculator>(),
          clock: _getIt<Clock>(),
          vehicleId: vehicleId,
          initialStart: args?.start,
          initialEnd: args?.end,
        ),
      )
      ..registerFactoryParam<OwnerCarsCubit, String, void>(
        (ownerId, _) =>
            OwnerCarsCubit(repository: discoveryRepository, ownerId: ownerId),
      )
      ..registerFactoryParam<BookingRequestedCubit, String, void>(
        (bookingId, _) => BookingRequestedCubit(
          bookings: bookingLookup,
          bookingId: bookingId,
        ),
      )
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
      )
      ..registerFactory<MyCarsBloc>(
        () => idle<MockMyCarsBloc, MyCarsState>(
          MockMyCarsBloc(),
          const MyCarsEmpty(),
        ),
      )
      ..registerFactory<CarCountCubit>(
        () => idle<MockCarCountCubit, CarCountState>(
          MockCarCountCubit(),
          const CarCountLoaded(published: 2, paused: 1),
        ),
      )
      ..registerFactory<AvailabilityBloc>(
        () => idle<MockAvailabilityBloc, AvailabilityState>(
          MockAvailabilityBloc(),
          const AvailabilityFailure('Not loaded in tests.'),
        ),
      )
      ..registerFactory<DocumentsBloc>(
        () => idle<MockDocumentsBloc, DocumentsState>(
          MockDocumentsBloc(),
          const DocumentsFailure('Not loaded in tests.'),
        ),
      )
      ..registerFactory<CarWizardBloc>(
        () => idle<MockCarWizardBloc, CarWizardState>(
          MockCarWizardBloc(),
          const CarWizardState(),
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
