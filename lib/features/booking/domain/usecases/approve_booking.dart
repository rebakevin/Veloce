import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../repositories/booking_repository.dart';

/// Owner approval. The "I reviewed their info" tick is required before the
/// repository checks locks, pending reviews and overlapping requests.
class ApproveBooking {
  const ApproveBooking(this._repository);

  final BookingRepository _repository;

  Future<Result<void>> call(String bookingId, {required bool reviewed}) {
    if (!reviewed) {
      return Future.value(
        const Result.failure(
          ValidationFailure('Tick "I reviewed their info" first.'),
        ),
      );
    }
    return _repository.approve(bookingId);
  }
}
