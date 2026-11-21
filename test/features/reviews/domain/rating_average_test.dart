import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/features/reviews/domain/services/rating_aggregate.dart';

void main() {
  group('RatingAggregate', () {
    test('no reviews gives count 0 and average 0', () {
      final aggregate = RatingAggregate.fromStars(const []);
      expect(aggregate.count, 0);
      expect(aggregate.average, 0.0);
    });

    test('a first review sets the average to its stars', () {
      final aggregate = RatingAggregate.fromStars(const [5]);
      expect(aggregate.count, 1);
      expect(aggregate.average, 5.0);
    });

    test('the average is exact and not rounded to one decimal', () {
      final aggregate = RatingAggregate.fromStars(const [5, 5, 4]);
      expect(aggregate.count, 3);
      expect(aggregate.average, closeTo(14 / 3, 1e-12));
    });

    test('an edit changes the sum without drift over many reviews', () {
      final stars = [...List<int>.filled(40, 4), 5];
      final before = RatingAggregate.fromStars(stars);
      stars[40] = 1;
      final after = RatingAggregate.fromStars(stars);
      expect(before.count, after.count);
      expect(after.average, closeTo(161 / 41, 1e-12));
    });
  });
}
