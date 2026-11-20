import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/features/reviews/domain/rules/pending_review_rule.dart';

BookingRef _done(String id) =>
    BookingRef(id: id, status: BookingStatus.completed);

void main() {
  const rule = PendingReviewRule();
  const me = 'u1';

  bool missing({
    List<BookingRef> asRenter = const [],
    List<BookingRef> asOwner = const [],
    Set<String> existing = const {},
  }) => rule.hasMissingReview(
    userId: me,
    renterBookings: asRenter,
    ownerBookings: asOwner,
    existingReviewIds: existing,
  );

  group('PendingReviewRule', () {
    test('no completed bookings means nothing is missing', () {
      expect(missing(), isFalse);
    });

    test('renter with both reviews has nothing missing', () {
      expect(
        missing(
          asRenter: [_done('b1')],
          existing: {'b1_u1_user', 'b1_u1_vehicle'},
        ),
        isFalse,
      );
    });

    test('renter missing the owner review is pending', () {
      expect(
        missing(asRenter: [_done('b1')], existing: {'b1_u1_vehicle'}),
        isTrue,
      );
    });

    test('renter missing the car review is pending', () {
      expect(
        missing(asRenter: [_done('b1')], existing: {'b1_u1_user'}),
        isTrue,
      );
    });

    test('owner missing the renter review is pending', () {
      expect(missing(asOwner: [_done('b2')]), isTrue);
    });

    test('owner with the renter review has nothing missing', () {
      expect(
        missing(asOwner: [_done('b2')], existing: {'b2_u1_user'}),
        isFalse,
      );
    });

    test('mixed roles: all done is not pending', () {
      expect(
        missing(
          asRenter: [_done('b1')],
          asOwner: [_done('b2')],
          existing: {'b1_u1_user', 'b1_u1_vehicle', 'b2_u1_user'},
        ),
        isFalse,
      );
    });

    test('mixed roles: owner side missing is pending', () {
      expect(
        missing(
          asRenter: [_done('b1')],
          asOwner: [_done('b2')],
          existing: {'b1_u1_user', 'b1_u1_vehicle'},
        ),
        isTrue,
      );
    });

    test('reviews by another author do not satisfy the user', () {
      expect(missing(asOwner: [_done('b2')], existing: {'b2_u9_user'}), isTrue);
    });

    test('non-completed bookings never count', () {
      final others = [
        for (final status in BookingStatus.values)
          if (status != BookingStatus.completed)
            BookingRef(id: 'x_${status.key}', status: status),
      ];
      expect(missing(asRenter: others, asOwner: others), isFalse);
      expect(
        rule.requiredReviewIds(
          userId: me,
          renterBookings: others,
          ownerBookings: others,
        ),
        isEmpty,
      );
    });

    test('required ids list renter reviews first, then owner', () {
      expect(
        rule.requiredReviewIds(
          userId: me,
          renterBookings: [_done('b1')],
          ownerBookings: [_done('b2')],
        ),
        ['b1_u1_user', 'b1_u1_vehicle', 'b2_u1_user'],
      );
    });
  });
}
