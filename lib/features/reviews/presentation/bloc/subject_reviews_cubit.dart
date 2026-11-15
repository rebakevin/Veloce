import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:veloce/core/data/services/user_lookup.dart';
import 'package:veloce/core/data/services/vehicle_lookup.dart';
import 'package:veloce/core/domain/entities/review.dart';
import 'package:veloce/core/domain/entities/user_account.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/enums/subject_type.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../../domain/repositories/review_repository.dart';

class ReviewItemData extends Equatable {
  const ReviewItemData({
    required this.review,
    this.authorName,
    this.authorPhotoUrl,
    this.subjectTitle,
  });

  final Review review;
  final String? authorName;
  final String? authorPhotoUrl;
  final String? subjectTitle;

  @override
  List<Object?> get props => [review, authorName, authorPhotoUrl, subjectTitle];
}

sealed class SubjectReviewsState extends Equatable {
  const SubjectReviewsState();

  @override
  List<Object?> get props => [];
}

final class SubjectReviewsLoading extends SubjectReviewsState {
  const SubjectReviewsLoading();
}

final class SubjectReviewsLoaded extends SubjectReviewsState {
  const SubjectReviewsLoaded({required this.reviews, this.vehicle, this.user});

  final List<ReviewItemData> reviews;
  final Vehicle? vehicle;
  final UserAccount? user;

  @override
  List<Object?> get props => [reviews, vehicle, user];
}

final class SubjectReviewsEmpty extends SubjectReviewsState {
  const SubjectReviewsEmpty({this.vehicle, this.user});

  final Vehicle? vehicle;
  final UserAccount? user;

  @override
  List<Object?> get props => [vehicle, user];
}

final class SubjectReviewsFailure extends SubjectReviewsState {
  const SubjectReviewsFailure(this.error);

  final AppFailure error;

  @override
  List<Object?> get props => [error];
}

class SubjectReviewsCubit extends Cubit<SubjectReviewsState> {
  SubjectReviewsCubit({
    required ReviewRepository repository,
    required VehicleLookup vehicleLookup,
    required UserLookup userLookup,
    required SubjectType subjectType,
    required String subjectId,
  }) : _repository = repository,
       _vehicleLookup = vehicleLookup,
       _userLookup = userLookup,
       _subjectType = subjectType,
       _subjectId = subjectId,
       super(const SubjectReviewsLoading());

  final ReviewRepository _repository;
  final VehicleLookup _vehicleLookup;
  final UserLookup _userLookup;
  final SubjectType _subjectType;
  final String _subjectId;

  Future<void> load() async {
    emit(const SubjectReviewsLoading());

    Vehicle? vehicle;
    UserAccount? user;

    if (_subjectType == SubjectType.vehicle) {
      vehicle = (await _vehicleLookup.byId(_subjectId)).valueOrNull;
    } else {
      user = (await _userLookup.byId(_subjectId)).valueOrNull;
    }

    final result = await _repository.getReviewsForSubject(
      subjectType: _subjectType,
      subjectId: _subjectId,
    );

    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        if (value.isEmpty) {
          emit(SubjectReviewsEmpty(vehicle: vehicle, user: user));
          return;
        }

        final items = <ReviewItemData>[];
        for (final review in value) {
          final author = (await _userLookup.byId(review.authorId)).valueOrNull;
          items.add(
            ReviewItemData(
              review: review,
              authorName: author?.name,
              authorPhotoUrl: author?.photoUrl,
            ),
          );
        }

        if (isClosed) return;
        emit(
          SubjectReviewsLoaded(reviews: items, vehicle: vehicle, user: user),
        );
      case Failure(:final failure):
        emit(SubjectReviewsFailure(failure));
    }
  }
}
