import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/auth/domain/entities/auth_user.dart';
import 'package:veloce/features/auth/domain/entities/google_sign_in_outcome.dart';
import 'package:veloce/features/auth/domain/usecases/login_with_email.dart';
import 'package:veloce/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:veloce/features/auth/presentation/bloc/login_bloc.dart';

import '../../../../support/builders.dart';
import '../../domain/auth_fakes.dart';

class _MockLogin extends Mock implements LoginWithEmail {}

class _MockGoogle extends Mock implements SignInWithGoogle {}

void main() {
  late _MockLogin login;
  late _MockGoogle google;
  late MockLinkCurrentAccount link;

  setUp(() {
    login = _MockLogin();
    google = _MockGoogle();
    link = MockLinkCurrentAccount();
    stubLinkSucceeds(link);
  });

  LoginBloc build() => LoginBloc(
    loginWithEmail: login,
    signInWithGoogle: google,
    linkCurrentAccount: link,
  );

  group('LoginBloc email', () {
    blocTest<LoginBloc, LoginState>(
      'valid credentials submit and succeed',
      setUp: () =>
          when(() => login(email: 'a@b.rw', password: 'secret123'))
              .thenAnswer((_) async => Result.success(anAuthUser())),
      build: build,
      act: (bloc) => bloc.add(
        const LoginSubmitted(email: 'a@b.rw', password: 'secret123'),
      ),
      expect: () => [
        const LoginState(
          status: LoginStatus.submitting,
          method: LoginMethod.email,
        ),
        const LoginState(status: LoginStatus.success),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'a successful login links the account with the typed password',
      setUp: () =>
          when(() => login(email: 'a@b.rw', password: 'secret123'))
              .thenAnswer((_) async => Result.success(anAuthUser())),
      build: build,
      act: (bloc) => bloc.add(
        const LoginSubmitted(email: 'a@b.rw', password: 'secret123'),
      ),
      verify: (_) => verify(() => link(password: 'secret123')).called(1),
    );

    blocTest<LoginBloc, LoginState>(
      'a login that cannot link the account still succeeds',
      setUp: () {
        when(() => login(email: 'a@b.rw', password: 'secret123'))
            .thenAnswer((_) async => Result.success(anAuthUser()));
        when(() => link(password: any(named: 'password')))
            .thenAnswer((_) async => const Result.failure(NetworkFailure()));
      },
      build: build,
      act: (bloc) => bloc.add(
        const LoginSubmitted(email: 'a@b.rw', password: 'secret123'),
      ),
      expect: () => [
        const LoginState(
          status: LoginStatus.submitting,
          method: LoginMethod.email,
        ),
        const LoginState(status: LoginStatus.success),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'a failed login links nothing',
      setUp: () =>
          when(
            () => login(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenAnswer(
            (_) async => const Result.failure(
              ValidationFailure('Wrong email or password.'),
            ),
          ),
      build: build,
      act: (bloc) =>
          bloc.add(const LoginSubmitted(email: 'a@b.rw', password: 'nope')),
      verify: (_) => verifyNoLink(link),
    );

    blocTest<LoginBloc, LoginState>(
      'wrong password shows the failure message',
      setUp: () =>
          when(
            () => login(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenAnswer(
            (_) async => const Result.failure(
              ValidationFailure('Wrong email or password.'),
            ),
          ),
      build: build,
      act: (bloc) =>
          bloc.add(const LoginSubmitted(email: 'a@b.rw', password: 'nope')),
      expect: () => [
        const LoginState(
          status: LoginStatus.submitting,
          method: LoginMethod.email,
        ),
        const LoginState(
          status: LoginStatus.failure,
          message: 'Wrong email or password.',
        ),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'blank fields show inline errors and send nothing',
      build: build,
      act: (bloc) => bloc.add(const LoginSubmitted(email: '', password: '')),
      expect: () => [
        const LoginState(
          status: LoginStatus.invalid,
          emailError: 'Enter your email address.',
          passwordError: 'Enter your password.',
        ),
      ],
      verify: (_) => verifyNever(
        () => login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ),
    );

    blocTest<LoginBloc, LoginState>(
      'a malformed email is rejected before the request',
      build: build,
      act: (bloc) =>
          bloc.add(const LoginSubmitted(email: 'nope', password: 'x')),
      expect: () => [
        const LoginState(
          status: LoginStatus.invalid,
          emailError: 'Enter a valid email address.',
        ),
      ],
    );

    test('a second submit while one runs is ignored', () async {
      final pending = Completer<Result<AuthUser>>();
      when(
        () => login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) => pending.future);
      final bloc = build();
      const event = LoginSubmitted(email: 'a@b.rw', password: 'secret123');

      bloc
        ..add(event)
        ..add(event);
      await Future<void>.delayed(Duration.zero);
      pending.complete(Result.success(anAuthUser()));
      await bloc.stream.firstWhere((s) => s.status == LoginStatus.success);

      verify(
        () => login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).called(1);
      await bloc.close();
    });
  });

  group('LoginBloc google', () {
    final googleUser = anAuthUser(provider: AuthProviderKind.google);

    blocTest<LoginBloc, LoginState>(
      'a returning Google user goes home',
      setUp: () => when(() => google()).thenAnswer(
        (_) async => Result.success(ReturningGoogleUser(googleUser, aUser())),
      ),
      build: build,
      act: (bloc) => bloc.add(const LoginGoogleRequested()),
      expect: () => [
        const LoginState(
          status: LoginStatus.submitting,
          method: LoginMethod.google,
        ),
        const LoginState(status: LoginStatus.success),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'a returning Google user is linked without a password',
      setUp: () => when(() => google()).thenAnswer(
        (_) async => Result.success(ReturningGoogleUser(googleUser, aUser())),
      ),
      build: build,
      act: (bloc) => bloc.add(const LoginGoogleRequested()),
      verify: (_) {
        verify(() => link()).called(1);
        verifyNever(() => link(password: any(named: 'password')));
      },
    );

    blocTest<LoginBloc, LoginState>(
      'a new Google user is not linked until registration finishes',
      setUp: () => when(() => google())
          .thenAnswer((_) async => Result.success(NewGoogleUser(googleUser))),
      build: build,
      act: (bloc) => bloc.add(const LoginGoogleRequested()),
      verify: (_) => verifyNoLink(link),
    );

    blocTest<LoginBloc, LoginState>(
      'a new Google user is sent to registration',
      setUp: () => when(() => google())
          .thenAnswer((_) async => Result.success(NewGoogleUser(googleUser))),
      build: build,
      act: (bloc) => bloc.add(const LoginGoogleRequested()),
      expect: () => [
        const LoginState(
          status: LoginStatus.submitting,
          method: LoginMethod.google,
        ),
        const LoginState(status: LoginStatus.needsRegistration),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'a cancelled or failed Google sign-in reports the message',
      setUp: () =>
          when(() => google())
              .thenAnswer((_) async => const Result.failure(NetworkFailure())),
      build: build,
      act: (bloc) => bloc.add(const LoginGoogleRequested()),
      expect: () => [
        const LoginState(
          status: LoginStatus.submitting,
          method: LoginMethod.google,
        ),
        LoginState(
          status: LoginStatus.failure,
          message: const NetworkFailure().message,
        ),
      ],
    );
  });
}
