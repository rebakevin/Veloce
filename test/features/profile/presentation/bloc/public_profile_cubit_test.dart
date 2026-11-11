import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/profile/domain/entities/public_profile.dart';
import 'package:veloce/features/profile/domain/repositories/profile_repository.dart';
import 'package:veloce/features/profile/presentation/bloc/public_profile_cubit.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late _MockProfileRepository repository;
  const profile = PublicProfile(
    userId: 'u1',
    name: 'Aline',
    photoUrl: null,
    ratingAvg: 4.5,
    ratingCount: 2,
    completedCount: 1,
  );

  setUp(() => repository = _MockProfileRepository());

  PublicProfileCubit build() =>
      PublicProfileCubit(repository: repository, userId: 'u1');

  blocTest<PublicProfileCubit, PublicProfileState>(
    'loads the profile',
    setUp: () =>
        when(() => repository.getPublicProfile('u1'))
            .thenAnswer((_) async => const Result.success(profile)),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const PublicProfileLoading(),
      const PublicProfileLoaded(profile),
    ],
  );

  blocTest<PublicProfileCubit, PublicProfileState>(
    'reports not found',
    setUp: () =>
        when(() => repository.getPublicProfile('u1'))
            .thenAnswer((_) async => const Result.failure(NotFoundFailure())),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [const PublicProfileLoading(), const PublicProfileNotFound()],
  );

  blocTest<PublicProfileCubit, PublicProfileState>(
    'reports a technical failure',
    setUp: () =>
        when(() => repository.getPublicProfile('u1'))
            .thenAnswer((_) async => const Result.failure(NetworkFailure())),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const PublicProfileLoading(),
      const PublicProfileFailure(NetworkFailure()),
    ],
  );
}
