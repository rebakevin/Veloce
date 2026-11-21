# Phase 6 findings (reviews, notifications, finances)

Audited: lib/features/{reviews,notifications,finances}, their tests, `firestore.rules` (reviews, notifications, rating aggregates, repairExpenses), `firestore.indexes.json`, other phases' NotificationWriter callers.
Tooling: `flutter analyze` = No issues found. `flutter test test/features/reviews test/features/notifications test/features/finances` = 86 tests, all passed.

## Verdict

The UI-to-repository path of Phase 6 exists and is mostly coherent: review create/edit with id `bookingId_authorId_subjectType` and aggregate update in one batch, a working pending-review checker (completed bookings only, owner->renter, renter->owner + car), notifications bloc with badge/deep link/mark/clear, finances repository with a correct per-booking caution offset, chart/table/per-car list and renter payments. The code is lint-clean and the suite is green. The weak points are (1) notification event types: `payment_deadline`, `late_fee_applied` and `review_due` are never written by any phase, and "claim changed" is written under the wrong type (`return_confirmed`); (2) rules: reviews can be deleted by the reviewed user or any booking party (contradicting "never deleted"), review create/update shape is not validated, and notification update/create are not restricted to `read`/the real recipient flow; (3) a probable Firestore rules problem where the owner `repairExpenses` list query (which drives Total losses) is likely denied because the read rule calls `get()` on an unconstrained document field, and no rules test runs a list query; (4) review aggregates are computed from a client read outside the batch and from a 1-decimal rounded average (drift, lost updates), and a deleted subject doc/vehicle makes a review impossible, which would permanently block the author through the pending-review rule; (5) renter payments omits the status and lists internal owner-side rows; (6) tests for the three Firestore repositories and the checker do not exist, and two "calculation" tests re-implement the arithmetic inline and test no production code.

## TODO tasks

| Task | Mark | Notes |
| --- | --- | --- |
| 6.A ReviewRepository create/edit, id scheme, aggregates in batch | bug | Works on happy path; F6-04, F6-05, F6-06, F6-07 |
| 6.A Real PendingReviewChecker | ok | Correct (completed only, correct ids); minor perf F6-15 |
| 6.A Screens (write/edit, car, user, my reviews) | bug | No completed/party guard in ReviewBloc, F6-08 |
| 6.A PostRentalSection, ReviewsPreviewSection | ok | Wired in booking detail and public profile |
| 6.B NotificationsBloc (stream, unread, mark, clear, deep link) | ok | Failures of mark/delete swallowed, F6-16 |
| 6.B Icon per type, dot, badge, notifications_enabled | ok | Badge in `role_shell.dart`; off => hidden, badge 0 |
| 6.B Event types written | gap | F6-01, F6-02 |
| 6.C FinancesRepository earned/losses incl. caution offset | bug | Formulas right; F6-03 (rules vs query), F6-12 |
| 6.C Finances screen (toggles, tiles, per-car list) | gap | No chart empty state F6-10; per-car list F6-13 |
| 6.C Chart | ok | Paired bars, legend, tooltip; uses `DateTime.now()` F6-17 |
| 6.C Table + View all (>5 only) + total = tiles | ok | Tested; period not carried to transactions page F6-11 |
| 6.C Car finances + transactions page | ok | Same caveats as above |
| 6.C FinancesCard | ok | Fetches this month via repository |
| 6.C Empty states, RWF, no export | gap | F6-10 |
| 6.D Renter payments | gap | F6-09 |
| 6.E Rules and indexes | bug | F6-03, F6-04..F6-06 (rules), indexes ok |
| 6.E Rating aggregate guard | ok | Bounded only (documented); F6-07 |
| 6.F Unit tests | test-gap | F6-14 |
| 6.F Bloc tests | ok | FinancesBloc, NotificationsBloc, ReviewBloc, cubits present |
| 6.F Widget test table 5 rows | ok | Passes |
| 6.G Report | ok | `docs/report/phase-6-draft.md` exists (not re-read) |
| 6.G Demo segment F | needs-human | Unticked, manual |

## Findings

