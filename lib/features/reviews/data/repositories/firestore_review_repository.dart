import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veloce/core/constants/firestore_fields.dart';
import 'package:veloce/core/constants/firestore_paths.dart';
import 'package:veloce/core/data/models/review_model.dart';
import 'package:veloce/core/data/services/failure_mapper.dart';
import 'package:veloce/core/domain/entities/review.dart';
import 'package:veloce/core/domain/enums/subject_type.dart';
import 'package:veloce/core/domain/services/atomic_write.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../../domain/repositories/review_repository.dart';

/// Firestore implementation of [ReviewRepository].
class FirestoreReviewRepository implements ReviewRepository {
  const FirestoreReviewRepository({
    required FirebaseFirestore firestore,
    required AtomicWriteFactory writes,
    required Clock clock,
  }) : _firestore = firestore,
       _writes = writes,
       _clock = clock;

  final FirebaseFirestore _firestore;
  final AtomicWriteFactory _writes;
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
      final existingDoc = await reviewRef.get();

      final String targetPath;
      final DocumentReference<Map<String, dynamic>> subjectRef;
      if (subjectType == SubjectType.user) {
        targetPath = FirestorePaths.user(subjectId);
        subjectRef = _firestore.doc(targetPath);
      } else {
        targetPath = FirestorePaths.vehicle(subjectId);
        subjectRef = _firestore.doc(targetPath);
      }

      final subjectDoc = await subjectRef.get();
      final subjectData = subjectDoc.data() ?? <String, dynamic>{};
      final oldAvg =
          (subjectData[FirestoreFields.ratingAvg] as num?)?.toDouble() ?? 0.0;
      final oldCount =
          (subjectData[FirestoreFields.ratingCount] as num?)?.toInt() ?? 0;

      final Review review;
      final int newCount;
      final double newAvg;

      if (existingDoc.exists) {
        final existing = ReviewModel.fromMap(
          existingDoc.id,
          existingDoc.data()!,
        );
        review = existing.copyWith(
          stars: stars,
          comment: trimmedComment,
          editedAt: _clock.now(),
        );
        newCount = oldCount;
        final sum = (oldAvg * oldCount) - existing.stars + stars;
        newAvg = newCount > 0 ? sum / newCount : 0.0;
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
        newCount = oldCount + 1;
        final sum = (oldAvg * oldCount) + stars;
        newAvg = sum / newCount;
      }

      final roundedAvg = (newAvg * 10).round() / 10.0;

      final batch = _writes.begin();
      batch.set('${FirestorePaths.reviews}/$docId', ReviewModel.toMap(review));
      batch.update(targetPath, {
        FirestoreFields.ratingAvg: roundedAvg,
        FirestoreFields.ratingCount: newCount,
      });

      await batch.commit();
      return Result.success(review);
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
