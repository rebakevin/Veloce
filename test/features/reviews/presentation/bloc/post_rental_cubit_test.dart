import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/data/services/booking_lookup.dart';
import 'package:veloce/core/data/services/user_lookup.dart';
import 'package:veloce/core/data/services/vehicle_lookup.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/subject_type.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/reviews/domain/repositories/review_repository.dart';
import 'package:veloce/features/reviews/presentation/bloc/post_rental_cubit.dart';

import '../../../../support/builders.dart';

class _MockReviewRepository extends Mock implements ReviewRepository {}

class _MockBookingLookup extends Mock implements BookingLookup {}

class _MockVehicleLookup extends Mock implements VehicleLookup {}

class _MockUserLookup extends Mock implements UserLookup {}

class _MockAuthSession extends Mock implements AuthSession {}

void main() {
  setUpAll(() => registerFallbackValue(SubjectType.user));

  late _MockReviewRepository repository;
  late _MockBookingLookup bookingLookup;
  late _MockAuthSession session;
  late (_MockUserLookup, _MockVehicleLookup) cubitDeps;

  setUp(() {
    repository = _MockReviewRepository();
    bookingLookup = _MockBookingLookup();
    session = _MockAuthSession();
    when(() => session.currentUserId).thenReturn('renter-1');
    when(
      () => repository.getReview(
        bookingId: any(named: 'bookingId'),
        authorId: any(named: 'authorId'),
        subjectType: any(named: 'subjectType'),
      ),
    ).thenAnswer((_) async => const Result.success(null));
    final userLookup = _MockUserLookup();
    final vehicleLookup = _MockVehicleLookup();
    when(() => userLookup.byId(any()))
        .thenAnswer((_) async => Result.success(aUser()));
    when(() => vehicleLookup.byId(any()))
        .thenAnswer((_) async => Result.success(aVehicle()));
    cubitDeps = (userLookup, vehicleLookup);
  });

  PostRentalCubit build() => PostRentalCubit(
    repository: repository,
    bookingLookup: bookingLookup,
    userLookup: cubitDeps.$1,
    vehicleLookup: cubitDeps.$2,
    session: session,
    bookingId: 'booking_1',
  );

  test('a completed booking with a pending review loads', () async {
    when(() => bookingLookup.byId('booking_1')).thenAnswer(
      (_) async => Result.success(
        aBooking(id: 'booking_1', status: BookingStatus.completed),
      ),
    );

    final cubit = build();
    await cubit.load();

    expect(cubit.state, isA<PostRentalLoaded>());
    expect((cubit.state as PostRentalLoaded).hasPendingReview, isTrue);
  });

  test('hidden when the booking is not completed', () async {
    when(() => bookingLookup.byId('booking_1')).thenAnswer(
      (_) async => Result.success(
        aBooking(id: 'booking_1', status: BookingStatus.active),
      ),
    );

    final cubit = build();
    await cubit.load();

    expect(cubit.state, isA<PostRentalHidden>());
  });
}
