import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Rating Average Calculation', () {
    double calculateNewAverage({
      required double oldAvg,
      required int oldCount,
      required int newStars,
    }) {
      final newCount = oldCount + 1;
      final sum = (oldAvg * oldCount) + newStars;
      final newAvg = sum / newCount;
      return (newAvg * 10).round() / 10.0;
    }

    double calculateEditedAverage({
      required double oldAvg,
      required int count,
      required int oldStars,
      required int newStars,
    }) {
      if (count <= 0) return 0.0;
      final sum = (oldAvg * count) - oldStars + newStars;
      final newAvg = sum / count;
      return (newAvg * 10).round() / 10.0;
    }

    test('first review sets the average directly to the review rating', () {
      final avg = calculateNewAverage(oldAvg: 0.0, oldCount: 0, newStars: 5);
      expect(avg, 5.0);
    });

    test('computes correct mean for consecutive reviews', () {
      // 1st review: 5 stars -> 5.0
      var avg = calculateNewAverage(oldAvg: 0.0, oldCount: 0, newStars: 5);
      expect(avg, 5.0);

      // 2nd review: 4 stars -> (5 + 4) / 2 = 4.5
      avg = calculateNewAverage(oldAvg: avg, oldCount: 1, newStars: 4);
      expect(avg, 4.5);

      // 3rd review: 3 stars -> (4.5 * 2 + 3) / 3 = 12 / 3 = 4.0
      avg = calculateNewAverage(oldAvg: avg, oldCount: 2, newStars: 3);
      expect(avg, 4.0);
    });

    test('rounds to 1 decimal place properly', () {
      // 1st review: 5 stars
      // 2nd review: 4 stars
      // 3rd review: 5 stars -> (5 + 4 + 5) / 3 = 14 / 3 = 4.6666... -> 4.7
      final avg = calculateNewAverage(oldAvg: 4.5, oldCount: 2, newStars: 5);
      expect(avg, 4.7);
    });

    test(
      'editing a review correctly replaces the old rating in the aggregate',
      () {
        // Suppose we have 2 reviews with avg 4.5 (ratings: 5 and 4)
        // Author of the 4-star review edits it to 5 stars
        // New sum: (4.5 * 2) - 4 + 5 = 9 - 4 + 5 = 10 -> 10 / 2 = 5.0
        final updatedAvg = calculateEditedAverage(
          oldAvg: 4.5,
          count: 2,
          oldStars: 4,
          newStars: 5,
        );
        expect(updatedAvg, 5.0);
      },
    );

    test('editing a single review changes average directly to new stars', () {
      final updatedAvg = calculateEditedAverage(
        oldAvg: 3.0,
        count: 1,
        oldStars: 3,
        newStars: 5,
      );
      expect(updatedAvg, 5.0);
    });
  });
}
