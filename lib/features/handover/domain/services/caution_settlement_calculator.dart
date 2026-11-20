import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import 'late_fee_calculator.dart';

/// How the caution fee is split when a booking completes.
class CautionSettlement {
  const CautionSettlement({
    required this.lateDays,
    required this.lateFee,
    required this.claimDeduction,
    required this.refund,
  });

  final int lateDays;

  /// Late fee paid to the owner (already capped, 0 when waived).
  final int lateFee;

  /// Agreed claim paid to the owner (0 when there is no claim).
  final int claimDeduction;

  /// Remainder returned to the renter.
  final int refund;

  /// Always equals the caution fee, so nothing stays held.
  int get total => lateFee + claimDeduction + refund;
}

/// Splits the caution fee into late fee, claim deduction and refund.
///
/// Late days and the capped late fee come from [LateFeeCalculator].
abstract final class CautionSettlementCalculator {
  /// Renter agreed to [claimAmount]: deduct it, charge the late fee within
  /// what is left, refund the remainder.
  static Result<CautionSettlement> forAgreedClaim({
    required int rentalFee,
    required int cautionFee,
    required DateTime dueAt,
    required DateTime returnedAt,
    required int claimAmount,
    required bool lateFeeWaived,
  }) {
    return _settle(
      rentalFee: rentalFee,
      cautionFee: cautionFee,
      dueAt: dueAt,
      returnedAt: returnedAt,
      claimAmount: claimAmount,
      lateFeeWaived: lateFeeWaived,
      overdrawnMessage: 'Claim and late fee exceed the caution fee.',
    );
  }

  /// No claim (no issue, or the owner refunds): charge the late fee and
  /// refund the rest of the caution.
  static Result<CautionSettlement> forRefund({
    required int rentalFee,
    required int cautionFee,
    required DateTime dueAt,
    required DateTime returnedAt,
    required bool lateFeeWaived,
  }) {
    return _settle(
      rentalFee: rentalFee,
      cautionFee: cautionFee,
      dueAt: dueAt,
      returnedAt: returnedAt,
      claimAmount: 0,
      lateFeeWaived: lateFeeWaived,
      overdrawnMessage: 'The late fee exceeds the caution fee.',
    );
  }

  static Result<CautionSettlement> _settle({
    required int rentalFee,
    required int cautionFee,
    required DateTime dueAt,
    required DateTime returnedAt,
    required int claimAmount,
    required bool lateFeeWaived,
    required String overdrawnMessage,
  }) {
    final lateDays = LateFeeCalculator.calculateLateDays(
      dueAt: dueAt,
      returnedAt: returnedAt,
    );

    final lateFee = LateFeeCalculator.calculateLateFee(
      rentalFee: rentalFee,
      lateDays: lateDays,
      cautionFee: cautionFee,
      claimAmount: claimAmount,
      waived: lateFeeWaived,
    );

    final refund = cautionFee - claimAmount - lateFee;

    if (refund < 0) {
      return Result.failure(ValidationFailure(overdrawnMessage));
    }

    return Result.success(
      CautionSettlement(
        lateDays: lateDays,
        lateFee: lateFee,
        claimDeduction: claimAmount,
        refund: refund,
      ),
    );
  }
}
