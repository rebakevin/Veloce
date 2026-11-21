import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:veloce/core/data/services/booking_lookup.dart';
import 'package:veloce/core/data/services/user_lookup.dart';
import 'package:veloce/core/data/services/vehicle_lookup.dart';
import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/entities/review.dart';
import 'package:veloce/core/domain/entities/user_account.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/subject_type.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../../domain/repositories/review_repository.dart';

enum ReviewStatus { initial, loading, ready, submitting, success, failure }

sealed class ReviewEvent extends Equatable {
  const ReviewEvent();

  @override
  List<Object?> get props => [];
}

final class ReviewStarted extends ReviewEvent {
  const ReviewStarted(this.bookingId);

  final String bookingId;

  @override
  List<Object?> get props => [bookingId];
}

final class ReviewSubjectChanged extends ReviewEvent {
  const ReviewSubjectChanged(this.subjectType);

  final SubjectType subjectType;

  @override
  List<Object?> get props => [subjectType];
}

final class ReviewStarsChanged extends ReviewEvent {
  const ReviewStarsChanged({required this.subjectType, required this.stars});

  final SubjectType subjectType;
  final int stars;

  @override
  List<Object?> get props => [subjectType, stars];
}

final class ReviewCommentChanged extends ReviewEvent {
  const ReviewCommentChanged({
    required this.subjectType,
    required this.comment,
  });

  final SubjectType subjectType;
  final String comment;

  @override
  List<Object?> get props => [subjectType, comment];
}

final class ReviewSubmitted extends ReviewEvent {
  const ReviewSubmitted(this.subjectType);

  final SubjectType subjectType;

  @override
  List<Object?> get props => [subjectType];
}

class ReviewState extends Equatable {
  const ReviewState({
    this.status = ReviewStatus.initial,
    this.booking,
    this.vehicle,
    this.otherUser,
    this.isRenter = true,
    this.activeSubject = SubjectType.user,
    this.ownerStars = 0,
    this.ownerComment = '',
    this.ownerExistingReview,
    this.ownerStarsError,
    this.ownerCommentError,
    this.vehicleStars = 0,
    this.vehicleComment = '',
    this.vehicleExistingReview,
    this.vehicleStarsError,
    this.vehicleCommentError,
    this.renterStars = 0,
    this.renterComment = '',
    this.renterExistingReview,
    this.renterStarsError,
    this.renterCommentError,
    this.failure,
    this.successMessage,
  });

  final ReviewStatus status;
  final Booking? booking;
  final Vehicle? vehicle;
  final UserAccount? otherUser;
  final bool isRenter;
  final SubjectType activeSubject;

  // Renter -> Owner fields
  final int ownerStars;
  final String ownerComment;
  final Review? ownerExistingReview;
  final String? ownerStarsError;
  final String? ownerCommentError;

  // Renter -> Vehicle fields
  final int vehicleStars;
  final String vehicleComment;
  final Review? vehicleExistingReview;
  final String? vehicleStarsError;
  final String? vehicleCommentError;

  // Owner -> Renter fields
  final int renterStars;
  final String renterComment;
  final Review? renterExistingReview;
  final String? renterStarsError;
  final String? renterCommentError;

  final AppFailure? failure;
  final String? successMessage;

