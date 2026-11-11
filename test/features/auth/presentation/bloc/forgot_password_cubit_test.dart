import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/auth/domain/usecases/send_password_reset.dart';
import 'package:veloce/features/auth/presentation/bloc/forgot_password_cubit.dart';

class _MockReset extends Mock implements SendPasswordReset {}

void main() {
  late _MockReset reset;

  setUp(() => reset = _MockReset());

  group('ForgotPasswordCubit', () {
    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'an invalid email shows an inline error and sends nothing',
      build: () => ForgotPasswordCubit(reset),
      act: (cubit) => cubit.submit('nope'),
      expect: () => [
        const ForgotPasswordState(emailError: 'Enter a valid email address.'),
      ],
      verify: (_) => verifyNever(() => reset(any())),
    );

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'a valid email is sent',
      setUp: () =>
          when(() => reset('a@b.rw'))
              .thenAnswer((_) async => const Result.success(null)),
      build: () => ForgotPasswordCubit(reset),
      act: (cubit) => cubit.submit('a@b.rw'),
      expect: () => [
        const ForgotPasswordState(status: ForgotPasswordStatus.sending),
        const ForgotPasswordState(status: ForgotPasswordStatus.sent),
      ],
    );

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'a failure carries its message',
      setUp: () =>
          when(() => reset(any()))
              .thenAnswer((_) async => const Result.failure(NetworkFailure())),
      build: () => ForgotPasswordCubit(reset),
      act: (cubit) => cubit.submit('a@b.rw'),
      expect: () => [
        const ForgotPasswordState(status: ForgotPasswordStatus.sending),
        ForgotPasswordState(
          status: ForgotPasswordStatus.failure,
          message: const NetworkFailure().message,
        ),
      ],
    );

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'a second submit while sending is ignored',
      setUp: () =>
          when(() => reset(any()))
              .thenAnswer((_) async => const Result.success(null)),
      build: () => ForgotPasswordCubit(reset),
      act: (cubit) {
        cubit
          ..submit('a@b.rw')
          ..submit('a@b.rw');
      },
      verify: (_) => verify(() => reset(any())).called(1),
    );

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'reset returns to the form',
      build: () => ForgotPasswordCubit(reset),
      seed: () => const ForgotPasswordState(status: ForgotPasswordStatus.sent),
      act: (cubit) => cubit.reset(),
      expect: () => [const ForgotPasswordState()],
    );
  });
}
