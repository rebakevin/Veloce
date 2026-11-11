import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/domain/entities/contact.dart';
import 'package:veloce/core/domain/entities/user_account.dart';
import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/core/widgets/app_messenger.dart';
import 'package:veloce/features/profile/presentation/bloc/profile_bloc.dart';

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

/// Registers an [AppMessenger] (pages show snackbars through it).
AppMessenger registerMessenger() {
  final getIt = GetIt.instance;
  if (getIt.isRegistered<AppMessenger>()) getIt.unregister<AppMessenger>();
  final messenger = AppMessenger();
  getIt.registerSingleton<AppMessenger>(messenger);
  return messenger;
}

Future<void> resetGetIt() => GetIt.instance.reset();

final _account = UserAccount(
  id: 'u1',
  role: UserRole.renter,
  name: 'Aline Uwase',
  photoUrl: null,
  verified: true,
  ratingAvg: 4.5,
  ratingCount: 3,
  completedCount: 2,
  createdAt: DateTime(2025),
);

ProfileLoaded loadedProfile({
  UserRole role = UserRole.renter,
  ProfileAction action = ProfileAction.idle,
}) {
  return ProfileLoaded(
    account: _account.copyWith(role: role),
    contact: Contact(
      userId: 'u1',
      email: 'aline@example.com',
      phone: '0788123456',
      dateOfBirth: DateTime(1995, 5, 20),
      authProvider: AuthProviderKind.password,
    ),
    action: action,
  );
}

/// Router with [home] at `/home`, a `/start` page below it, and a stub page
/// for every route in [stubs] so pushes and `go` calls have somewhere to land.
GoRouter testRouter({
  required Widget home,
  String initial = '/home',
  List<String> stubs = const [],
}) {
  return GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/start', builder: (_, _) => const Text('start page')),
      GoRoute(path: '/home', builder: (_, _) => home),
      for (final stub in stubs)
        GoRoute(path: stub, builder: (_, _) => Text('stub $stub')),
    ],
  );
}

Widget routerApp(
  GoRouter router,
  AppMessenger messenger, {
  List<BlocProvider<dynamic>> providers = const [],
}) {
  final app = MaterialApp.router(
    routerConfig: router,
    theme: AppTheme.light,
    scaffoldMessengerKey: messenger.key,
  );
  return providers.isEmpty
      ? app
      : MultiBlocProvider(providers: providers, child: app);
}
