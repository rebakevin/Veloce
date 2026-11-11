import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/auth/domain/entities/auth_user.dart';
import 'package:veloce/features/auth/domain/usecases/reload_auth_user.dart';
import 'package:veloce/features/auth/domain/usecases/send_email_verification.dart';
import 'package:veloce/features/auth/presentation/bloc/verify_email_cubit.dart';

import '../../domain/auth_fakes.dart';

class _MockSend extends Mock implements SendEmailVerification {}

class _MockReload extends Mock implements ReloadAuthUser {}

void main() {
  late _MockSend send;
  late _MockReload reload;

  setUp(() {
    send = _MockSend();
    reload = _MockReload();
  });

  VerifyEmailCubit build() =>
      VerifyEmailCubit(sendVerification: send, reloadUser: reload);

  AuthUser verified({required bool value}) => AuthUser(
    uid: 'uid-1',
    email: 'uid-1@example.com',
    emailVerified: value,
    displayName: null,
    provider: anAuthUser().provider,
  );

  group('VerifyEmailCubit', () {
    blocTest<VerifyEmailCubit, VerifyEmailState>(
      'resend reports that a new email went out',
      setUp: () =>
          when(() => send())
              .thenAnswer((_) async => const Result.success(null)),
      build: build,
      act: (cubit) => cubit.resend(),
      expect: () => [
        const VerifyEmailState(status: VerifyEmailStatus.resending),
        const VerifyEmailState(status: VerifyEmailStatus.resent),
      ],
    );

    blocTest<VerifyEmailCubit, VerifyEmailState>(
      'resend failure carries the message',
      setUp: () =>
          when(() => send())
              .thenAnswer((_) async => const Result.failure(NetworkFailure())),
      build: build,
      act: (cubit) => cubit.resend(),
      expect: () => [
        const VerifyEmailState(status: VerifyEmailStatus.resending),
        VerifyEmailState(
          status: VerifyEmailStatus.failure,
          message: const NetworkFailure().message,
        ),
      ],
    );

    blocTest<VerifyEmailCubit, VerifyEmailState>(
      'checking after the link was opened reports verified',
      setUp: () =>
          when(() => reload())
              .thenAnswer((_) async => Result.success(verified(value: true))),
      build: build,
      act: (cubit) => cubit.checkVerified(),
      expect: () => [
        const VerifyEmailState(status: VerifyEmailStatus.checking),
        const VerifyEmailState(status: VerifyEmailStatus.verified),
      ],
    );

    blocTest<VerifyEmailCubit, VerifyEmailState>(
      'checking before the link was opened reports not verified yet',
      setUp: () =>
          when(() => reload())
              .thenAnswer((_) async => Result.success(verified(value: false))),
      build: build,
      act: (cubit) => cubit.checkVerified(),
      expect: () => [
        const VerifyEmailState(status: VerifyEmailStatus.checking),
        const VerifyEmailState(status: VerifyEmailStatus.notVerifiedYet),
      ],
    );

    blocTest<VerifyEmailCubit, VerifyEmailState>(
      'a second check while one runs is ignored',
      setUp: () =>
          when(() => reload())
              .thenAnswer((_) async => Result.success(verified(value: true))),
      build: build,
      act: (cubit) {
        cubit
          ..checkVerified()
          ..checkVerified();
      },
      verify: (_) => verify(() => reload()).called(1),
    );
  });
}
