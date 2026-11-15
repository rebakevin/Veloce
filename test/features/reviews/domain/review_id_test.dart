import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/subject_type.dart';

void main() {
  group('Review ID Generation', () {
    String generateReviewId({
      required String bookingId,
      required String authorId,
      required SubjectType subjectType,
    }) {
      return '${bookingId}_${authorId}_${subjectType.key}';
    }

    test('generates expected composite key for user subject', () {
      final id = generateReviewId(
        bookingId: 'booking_123',
        authorId: 'user_456',
        subjectType: SubjectType.user,
      );
      expect(id, 'booking_123_user_456_user');
    });

    test('generates expected composite key for vehicle subject', () {
      final id = generateReviewId(
        bookingId: 'booking_123',
        authorId: 'user_456',
        subjectType: SubjectType.vehicle,
      );
      expect(id, 'booking_123_user_456_vehicle');
    });

    test('ensures deterministic IDs prevent duplicate reviews per booking-author-subject', () {
      final id1 = generateReviewId(
        bookingId: 'b1',
        authorId: 'u1',
        subjectType: SubjectType.vehicle,
      );
      final id2 = generateReviewId(
        bookingId: 'b1',
        authorId: 'u1',
        subjectType: SubjectType.vehicle,
      );
      expect(id1, equals(id2));
    });

    test('distinguishes between owner and vehicle reviews written by same renter on same booking', () {
      final userReviewId = generateReviewId(
        bookingId: 'b1',
        authorId: 'renter_1',
        subjectType: SubjectType.user,
      );
      final carReviewId = generateReviewId(
        bookingId: 'b1',
        authorId: 'renter_1',
        subjectType: SubjectType.vehicle,
      );
      expect(userReviewId, isNot(equals(carReviewId)));
    });
  });
}
