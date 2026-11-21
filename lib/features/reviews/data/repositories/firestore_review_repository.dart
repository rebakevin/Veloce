import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veloce/core/constants/firestore_fields.dart';
import 'package:veloce/core/constants/firestore_paths.dart';
import 'package:veloce/core/data/models/review_model.dart';
import 'package:veloce/core/data/services/failure_mapper.dart';
import 'package:veloce/core/domain/entities/review.dart';
import 'package:veloce/core/domain/enums/subject_type.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../../domain/repositories/review_repository.dart';
import '../../domain/services/rating_aggregate.dart';

/// Firestore implementation of [ReviewRepository].
class FirestoreReviewRepository implements ReviewRepository {
  const FirestoreReviewRepository({
    required this._firestore,
    required this._clock,
  });

  final FirebaseFirestore _firestore;
  final Clock _clock;

  @override
  Future<Result<Review>> submitReview({
    required String bookingId,
    required String authorId,
    required SubjectType subjectType,
    required String subjectId,
    required int stars,
    required String comment,
  }) async {
    final trimmedComment = comment.trim();
    if (stars < 1 || stars > 5) {
      return const Result.failure(
        ValidationFailure('Please select a rating between 1 and 5 stars.'),
      );
    }
    if (trimmedComment.isEmpty) {
      return const Result.failure(
        ValidationFailure('Please write a review comment.'),
      );
    }

    try {
      final docId = '${bookingId}_${authorId}_${subjectType.key}';
      final reviewRef = _firestore
          .collection(FirestorePaths.reviews)
          .doc(docId);
      final subjectRef = _firestore.doc(
        subjectType == SubjectType.user
            ? FirestorePaths.user(subjectId)
            : FirestorePaths.vehicle(subjectId),
      );

      // Stars of the other reviews of this subject: the aggregate is rebuilt
      // from real data, so it is exact and does not drift.
      final othersSnapshot = await _firestore
          .collection(FirestorePaths.reviews)
          .where(FirestoreFields.subjectType, isEqualTo: subjectType.key)
          .where(FirestoreFields.subjectId, isEqualTo: subjectId)
          .get();
      final otherStars = [
        for (final doc in othersSnapshot.docs)
          if (doc.id != docId)
            (doc.data()[FirestoreFields.stars] as num).toInt(),
      ];

      Future<Review> write({required bool writeAggregate}) =>
          _firestore.runTransaction<Review>((transaction) async {
            final existingDoc = await transaction.get(reviewRef);
            final subjectDoc = await transaction.get(subjectRef);

            final Review review;
            if (existingDoc.exists) {
              review = ReviewModel.fromMap(existingDoc.id, existingDoc.data()!)
                  .copyWith(
                    stars: stars,
                    comment: trimmedComment,
                    editedAt: _clock.now(),
                  );
            } else {
              review = Review(
                id: docId,
                bookingId: bookingId,
                authorId: authorId,
                subjectType: subjectType,
                subjectId: subjectId,
                stars: stars,
                comment: trimmedComment,
                createdAt: _clock.now(),
                editedAt: null,
              );
            }

            transaction.set(reviewRef, ReviewModel.toMap(review));
            // A deleted subject (account or vehicle) must not block the review.
            // The aggregate is recomputed from the real reviews and written as
            // is, so a stored count that drifted is corrected instead of
            // blocking every later review.
            if (subjectDoc.exists && writeAggregate) {
              final aggregate = RatingAggregate.fromStars([
                ...otherStars,
                stars,
              ]);
              transaction.update(subjectRef, {
                FirestoreFields.ratingAvg: aggregate.average,
                FirestoreFields.ratingCount: aggregate.count,
              });
            }
            return review;
          });

      try {
        return Result.success(await write(writeAggregate: true));
      } on FirebaseException catch (e) {
        // The rules may refuse a recomputed aggregate that moved by more than
        // one. The review itself must still be saved; the next review
        // recomputes the aggregate again.
        if (e.code != 'permission-denied') rethrow;
        return Result.success(await write(writeAggregate: false));
      }
    } catch (e, st) {
      return Result.failure(mapToFailure(e, st));
    }
  }

  @override
  Future<Result<Review?>> getReview({
    required String bookingId,
    required String authorId,
    required SubjectType subjectType,
  }) async {
    try {
      final docId = '${bookingId}_${authorId}_${subjectType.key}';
      final doc = await _firestore
          .collection(FirestorePaths.reviews)
          .doc(docId)
          .get();
      if (!doc.exists || doc.data() == null) {
        return const Result.success(null);
      }
      return Result.success(ReviewModel.fromMap(doc.id, doc.data()!));
    } catch (e, st) {
      return Result.failure(mapToFailure(e, st));
    }
  }

  @override
  Future<Result<List<Review>>> getReviewsForSubject({
    required SubjectType subjectType,
    required String subjectId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.reviews)
          .where(FirestoreFields.subjectType, isEqualTo: subjectType.key)
          .where(FirestoreFields.subjectId, isEqualTo: subjectId)
          .orderBy(FirestoreFields.createdAt, descending: true)
          .get();

      final reviews = snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.id, doc.data()))
          .toList();
      return Result.success(reviews);
    } catch (e, st) {
      return Result.failure(mapToFailure(e, st));
    }
  }

  @override
  Future<Result<List<Review>>> getReviewsByAuthor(String authorId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.reviews)
          .where(FirestoreFields.authorId, isEqualTo: authorId)
          .orderBy(FirestoreFields.createdAt, descending: true)
          .get();

      final reviews = snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.id, doc.data()))
          .toList();
      return Result.success(reviews);
    } catch (e, st) {
      return Result.failure(mapToFailure(e, st));
    }
  }

  @override
  Future<Result<List<Review>>> getReviewsForBooking(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.reviews)
          .where(FirestoreFields.bookingId, isEqualTo: bookingId)
          .get();

      final reviews = snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.id, doc.data()))
          .toList();
      return Result.success(reviews);
    } catch (e, st) {
      return Result.failure(mapToFailure(e, st));
    }
  }
}
