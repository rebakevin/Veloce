import 'package:veloce/core/domain/entities/review.dart';
import 'package:veloce/core/domain/enums/subject_type.dart';
import 'package:veloce/core/error/result.dart';

/// Repository for creating, editing and reading reviews.
/// Reviews can never be deleted in the app.
abstract interface class ReviewRepository {
  /// Creates a new review or updates an existing one for [bookingId], [authorId]
  /// and [subjectType].
  ///
  /// Rating aggregates on the target subject (user or vehicle) are updated in
  /// the same atomic batch.
  Future<Result<Review>> submitReview({
    required String bookingId,
    required String authorId,
    required SubjectType subjectType,
    required String subjectId,
    required int stars,
    required String comment,
  });

  /// Reads a specific review by booking, author and subject type.
  Future<Result<Review?>> getReview({
    required String bookingId,
    required String authorId,
    required SubjectType subjectType,
  });

  /// Lists reviews received by a subject (user or vehicle), newest first.
  Future<Result<List<Review>>> getReviewsForSubject({
    required SubjectType subjectType,
    required String subjectId,
  });

  /// Lists reviews written by an author, newest first.
  Future<Result<List<Review>>> getReviewsByAuthor(String authorId);

  /// Lists all reviews written for a specific booking.
  Future<Result<List<Review>>> getReviewsForBooking(String bookingId);
}
