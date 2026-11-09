import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/validation/validators.dart';

void main() {
  final now = DateTime(2026, 11, 9);

  group('email', () {
    test('accepts a normal address', () {
      expect(Validators.email('aline@example.com'), isNull);
    });
    test('rejects blank and malformed input with a message', () {
      expect(Validators.email('  '), isNotNull);
      expect(Validators.email('aline@'), isNotNull);
    });
  });

  group('password', () {
    test('needs 8 characters with a letter and a digit', () {
      expect(Validators.password('abcdefg1'), isNull);
      expect(Validators.password('short1'), isNotNull);
      expect(Validators.password('onlyletters'), isNotNull);
      expect(Validators.password('12345678'), isNotNull);
    });
  });

  group('phone and MoMo', () {
    test('Rwandan phone is 07[2389] plus 7 digits', () {
      expect(Validators.phone('0788123456'), isNull);
      expect(Validators.phone('0718123456'), isNotNull);
      expect(Validators.phone('788123456'), isNotNull);
    });
    test('MoMo is typed without the leading 0', () {
      expect(Validators.momoNumber('788123456'), isNull);
      expect(Validators.momoNumber('0788123456'), isNotNull);
    });
  });

  group('date of birth', () {
    test('requires 18 years', () {
      expect(Validators.dateOfBirth(DateTime(2008, 11, 9), now: now), isNull);
      expect(
        Validators.dateOfBirth(DateTime(2008, 11, 10), now: now),
        isNotNull,
      );
      expect(Validators.dateOfBirth(null, now: now), isNotNull);
    });
  });

  group('identity documents', () {
    test('National ID has exactly 16 digits', () {
      expect(Validators.nationalId('1199880012345678'), isNull);
      expect(Validators.nationalId('119988001234567'), isNotNull);
    });
    test('licence must not be expired', () {
      expect(Validators.licenceExpiry(DateTime(2027), now: now), isNull);
      expect(
        Validators.licenceExpiry(DateTime(2026, 11, 9), now: now),
        isNotNull,
      );
    });
  });

  group('vehicle fields', () {
    test('plate matches RAB 123 A with optional spaces', () {
      expect(Validators.plate('RAB 123 A'), isNull);
      expect(Validators.plate('rab123a'), isNull);
      expect(Validators.plate('ABC 123 A'), isNotNull);
    });
    test('year is 2005 to 2026', () {
      expect(Validators.vehicleYear(2005), isNull);
      expect(Validators.vehicleYear(2026), isNull);
      expect(Validators.vehicleYear(2004), isNotNull);
      expect(Validators.vehicleYear(2027), isNotNull);
    });
    test('price is at least 5,000 and caution is not negative', () {
      expect(Validators.dailyPrice(5000), isNull);
      expect(Validators.dailyPrice(4999), isNotNull);
      expect(Validators.cautionFee(0), isNull);
      expect(Validators.cautionFee(-1), isNotNull);
    });
  });

  test('rating is 1 to 5 and reasons cannot be blank', () {
    expect(Validators.rating(5), isNull);
    expect(Validators.rating(0), isNotNull);
    expect(
      Validators.requiredText('  ', field: 'Reason'),
      'Reason is required.',
    );
  });
}
