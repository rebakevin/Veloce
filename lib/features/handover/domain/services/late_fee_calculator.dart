import 'dart:math';

class LateFeeCalculator {
  static int calculateLateDays({
    required DateTime dueAt,
    required DateTime returnedAt,
  }) {
    if (!returnedAt.isAfter(dueAt)) return 0;

    final lateTime = returnedAt.difference(dueAt).inMicroseconds;

    return (lateTime / Duration.microsecondsPerDay).ceil();
  }

  static int calculateLateFee({
    required int rentalFee,
    required int lateDays,
    required int cautionFee,
    int claimAmount = 0,
    int? ownerAdjustedFee,
    bool waived = false,
  }) {
    if (rentalFee < 0 || lateDays < 0 || cautionFee < 0 || claimAmount < 0) {
      throw ArgumentError('Amounts and late days cannot be negative.');
    }

    if (claimAmount > cautionFee) {
      throw ArgumentError('Claim cannot exceed the caution fee.');
    }

    if (waived) return 0;

    final calculatedFee = (rentalFee * (pow(1.3, lateDays) - 1)).round();

    final remainingCaution = cautionFee - claimAmount;
    final cappedFee = min(calculatedFee, remainingCaution);

    if (ownerAdjustedFee == null) return cappedFee;

    if (ownerAdjustedFee < 0) {
      throw ArgumentError('Adjusted fee cannot be negative.');
    }

    return min(ownerAdjustedFee, cappedFee);
  }
}
