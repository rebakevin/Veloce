import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veloce/core/constants/firestore_fields.dart';
import 'package:veloce/core/constants/firestore_paths.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/services/pending_review_checker.dart';

import '../domain/rules/pending_review_rule.dart';

/// Real implementation of [PendingReviewChecker].
///
/// Fetches the user's completed bookings and delegates the decision to
/// [PendingReviewRule].
class FirestorePendingReviewChecker implements PendingReviewChecker {
  const FirestorePendingReviewChecker({
    required this._firestore,
    this._rule = const PendingReviewRule(),
  });

  final FirebaseFirestore _firestore;
  final PendingReviewRule _rule;

  @override
  Future<bool> hasPendingReview(String userId) async {
    final renterBookings = await _completedBookings(
      FirestoreFields.renterId,
      userId,
    );
    final ownerBookings = await _completedBookings(
      FirestoreFields.ownerId,
      userId,
    );

    final required = _rule.requiredReviewIds(
      userId: userId,
      renterBookings: renterBookings,
      ownerBookings: ownerBookings,
    );

    for (final reviewId in required) {
      final doc = await _firestore
          .collection(FirestorePaths.reviews)
          .doc(reviewId)
          .get();
      if (!doc.exists) return true;
    }
    return false;
  }

  Future<List<BookingRef>> _completedBookings(
    String field,
    String userId,
  ) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.bookings)
        .where(field, isEqualTo: userId)
        .where(FirestoreFields.status, isEqualTo: BookingStatus.completed.key)
        .get();
    return [
      for (final doc in snapshot.docs)
        BookingRef(id: doc.id, status: BookingStatus.completed),
    ];
  }
}
