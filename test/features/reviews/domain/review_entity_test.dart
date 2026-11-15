import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/entities/review.dart';
import 'package:veloce/core/domain/enums/subject_type.dart';

void main() {
  group('Review Entity', () {
    final now = DateTime.utc(2026, 11, 15, 10, 0);

    test('instantiates with all required fields', () {
      final review = Review(
        id: 'b1_u1_vehicle',
        bookingId: 'b1',
        authorId: 'u1',
        subjectType: SubjectType.vehicle,
        subjectId: 'v1',
        stars: 5,
        comment: 'Great vehicle, clean and comfortable!',
        createdAt: now,
        editedAt: null,
      );

      expect(review.id, 'b1_u1_vehicle');
      expect(review.bookingId, 'b1');
      expect(review.authorId, 'u1');
      expect(review.subjectType, SubjectType.vehicle);
      expect(review.subjectId, 'v1');
      expect(review.stars, 5);
      expect(review.comment, 'Great vehicle, clean and comfortable!');
      expect(review.createdAt, now);
      expect(review.editedAt, isNull);
    });

    test('supports value equality through Equatable', () {
      final r1 = Review(
        id: 'r1',
        bookingId: 'b1',
        authorId: 'u1',
        subjectType: SubjectType.user,
        subjectId: 'u2',
        stars: 4,
        comment: 'Polite renter',
        createdAt: now,
        editedAt: null,
      );
      final r2 = Review(
        id: 'r1',
        bookingId: 'b1',
        authorId: 'u1',
        subjectType: SubjectType.user,
        subjectId: 'u2',
        stars: 4,
        comment: 'Polite renter',
        createdAt: now,
        editedAt: null,
      );

      expect(r1, equals(r2));
    });

    test('copyWith updates specified fields correctly', () {
      final initial = Review(
        id: 'r1',
        bookingId: 'b1',
        authorId: 'u1',
        subjectType: SubjectType.vehicle,
        subjectId: 'v1',
        stars: 4,
        comment: 'Good ride',
        createdAt: now,
        editedAt: null,
      );

      final editedTime = now.add(const Duration(days: 1));
      final updated = initial.copyWith(
        stars: 5,
        comment: 'Updated to 5 stars! Exceptional car!',
        editedAt: editedTime,
      );

      expect(updated.stars, 5);
      expect(updated.comment, 'Updated to 5 stars! Exceptional car!');
      expect(updated.editedAt, editedTime);
      expect(updated.id, initial.id);
      expect(updated.authorId, initial.authorId);
    });
  });
}
