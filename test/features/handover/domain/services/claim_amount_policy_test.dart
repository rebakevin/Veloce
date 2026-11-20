import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/features/handover/domain/services/claim_amount_policy.dart';

AppFailure? _revise(int amount) => ClaimAmountPolicy.validateRevision(
  amount: amount,
  currentAmount: 70000,
  originalAmount: 120000,
  cautionFee: 100000,
);

void main() {
  group('new claim', () {
    test('accepts an amount up to the caution fee', () {
      expect(
        ClaimAmountPolicy.validateNewClaim(amount: 100000, cautionFee: 100000),
        isNull,
      );
    });

    test('rejects an amount above the caution fee', () {
      expect(
        ClaimAmountPolicy.validateNewClaim(amount: 100001, cautionFee: 100000),
        const ValidationFailure('The claim cannot exceed the caution fee.'),
      );
    });

    test('rejects zero and negative amounts', () {
      expect(
        ClaimAmountPolicy.validateNewClaim(amount: 0, cautionFee: 100000),
        isA<ValidationFailure>(),
      );
      expect(
        ClaimAmountPolicy.validateNewClaim(amount: -5, cautionFee: 100000),
        isA<ValidationFailure>(),
      );
    });
  });

  group('re-claim ceiling', () {
    test('accepts the same or a lower amount', () {
      expect(_revise(70000), isNull);
      expect(_revise(1), isNull);
    });

    test('rejects an amount above the current claim', () {
      expect(
        _revise(70001),
        const ValidationFailure(
          'A revised claim cannot exceed the previous claim amount.',
        ),
      );
    });

    test('rejects an amount above the original claim', () {
      final failure = ClaimAmountPolicy.validateRevision(
        amount: 60000,
        currentAmount: 90000,
        originalAmount: 50000,
        cautionFee: 100000,
      );

      expect(failure, isA<ValidationFailure>());
    });

    test('rejects an amount above the caution fee', () {
      final failure = ClaimAmountPolicy.validateRevision(
        amount: 100001,
        currentAmount: 120000,
        originalAmount: 120000,
        cautionFee: 100000,
      );

      expect(failure, isA<ValidationFailure>());
    });

    test('rejects zero and negative amounts', () {
      expect(_revise(0), isA<ValidationFailure>());
      expect(_revise(-1), isA<ValidationFailure>());
    });
  });
}
