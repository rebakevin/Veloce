import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/auth/domain/entities/auth_user.dart';
import 'package:veloce/features/auth/domain/repositories/registration_store.dart';
import 'package:veloce/features/auth/domain/usecases/observe_auth_state.dart';
import 'package:veloce/features/auth/domain/usecases/reload_auth_user.dart';
import 'package:veloce/features/auth/domain/usecases/sign_out.dart';
import 'package:veloce/features/auth/presentation/bloc/auth_bloc.dart';

import '../../../../support/builders.dart';
import '../../domain/auth_fakes.dart';

class _MockObserve extends Mock implements ObserveAuthState {}

class _MockStore extends Mock implements RegistrationStore {}

class _MockSignOut extends Mock implements SignOut {}

class _MockReload extends Mock implements ReloadAuthUser {}

void main() {
  late StreamController<AuthUser?> users;
  late _MockObserve observe;
  late _MockStore store;
  late _MockSignOut signOut;
  late _MockReload reload;
  late int cacheClears;

  setUp(() {
    users = StreamController<AuthUser?>();
    observe = _MockObserve();
    store = _MockStore();
    signOut = _MockSignOut();
    reload = _MockReload();
    cacheClears = 0;
    when(() => observe()).thenAnswer((_) => users.stream);
  });

  tearDown(() => users.close());

  AuthBloc build() => AuthBloc(
    observe: observe,
    profiles: store,
    signOut: signOut,
    reloadUser: reload,
    clearCaches: () => cacheClears++,
  );

  final user = anAuthUser();
  final account = aUser(role: UserRole.owner);

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'restores an existing session with its profile and role',
      setUp: () =>
          when(() => store.findProfile(user.uid))
              .thenAnswer((_) async => Result.success(account)),
      build: build,
      act: (bloc) {
        bloc.add(const AuthStarted());
        users.add(user);
      },
      expect: () => [AuthAuthenticated(user: user, account: account)],
      verify: (bloc) {
        final state = bloc.state as AuthAuthenticated;
        expect(state.role, UserRole.owner);
        expect(state.isEmailVerified, isFalse);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'reports unauthenticated when there is no session',
      build: build,
      act: (bloc) {
        bloc.add(const AuthStarted());
        users.add(null);
      },
      expect: () => [const AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'a Google user without a profile needs role choice',
      setUp: () =>
          when(() => store.findProfile(any()))
              .thenAnswer((_) async => const Result.success(null)),
      build: build,
      act: (bloc) {
        bloc.add(const AuthStarted());
        users.add(anAuthUser(provider: AuthProviderKind.google));
      },
      expect: () => [
        AuthNeedsProfile(anAuthUser(provider: AuthProviderKind.google)),
      ],
      verify: (bloc) =>
          expect((bloc.state as AuthNeedsProfile).needsRoleChoice, isTrue),
    );

    blocTest<AuthBloc, AuthState>(
      'refreshing the profile after registration authenticates the user',
      setUp: () {
        var calls = 0;
        when(() => store.findProfile(user.uid)).thenAnswer(
          (_) async => Result.success(++calls == 1 ? null : account),
        );
      },
      build: build,
      act: (bloc) async {
        bloc.add(const AuthStarted());
        users.add(user);
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AuthProfileRefreshed());
      },
      expect: () => [
        AuthNeedsProfile(user),
        AuthAuthenticated(user: user, account: account),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'a profile read failure is reported so the screen can retry',
      setUp: () =>
          when(() => store.findProfile(any()))
              .thenAnswer((_) async => const Result.failure(NetworkFailure())),
      build: build,
      act: (bloc) {
        bloc.add(const AuthStarted());
        users.add(user);
      },
      expect: () => [AuthProfileFailed(user, const NetworkFailure().message)],
    );

    blocTest<AuthBloc, AuthState>(
      'sign out clears caches and becomes unauthenticated',
      setUp: () {
        when(() => store.findProfile(any()))
            .thenAnswer((_) async => Result.success(account));
        when(() => signOut())
            .thenAnswer((_) async => const Result.success(null));
      },
      build: build,
      act: (bloc) async {
        bloc.add(const AuthStarted());
        users.add(user);
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SignOutRequested());
      },
      expect: () => [
        AuthAuthenticated(user: user, account: account),
        const AuthUnauthenticated(),
      ],
      verify: (_) {
        expect(cacheClears, 1);
        verify(() => signOut()).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'a failed sign out keeps the session',
      setUp: () {
        when(() => store.findProfile(any()))
            .thenAnswer((_) async => Result.success(account));
        when(() => signOut())
            .thenAnswer((_) async => const Result.failure(NetworkFailure()));
      },
      build: build,
      act: (bloc) async {
        bloc.add(const AuthStarted());
        users.add(user);
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SignOutRequested());
      },
      expect: () => [AuthAuthenticated(user: user, account: account)],
      verify: (_) => expect(cacheClears, 0),
    );

    blocTest<AuthBloc, AuthState>(
      'verifying the email updates the user without reading the profile again',
      setUp: () {
        when(() => store.findProfile(any()))
            .thenAnswer((_) async => Result.success(account));
        when(() => reload()).thenAnswer(
          (_) async => Result.success(
            AuthUser(
              uid: user.uid,
              email: user.email,
              emailVerified: true,
              displayName: user.displayName,
              provider: user.provider,
            ),
          ),
        );
      },
      build: build,
      act: (bloc) async {
        bloc.add(const AuthStarted());
        users.add(user);
        await Future<void>.delayed(Duration.zero);
        bloc.add(const EmailVerificationRefreshed());
      },
      skip: 1,
      verify: (bloc) {
        expect(bloc.state.isEmailVerified, isTrue);
        verify(() => store.findProfile(any())).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'closing cancels the auth subscription',
      build: build,
      act: (bloc) async {
        bloc.add(const AuthStarted());
        await Future<void>.delayed(Duration.zero);
        await bloc.close();
      },
      verify: (_) => expect(users.hasListener, isFalse),
    );
  });
}
