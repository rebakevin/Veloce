import 'package:veloce/core/error/app_failure.dart';

/// Ceilings for the amount of a caution claim.
abstract final class ClaimAmountPolicy {
  /// A new claim must be positive and at most the caution fee.
  static AppFailure? validateNewClaim({
    required int amount,
    required int cautionFee,
  }) {
    if (amount <= 0) {
      return const ValidationFailure('The claim amount must be above zero.');
    }

    if (amount > cautionFee) {
      return const ValidationFailure(
        'The claim cannot exceed the caution fee.',
      );
    }

    return null;
  }

  /// A re-claim must be positive and at most the current claim, the original
  /// claim and the caution fee.
  static AppFailure? validateRevision({
    required int amount,
    required int currentAmount,
    required int originalAmount,
    required int cautionFee,
  }) {
    if (amount <= 0) {
      return const ValidationFailure('The claim amount must be above zero.');
    }

    if (amount > currentAmount ||
        amount > originalAmount ||
        amount > cautionFee) {
      return const ValidationFailure(
        'A revised claim cannot exceed the previous claim amount.',
      );
    }

    return null;
  }
}
