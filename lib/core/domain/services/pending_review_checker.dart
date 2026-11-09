/// Whether a user still owes a review. Blocks new requests and approvals.
///
/// Phase 0 registers a stub that always answers `false`; Phase 6 replaces it.
abstract interface class PendingReviewChecker {
  Future<bool> hasPendingReview(String userId);
}
