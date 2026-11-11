import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/domain/entities/contact.dart';
import 'package:veloce/core/domain/entities/licence.dart';
import 'package:veloce/core/domain/entities/payout_method.dart';
import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/profile/domain/entities/licence_submission.dart';
import 'package:veloce/features/profile/domain/entities/profile_update.dart';
import 'package:veloce/features/profile/domain/repositories/profile_repository.dart';
import 'package:veloce/features/profile/presentation/bloc/profile_bloc.dart';

import '../../../../support/builders.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _FixedClock implements Clock {
  @override
  DateTime now() => testNow;
}

void main() {
  late _MockProfileRepository repository;
  final contact = Contact(
    userId: 'user-1',
    email: 'a@example.com',
    phone: '0788123456',
    dateOfBirth: DateTime(1995, 5, 5),
    authProvider: AuthProviderKind.password,
  );
  final licence = Licence(
    userId: 'user-1',
    number: 'DL-1',
    expiry: DateTime(2030),
    photoUrl: 'url',
    active: true,
  );
  const payout = PayoutMethod(userId: 'user-1', momoNumber: '788123456');
  final renter = aUser();
  final renterLoaded = ProfileLoaded(
    account: renter,
    contact: contact,
    licence: licence,
  );

  ProfileBloc build() =>
      ProfileBloc(repository: repository, clock: _FixedClock());

  void stubRenter() {
    when(() => repository.getProfile())
        .thenAnswer((_) async => Result.success(renter));
    when(() => repository.getContact())
        .thenAnswer((_) async => Result.success(contact));
    when(() => repository.getLicence())
        .thenAnswer((_) async => Result.success(licence));
    when(() => repository.watchProfile())
        .thenAnswer((_) => const Stream.empty());
  }

  setUpAll(() {
    registerFallbackValue(
      ProfileUpdate(
        name: 'x',
        phone: '0788123456',
        dateOfBirth: DateTime(1990),
      ),
    );
    registerFallbackValue(
      LicenceSubmission(number: 'x', expiry: DateTime(2030)),
    );
  });

  setUp(() => repository = _MockProfileRepository());

  LicenceSubmission licenceInput() =>
      LicenceSubmission(number: 'DL-2', expiry: DateTime(2031));

  group('load', () {
    blocTest<ProfileBloc, ProfileState>(
      'loads account, contact and licence for a renter',
      setUp: stubRenter,
      build: build,
      act: (bloc) => bloc.add(const ProfileStarted()),
      expect: () => [const ProfileLoading(), renterLoaded],
      verify: (_) {
        verifyNever(() => repository.getIdentity());
        verifyNever(() => repository.getPayout());
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'loads identity and payout for an owner',
      setUp: () {
        stubRenter();
        when(
          () => repository.getProfile(),
        ).thenAnswer((_) async => Result.success(aUser(role: UserRole.owner)));
        when(() => repository.getIdentity())
            .thenAnswer((_) async => const Result.success(null));
        when(() => repository.getPayout())
            .thenAnswer((_) async => const Result.success(payout));
      },
      build: build,
      act: (bloc) => bloc.add(const ProfileStarted()),
      expect: () => [
        const ProfileLoading(),
        ProfileLoaded(
          account: aUser(role: UserRole.owner),
          contact: contact,
          payout: payout,
        ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits a failure when the profile cannot be read',
      setUp: () =>
          when(() => repository.getProfile())
              .thenAnswer((_) async => const Result.failure(NetworkFailure())),
      build: build,
      act: (bloc) => bloc.add(const ProfileStarted()),
      expect: () => [
        const ProfileLoading(),
        const ProfileFailure(NetworkFailure()),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'applies a watched account change',
      setUp: () {
        stubRenter();
        when(() => repository.watchProfile()).thenAnswer(
          (_) => Stream.value(Result.success(renter.copyWith(name: 'New'))),
        );
      },
      build: build,
      act: (bloc) => bloc.add(const ProfileStarted()),
      expect: () => [
        const ProfileLoading(),
        renterLoaded,
        renterLoaded.copyWith(account: renter.copyWith(name: 'New')),
      ],
    );
  });

  group('update profile', () {
    final update = ProfileUpdate(
      name: 'Aline N',
      phone: '0788123456',
      dateOfBirth: DateTime(1995, 5, 5),
    );

    blocTest<ProfileBloc, ProfileState>(
      'submits and reports success',
      setUp: () {
        stubRenter();
        when(() => repository.updateProfile(any()))
            .thenAnswer((_) async => const Result.success(null));
      },
      build: build,
      seed: () => renterLoaded,
      act: (bloc) => bloc.add(ProfileUpdateSubmitted(update)),
      expect: () => [
        renterLoaded.copyWith(
          action: const ProfileAction(
            kind: ProfileActionKind.updateProfile,
            status: ProfileActionStatus.submitting,
          ),
        ),
        renterLoaded.copyWith(
          action: const ProfileAction(
            kind: ProfileActionKind.updateProfile,
            status: ProfileActionStatus.success,
          ),
        ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'invalid fields never reach the repository',
      build: build,
      seed: () => renterLoaded,
      act: (bloc) => bloc.add(
        ProfileUpdateSubmitted(
          ProfileUpdate(
            name: ' ',
            phone: '0788123456',
            dateOfBirth: DateTime(1995),
          ),
        ),
      ),
      expect: () => [
        isA<ProfileLoaded>().having(
          (s) => s.action.status,
          'status',
          ProfileActionStatus.invalid,
        ),
      ],
      verify: (_) => verifyNever(() => repository.updateProfile(any())),
    );

    blocTest<ProfileBloc, ProfileState>(
      'a network failure keeps the data and reports failure',
      setUp: () =>
          when(() => repository.updateProfile(any()))
              .thenAnswer((_) async => const Result.failure(NetworkFailure())),
      build: build,
      seed: () => renterLoaded,
      act: (bloc) => bloc.add(ProfileUpdateSubmitted(update)),
      expect: () => [
        isA<ProfileLoaded>(),
        isA<ProfileLoaded>()
            .having(
              (s) => s.action.status,
              'status',
              ProfileActionStatus.failure,
            )
            .having((s) => s.contact, 'contact', contact),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'ignores a second submit while one runs',
      setUp: () {
        final completer = Completer<Result<void>>();
        when(() => repository.updateProfile(any()))
            .thenAnswer((_) => completer.future);
      },
      build: build,
      seed: () => renterLoaded,
      act: (bloc) {
        bloc
          ..add(ProfileUpdateSubmitted(update))
          ..add(ProfileUpdateSubmitted(update));
      },
      expect: () => [isA<ProfileLoaded>()],
      verify: (_) => verify(() => repository.updateProfile(any())).called(1),
    );
  });

  group('licence', () {
    blocTest<ProfileBloc, ProfileState>(
      'saves and shows the new licence',
      setUp: () => when(() => repository.saveLicence(any())).thenAnswer(
        (_) async => Result.success(licence.copyWith(number: 'DL-2')),
      ),
      build: build,
      seed: () => renterLoaded,
      act: (bloc) => bloc.add(ProfileLicenceSubmitted(licenceInput())),
      expect: () => [
        isA<ProfileLoaded>(),
        isA<ProfileLoaded>()
            .having((s) => s.licence?.number, 'number', 'DL-2')
            .having(
              (s) => s.action.status,
              'status',
              ProfileActionStatus.success,
            ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'verification failure then retry succeeds',
      setUp: () {
        var calls = 0;
        when(() => repository.saveLicence(any())).thenAnswer((_) async {
          calls++;
          return calls == 1
              ? const Result.failure(ValidationFailure('Try again.'))
              : Result.success(licence.copyWith(number: 'DL-2'));
        });
      },
      build: build,
      seed: () => renterLoaded,
      act: (bloc) async {
        bloc.add(ProfileLicenceSubmitted(licenceInput()));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ProfileLicenceRetried());
      },
      expect: () => [
        isA<ProfileLoaded>().having(
          (s) => s.action.status,
          'status',
          ProfileActionStatus.submitting,
        ),
        isA<ProfileLoaded>()
            .having(
              (s) => s.action.status,
              'status',
              ProfileActionStatus.verificationFailed,
            )
            .having((s) => s.action.message, 'message', 'Try again.'),
        isA<ProfileLoaded>().having(
          (s) => s.action.status,
          'status',
          ProfileActionStatus.submitting,
        ),
        isA<ProfileLoaded>()
            .having(
              (s) => s.action.status,
              'status',
              ProfileActionStatus.success,
            )
            .having((s) => s.licence?.number, 'number', 'DL-2'),
      ],
      verify: (_) => verify(() => repository.saveLicence(any())).called(2),
    );

    blocTest<ProfileBloc, ProfileState>(
      'an expired licence is invalid locally',
      build: build,
      seed: () => renterLoaded,
      act: (bloc) => bloc.add(
        ProfileLicenceSubmitted(
          LicenceSubmission(number: 'DL-2', expiry: DateTime(2020)),
        ),
      ),
      expect: () => [
        isA<ProfileLoaded>().having(
          (s) => s.action.status,
          'status',
          ProfileActionStatus.invalid,
        ),
      ],
      verify: (_) => verifyNever(() => repository.saveLicence(any())),
    );

    blocTest<ProfileBloc, ProfileState>(
      'acknowledging clears the result',
      build: build,
      seed: () => renterLoaded.copyWith(
        action: const ProfileAction(
          kind: ProfileActionKind.licence,
          status: ProfileActionStatus.success,
        ),
      ),
      act: (bloc) => bloc.add(const ProfileActionAcknowledged()),
      expect: () => [renterLoaded],
    );
  });

  group('owner payout', () {
    final ownerLoaded = ProfileLoaded(
      account: aUser(role: UserRole.owner),
      contact: contact,
    );

    blocTest<ProfileBloc, ProfileState>(
      'an invalid MoMo number is rejected locally',
      build: build,
      seed: () => ownerLoaded,
      act: (bloc) => bloc.add(const ProfilePayoutSubmitted('12')),
      expect: () => [
        isA<ProfileLoaded>()
            .having(
              (s) => s.action.status,
              'status',
              ProfileActionStatus.invalid,
            )
            .having((s) => s.action.message, 'message', contains('digits')),
      ],
      verify: (_) => verifyNever(() => repository.savePayout(any())),
    );

    blocTest<ProfileBloc, ProfileState>(
      'a valid MoMo number is saved',
      setUp: () =>
          when(() => repository.savePayout('788123456'))
              .thenAnswer((_) async => const Result.success(payout)),
      build: build,
      seed: () => ownerLoaded,
      act: (bloc) => bloc.add(const ProfilePayoutSubmitted('788123456')),
      expect: () => [
        isA<ProfileLoaded>(),
        isA<ProfileLoaded>()
            .having((s) => s.payout, 'payout', payout)
            .having(
              (s) => s.action.status,
              'status',
              ProfileActionStatus.success,
            ),
      ],
    );
  });
}