### F6-01 [severity: major] [kind: gap]
- Where: callers of `NotificationWriter` in `lib/features/{booking,discovery,handover}/data/*` (none of them uses these types)
- What: `NotificationType.paymentDeadline`, `lateFeeApplied` and `reviewDue` are never written anywhere in `lib/`. Phase 6 acceptance requires all event types. The payment-deadline path (booking approved, awaiting payment) and review due (at `completed`) have no notification at all; the late fee ledger row is written in handover (lines ~980, 1288, 1613) with no notification.
- Evidence: `grep -rE "NotificationType\.[a-zA-Z]+" lib` outside the notifications feature returns only requestReceived/Approved/Declined/Expired, bookingCancelled, paymentReceived, pickupConfirmed, returnConfirmed. Seed data only fakes them.
- Fix: add writes in the handover completion batches (`reviewDue` to both parties, `lateFeeApplied` to the renter and owner) and a deadline reminder (lazy, in `ExpirySweeper`/activity load, writing once per booking). Needs a decision on who owns it (Phase 4/5 files).
- Status: partly fixed: `reviewDue` is written (idempotent, id `review_due_<booking>_<user>`) when PostRentalCubit detects a due review (`ReviewRepository.notifyReviewDue`). Still open for main/handover/booking: `paymentDeadline`, `lateFeeApplied`

### F6-02 [severity: minor] [kind: bug]
- Where: `lib/features/handover/data/firestore_handover_repository.dart` lines ~773, 892, 1011, 1020, 1149, 1320, 1329, 1447, 1654, 1663
- What: claim submitted/disputed/revised/settled and the final "Rental completed" notifications all use `NotificationType.returnConfirmed`, so "claim changed" shows the return icon and cannot be told apart by type. Spec 8.1 lists "claim amount changed" as its own event.
- Evidence: reading the writer calls and titles ('Caution claim revised', 'Rental completed').
- Fix: use `claimChanged` for the claim titles, `reviewDue` for completion (see F6-01).
- Status: open

### F6-03 [severity: major] [kind: bug] (needs-human to confirm on emulator)
- Where: `firestore.rules:302-304` (repairExpenses read) vs `firestore_finances_repository.dart` repair query (`where ownerId == uid`)
- What: the read rule is `resource.data.ownerId == me() && bk(resource.data.bookingId).ownerId == me()`. For a list query Firestore must prove the rule from query constraints; `get()` on `resource.data.bookingId` is not constrained by the query, so the list is very likely denied with permission-denied. Result: `getOwnerFinances` returns a failure and the whole finances screen shows an error (and the home `FinancesCard`), not just losses.
- Evidence: `tool/rules-test/firestore.rules.test.js` (lines 722-773) only does `getDoc`/`setDoc`, never a collection query, so the suite cannot catch it. Not run on an emulator in this audit.
- Fix: add an emulator test with `getDocs(query(repairExpenses, where('ownerId','==',OWNER)))`; if it fails, drop the `bk(...)` clause from read (ownerId is already checked on create against the booking), and keep it on create/update.
- Status: fixed on the client side: the query already has `where ownerId == uid` and repairExpenses docs store ownerId, so with the rule now needing only ownerId == me() the list is rule-provable. Confirm on emulator (needs-human)

### F6-04 [severity: major] [kind: bug]
- Where: `firestore.rules:333-337` (reviews delete)
- What: delete is allowed for the author, for the reviewed user (`subjectId == me()`) and for any booking party. A reviewed user can delete a bad review about themself with a hand-made client call; aggregates are not adjusted. Spec/acceptance: reviews are never deleted except account deletion (ADR 0002).
- Evidence: rule text. `rules-test` covers it as intended behaviour.
- Fix: restrict delete to account-deletion cases the client really needs (author only, or batch with the account delete), or remove it and delete through a function.
- Status: open

### F6-05 [severity: minor] [kind: bug]
- Where: `firestore.rules:325-331` (reviews create/update)
- What: create only checks `authorId == me()`. It does not check the document id equals `bookingId_authorId_subjectType`, that the booking is completed and the author a party, that `subjectId` matches the booking, that `stars` is 1..5 and `comment` non-empty. A crafted client can post duplicates with other ids, review any user, or write stars = 99. Update also lets the author change `stars` to any value and `createdAt`. The "same author cannot review the same subject twice" rule is client-only. (Already noted in the merging doc for the completed-booking part.)
- Fix: validate id with `id == bookingId + '_' + authorId + '_' + subjectType`, `isParty(bk(bookingId))`, `bk(...).status == 'completed'`, stars range and comment size; forbid `createdAt` change on update.
- Status: open

### F6-06 [severity: minor] [kind: bug]
- Where: `firestore.rules:338-341` (notifications)
- What: owner `update` is unrestricted (can change title/text/type, not only `read`), contrary to "writable by owner only for read/clear". `create` is allowed to any signed-in user for any `userId` with any content (spam/forgery of notifications to others; the writer is a client).
- Fix: `update` only when `changed().hasOnly(['read'])`; on create require the author be a party of `bookingId` or the target be the booking counterpart, and `read == false`.
- Status: open

