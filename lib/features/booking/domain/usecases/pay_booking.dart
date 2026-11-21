import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/domain/services/momo_gateway.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/core/validation/validators.dart';
import 'package:veloce/features/auth/auth.dart';

import '../entities/booking_view.dart';
import '../repositories/booking_repository.dart';

/// Renter payment. The amount is the value locked on the booking at request
/// time; the deadline is checked before the simulated MoMo charge.
class PayBooking {
  const PayBooking(this._repository, this._clock, this._emailGate);

  final BookingRepository _repository;
  final Clock _clock;
  final EmailVerificationGate _emailGate;

  Future<Result<MomoReceipt>> call(
    BookingView view, {
    required String momoNumber,
  }) {
    final emailFailure = _emailGate.check();
    if (emailFailure != null) return Future.value(Result.failure(emailFailure));
    if (view.effectiveStatus != BookingStatus.approved) {
      return Future.value(
        const Result.failure(
          ConflictFailure('This booking is not waiting for payment.'),
        ),
      );
    }
    final problem = Validators.momoNumber(momoNumber);
    if (problem != null) {
      return Future.value(Result.failure(ValidationFailure(problem)));
    }
    final deadline = view.booking.payDeadline;
    if (deadline != null && _clock.now().isAfter(deadline)) {
      return Future.value(
        const Result.failure(
          ConflictFailure('The payment deadline has passed.'),
        ),
      );
    }
    return _repository.pay(view.booking.id, momoNumber: momoNumber.trim());
  }
}
