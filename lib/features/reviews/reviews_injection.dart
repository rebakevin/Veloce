import 'package:get_it/get_it.dart';

import 'package:veloce/core/domain/services/pending_review_checker.dart';

import 'data/pending_review_checker_stub.dart';

/// Registers the reviews feature's dependencies. Phase 6 swaps the stub for the
/// real [PendingReviewChecker].
void registerReviews(GetIt getIt) {
  getIt.registerLazySingleton<PendingReviewChecker>(
    () => const PendingReviewCheckerStub(),
  );
}