### F6-07 [severity: major] [kind: bug]
- Where: `lib/features/reviews/data/repositories/firestore_review_repository.dart:50-110`
- What: (a) the subject doc and the existing review are read outside the batch, so two concurrent reviews of one car/user both write `count+1` from the same base and lose one update (rules accept it); (b) the new average is rebuilt from the stored 1-decimal rounded `ratingAvg * ratingCount`, and the result is rounded again, so rounding error accumulates across reviews and edits (e.g. 5,5,4 stored as 4.7; reconstructed sum 14.1, not 14). The acceptance criterion "average is correct after an edit" can fail after a few operations; (c) if the subject document does not exist (deleted account, deleted vehicle) `batch.update` fails and the review can never be written. Because the pending-review rule keeps requiring that review, the author stays blocked from requests/approvals forever. Vehicle deletion exists (`vehicle` repository `write.delete(vehiclePath)`).
- Evidence: code read; `rating_average_test.dart` re-implements the formula inline, so it does not exercise this code.
- Fix: read inside a transaction (or store `ratingSum` alongside, or recompute from the reviews of the subject), keep the unrounded value and round only for display; if the subject doc is missing, write the review only (or exclude missing subjects in `PendingReviewRule`).
- Status: fixed

### F6-08 [severity: minor] [kind: bug]
- Where: `lib/features/reviews/presentation/bloc/review_bloc.dart` `_onStarted` / `_onSubmitted`
- What: any user (or a party before completion) who opens `/booking/:id/review` can write a review. `isRenter = currentUserId == booking.renterId`, so a non-party is treated as the owner and posts a renter review; the booking status is never checked (the pending-review checker only counts completed bookings, but a review for an active booking can still be written and edited).
- Fix: after loading the booking, fail with `PermissionFailure`/`ValidationFailure` unless the user is a party and `status == completed`.
- Status: fixed

### F6-09 [severity: major] [kind: gap]
- Where: `lib/features/finances/data/repositories/firestore_finances_repository.dart` `getRenterPayments`, `renter_payments_page.dart`
- What: spec lists payment, caution refund, claim deduction, late fee, cancellation refund with date, booking, amount and status. The page (a) shows no status, (b) does not tell caution refund from cancellation refund (both "Refund"), (c) lists every ledger row with `renterId == me`, including `release`, `platform_fee` and `payout` (owner-side bookkeeping, which carries the renter id), shown as "Rental fee released", "Platform fee", "Payout", (d) shows no sign or direction, (e) does N+1 booking and vehicle lookups.
- Fix: filter to charge/refund/claim_deduction/late_fee; derive the refund label from the booking state/claim; show `entry.status` chip; batch the lookups.
- Status: fixed (n+1 lookups reduced to one per distinct booking/vehicle, not batched)

### F6-10 [severity: minor] [kind: gap]
- Where: `owner_finances_page.dart` (Chart branch), `finance_chart.dart`
- What: spec 7.5 wants an empty state in both views. The Table has one; the Chart renders an empty 0..100000 axis with no message, and the tiles show 0.
- Fix: show `EmptyState` when `transactions.isEmpty` in chart mode.
- Status: fixed

### F6-11 [severity: minor] [kind: bug]
- Where: `owner_transactions_page.dart`, `owner_finances_page.dart` onViewAll
- What: "View all transactions" opens a page with its own new `FinancesBloc` that starts on `thisMonth`. If the user was on This year, the list switches back to the month, although spec 7.3 says "full list for the selected period". The data is fetched again.
- Fix: pass the period (query parameter or `extra`) or share the bloc.
- Status: fixed

### F6-12 [severity: nit] [kind: spec-drift]
- Where: `firestore_finances_repository.dart:35,119`
- What: earned = `release.amount - 2000` with a constant, spec says `release - platform_fee` entry. Equivalent while the fee is fixed; breaks if the fee changes. Also no `status` filter on ledger rows (rules only write `success`).
- Status: fixed

### F6-13 [severity: nit] [kind: bug]
- Where: `firestore_finances_repository.dart` step 8
- What: the per-car list is built from the owner's current vehicles, so earnings of a deleted car appear in the tiles and table but in no per-car row; the share denominator still includes them.
- Status: open (deleted cars still have no per-car row; needs a CarFinanceShare without a Vehicle)

