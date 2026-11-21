# Round 2 audit: Phases 4-6 (booking, handover, reviews, notifications, finances)

Scope: lib/features/booking, handover, reviews, notifications, finances, read against `firestore.rules`, `firestore.indexes.json` and the round 1 Fix logs. Nothing was edited except this file.

Checks run: `flutter analyze` (no issues). `flutter test test/features/booking test/features/handover test/features/reviews test/features/notifications test/features/finances` (273 tests, all passed). The suite is green, but none of the findings below is covered by a test: the repositories have no fake-Firestore or rules tests for these paths.

Counts: blocker 2, major 1, minor 7, nit 3. Total 13.

## Round 1 fixes verified in code

Worked as claimed: F4-01 (`pickupDeadline`, approve refuses only a past deadline), F4-02 (single-flight `_sweeps`, per-booking skip), F4-03 (state rebuilt after await), F4-05 (`_unrecordedCharges` retry), F4-08 (owner lists apply lock), F4-10/11/12/13, F5-03 (lock deleted in `startReturn` and `confirmReturn`), F5-04 (`handoverActionsFor` per role/status, every link has a usable screen), F5-05 (late fee preview, waive/reduce/restore, `ownerAdjustedFeeOf`), F5-11 (receipts via `MediaStorage`, no `firebase_storage` import left in lib, DI moved to `handover_injection.dart`), F6-07 (aggregate rebuilt in a transaction), F6-09 (`RenterPaymentKind`, bookkeeping rows hidden). Every `NotificationType` is written by at least one path with a booking deep link to `RouteNames.booking(id)`, and `userId` is always the intended recipient. Held balance: charge = rental + caution; release = rental; settlement refund = caution - claim - late fee >= 0, so the balance ends at 0 on the happy, claim, dispute-then-refund and cancel (refund = totalPayable) paths.

Half-finished: F4-07 (see R2B-05) and F6-01 `reviewDue` (see R2B-03).

## Findings

### R2B-01 [severity: blocker] [kind: bug]
- Where: `lib/features/handover/data/completion_writer.dart:71-79`, `firestore.rules:132-147`
- What: `CompletionWriter._countCompletion` increments `users/{uid}.completedCount` for both parties in the completing batch. The rules allow that field only through the third `users` update rule, which requires `me() != uid`. The self-update rule explicitly excludes `completedCount`. The completing user (renter on no-issue and agreed claim, owner on refund) therefore always writes their own doc and is denied, so the whole batch fails. No booking can reach `completed`, which also blocks reviews and the caution refund.
- Evidence: read of the three `allow update` clauses on `/users/{uid}`; `grep completedCount tool/rules-test` shows only a negative test, no completion test.
- Fix: in the third clause drop `me() != uid` (allow +1 by any signed-in user including self), or increment only the other party. Add a rules-test for a completion batch.
- Status: open (rules, main session)

### R2B-02 [severity: blocker] [kind: bug]
- Where: `lib/features/booking/data/firestore_booking_repository.dart:836-846` (`_pendingOverlaps`), `firestore.rules:187`
- What: approve runs `bookings.where(vehicleId==).where(status=='pending').where(startDate<).orderBy(startDate)`. The `bookings` read rule is party-only (`isParty(resource.data)`), and the query has no `ownerId` or `renterId` constraint, so Firestore cannot prove it and rejects the whole query with permission-denied. `approve` returns that failure before writing anything, so an owner can never approve a request. The same query was already flagged for vehicles in F2-01.
- Evidence: rule and query read side by side; failure is returned at the `overlapsResult` check.
- Fix: add `.where(ownerId, isEqualTo: ownerId)` and a composite index (ownerId, vehicleId, status, startDate) in `firestore.indexes.json`. Confirm on the emulator.
- Status: open (needs index, main session)

### R2B-03 [severity: minor] [kind: bug]
- Where: `lib/features/reviews/data/repositories/firestore_review_repository.dart:150-175` (`notifyReviewDue`), `completion_writer.dart:146-152`
- What: `notifyReviewDue` does `transaction.get` on `notifications/review_due_<b>_<u>`. For a missing doc the `read` rule evaluates `resource.data.userId` on null, which is denied, so the call always fails and the error is ignored by `PostRentalCubit`. The F6-01 fix therefore never writes anything; the only working `reviewDue` is the random-id one from `CompletionWriter`. If the get were allowed, the user would get two `reviewDue` notifications per booking.
- Fix: remove `notifyReviewDue` and the cubit call (completion already notifies), or share one fixed id and use a plain `set`.
- Status: open

