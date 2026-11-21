import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/domain/services/pending_review_checker.dart';
import 'package:veloce/core/domain/services/pricing_calculator.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/auth/auth.dart';

import '../entities/booking_request_draft.dart';
import '../entities/vehicle_detail.dart';
import '../repositories/request_repository.dart';
import '../repositories/search_repository.dart';
import '../services/availability_rules.dart';

/// Validates a renter's request and then asks the repository to write it.
class CreateBookingRequest {
  const CreateBookingRequest({
    required this._search,
    required this._requests,
    required this._pendingReviews,
    required this._emailGate,
    required this._pricing,
    required this._clock,
    this.rules = const AvailabilityRules(),
  });

  final SearchRepository _search;
  final RequestRepository _requests;
  final PendingReviewChecker _pendingReviews;
  final EmailVerificationGate _emailGate;
  final PricingCalculator _pricing;
  final Clock _clock;
  final AvailabilityRules rules;

  Future<Result<Booking>> call({
    required String renterId,
    required String vehicleId,
    required DateTime start,
    required DateTime end,
  }) async {
    final emailFailure = _emailGate.check();
    if (emailFailure != null) return Result.failure(emailFailure);

    final detailResult = await _search.detail(vehicleId);
    if (detailResult case Failure(:final failure)) {
      return Result.failure(failure);
    }
    final detail = (detailResult as Success<VehicleDetail>).value;
    final vehicle = detail.vehicle;

    if (vehicle.ownerId == renterId) {
      return const Result.failure(
        ConflictFailure('You cannot request your own car.'),
      );
    }

    final now = _clock.now();
    if (vehicle.status != VehicleStatus.published ||
        !rules.hasValidDocs(vehicle, now)) {
      return const Result.failure(
        ConflictFailure('This car is no longer available.'),
      );
    }
    if (rules.isPast(start, now)) {
      return const Result.failure(
        ValidationFailure('Choose a pickup date from today onwards.'),
      );
    }
    if (end.isBefore(start)) {
      return const Result.failure(
        ValidationFailure('The return date must be after the pickup date.'),
      );
    }
    if (!rules.isWithinWindow(vehicle, start, end)) {
      return const Result.failure(
        ValidationFailure('These dates are outside the owner’s availability.'),
      );
    }
    if (!rules.isFree(detail.blocks, start, end)) {
      return const Result.failure(
        ConflictFailure('Those dates are already booked. Choose other days.'),
      );
    }

    final lockResult = await _requests.hasActiveLock(renterId);
    if (lockResult case Failure(:final failure)) {
      return Result.failure(failure);
    }
    if (lockResult case Success(value: true)) {
      return const Result.failure(
        ConflictFailure(
          'You already have an active booking or request lock. '
          'Finish or cancel it before requesting another car.',
        ),
      );
    }

    if (await _pendingReviews.hasPendingReview(renterId)) {
      return const Result.failure(
        ConflictFailure(
          'Write your pending review before sending a new request.',
        ),
      );
    }

    final quote = _pricing.quote(
      dailyPrice: vehicle.dailyPrice,
      longRates: vehicle.longRates,
      cautionFee: vehicle.cautionFee,
      start: start,
      end: end,
    );
    return _requests.createBooking(
      renterId: renterId,
      draft: BookingRequestDraft(
        vehicle: vehicle,
        start: start,
        end: end,
        quote: quote,
      ),
    );
  }
}
