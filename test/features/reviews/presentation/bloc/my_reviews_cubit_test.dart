import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/data/services/user_lookup.dart';
import 'package:veloce/core/data/services/vehicle_lookup.dart';
import 'package:veloce/core/domain/entities/review.dart';
import 'package:veloce/core/domain/enums/subject_type.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/reviews/domain/repositories/review_repository.dart';
import 'package:veloce/features/reviews/presentation/bloc/my_reviews_cubit.dart';

import '../../../../support/builders.dart';

class _MockReviewRepository extends Mock implements ReviewRepository {}

class _MockUserLookup extends Mock implements UserLookup {}

class _MockVehicleLookup extends Mock implements VehicleLookup {}

class _MockAuthSession extends Mock implements AuthSession {}

void main() {
  late _MockReviewRepository repository;
  late _MockUserLookup userLookup;
  late _MockVehicleLookup vehicleLookup;
  late _MockAuthSession session;

  final testReview = Review(
    id: 'r1',
    bookingId: 'b1',
    authorId: 'user_1',
    subjectType: SubjectType.vehicle,
    subjectId: 'car-1',
    stars: 5,
    comment: 'Super car!',
    createdAt: DateTime(2026, 11, 15),
    editedAt: null,
  );

  final testVehicle = aVehicle();

  setUp(() {
    repository = _MockReviewRepository();
    userLookup = _MockUserLookup();
    vehicleLookup = _MockVehicleLookup();
    session = _MockAuthSession();

    when(() => session.currentUserId).thenReturn('user_1');
    when(() => vehicleLookup.byId('car-1'))
        .thenAnswer((_) async => Result.success(testVehicle));
    when(() => userLookup.byId(any()))
        .thenAnswer((_) async => const Result.failure(NotFoundFailure()));
  });

  MyReviewsCubit buildCubit() => MyReviewsCubit(
    repository: repository,
    userLookup: userLookup,
    vehicleLookup: vehicleLookup,
    session: session,
  );

  group('MyReviewsCubit', () {
    test('initial state is MyReviewsLoading', () {
      expect(buildCubit().state, isA<MyReviewsLoading>());
    });

    blocTest<MyReviewsCubit, MyReviewsState>(
      'emits MyReviewsFailure if user is not signed in',
      setUp: () {
        when(() => session.currentUserId).thenReturn(null);
      },
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [isA<MyReviewsFailure>()],
    );

    blocTest<MyReviewsCubit, MyReviewsState>(
      'emits MyReviewsEmpty when user has written zero reviews',
      setUp: () {
        when(() => repository.getReviewsByAuthor('user_1'))
            .thenAnswer((_) async => const Result.success([]));
      },
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [isA<MyReviewsLoading>(), isA<MyReviewsEmpty>()],
    );

    blocTest<MyReviewsCubit, MyReviewsState>(
      'emits MyReviewsLoaded with resolved subject details',
      setUp: () {
        when(() => repository.getReviewsByAuthor('user_1'))
            .thenAnswer((_) async => Result.success([testReview]));
      },
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<MyReviewsLoading>(),
        predicate<MyReviewsState>((s) {
          if (s is! MyReviewsLoaded) return false;
          return s.reviews.length == 1 &&
              s.reviews.first.subjectTitle == 'For Toyota Vitz';
        }),
      ],
    );

    blocTest<MyReviewsCubit, MyReviewsState>(
      'emits MyReviewsFailure when repository returns failure',
      setUp: () {
        when(() => repository.getReviewsByAuthor('user_1')).thenAnswer(
          (_) async => const Result.failure(UnknownFailure('DB error')),
        );
      },
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<MyReviewsLoading>(),
        predicate<MyReviewsState>(
          (s) => s is MyReviewsFailure && s.error is UnknownFailure,
        ),
      ],
    );
  });
}
