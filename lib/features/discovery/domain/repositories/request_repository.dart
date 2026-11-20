import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/error/result.dart';

import '../entities/booking_request_draft.dart';

/// The writes and lock check behind a booking request.
abstract interface class RequestRepository {
  Future<Result<bool>> hasActiveLock(String renterId);

  Future<Result<Booking>> createBooking({
    required String renterId,
    required BookingRequestDraft draft,
  });
}
