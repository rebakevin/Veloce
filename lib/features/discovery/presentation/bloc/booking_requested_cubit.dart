import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:veloce/core/data/services/booking_lookup.dart';
import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/error/app_failure.dart';

sealed class BookingRequestedState extends Equatable {
  const BookingRequestedState();

  @override
  List<Object?> get props => const [];
}

final class BookingRequestedLoading extends BookingRequestedState {
  const BookingRequestedLoading();
}

final class BookingRequestedLoaded extends BookingRequestedState {
  const BookingRequestedLoaded(this.booking);

  final Booking booking;

  @override
  List<Object?> get props => [booking];
}

final class BookingRequestedFailure extends BookingRequestedState {
  const BookingRequestedFailure(this.error);

  final AppFailure error;

  @override
  List<Object?> get props => [error];
}

/// Loads the booking shown on `/booking/:id/requested`.
class BookingRequestedCubit extends Cubit<BookingRequestedState> {
  BookingRequestedCubit({required this._bookings, required this.bookingId})
    : super(const BookingRequestedLoading());

  final BookingLookup _bookings;
  final String bookingId;

  Future<void> load() async {
    emit(const BookingRequestedLoading());
    final result = await _bookings.byId(bookingId);
    if (isClosed) return;
    result.when(
      success: (booking) => emit(BookingRequestedLoaded(booking)),
      failure: (failure) => emit(BookingRequestedFailure(failure)),
    );
  }
}
