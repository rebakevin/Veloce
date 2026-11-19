import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/auth/domain/entities/google_registration_input.dart';
import 'package:veloce/features/auth/domain/entities/registration_input.dart';
import 'package:veloce/features/auth/domain/entities/registration_outcome.dart';
import 'package:veloce/features/auth/domain/usecases/complete_google_registration.dart';
import 'package:veloce/features/auth/domain/usecases/register_with_email.dart';
import 'package:veloce/features/auth/presentation/bloc/register_bloc.dart';

import '../../domain/auth_fakes.dart';

class _MockRegister extends Mock implements RegisterWithEmail {}

class _MockGoogle extends Mock implements CompleteGoogleRegistration {}

void main() {
  late _MockRegister register;
  late _MockGoogle completeGoogle;
  late MockLinkCurrentAccount link;

  final photo = Uint8List.fromList([1, 2, 3]);

  setUpAll(() {
    registerFallbackValue(aRegistration());
    registerFallbackValue(
      GoogleRegistrationInput(
        role: UserRole.renter,
        phone: '0788123456',
        dateOfBirth: DateTime(1995),
        document: aRegistration().document,
      ),
    );
  });

  setUp(() {
    register = _MockRegister();
    completeGoogle = _MockGoogle();
    link = MockLinkCurrentAccount();
    stubLinkSucceeds(link);
    when(() => register(any())).thenAnswer(
      (_) async => Result.success(
        RegistrationOutcome(user: anAuthUser(), verificationEmailSent: true),
      ),
    );
  });

  RegisterBloc build({bool google = false}) => RegisterBloc(
    registerWithEmail: register,
    completeGoogle: completeGoogle,
    linkCurrentAccount: link,
    clock: const FixedClock(),
    googleUser: google ? anAuthUser(provider: AuthProviderKind.google) : null,
  );

  /// Everything the renter details step needs.
  RegisterDraftEdited validRenterEdits({DateTime? dateOfBirth}) =>
      RegisterDraftEdited(
        name: 'Aline Uwase',
        phone: '0788123456',
        email: 'aline@example.com',
        password: 'secret123',
        dateOfBirth: dateOfBirth ?? DateTime(1995, 5, 5),
        documentNumber: 'DL-12345',
        licenceExpiry: DateTime(2030),
        photoBytes: photo,
      );

  /// Drives a fresh bloc through the details step. The stream listener is
  /// attached before the events, so a short-lived failure state is not missed.
  Future<RegisterBloc> submitRenter({
    bool Function(RegisterState state)? until,
  }) async {
    final bloc = build();
    final settled = bloc.stream.firstWhere(
      until ?? (state) => state.step == RegisterStep.done,
    );
    bloc
      ..add(const RegisterRoleSelected(UserRole.renter))
      ..add(validRenterEdits())
      ..add(const RegisterDetailsSubmitted());
    await settled;
    return bloc;
  }

  group('RegisterBloc details', () {
    blocTest<RegisterBloc, RegisterState>(
      'choosing a role moves to the details step',
      build: build,
      act: (bloc) => bloc.add(const RegisterRoleSelected(UserRole.owner)),
      expect: () => [
        isA<RegisterState>()
            .having((s) => s.step, 'step', RegisterStep.details)
            .having((s) => s.draft.role, 'role', UserRole.owner),
      ],
    );

    blocTest<RegisterBloc, RegisterState>(
      'blank details are blocked with an inline message per field',
      build: build,
      act: (bloc) => bloc
        ..add(const RegisterRoleSelected(UserRole.renter))
        ..add(const RegisterDetailsSubmitted()),
      skip: 1,
      expect: () => [
        isA<RegisterState>()
            .having((s) => s.step, 'step', RegisterStep.details)
            .having(
              (s) => s.fieldErrors.keys,
              'fields',
              containsAll(RegisterField.values),
            ),
      ],
      verify: (_) => verifyNever(() => register(any())),
    );

    blocTest<RegisterBloc, RegisterState>(
      'an owner is asked for a National ID, not a licence',
      build: build,
      act: (bloc) => bloc
        ..add(const RegisterRoleSelected(UserRole.owner))
        ..add(const RegisterDraftEdited(documentNumber: '123'))
        ..add(const RegisterDetailsSubmitted()),
      verify: (bloc) {
        expect(
          bloc.state.fieldErrors[RegisterField.documentNumber],
          'A National ID has 16 digits.',
        );
        expect(
          bloc.state.fieldErrors.containsKey(RegisterField.licenceExpiry),
          isFalse,
        );
      },
    );

    blocTest<RegisterBloc, RegisterState>(
      'a date of birth under 18 is blocked',
      build: build,
      act: (bloc) => bloc
        ..add(const RegisterRoleSelected(UserRole.renter))
        ..add(validRenterEdits(dateOfBirth: DateTime(2010)))
        ..add(const RegisterDetailsSubmitted()),
      verify: (bloc) {
        expect(bloc.state.step, RegisterStep.details);
        expect(bloc.state.fieldErrors, {
          RegisterField.dateOfBirth: 'You must be at least 18 years old.',
        });
      },
    );

    blocTest<RegisterBloc, RegisterState>(
      'editing a field clears its error',
      build: build,
      act: (bloc) => bloc
        ..add(const RegisterRoleSelected(UserRole.renter))
        ..add(const RegisterDetailsSubmitted())
        ..add(const RegisterDraftEdited(email: 'a@b.rw')),
      verify: (bloc) {
        expect(
          bloc.state.fieldErrors.containsKey(RegisterField.email),
          isFalse,
        );
        expect(bloc.state.fieldErrors.containsKey(RegisterField.phone), isTrue);
      },
    );
  });

  group('RegisterBloc submit', () {
    test('valid details register the account straight away', () async {
      final bloc = await submitRenter();

      expect(bloc.state.step, RegisterStep.done);
      expect(bloc.state.status, RegisterStatus.idle);
      expect(bloc.state.verificationEmailSent, isTrue);
      final input =
          verify(() => register(captureAny())).captured.single
              as RegistrationInput;
      expect(input.email, 'aline@example.com');
      expect(input.role, UserRole.renter);
      await bloc.close();
    });

    test('a finished sign-up links the account with its password', () async {
      final bloc = await submitRenter();

      verify(() => link(password: 'secret123')).called(1);
      await bloc.close();
    });

    test('a sign-up that cannot link the account still finishes', () async {
      when(() => link(password: any(named: 'password')))
          .thenAnswer((_) async => const Result.failure(NetworkFailure()));
      final bloc = await submitRenter();

      expect(bloc.state.status, RegisterStatus.idle);
      await bloc.close();
    });

    test('a failed sign-up links nothing', () async {
      when(() => register(any()))
          .thenAnswer((_) async => const Result.failure(NetworkFailure()));
      final bloc = await submitRenter(
        until: (state) => state.status == RegisterStatus.failure,
      );

      verifyNoLink(link);
      await bloc.close();
    });

    test('a submit failure can be retried', () async {
      var attempts = 0;
      when(() => register(any())).thenAnswer(
        (_) async => ++attempts == 1
            ? const Result.failure(NetworkFailure())
            : Result.success(
                RegistrationOutcome(
                  user: anAuthUser(),
                  verificationEmailSent: false,
                ),
              ),
      );
      final bloc = await submitRenter(
        until: (state) => state.status == RegisterStatus.failure,
      );
      final failed = bloc.state;
      expect(failed.step, RegisterStep.submitting);
      expect(failed.message, const NetworkFailure().message);

      bloc.add(const RegisterSubmitRetried());
      final done = await bloc.stream.firstWhere(
        (state) => state.step == RegisterStep.done,
      );
      expect(done.verificationEmailSent, isFalse);
      await bloc.close();
    });
  });

  group('RegisterBloc google path', () {
    blocTest<RegisterBloc, RegisterState>(
      'skips email and password and completes the profile',
      setUp: () =>
          when(() => completeGoogle(any()))
              .thenAnswer((_) async => Result.success(anAuthUser())),
      build: () => build(google: true),
      act: (bloc) => bloc
        ..add(const RegisterRoleSelected(UserRole.owner))
        ..add(
          RegisterDraftEdited(
            phone: '0788123456',
            dateOfBirth: DateTime(1990),
            documentNumber: '1199880012345678',
            photoBytes: photo,
          ),
        )
        ..add(const RegisterDetailsSubmitted()),
      verify: (bloc) {
        expect(bloc.state.step, RegisterStep.done);
        expect(bloc.state.verificationEmailSent, isFalse);
        expect(bloc.state.draft.name, 'Aline Uwase');
        verifyNever(() => register(any()));
        verify(() => completeGoogle(any())).called(1);
      },
    );

    blocTest<RegisterBloc, RegisterState>(
      'links the new Google account without a password',
      setUp: () =>
          when(() => completeGoogle(any()))
              .thenAnswer((_) async => Result.success(anAuthUser())),
      build: () => build(google: true),
      act: (bloc) => bloc
        ..add(const RegisterRoleSelected(UserRole.owner))
        ..add(
          RegisterDraftEdited(
            phone: '0788123456',
            dateOfBirth: DateTime(1990),
            documentNumber: '1199880012345678',
            photoBytes: photo,
          ),
        )
        ..add(const RegisterDetailsSubmitted()),
      verify: (_) {
        verify(() => link()).called(1);
        verifyNever(() => link(password: any(named: 'password')));
      },
    );

    blocTest<RegisterBloc, RegisterState>(
      'does not ask for email or password',
      build: () => build(google: true),
      act: (bloc) => bloc
        ..add(const RegisterRoleSelected(UserRole.owner))
        ..add(const RegisterDetailsSubmitted()),
      verify: (bloc) {
        expect(
          bloc.state.fieldErrors.containsKey(RegisterField.email),
          isFalse,
        );
        expect(
          bloc.state.fieldErrors.containsKey(RegisterField.password),
          isFalse,
        );
        expect(bloc.state.fieldErrors.containsKey(RegisterField.phone), isTrue);
      },
    );
  });
}
