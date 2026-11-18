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
import 'presentation/bloc/activity_bloc.dart';
import 'presentation/bloc/booking_detail_bloc.dart';
import 'presentation/bloc/decision_bloc.dart';
import 'presentation/bloc/expiry_sweeper_cubit.dart';
import 'presentation/bloc/payment_bloc.dart';

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
    ..registerLazySingleton<ExpireBookings>(() => ExpireBookings(getIt()))
    ..registerFactory<ActivityBloc>(
      () => ActivityBloc(
        repository: getIt(),
        cancelBooking: getIt(),
        expireBookings: getIt(),
        session: getIt(),
      ),
    )
    ..registerFactoryParam<BookingDetailBloc, String, void>(
      (bookingId, _) => BookingDetailBloc(
        bookingId: bookingId,
        repository: getIt(),
        cancelBooking: getIt(),
        acknowledgeAgreement: getIt(),
        session: getIt(),
      ),
    )
    ..registerFactoryParam<DecisionBloc, String, void>(
      (bookingId, _) => DecisionBloc(
        bookingId: bookingId,
        repository: getIt(),
        approve: getIt(),
        decline: getIt(),
        session: getIt(),
      ),
    )
    ..registerFactoryParam<PaymentBloc, String, void>(
      (bookingId, _) => PaymentBloc(
        bookingId: bookingId,
        repository: getIt(),
        pay: getIt(),
        session: getIt(),
      ),
    )
    ..registerFactory<ExpirySweeperCubit>(
      () => ExpirySweeperCubit(expireBookings: getIt(), session: getIt()),
    );
}
