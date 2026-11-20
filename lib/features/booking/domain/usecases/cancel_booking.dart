import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../entities/booking_view.dart';
import '../repositories/booking_repository.dart';
import '../services/cancellation_policy.dart';

/// Either party may cancel until both sides confirm pickup.
class CancelBooking {
  const CancelBooking(this._repository, this._policy);

  final BookingRepository _repository;
  final CancellationPolicy _policy;

  Future<Result<void>> call(BookingView view, {String? reason}) {
    if (!_policy.canCancel(view.effectiveStatus)) {
      return Future.value(
        const Result.failure(
          ConflictFailure('This booking can no longer be cancelled.'),
        ),
      );
    }
    return _repository.cancel(view.booking.id, reason: reason);
  }
}
