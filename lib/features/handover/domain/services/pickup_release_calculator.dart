import 'package:veloce/core/constants/app_constants.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

/// The three money entries written when both sides confirm pickup.
class PickupRelease {
  const PickupRelease({
    required this.release,
    required this.platformFee,
    required this.payout,
  });

  /// Rental fee moved out of escrow to the owner.
  final int release;

  /// Platform fee taken back from the owner.
  final int platformFee;

  /// Owner share: `release - platformFee`.
  final int payout;

  /// A payout of zero is not written to the ledger.
  bool get hasPayout => payout > 0;
}

/// Splits a rental fee into release, platform fee and payout at pickup.
abstract final class PickupReleaseCalculator {
  static Result<PickupRelease> calculate({required int rentalFee}) {
    const platformFee = AppConstants.platformFee;
    final payout = rentalFee - platformFee;

    if (payout < 0) {
      return const Result.failure(
        ValidationFailure(
          'The rental fee cannot be less than the platform fee.',
        ),
      );
    }

    return Result.success(
      PickupRelease(
        release: rentalFee,
        platformFee: platformFee,
        payout: payout,
      ),
    );
  }
}