### R2B-04 [severity: major] [kind: bug]
- Where: `firestore_review_repository.dart:96-101` and the `ratingChange` rule (`firestore.rules:14-19`)
- What: a review is refused when the stored `ratingCount` differs from the real number of reviews (retried 3 times, then "Ratings changed"). The count can drift: account deletion removes the author's reviews without touching the subject's aggregate, and seeded data can disagree. Once drifted, every new review of that user or car fails permanently; the rule also forbids a count lower than the stored one, so it cannot self-heal.
- Fix: on a mismatch, write the recomputed aggregate if the rules allow it (loosen `ratingChange` to accept the recomputed count), or have account deletion fix the aggregates. Add a test with a drifted count.
- Status: open

### R2B-05 [severity: minor] [kind: gap]
- Where: `firestore_booking_repository.dart:737-749` (`_isLockLive`), `firestore.rules:243-249`
- What: F4-07 is only partly effective. The holder booking of a lock belongs to another owner, so reading it is permission-denied and the lock counts as live. When it can be read, the client treats an approved booking past its deadline as dead, but the rule requires the stored status to be expired/cancelled/declined, so the write is refused ("already booked"). Net behaviour equals round 1 until the holder is swept.
- Fix: put `payDeadline` on the lock doc and let the rule compare it with `request.time`, or have the renter sweep clear it (it does on the renter's next start).
- Status: open

### R2B-06 [severity: minor] [kind: bug]
- Where: `completion_writer.dart:_notify`, `firestore_booking_repository.dart:_remindPaymentDeadline`, `lib/core/data/models/app_notification_model.dart:21`
- What: the acting user also notifies themselves with `FieldValue.serverTimestamp()`. A local snapshot of the live notifications query holds the pending write with a null `createdAt`, `WireReader.dateTime` throws, and `NotificationsBloc` shows `NotificationsFailure` until the server ack arrives. Likely, not run on a device.
- Fix: read with `ServerTimestampBehavior.estimate` or tolerate a null `createdAt` in the model.
- Status: open (needs device check)

### R2B-07 [severity: minor] [kind: bug]
- Where: `lib/features/reviews/presentation/pages/booking_review_page.dart:102-110`
- What: the `ErrorView` branch is only reached when `state.booking == null`, and its `onRetry` only acts when `state.booking != null`, so Retry does nothing. The widget has `bookingId` available.
- Fix: `onRetry: () => context.read<ReviewBloc>().add(ReviewStarted(bookingId))`.
- Status: open

### R2B-08 [severity: minor] [kind: gap]
- Where: `lib/features/booking/data/firestore_booking_repository.dart:690-729`
- What: the "payment due soon" reminder is deduplicated by querying for an existing notification. After the user dismisses or clears it, every later sweep inside the 6 h window creates it again.
- Fix: keep a `reminded` flag or check the notification id with a get that the rules allow.
- Status: open

### R2B-09 [severity: minor] [kind: spec-drift]
- Where: `lib/features/finances/domain/services/owner_finance_calculator.dart`
- What: `claim_deduction` rows are paid to the owner but never counted as earned; they only offset repair losses. When a deduction exceeds the repairs (or there are none), the owner received money that Finances does not show. Money for deleted cars is in the totals but in no per-car row (F6-13, still open), so shares do not add to 100 percent.
- Fix: decide the rule with the product owner; either count the unspent deduction as earned or document it.
- Status: needs-human

### R2B-10 [severity: minor] [kind: gap]
- Where: `firestore_booking_repository.dart:_sweep`
- What: a pending request cancelled by the renter lock is only displayed as cancelled (effective status); the sweep acts only on `expired`, so it stays `pending` in Firestore until its 24 h expiry. It then expires with the wrong reason ("The owner did not respond in time.").
- Fix: accept this and say so, or persist it as cancelled.
- Status: open

### R2B-11 [severity: nit] [kind: gap]
- Where: `lib/features/reviews/data/pending_review_checker_stub.dart`, `lib/features/handover/domain/services/held_balance_guard.dart`, `pubspec.yaml:57`
- What: `PendingReviewCheckerStub` is unreferenced dead code (not DI-registered, not in a barrel). `HeldBalanceGuard` and `LedgerBalance` are used only by tests, so the held-balance invariant is not checked at runtime. `firebase_storage` is still a dependency though no file in lib imports it.
- Fix: delete the stub, either use the guard in `CompletionWriter` or drop it, remove `firebase_storage` from pubspec (main session).
- Status: open

### R2B-12 [severity: nit] [kind: bug]
- Where: `firestore_notifications_repository.dart:markAllAsRead/clearAllNotifications`
- What: one batch with no chunking; more than 500 notifications make the batch fail silently (the bloc ignores the result, F6-16).
- Fix: chunk by 400.
- Status: open

### R2B-13 [severity: nit] [kind: bug]
- Where: `lib/features/handover/presentation/pages/caution_claim_page.dart:131-134`, `caution_settlement_page.dart`
- What: the claim page shows raw enum keys ("Claim status: open", "Renter response: none"); both pages use hard-coded `TextStyle` and a bare `Text` for lookup failures with no retry, and do not guard non-parties. Other pages in scope (detail, activity, payment, finances, reviews) have loading, empty and error states, dispose their controllers, use no `setState`, and showed no unbounded-constraint or landscape-overflow problems in the code.
- Fix: use `.label` fields, theme text styles and `ErrorView`.
- Status: open

## Reply summary

blocker 2, major 1, minor 7, nit 3 (13). Top: R2B-01 (completion batch denied by the `users` rules, so nothing completes), R2B-02 (approve's overlap query is unreadable under party-only rules), R2B-04 (review aggregate lock-out after count drift). `flutter analyze` clean; 273 tests pass.

## Round 2 fix log

Fixed (client side):
- R2B-03 / R2R-10: removed `notifyReviewDue` (repository, interface) and its call in `PostRentalCubit`; `CompletionWriter` already writes `reviewDue` for both parties, so a second writer would only duplicate it. Tests in `post_rental_cubit_test.dart` updated.
- R2B-04: `FirestoreReviewRepository.submitReview` no longer compares the stored `ratingCount` with the real count (no retry loop, no "Ratings changed" failure). It writes the aggregate recomputed from the real reviews. If the rules refuse the aggregate (permission-denied, e.g. count moved by more than 1), the review is saved without the aggregate and the next review recomputes it. Needs main session: loosen `ratingChange` to accept a recomputed count, otherwise a drifted aggregate is only repaired when it is off by 0 or +1. No fake-Firestore harness exists, so no repository test.
- R2B-05 (partial): `_isLockLive` treats a permission failure on the holder booking as "not live" so the rules decide (they refuse while the holder is live and allow replacing a stored-dead holder). An effectively expired but not stored-expired holder is still refused by the rules; fixing that needs `payDeadline` on the lock plus a rule (main session).
- R2B-07: Retry on the review page re-sends `ReviewStarted` (`BookingReviewView` now receives `bookingId`).
- R2B-08: payment-deadline reminder is remembered per session (`_reminded`), so a dismissed reminder is not recreated by later sweeps (a new app session can recreate it once).
- R2B-10: the renter sweep persists a pending request cancelled by the renter lock (`_cancelPendingByLock`, allowed by the renter pending->cancelled rule).
- R2B-11: deleted `pending_review_checker_stub.dart`, `held_balance_guard.dart` and `held_balance_guard_test.dart` (`LedgerBalance` in core stays). `firebase_storage` in pubspec is still for the main session.
- R2B-12: `markAllAsRead` / `clearAllNotifications` commit in chunks of 400.
- R2B-13: claim and settlement pages use enum `.label`, `AppTextStyles`, `LoadingView`/`ErrorView`; the claim load failure has a retry (`CautionClaimCubit.retryLoad`, tested). A booking lookup failure shows `ErrorView` without retry (the stream is owned by the page; no `setState` allowed).

Not changed:
- R2B-09: SPECS 7.1 says caution fees received through agreed claims are not counted as earnings and only reduce losses; TECHNICAL 5.2 gives Loss = max(0, repair - claim_deduction). The calculator already matches, so this is by design. Money of deleted cars missing from per-car rows (F6-13) stays open.
- R2B-06: needs a device check; the fix would be in core `AppNotificationModel` (tolerate a null `createdAt`), not in my folders.
- R2B-01, R2B-02: fixed by the main session (rules, index).
Tests: `flutter analyze` clean; 264+ tests in the five feature folders pass.
