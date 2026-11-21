import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:veloce/core/data/services/momo_gateway_sim.dart';
import 'package:veloce/core/data/services/verification_sim.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/auth/data/dev_sign_in.dart';
import 'package:veloce/features/auth/domain/dev_account.dart';
import 'package:veloce/features/auth/presentation/bloc/dev_tools_cubit.dart';

class _MockDevSignIn extends Mock implements DevSignIn {}

void main() {
  late _MockDevSignIn signIn;
  late MomoGatewaySim momo;
  late VerificationSim verification;
  final account = DevAccounts.all.first;

  setUpAll(() => registerFallbackValue(account));

  setUp(() {
    signIn = _MockDevSignIn();
    momo = MomoGatewaySim();
    verification = VerificationSim();
  });

  DevToolsCubit build() =>
      DevToolsCubit(signIn: signIn, momo: momo, verification: verification);

  test('starts from the current simulation switches', () {
    momo.shouldSucceed = false;

    expect(build().state.momoSucceeds, isFalse);
    expect(build().state.verificationSucceeds, isTrue);
  });

  blocTest<DevToolsCubit, DevToolsState>(
    'signing in as an account reports signed in',
    setUp: () =>
        when(() => signIn.signIn(any()))
            .thenAnswer((_) async => const Result.success(null)),
    build: build,
    act: (cubit) => cubit.signInAs(account),
    expect: () => [
      const DevToolsState(status: DevToolsStatus.signingIn),
      const DevToolsState(status: DevToolsStatus.signedIn),
    ],
  );

  blocTest<DevToolsCubit, DevToolsState>(
    'a failed sign-in reports the failure message',
    setUp: () => when(() => signIn.signIn(any())).thenAnswer(
      (_) async => const Result.failure(ValidationFailure('Run the seed.')),
    ),
    build: build,
    act: (cubit) => cubit.signInAs(account),
    expect: () => [
      const DevToolsState(status: DevToolsStatus.signingIn),
      const DevToolsState(
        status: DevToolsStatus.failed,
        message: 'Run the seed.',
      ),
    ],
  );

  test('a second tap while signing in is ignored', () async {
    when(() => signIn.signIn(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return const Result.success(null);
    });
    final cubit = build();

    final first = cubit.signInAs(account);
    await cubit.signInAs(account);
    await first;

    verify(() => signIn.signIn(any())).called(1);
  });

  blocTest<DevToolsCubit, DevToolsState>(
    'the switches change the simulations',
    build: build,
    act: (cubit) => cubit
      ..setMomoSucceeds(value: false)
      ..setVerificationSucceeds(value: false),
    expect: () => [
      const DevToolsState(momoSucceeds: false),
      const DevToolsState(momoSucceeds: false, verificationSucceeds: false),
    ],
    verify: (_) {
      expect(momo.shouldSucceed, isFalse);
      expect(verification.shouldSucceed, isFalse);
    },
  );

  test('sign out signs the dev account out', () async {
    when(() => signIn.signOut()).thenAnswer((_) async {});

    await build().signOut();

    verify(() => signIn.signOut()).called(1);
  });
}
