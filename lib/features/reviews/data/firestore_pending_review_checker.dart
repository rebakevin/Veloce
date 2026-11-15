import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veloce/core/constants/firestore_fields.dart';
import 'package:veloce/core/constants/firestore_paths.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/subject_type.dart';
import 'package:veloce/core/domain/services/pending_review_checker.dart';

/// Real implementation of [PendingReviewChecker].
///
/// Returns true if the user owes a review for any completed booking:
/// - As a renter: owes owner review (`user`) and car review (`vehicle`).
/// - As an owner: owes renter review (`user`).
class FirestorePendingReviewChecker implements PendingReviewChecker {
  const FirestorePendingReviewChecker({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<bool> hasPendingReview(String userId) async {
    // 1. Completed bookings where userId is renter
    final renterBookings = await _firestore
        .collection(FirestorePaths.bookings)
        .where(FirestoreFields.renterId, isEqualTo: userId)
        .where(FirestoreFields.status, isEqualTo: BookingStatus.completed.key)
        .get();

    for (final doc in renterBookings.docs) {
      final bookingId = doc.id;
      final ownerReviewId = '${bookingId}_${userId}_${SubjectType.user.key}';
      final carReviewId = '${bookingId}_${userId}_${SubjectType.vehicle.key}';

      final ownerReviewDoc = await _firestore
          .collection(FirestorePaths.reviews)
          .doc(ownerReviewId)
          .get();
      if (!ownerReviewDoc.exists) return true;

      final carReviewDoc = await _firestore
          .collection(FirestorePaths.reviews)
          .doc(carReviewId)
          .get();
      if (!carReviewDoc.exists) return true;
    }

    // 2. Completed bookings where userId is owner
    final ownerBookings = await _firestore
        .collection(FirestorePaths.bookings)
        .where(FirestoreFields.ownerId, isEqualTo: userId)
        .where(FirestoreFields.status, isEqualTo: BookingStatus.completed.key)
        .get();

    for (final doc in ownerBookings.docs) {
      final bookingId = doc.id;
      final renterReviewId = '${bookingId}_${userId}_${SubjectType.user.key}';

      final renterReviewDoc = await _firestore
          .collection(FirestorePaths.reviews)
          .doc(renterReviewId)
          .get();
      if (!renterReviewDoc.exists) return true;
    }

    return false;
  }
}
