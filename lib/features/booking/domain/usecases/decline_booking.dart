import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../repositories/booking_repository.dart';

/// Owner decline. A reason is required so the renter knows why.
class DeclineBooking {
  const DeclineBooking(this._repository);

  final BookingRepository _repository;

  Future<Result<void>> call(String bookingId, {required String reason}) {
    final text = reason.trim();
    if (text.isEmpty) {
      return Future.value(
        const Result.failure(
          ValidationFailure('Tell the renter why you are declining.'),
        ),
      );
    }
    return _repository.decline(bookingId, reason: text);
  }
}
