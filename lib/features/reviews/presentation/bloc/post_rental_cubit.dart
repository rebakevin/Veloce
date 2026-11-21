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
import 'package:veloce/core/error/result.dart';

import '../../domain/repositories/review_repository.dart';

sealed class PostRentalState extends Equatable {
  const PostRentalState();

  @override
  List<Object?> get props => [];
}

final class PostRentalInitial extends PostRentalState {
  const PostRentalInitial();
}

final class PostRentalHidden extends PostRentalState {
  const PostRentalHidden();
}

final class PostRentalLoaded extends PostRentalState {
  const PostRentalLoaded({
    required this.booking,
    required this.isRenter,
    this.vehicle,
    this.otherUser,
    this.ownerReview,
    this.vehicleReview,
    this.renterReview,
  });

  final Booking booking;
  final bool isRenter;
  final Vehicle? vehicle;
  final UserAccount? otherUser;

  // For renter
  final Review? ownerReview;
  final Review? vehicleReview;

  // For owner
  final Review? renterReview;

  bool get hasPendingReview {
    if (isRenter) {
      return ownerReview == null || vehicleReview == null;
    } else {
      return renterReview == null;
    }
  }

  @override
  List<Object?> get props => [
    booking,
    isRenter,
    vehicle,
    otherUser,
    ownerReview,
    vehicleReview,
    renterReview,
  ];
}

class PostRentalCubit extends Cubit<PostRentalState> {
  PostRentalCubit({
    required this._repository,
    required this._bookingLookup,
    required this._userLookup,
    required this._vehicleLookup,
    required this._session,
    required this._bookingId,
  }) : super(const PostRentalInitial());

  final ReviewRepository _repository;
  final BookingLookup _bookingLookup;
  final UserLookup _userLookup;
  final VehicleLookup _vehicleLookup;
  final AuthSession _session;
  final String _bookingId;

  Future<void> load() async {
    final booking = (await _bookingLookup.byId(_bookingId)).valueOrNull;
    if (booking == null || booking.status != BookingStatus.completed) {
      emit(const PostRentalHidden());
      return;
    }

    final currentUserId = _session.currentUserId;
    if (currentUserId == null) {
      emit(const PostRentalHidden());
      return;
    }

    final isRenter = currentUserId == booking.renterId;
    final isOwner = currentUserId == booking.ownerId;
    if (!isRenter && !isOwner) {
      emit(const PostRentalHidden());
      return;
    }

    final otherUserId = isRenter ? booking.ownerId : booking.renterId;
    final otherUser = (await _userLookup.byId(otherUserId)).valueOrNull;
    final vehicle = (await _vehicleLookup.byId(booking.vehicleId)).valueOrNull;

    Review? ownerReview;
    Review? vehicleReview;
    Review? renterReview;

    if (isRenter) {
      final ownerRes = await _repository.getReview(
        bookingId: booking.id,
        authorId: currentUserId,
        subjectType: SubjectType.user,
      );
      ownerReview = ownerRes.valueOrNull;

      final vehicleRes = await _repository.getReview(
        bookingId: booking.id,
        authorId: currentUserId,
        subjectType: SubjectType.vehicle,
      );
      vehicleReview = vehicleRes.valueOrNull;
    } else {
      final renterRes = await _repository.getReview(
        bookingId: booking.id,
        authorId: currentUserId,
        subjectType: SubjectType.user,
      );
      renterReview = renterRes.valueOrNull;
    }

    final loaded = PostRentalLoaded(
      booking: booking,
      isRenter: isRenter,
      vehicle: vehicle,
      otherUser: otherUser,
      ownerReview: ownerReview,
      vehicleReview: vehicleReview,
      renterReview: renterReview,
    );
    if (isClosed) return;
    emit(loaded);
  }
}