### F6-14 [severity: major] [kind: test-gap]
- Where: `test/features/finances/domain/finances_calculation_test.dart`, `test/features/reviews/domain/rating_average_test.dart`
- What: no test touches `FirestoreReviewRepository`, `FirestoreFinancesRepository`, `FirestoreNotificationsRepository` or `FirestorePendingReviewChecker` (no fake Firestore in `test/`). The two files above re-implement the arithmetic inline and test no production code (acknowledged for finances in the merging doc; the rating one is the same). So earned = release - fee + late fee, period bucketing of the repository, caution offset through the repository, aggregates, and "same author cannot review twice" have no real test. Only `RepairLossAllocator` and `PendingReviewRule` are real unit tests.
- Fix: add `fake_cloud_firestore` (or extract pure calculators) and test the repositories; add `FinancesBloc`/`FinanceChart` bucketing tests with a fixed clock.
- Status: fixed (calculation moved to OwnerFinanceCalculator / RatingAggregate / RenterPaymentKind and tested; the Firestore repositories themselves still have no fake-Firestore test, pubspec not mine)

### F6-15 [severity: nit] [kind: gap]
- Where: `firestore_pending_review_checker.dart`
- What: sequential reads (2 queries plus one `get` per required review) on every request/approval; fine for demo, slow for many bookings. Result is correct.
- Status: open (nit, correct but sequential)

### F6-16 [severity: nit] [kind: gap]
- Where: `notifications_bloc.dart` `_onMarkReadRequested`, `_onDismissed`, clear/mark-all
- What: the `Result` of repository calls is ignored; a permission or network failure is silent. After a stream error there is no retry other than `NotificationsStarted` from the error view. The bloc is a lazy singleton bound at app start; ok on account switch via `session.changes`.
- Status: open (nit, notification action failures still silent)

### F6-17 [severity: nit] [kind: bug]
- Where: `finance_chart.dart:24`
- What: bucket count uses `DateTime.now()` instead of the injected `Clock`, while the repository uses `Clock`, so tests with a fixed clock and the chart can disagree around month boundaries.
- Status: fixed

### F6-18 [severity: minor] [kind: needs-human]
- What: on a device/emulator verify: the badge updates live, deep link opens the right booking for both roles, notifications switch off hides the list and badge, the seed scenarios (`p6-*` accounts), chart tooltip tap, and F6-03 (list query on `repairExpenses`) plus the deployed indexes (`firestore.indexes.json` has transactions ownerId/at, ownerId/vehicleId/at, renterId/at, reviews subjectType/subjectId/createdAt, authorId/createdAt, notifications userId/createdAt; all queries read here are covered). Demo segment F and Figma screenshots remain open.
- Status: needs-human

## Counts
Blocker 0.
Major: F6-01, F6-03, F6-04, F6-07, F6-09, F6-14 (6). Minor: F6-02, F6-05, F6-06, F6-08, F6-10, F6-11, F6-18 (7). Nit: F6-12, F6-13, F6-15, F6-16, F6-17 (5).

## Fix log
- F6-07: new `lib/features/reviews/domain/services/rating_aggregate.dart`; `firestore_review_repository.dart` rebuilds the aggregate from the real stars of the subject's reviews inside a transaction (retries if the stored count changed, tolerates a missing subject doc, stores the unrounded average); `reviews_injection.dart` no longer passes `writes`.
- F6-08: `review_bloc.dart` rejects non-parties (PermissionFailure) and non-completed bookings (ValidationFailure) on start and submit.
- F6-01 (reviewDue): `review_repository.dart`, `firestore_review_repository.dart` (`notifyReviewDue`), `post_rental_cubit.dart`.
- F6-09/F6-12: `finances/domain/enums/renter_payment_kind.dart`, `domain/services/owner_finance_calculator.dart`, `renter_payment_item.dart` (kind), `firestore_finances_repository.dart`, `renter_payments_page.dart` (status chip, sign, labels, hidden internal rows; fee row, success-only).
- F6-10/F6-11/F6-17: `owner_finances_page.dart` (chart empty state, period query param, clock), `finance_chart.dart` (`now`), `finance_period.dart`, `finances_routes.dart`, `owner_transactions_page.dart`, `finances_bloc.dart` (`FinancesStarted.period`).
- Tests: reviews `rating_average_test.dart`, `review_bloc_test.dart`, `post_rental_cubit_test.dart`; finances `owner_finance_calculator_test.dart`, `renter_payment_kind_test.dart`, `finance_period_test.dart`, `finances_bloc_test.dart`, page tests; removed `finances_calculation_test.dart`.
