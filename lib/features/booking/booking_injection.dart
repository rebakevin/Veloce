import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

import 'package:veloce/core/domain/services/booking_state_machine.dart';
import 'package:veloce/core/domain/services/momo_gateway.dart';

import 'data/firestore_booking_repository.dart';
import 'domain/repositories/booking_repository.dart';
import 'domain/services/booking_overlap.dart';
import 'domain/services/cancellation_policy.dart';
import 'domain/services/expiry_engine.dart';
import 'domain/usecases/acknowledge_agreement.dart';
import 'domain/usecases/approve_booking.dart';
import 'domain/usecases/cancel_booking.dart';
import 'domain/usecases/decline_booking.dart';
import 'domain/usecases/expire_bookings.dart';
import 'domain/usecases/pay_booking.dart';

/// Registers the booking feature's dependencies. Owned by Phase 4.
void registerBooking(GetIt getIt) {
  getIt
    ..registerLazySingleton<BookingOverlap>(() => const BookingOverlap())
    ..registerLazySingleton<ExpiryEngine>(() => const ExpiryEngine())
    ..registerLazySingleton<CancellationPolicy>(
      () => const CancellationPolicy(),
    )
    ..registerLazySingleton<BookingRepository>(
      () => FirestoreBookingRepository(
        firestore: getIt<FirebaseFirestore>(),
        writes: getIt(),
        users: getIt(),
        vehicles: getIt(),
        ledger: getIt(),
        audit: getIt(),
        notifications: getIt(),
        momo: getIt<MomoGateway>(),
        pendingReviews: getIt(),
        session: getIt(),
        clock: getIt(),
        stateMachine: getIt<BookingStateMachine>(),
        overlap: getIt(),
        expiry: getIt(),
        cancellation: getIt(),
      ),
    )
    ..registerLazySingleton<ApproveBooking>(() => ApproveBooking(getIt()))
    ..registerLazySingleton<DeclineBooking>(() => DeclineBooking(getIt()))
    ..registerLazySingleton<CancelBooking>(
      () => CancelBooking(getIt(), getIt()),
    )
    ..registerLazySingleton<PayBooking>(() => PayBooking(getIt(), getIt()))
    ..registerLazySingleton<AcknowledgeAgreement>(
      () => AcknowledgeAgreement(getIt()),
    )
    ..registerLazySingleton<ExpireBookings>(() => ExpireBookings(getIt()));
}
