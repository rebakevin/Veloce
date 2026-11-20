import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/domain/entities/booking_contact.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/checklist_side.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/booking/presentation/bloc/booking_detail_bloc.dart';

import '../../support/booking_test_data.dart';

void main() {
  late MockAuthSession session;
  late MockBookingRepository repository;
  late MockCancelBooking cancelBooking;
  late MockAcknowledgeAgreement acknowledgeAgreement;

  final approved = bookingView(status: BookingStatus.approved);
  final confirmed = bookingView(status: BookingStatus.confirmed);
  const contact = BookingContact(
    side: ChecklistSide.owner,
    bookingId: 'booking-1',
    phone: '0788123456',
    email: 'owner@example.com',
    meetingPoint: 'Kacyiru roundabout',
  );

  BookingDetailBloc build() => BookingDetailBloc(
    bookingId: 'booking-1',
    repository: repository,
    cancelBooking: cancelBooking,
    acknowledgeAgreement: acknowledgeAgreement,
    session: session,
  );

  setUpAll(() => registerFallbackValue(approved));

  setUp(() {
    session = MockAuthSession();
    repository = MockBookingRepository();
    cancelBooking = MockCancelBooking();
    acknowledgeAgreement = MockAcknowledgeAgreement();
    when(() => session.role).thenReturn(UserRole.renter);
    when(() => session.currentUserId).thenReturn('renter-1');
  });

  blocTest<BookingDetailBloc, BookingDetailState>(
    'a paid booking loads the contact',
    setUp: () {
      when(() => repository.watchBooking('booking-1'))
          .thenAnswer((_) => Stream.value(Result.success(confirmed)));
      when(() => repository.getCounterpartyContact('booking-1'))
          .thenAnswer((_) async => const Result.success(contact));
    },
    build: build,
    act: (bloc) => bloc.add(const BookingDetailStarted()),
    expect: () => [
      const BookingDetailLoading(),
      isA<BookingDetailLoaded>()
          .having((state) => state.role, 'role', UserRole.renter)
          .having((state) => state.contact, 'contact', contact),
    ],
  );

  blocTest<BookingDetailBloc, BookingDetailState>(
    'an unpaid booking never reads the contact document',
    setUp: () {
      when(() => repository.watchBooking('booking-1'))
          .thenAnswer((_) => Stream.value(Result.success(approved)));
    },
    build: build,
    act: (bloc) => bloc.add(const BookingDetailStarted()),
    expect: () => [
      const BookingDetailLoading(),
      isA<BookingDetailLoaded>().having(
        (state) => state.contact,
        'contact',
        isNull,
      ),
    ],
    verify: (_) {
      verifyNever(() => repository.getCounterpartyContact(any()));
    },
  );

  blocTest<BookingDetailBloc, BookingDetailState>(
    'a failed contact read is surfaced without hiding the booking',
    setUp: () {
      when(() => repository.watchBooking('booking-1'))
          .thenAnswer((_) => Stream.value(Result.success(confirmed)));
      when(() => repository.getCounterpartyContact('booking-1'))
          .thenAnswer((_) async => const Result.failure(NetworkFailure()));
    },
    build: build,
    act: (bloc) => bloc.add(const BookingDetailStarted()),
    expect: () => [
      const BookingDetailLoading(),
      isA<BookingDetailLoaded>()
          .having((state) => state.contact, 'contact', isNull)
          .having(
            (state) => state.action.status,
            'status',
            BookingDetailActionStatus.failure,
          ),
    ],
  );

  blocTest<BookingDetailBloc, BookingDetailState>(
    'cancelling reports success',
    setUp: () {
      when(() => cancelBooking(approved, reason: null))
          .thenAnswer((_) async => const Result.success(null));
    },
    build: build,
    seed: () => BookingDetailLoaded(view: approved, role: UserRole.renter),
    act: (bloc) => bloc.add(const BookingDetailCancelRequested()),
    expect: () => [
      isA<BookingDetailLoaded>().having(
        (state) => state.action.status,
        'status',
        BookingDetailActionStatus.submitting,
      ),
      isA<BookingDetailLoaded>().having(
        (state) => state.action.status,
        'status',
        BookingDetailActionStatus.success,
      ),
    ],
  );

  blocTest<BookingDetailBloc, BookingDetailState>(
    'acknowledging the agreement reports a failure message',
    setUp: () {
      when(() => acknowledgeAgreement('booking-1')).thenAnswer(
        (_) async => const Result.failure(
          ConflictFailure('The agreement opens after approval.'),
        ),
      );
    },
    build: build,
    seed: () => BookingDetailLoaded(view: confirmed, role: UserRole.renter),
    act: (bloc) => bloc.add(const BookingDetailAgreementAcknowledged()),
    expect: () => [
      isA<BookingDetailLoaded>(),
      isA<BookingDetailLoaded>()
          .having(
            (state) => state.action.status,
            'status',
            BookingDetailActionStatus.failure,
          )
          .having(
            (state) => state.action.message,
            'message',
            'The agreement opens after approval.',
          ),
    ],
  );
}