  ReviewState copyWith({
    ReviewStatus? status,
    Booking? booking,
    Vehicle? vehicle,
    UserAccount? otherUser,
    bool? isRenter,
    SubjectType? activeSubject,
    int? ownerStars,
    String? ownerComment,
    Review? ownerExistingReview,
    String? ownerStarsError,
    bool clearOwnerStarsError = false,
    String? ownerCommentError,
    bool clearOwnerCommentError = false,
    int? vehicleStars,
    String? vehicleComment,
    Review? vehicleExistingReview,
    String? vehicleStarsError,
    bool clearVehicleStarsError = false,
    String? vehicleCommentError,
    bool clearVehicleCommentError = false,
    int? renterStars,
    String? renterComment,
    Review? renterExistingReview,
    String? renterStarsError,
    bool clearRenterStarsError = false,
    String? renterCommentError,
    bool clearRenterCommentError = false,
    AppFailure? failure,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return ReviewState(
      status: status ?? this.status,
      booking: booking ?? this.booking,
      vehicle: vehicle ?? this.vehicle,
      otherUser: otherUser ?? this.otherUser,
      isRenter: isRenter ?? this.isRenter,
      activeSubject: activeSubject ?? this.activeSubject,
      ownerStars: ownerStars ?? this.ownerStars,
      ownerComment: ownerComment ?? this.ownerComment,
      ownerExistingReview: ownerExistingReview ?? this.ownerExistingReview,
      ownerStarsError: clearOwnerStarsError
          ? null
          : (ownerStarsError ?? this.ownerStarsError),
      ownerCommentError: clearOwnerCommentError
          ? null
          : (ownerCommentError ?? this.ownerCommentError),
      vehicleStars: vehicleStars ?? this.vehicleStars,
      vehicleComment: vehicleComment ?? this.vehicleComment,
      vehicleExistingReview:
          vehicleExistingReview ?? this.vehicleExistingReview,
      vehicleStarsError: clearVehicleStarsError
          ? null
          : (vehicleStarsError ?? this.vehicleStarsError),
      vehicleCommentError: clearVehicleCommentError
          ? null
          : (vehicleCommentError ?? this.vehicleCommentError),
      renterStars: renterStars ?? this.renterStars,
      renterComment: renterComment ?? this.renterComment,
      renterExistingReview: renterExistingReview ?? this.renterExistingReview,
      renterStarsError: clearRenterStarsError
          ? null
          : (renterStarsError ?? this.renterStarsError),
      renterCommentError: clearRenterCommentError
          ? null
          : (renterCommentError ?? this.renterCommentError),
      failure: failure,
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    booking,
    vehicle,
    otherUser,
    isRenter,
    activeSubject,
    ownerStars,
    ownerComment,
    ownerExistingReview,
    ownerStarsError,
    ownerCommentError,
    vehicleStars,
    vehicleComment,
    vehicleExistingReview,
    vehicleStarsError,
    vehicleCommentError,
    renterStars,
    renterComment,
    renterExistingReview,
    renterStarsError,
    renterCommentError,
    failure,
    successMessage,
  ];
}

class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  ReviewBloc({
    required this._repository,
    required this._bookingLookup,
    required this._vehicleLookup,
    required this._userLookup,
    required this._session,
  }) : super(const ReviewState()) {
    on<ReviewStarted>(_onStarted);
    on<ReviewSubjectChanged>(_onSubjectChanged);
    on<ReviewStarsChanged>(_onStarsChanged);
    on<ReviewCommentChanged>(_onCommentChanged);
    on<ReviewSubmitted>(_onSubmitted);
  }

  final ReviewRepository _repository;
  final BookingLookup _bookingLookup;
  final VehicleLookup _vehicleLookup;
  final UserLookup _userLookup;
  final AuthSession _session;

  Future<void> _onStarted(
    ReviewStarted event,
    Emitter<ReviewState> emit,
  ) async {
    emit(state.copyWith(status: ReviewStatus.loading));

    final booking = (await _bookingLookup.byId(event.bookingId)).valueOrNull;
    if (booking == null) {
      emit(
        state.copyWith(
          status: ReviewStatus.failure,
          failure: const NotFoundFailure('Booking not found.'),
        ),
      );
      return;
    }

    final currentUserId = _session.currentUserId;
    final failure = _reviewAccessFailure(booking, currentUserId);
    if (failure != null) {
      emit(state.copyWith(status: ReviewStatus.failure, failure: failure));
      return;
    }
    final isRenter = currentUserId == booking.renterId;
    final otherUserId = isRenter ? booking.ownerId : booking.renterId;

    final vehicle = (await _vehicleLookup.byId(booking.vehicleId)).valueOrNull;
    final otherUser = (await _userLookup.byId(otherUserId)).valueOrNull;

    Review? ownerReview;
    Review? vehicleReview;
    Review? renterReview;

    if (isRenter) {
      final ownerRes = await _repository.getReview(
        bookingId: booking.id,
        authorId: currentUserId ?? '',
        subjectType: SubjectType.user,
      );
      if (ownerRes is Success<Review?>) {
        ownerReview = ownerRes.value;
      }

      final vehicleRes = await _repository.getReview(
        bookingId: booking.id,
        authorId: currentUserId ?? '',
        subjectType: SubjectType.vehicle,
      );
      if (vehicleRes is Success<Review?>) {
        vehicleReview = vehicleRes.value;
      }
    } else {
      final renterRes = await _repository.getReview(
        bookingId: booking.id,
        authorId: currentUserId ?? '',
        subjectType: SubjectType.user,
      );
      if (renterRes is Success<Review?>) {
        renterReview = renterRes.value;
      }
    }

    SubjectType activeSubject = SubjectType.user;
    if (isRenter && ownerReview != null && vehicleReview == null) {
      activeSubject = SubjectType.vehicle;
    }

    emit(
      state.copyWith(
        status: ReviewStatus.ready,
        booking: booking,
        vehicle: vehicle,
        otherUser: otherUser,
        isRenter: isRenter,
        activeSubject: activeSubject,
        ownerExistingReview: ownerReview,
        ownerStars: ownerReview?.stars ?? 0,
        ownerComment: ownerReview?.comment ?? '',
        vehicleExistingReview: vehicleReview,
        vehicleStars: vehicleReview?.stars ?? 0,
        vehicleComment: vehicleReview?.comment ?? '',
        renterExistingReview: renterReview,
        renterStars: renterReview?.stars ?? 0,
        renterComment: renterReview?.comment ?? '',
      ),
    );
  }

  /// Only a party of a completed booking may write a review.
  static AppFailure? _reviewAccessFailure(Booking booking, String? userId) {
    if (userId == null ||
        (userId != booking.renterId && userId != booking.ownerId)) {
      return const PermissionFailure(
        'Only the renter or the owner can review this booking.',
      );
    }
    if (booking.status != BookingStatus.completed) {
      return const ValidationFailure(
        'You can review a booking once it is completed.',
      );
    }
    return null;
  }

  void _onSubjectChanged(
    ReviewSubjectChanged event,
    Emitter<ReviewState> emit,
  ) {
    emit(state.copyWith(activeSubject: event.subjectType));
  }

  void _onStarsChanged(ReviewStarsChanged event, Emitter<ReviewState> emit) {
    if (state.isRenter) {
      if (event.subjectType == SubjectType.user) {
        emit(
          state.copyWith(ownerStars: event.stars, clearOwnerStarsError: true),
        );
      } else {
        emit(
          state.copyWith(
            vehicleStars: event.stars,
            clearVehicleStarsError: true,
          ),
        );
      }
    } else {
      emit(
        state.copyWith(renterStars: event.stars, clearRenterStarsError: true),
      );
    }
  }

  void _onCommentChanged(
    ReviewCommentChanged event,
    Emitter<ReviewState> emit,
  ) {
    if (state.isRenter) {
      if (event.subjectType == SubjectType.user) {
        emit(
          state.copyWith(
            ownerComment: event.comment,
            clearOwnerCommentError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            vehicleComment: event.comment,
            clearVehicleCommentError: true,
          ),
        );
      }
    } else {
      emit(
        state.copyWith(
          renterComment: event.comment,
          clearRenterCommentError: true,
        ),
      );
    }
  }

  Future<void> _onSubmitted(
    ReviewSubmitted event,
    Emitter<ReviewState> emit,
  ) async {
    final booking = state.booking;
    final currentUserId = _session.currentUserId;
    if (booking == null || currentUserId == null) return;
    final accessFailure = _reviewAccessFailure(booking, currentUserId);
    if (accessFailure != null) {
      emit(
        state.copyWith(status: ReviewStatus.failure, failure: accessFailure),
      );
      return;
    }

    final SubjectType subjectType = event.subjectType;
    final int stars;
    final String comment;
    final String subjectId;

    if (state.isRenter) {
      if (subjectType == SubjectType.user) {
        stars = state.ownerStars;
        comment = state.ownerComment.trim();
        subjectId = booking.ownerId;
      } else {
        stars = state.vehicleStars;
        comment = state.vehicleComment.trim();
        subjectId = booking.vehicleId;
      }
    } else {
      stars = state.renterStars;
      comment = state.renterComment.trim();
      subjectId = booking.renterId;
    }

    bool hasError = false;
    String? starsError;
    String? commentError;

    if (stars < 1 || stars > 5) {
      starsError = 'Please select a star rating.';
      hasError = true;
    }
    if (comment.isEmpty) {
      commentError = 'Please enter a review comment.';
      hasError = true;
    }

    if (hasError) {
      if (state.isRenter) {
        if (subjectType == SubjectType.user) {
          emit(
            state.copyWith(
              ownerStarsError: starsError,
              ownerCommentError: commentError,
            ),
          );
        } else {
          emit(
            state.copyWith(
              vehicleStarsError: starsError,
              vehicleCommentError: commentError,
            ),
          );
        }
      } else {
        emit(
          state.copyWith(
            renterStarsError: starsError,
            renterCommentError: commentError,
          ),
        );
      }
      return;
    }

    emit(state.copyWith(status: ReviewStatus.submitting));

    final result = await _repository.submitReview(
      bookingId: booking.id,
      authorId: currentUserId,
      subjectType: subjectType,
      subjectId: subjectId,
      stars: stars,
      comment: comment,
    );

    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        if (state.isRenter) {
          if (subjectType == SubjectType.user) {
            emit(
              state.copyWith(
                status: ReviewStatus.success,
                ownerExistingReview: value,
                successMessage: 'Review for owner submitted.',
              ),
            );
          } else {
            emit(
              state.copyWith(
                status: ReviewStatus.success,
                vehicleExistingReview: value,
                successMessage: 'Review for vehicle submitted.',
              ),
            );
          }
        } else {
          emit(
            state.copyWith(
              status: ReviewStatus.success,
              renterExistingReview: value,
              successMessage: 'Review for renter submitted.',
            ),
          );
        }
      case Failure(:final failure):
        emit(state.copyWith(status: ReviewStatus.failure, failure: failure));
    }
  }
}
