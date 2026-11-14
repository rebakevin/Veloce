import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/verification_provider.dart';
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

class _MockVerification extends Mock implements VerificationProvider {}

void main() {
  late _MockRegister register;
  late _MockGoogle completeGoogle;
  late _MockVerification verification;
  late MockLinkCurrentAccount link;

  const challenge = OtpChallenge(phone: '0788123456', code: '123456');
  final photo = Uint8List.fromList([1, 2, 3]);

  setUpAll(() {
    registerFallbackValue(challenge);
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
    verification = _MockVerification();
    link = MockLinkCurrentAccount();
    stubLinkSucceeds(link);
    when(() => verification.sendOtp(any()))
        .thenAnswer((_) async => const Result.success(challenge));
    when(
      () => verification.confirmOtp(
        challenge: any(named: 'challenge'),
        code: any(named: 'code'),
      ),
    ).thenAnswer((_) async => const Result.success(null));
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
    verification: verification,
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

  /// Drives a fresh bloc to the OTP step.
  Future<RegisterBloc> atOtpStep() async {
    final bloc = build()
      ..add(const RegisterRoleSelected(UserRole.renter))
      ..add(validRenterEdits())
      ..add(const RegisterDetailsSubmitted());
    await bloc.stream.firstWhere((s) => s.step == RegisterStep.otp);
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
      verify: (_) => verifyNever(() => verification.sendOtp(any())),
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

    blocTest<RegisterBloc, RegisterState>(
      'valid details send an OTP and expose its code on the otp step',
      build: build,
      act: (bloc) => bloc
        ..add(const RegisterRoleSelected(UserRole.renter))
        ..add(validRenterEdits())
        ..add(const RegisterDetailsSubmitted()),
      verify: (bloc) {
        expect(bloc.state.step, RegisterStep.otp);
        expect(bloc.state.challenge?.code, '123456');
        verify(() => verification.sendOtp('0788123456')).called(1);
      },
    );
  });

  group('RegisterBloc otp and submit', () {
    test('a wrong code keeps the otp step with a failure message', () async {
      when(
        () => verification.confirmOtp(
          challenge: any(named: 'challenge'),
          code: '000000',
        ),
      ).thenAnswer(
        (_) async => const Result.failure(
          ValidationFailure('That code is not correct.'),
        ),
      );
      final bloc = await atOtpStep();
      bloc.add(const RegisterOtpSubmitted('000000'));
      final state = await bloc.stream.firstWhere(
        (s) => s.status == RegisterStatus.failure,
      );
      expect(state.step, RegisterStep.otp);
      expect(state.message, 'That code is not correct.');
      verifyNever(() => register(any()));
      await bloc.close();
    });

    test('typing after a wrong code clears the message', () async {
      when(
        () => verification.confirmOtp(
          challenge: any(named: 'challenge'),
          code: '000000',
        ),
      ).thenAnswer(
        (_) async => const Result.failure(
          ValidationFailure('That code is not correct.'),
        ),
      );
      final bloc = await atOtpStep();
      bloc.add(const RegisterOtpSubmitted('000000'));
      await bloc.stream.firstWhere((s) => s.status == RegisterStatus.failure);

      bloc.add(const RegisterOtpEdited());
      final state = await bloc.stream.firstWhere(
        (s) => s.status == RegisterStatus.idle,
      );

      expect(state.step, RegisterStep.otp);
      expect(state.message, isNull);
      await bloc.close();
    });

    test('a malformed code is rejected without a request', () async {
      final bloc = await atOtpStep();
      bloc.add(const RegisterOtpSubmitted('12'));
      final state = await bloc.stream.firstWhere(
        (s) => s.status == RegisterStatus.failure,
      );
      expect(state.message, 'Enter the 6-digit code.');
      verifyNever(
        () => verification.confirmOtp(
          challenge: any(named: 'challenge'),
          code: any(named: 'code'),
        ),
      );
      await bloc.close();
    });

    test('a simulated verification failure can be retried', () async {
      var attempts = 0;
      when(
        () => verification.confirmOtp(
          challenge: any(named: 'challenge'),
          code: any(named: 'code'),
        ),
      ).thenAnswer(
        (_) async => ++attempts == 1
            ? const Result.failure(ValidationFailure('Verification failed.'))
            : const Result.success(null),
      );
      final bloc = await atOtpStep();

      bloc.add(const RegisterOtpSubmitted('123456'));
      await bloc.stream.firstWhere((s) => s.status == RegisterStatus.failure);
      bloc.add(const RegisterOtpSubmitted('123456'));
      final done = await bloc.stream.firstWhere(
        (s) => s.step == RegisterStep.done,
      );

      expect(done.verificationEmailSent, isTrue);
      await bloc.close();
    });

    test('a finished sign-up links the account with its password', () async {
      final bloc = await atOtpStep();
      bloc.add(const RegisterOtpSubmitted('123456'));
      await bloc.stream.firstWhere((s) => s.step == RegisterStep.done);

      verify(() => link(password: 'secret123')).called(1);
      await bloc.close();
    });

    test('a sign-up that cannot link the account still finishes', () async {
      when(() => link(password: any(named: 'password')))
          .thenAnswer((_) async => const Result.failure(NetworkFailure()));
      final bloc = await atOtpStep();
      bloc.add(const RegisterOtpSubmitted('123456'));

      final done = await bloc.stream.firstWhere(
        (s) => s.step == RegisterStep.done,
      );
      expect(done.status, RegisterStatus.idle);
      await bloc.close();
    });

    test('a failed sign-up links nothing', () async {
      when(() => register(any()))
          .thenAnswer((_) async => const Result.failure(NetworkFailure()));
      final bloc = await atOtpStep();
      bloc.add(const RegisterOtpSubmitted('123456'));
      await bloc.stream.firstWhere((s) => s.status == RegisterStatus.failure);

      verifyNoLink(link);
      await bloc.close();
    });

    test('resending the OTP issues a fresh challenge', () async {
      final bloc = await atOtpStep();
      bloc.add(const RegisterOtpResent());
      await Future<void>.delayed(Duration.zero);
      verify(() => verification.sendOtp(any())).called(2);
      await bloc.close();
    });

    test('a correct code registers the user and finishes', () async {
      final bloc = await atOtpStep();
      bloc.add(const RegisterOtpSubmitted('123456'));
      final done = await bloc.stream.firstWhere(
        (s) => s.step == RegisterStep.done,
      );
      expect(done.status, RegisterStatus.idle);
      final input =
          verify(() => register(captureAny())).captured.single
              as RegistrationInput;
      expect(input.email, 'aline@example.com');
      expect(input.role, UserRole.renter);
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
      final bloc = await atOtpStep();
      bloc.add(const RegisterOtpSubmitted('123456'));
      final failed = await bloc.stream.firstWhere(
        (s) => s.status == RegisterStatus.failure,
      );
      expect(failed.step, RegisterStep.submitting);
      expect(failed.message, const NetworkFailure().message);

      bloc.add(const RegisterSubmitRetried());
      final done = await bloc.stream.firstWhere(
        (s) => s.step == RegisterStep.done,
      );
      expect(done.verificationEmailSent, isFalse);
      await bloc.close();
    });

    test('back from otp returns to details and drops the challenge', () async {
      final bloc = await atOtpStep();
      bloc.add(const RegisterBackPressed());
      final state = await bloc.stream.firstWhere(
        (s) => s.step == RegisterStep.details,
      );
      expect(state.challenge, isNull);
      expect(state.draft.email, 'aline@example.com');
      await bloc.close();
    });
  });

  group('RegisterBloc google path', () {
    blocTest<RegisterBloc, RegisterState>(
      'skips email, password and otp and completes the profile',
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
        expect(bloc.state.draft.name, 'Aline Uwase');
        verifyNever(() => verification.sendOtp(any()));
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
