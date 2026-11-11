import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/features/profile/domain/entities/identity_submission.dart';
import 'package:veloce/features/profile/domain/entities/licence_submission.dart';
import 'package:veloce/features/profile/domain/entities/profile_update.dart';
import 'package:veloce/features/profile/domain/entities/public_profile.dart';

import '../../../support/builders.dart';

void main() {
  group('ProfileUpdate', () {
    ProfileUpdate update({
      String name = 'Aline',
      String phone = '0788123456',
      DateTime? dob,
    }) => ProfileUpdate(
      name: name,
      phone: phone,
      dateOfBirth: dob ?? DateTime(1995, 5, 5),
    );

    test('accepts valid fields', () {
      expect(update().validate(now: testNow), isNull);
    });

    test('blank name, bad phone and under-18 are each caught', () {
      expect(update(name: '  ').validate(now: testNow), contains('Name'));
      expect(update(phone: '123').validate(now: testNow), contains('Rwandan'));
      expect(
        update(dob: DateTime(2015)).validate(now: testNow),
        contains('18'),
      );
    });
  });

  group('documents', () {
    test('an expired licence is rejected', () {
      final submission = LicenceSubmission(
        number: 'DL-1',
        expiry: DateTime(2020),
      );

      expect(submission.validate(now: testNow), 'This licence has expired.');
    });

    test('a National ID needs exactly 16 digits', () {
      expect(
        const IdentitySubmission(nationalIdNumber: '123').validate(),
        contains('16'),
      );
      expect(
        const IdentitySubmission(nationalIdNumber: '1199880012345678')
            .validate(),
        isNull,
      );
    });
  });

  group('PublicProfile', () {
    PublicProfile profile(int completed) => PublicProfile(
      userId: 'u1',
      name: 'Aline',
      photoUrl: null,
      ratingAvg: 4.5,
      ratingCount: 2,
      completedCount: completed,
    );

    test('flags first-time users until a rental completes', () {
      expect(profile(0).isFirstTime, isTrue);
      expect(profile(1).isFirstTime, isFalse);
    });
  });
}
