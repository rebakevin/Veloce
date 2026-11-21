import 'package:equatable/equatable.dart';

/// Exact rating aggregate of a subject (user or vehicle).
///
/// Built from the star values of the reviews themselves, never from the stored
/// one-decimal average, so editing or adding reviews does not drift. The
/// [average] is not rounded; rounding is for display only.
class RatingAggregate extends Equatable {
  const RatingAggregate({required this.count, required this.average});

  /// Aggregate of [stars], the stars of every review of the subject.
  factory RatingAggregate.fromStars(Iterable<int> stars) {
    var count = 0;
    var sum = 0;
    for (final value in stars) {
      count++;
      sum += value;
    }
    return RatingAggregate(
      count: count,
      average: count == 0 ? 0.0 : sum / count,
    );
  }

  final int count;
  final double average;

  @override
  List<Object?> get props => [count, average];
}
