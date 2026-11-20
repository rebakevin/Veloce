import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:veloce/core/data/services/user_lookup.dart';
import 'package:veloce/core/data/services/vehicle_lookup.dart';
import 'package:veloce/core/domain/enums/subject_type.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../../domain/repositories/review_repository.dart';
import 'subject_reviews_cubit.dart';

sealed class MyReviewsState extends Equatable {
  const MyReviewsState();

  @override
  List<Object?> get props => [];
}

final class MyReviewsLoading extends MyReviewsState {
  const MyReviewsLoading();
}

final class MyReviewsLoaded extends MyReviewsState {
  const MyReviewsLoaded(this.reviews);

  final List<ReviewItemData> reviews;

  @override
  List<Object?> get props => [reviews];
}

final class MyReviewsEmpty extends MyReviewsState {
  const MyReviewsEmpty();
}

final class MyReviewsFailure extends MyReviewsState {
  const MyReviewsFailure(this.error);

  final AppFailure error;

  @override
  List<Object?> get props => [error];
}

class MyReviewsCubit extends Cubit<MyReviewsState> {
  MyReviewsCubit({
    required this._repository,
    required this._userLookup,
    required this._vehicleLookup,
    required this._session,
  }) : super(const MyReviewsLoading());

  final ReviewRepository _repository;
  final UserLookup _userLookup;
  final VehicleLookup _vehicleLookup;
  final AuthSession _session;

  Future<void> load() async {
    final currentUserId = _session.currentUserId;
    if (currentUserId == null) {
      emit(const MyReviewsFailure(PermissionFailure('You must be signed in.')));
      return;
    }

    emit(const MyReviewsLoading());
    final result = await _repository.getReviewsByAuthor(currentUserId);
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        if (value.isEmpty) {
          emit(const MyReviewsEmpty());
          return;
        }

        final items = <ReviewItemData>[];
        for (final review in value) {
          String? title;
          if (review.subjectType == SubjectType.user) {
            final user = (await _userLookup.byId(review.subjectId)).valueOrNull;
            title = user != null ? 'For ${user.name}' : 'User review';
          } else {
            final vehicle = (await _vehicleLookup.byId(review.subjectId))
                .valueOrNull;
            title = vehicle != null
                ? 'For ${vehicle.make} ${vehicle.model}'
                : 'Vehicle review';
          }
          items.add(ReviewItemData(review: review, subjectTitle: title));
        }

        if (isClosed) return;
        emit(MyReviewsLoaded(items));
      case Failure(:final failure):
        emit(MyReviewsFailure(failure));
    }
  }
}
