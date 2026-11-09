import 'package:veloce/core/domain/services/pending_review_checker.dart';

/// Phase 0 stand-in: nobody owes a review. Phase 6 replaces it.
class PendingReviewCheckerStub implements PendingReviewChecker {
  const PendingReviewCheckerStub();

  @override
  Future<bool> hasPendingReview(String userId) async => false;
}
