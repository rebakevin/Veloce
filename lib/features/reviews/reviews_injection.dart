import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

import 'package:veloce/core/data/services/booking_lookup.dart';
import 'package:veloce/core/data/services/user_lookup.dart';
import 'package:veloce/core/data/services/vehicle_lookup.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/domain/services/pending_review_checker.dart';

import 'data/firestore_pending_review_checker.dart';
import 'data/repositories/firestore_review_repository.dart';
import 'domain/repositories/review_repository.dart';
import 'presentation/bloc/my_reviews_cubit.dart';
import 'presentation/bloc/review_bloc.dart';

void registerReviews(GetIt getIt) {
  getIt
    ..registerLazySingleton<ReviewRepository>(
      () => FirestoreReviewRepository(
        firestore: getIt<FirebaseFirestore>(),
        clock: getIt<Clock>(),
      ),
    )
    ..registerLazySingleton<PendingReviewChecker>(
      () =>
          FirestorePendingReviewChecker(firestore: getIt<FirebaseFirestore>()),
    )
    ..registerFactory<ReviewBloc>(
      () => ReviewBloc(
        repository: getIt(),
        bookingLookup: getIt<BookingLookup>(),
        vehicleLookup: getIt<VehicleLookup>(),
        userLookup: getIt<UserLookup>(),
        session: getIt<AuthSession>(),
      ),
    )
    ..registerFactory<MyReviewsCubit>(
      () => MyReviewsCubit(
        repository: getIt(),
        userLookup: getIt(),
        vehicleLookup: getIt(),
        session: getIt(),
      ),
    );
}
