import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/handover/domain/services/pickup_release_calculator.dart';

PickupRelease _release(int rentalFee) {
  final result = PickupReleaseCalculator.calculate(rentalFee: rentalFee);
  return (result as Success<PickupRelease>).value;
}

void main() {
  group('PickupReleaseCalculator', () {
    test('releases the rental fee, takes 2,000 and pays out the rest', () {
      final release = _release(210000);

      expect(release.release, 210000);
      expect(release.platformFee, 2000);
      expect(release.payout, 208000);
      expect(release.hasPayout, isTrue);
    });

    test('a rental fee equal to the platform fee has no payout', () {
      final release = _release(2000);

      expect(release.payout, 0);
      expect(release.hasPayout, isFalse);
    });

    test('a rental fee below the platform fee fails validation', () {
      final result = PickupReleaseCalculator.calculate(rentalFee: 1999);

      expect(
        result,
        isA<Failure<PickupRelease>>().having(
          (f) => f.failure,
          'failure',
          const ValidationFailure(
            'The rental fee cannot be less than the platform fee.',
          ),
        ),
      );
    });
  });
}
