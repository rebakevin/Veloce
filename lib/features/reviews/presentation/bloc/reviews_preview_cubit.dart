import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:veloce/core/data/services/user_lookup.dart';
import 'package:veloce/core/domain/entities/review.dart';
import 'package:veloce/core/domain/enums/subject_type.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../../domain/repositories/review_repository.dart';

class ReviewPreviewItem extends Equatable {
  const ReviewPreviewItem({
    required this.review,
    this.authorName,
    this.authorPhotoUrl,
  });

  final Review review;
  final String? authorName;
  final String? authorPhotoUrl;

  @override
  List<Object?> get props => [review, authorName, authorPhotoUrl];
}

sealed class ReviewsPreviewState extends Equatable {
  const ReviewsPreviewState();

  @override
  List<Object?> get props => [];
}

final class ReviewsPreviewLoading extends ReviewsPreviewState {
  const ReviewsPreviewLoading();
}

final class ReviewsPreviewLoaded extends ReviewsPreviewState {
  const ReviewsPreviewLoaded({
    required this.items,
    required this.totalCount,
    required this.averageRating,
    required this.userId,
  });

  final List<ReviewPreviewItem> items;
  final int totalCount;
  final double averageRating;
  final String userId;

  @override
  List<Object?> get props => [items, totalCount, averageRating, userId];
}

final class ReviewsPreviewEmpty extends ReviewsPreviewState {
  const ReviewsPreviewEmpty();
}

final class ReviewsPreviewFailure extends ReviewsPreviewState {
  const ReviewsPreviewFailure(this.error);

  final AppFailure error;

  @override
  List<Object?> get props => [error];
}

class ReviewsPreviewCubit extends Cubit<ReviewsPreviewState> {
  ReviewsPreviewCubit({
    required this._repository,
    required this._userLookup,
    required this._userId,
  }) : super(const ReviewsPreviewLoading());

  final ReviewRepository _repository;
  final UserLookup _userLookup;
  final String _userId;

  static const int _previewCount = 3;

  Future<void> load() async {
    emit(const ReviewsPreviewLoading());

    final result = await _repository.getReviewsForSubject(
      subjectType: SubjectType.user,
      subjectId: _userId,
    );

    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        if (value.isEmpty) {
          emit(const ReviewsPreviewEmpty());
          return;
        }

        final totalCount = value.length;
        final averageRating = value.isEmpty
            ? 0.0
            : value.fold<int>(0, (sum, r) => sum + r.stars) / totalCount;
        final roundedAvg = (averageRating * 10).round() / 10.0;

        final preview = value.take(_previewCount).toList();
        final items = <ReviewPreviewItem>[];

        for (final review in preview) {
          final authorRes = await _userLookup.byId(review.authorId);
          final author = authorRes.valueOrNull;
          items.add(
            ReviewPreviewItem(
              review: review,
              authorName: author?.name,
              authorPhotoUrl: author?.photoUrl,
            ),
          );
        }

        if (isClosed) return;
        emit(
          ReviewsPreviewLoaded(
            items: items,
            totalCount: totalCount,
            averageRating: roundedAvg,
            userId: _userId,
          ),
        );

      case Failure(:final failure):
        emit(ReviewsPreviewFailure(failure));
    }
  }
}
