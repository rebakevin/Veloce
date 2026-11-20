import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/data/services/booking_lookup.dart';
import 'package:veloce/core/data/services/user_lookup.dart';
import 'package:veloce/core/data/services/vehicle_lookup.dart';
import 'package:veloce/core/domain/entities/review.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/subject_type.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/reviews/domain/repositories/review_repository.dart';
import 'package:veloce/features/reviews/presentation/bloc/review_bloc.dart';

import '../../../../support/builders.dart';

class _MockReviewRepository extends Mock implements ReviewRepository {}

class _MockBookingLookup extends Mock implements BookingLookup {}

class _MockVehicleLookup extends Mock implements VehicleLookup {}

class _MockUserLookup extends Mock implements UserLookup {}

class _MockAuthSession extends Mock implements AuthSession {}

void main() {
  setUpAll(() {
    registerFallbackValue(SubjectType.user);
  });

  late _MockReviewRepository repository;
  late _MockBookingLookup bookingLookup;
  late _MockVehicleLookup vehicleLookup;
  late _MockUserLookup userLookup;
  late _MockAuthSession session;

  final testBooking = aBooking(
    id: 'booking_1',
    status: BookingStatus.completed,
  );

  final testVehicle = aVehicle();

  final testOwner = aUser(role: UserRole.owner);

  setUp(() {
    repository = _MockReviewRepository();
    bookingLookup = _MockBookingLookup();
    vehicleLookup = _MockVehicleLookup();
    userLookup = _MockUserLookup();
    session = _MockAuthSession();

    when(() => session.currentUserId).thenReturn('renter-1');
    when(() => bookingLookup.byId('booking_1'))
        .thenAnswer((_) async => Result.success(testBooking));
    when(() => vehicleLookup.byId('car-1'))
        .thenAnswer((_) async => Result.success(testVehicle));
    when(() => userLookup.byId('owner-1'))
        .thenAnswer((_) async => Result.success(testOwner));
    when(
      () => repository.getReview(
        bookingId: any(named: 'bookingId'),
        authorId: any(named: 'authorId'),
        subjectType: any(named: 'subjectType'),
      ),
    ).thenAnswer((_) async => const Result.success(null));
  });

  ReviewBloc buildBloc() => ReviewBloc(
    repository: repository,
    bookingLookup: bookingLookup,
    vehicleLookup: vehicleLookup,
    userLookup: userLookup,
    session: session,
  );

  group('ReviewBloc', () {
    test('initial state has ReviewStatus.initial', () {
      expect(buildBloc().state.status, ReviewStatus.initial);
    });

    blocTest<ReviewBloc, ReviewState>(
      'ReviewStarted loads booking, participants and existing reviews successfully',
      build: buildBloc,
      act: (bloc) => bloc.add(const ReviewStarted('booking_1')),
      expect: () => [
        predicate<ReviewState>((s) => s.status == ReviewStatus.loading),
        predicate<ReviewState>(
          (s) =>
              s.status == ReviewStatus.ready &&
              s.booking == testBooking &&
              s.vehicle == testVehicle &&
              s.otherUser == testOwner &&
              s.isRenter == true,
        ),
      ],
    );

    blocTest<ReviewBloc, ReviewState>(
      'ReviewStarsChanged updates stars for specified subject and clears error',
      build: buildBloc,
      seed: () => const ReviewState(isRenter: true, ownerStarsError: 'Error'),
      act: (bloc) => bloc.add(
        const ReviewStarsChanged(subjectType: SubjectType.user, stars: 5),
      ),
      expect: () => [
        predicate<ReviewState>(
          (s) => s.ownerStars == 5 && s.ownerStarsError == null,
        ),
      ],
    );

    blocTest<ReviewBloc, ReviewState>(
      'ReviewCommentChanged updates comment and clears error',
      build: buildBloc,
      seed: () => const ReviewState(isRenter: true, ownerCommentError: 'Error'),
      act: (bloc) => bloc.add(
        const ReviewCommentChanged(
          subjectType: SubjectType.user,
          comment: 'Great host!',
        ),
      ),
      expect: () => [
        predicate<ReviewState>(
          (s) => s.ownerComment == 'Great host!' && s.ownerCommentError == null,
        ),
      ],
    );

    blocTest<ReviewBloc, ReviewState>(
      'ReviewSubmitted validates mandatory stars and non-empty comment',
      build: buildBloc,
      seed: () => ReviewState(
        status: ReviewStatus.ready,
        booking: testBooking,
        isRenter: true,
        ownerStars: 0,
        ownerComment: '',
      ),
      act: (bloc) => bloc.add(const ReviewSubmitted(SubjectType.user)),
      expect: () => [
        predicate<ReviewState>(
          (s) =>
              s.ownerStarsError == 'Please select a star rating.' &&
              s.ownerCommentError == 'Please enter a review comment.',
        ),
      ],
    );

    blocTest<ReviewBloc, ReviewState>(
      'ReviewSubmitted submits review and updates state on success',
      setUp: () {
        when(
          () => repository.submitReview(
            bookingId: 'booking_1',
            authorId: 'renter-1',
            subjectType: SubjectType.user,
            subjectId: 'owner-1',
            stars: 5,
            comment: 'Super polite owner!',
          ),
        ).thenAnswer(
          (_) async => Result.success(
            Review(
              id: 'r1',
              bookingId: 'booking_1',
              authorId: 'renter-1',
              subjectType: SubjectType.user,
              subjectId: 'owner-1',
              stars: 5,
              comment: 'Super polite owner!',
              createdAt: DateTime.now(),
              editedAt: null,
            ),
          ),
        );
      },
      build: buildBloc,
      seed: () => ReviewState(
        status: ReviewStatus.ready,
        booking: testBooking,
        isRenter: true,
        ownerStars: 5,
        ownerComment: 'Super polite owner!',
      ),
      act: (bloc) => bloc.add(const ReviewSubmitted(SubjectType.user)),
      expect: () => [
        predicate<ReviewState>((s) => s.status == ReviewStatus.submitting),
        predicate<ReviewState>(
          (s) =>
              s.status == ReviewStatus.success &&
              s.ownerExistingReview != null &&
              s.successMessage == 'Review for owner submitted.',
        ),
      ],
    );

    blocTest<ReviewBloc, ReviewState>(
      'ReviewSubmitted emits failure when repository returns an error',
      setUp: () {
        when(
          () => repository.submitReview(
            bookingId: 'booking_1',
            authorId: 'renter-1',
            subjectType: SubjectType.user,
            subjectId: 'owner-1',
            stars: 5,
            comment: 'Nice car',
          ),
        ).thenAnswer(
          (_) async => const Result.failure(UnknownFailure('Network issue')),
        );
      },
      build: buildBloc,
      seed: () => ReviewState(
        status: ReviewStatus.ready,
        booking: testBooking,
        isRenter: true,
        ownerStars: 5,
        ownerComment: 'Nice car',
      ),
      act: (bloc) => bloc.add(const ReviewSubmitted(SubjectType.user)),
      expect: () => [
        predicate<ReviewState>((s) => s.status == ReviewStatus.submitting),
        predicate<ReviewState>(
          (s) =>
              s.status == ReviewStatus.failure && s.failure is UnknownFailure,
        ),
      ],
    );
  });
}
