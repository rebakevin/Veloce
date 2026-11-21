# Round 2: rules vs writes audit

Hand trace of every Firestore write and query in `lib/` against `firestore.rules` (emulator not available). Syntax check of the rules by reading: braces balanced, `duration.value(25, 'h')`, `existsAfter`, `getAfter`, `in [...]` and string concatenation are all valid; the `get`/`existsAfter` count for the happy-path batches (approve, cancel, pay, pickup, settle) stays under the 20-access-call batch limit. The one place it does not is the account eraser (R2R-04).

Happy path walked: register, publish car, search, request, approve, pay, pickup both sides, return, settle (no-issue), cancel, claim/agree/dispute/re-claim, reviews both ways, notifications, account deletion. Paths that work as written: register, publish, search, request, pay, cancel, pickup, start return, confirm return (except R2R-06), notifications read/mark/delete, reviews, favourites, repair expenses, vehicle edit/remove.

Counts: 3 blocker, 5 major, 9 minor, 5 test findings.

## Blockers

### R2R-01 [severity: blocker] [kind: bug]
- Where: `lib/core/data/models/caution_claim_model.dart` (`toMap`), rules `cautionClaims` create (firestore.rules:330-338) and update (:339-344)
- What: both rules require `request.resource.data.bookingId == bid`, but `CautionClaimModel.toMap` writes no `bookingId` (only originalAmount, currentAmount, reason, evidenceUrls, renterResponse, history, status, updatedAt). Every claim write is denied: submitClaim, respondToClaim (dispute and agree, whole transaction fails), reviseClaim, refundCaution (claim set to refunded). The claim, dispute, re-claim and agreed-settle paths cannot work.
- Evidence: model read; the rules test fixture `claim()` includes `bookingId`, which hides it (R2R-T3).
- Fix: add `FirestoreFields.bookingId: entity.bookingId` to `toMap` (or drop the field check from the rules and rely on the path id).
- Status: open

### R2R-02 [severity: blocker] [kind: bug]
- Where: `lib/features/handover/data/completion_writer.dart:_countCompletion`; rules users update (firestore.rules:139-147)
- What: the completer's batch does `update users/{renterId}` and `users/{ownerId}` with `completedCount: increment(1)`, including the signed-in actor. Rule 1 (`isSelf`) forbids changing `completedCount`; rule 3 requires `me() != uid`. The self update is rejected, so the whole settlement batch/transaction fails on every completion path (acknowledgeNoIssue, agreed claim, refundCaution). No booking can reach `completed` (and no review can follow).
- Evidence: rule logic by hand; no rules test covers completedCount +1.
- Fix: let a party bump its own count by exactly 1 too (drop `me() != uid` from rule 3, bounded like the rating aggregate), or only bump the counterparty and let the other side's own next action bump theirs (not workable in one write). Add a rules test.
- Status: open

### R2R-03 [severity: blocker] [kind: bug]
- Where: `lib/features/booking/data/firestore_booking_repository.dart:837` (`_pendingOverlaps`); rule `bookings` read (firestore.rules:187)
- What: the query is `bookings where vehicleId == X, status == pending, startDate < end` with no `ownerId` (or `renterId`) filter. The read rule is `isParty(resource.data)`, which the engine cannot prove for the query, so the whole query is denied. `approve()` calls it before the batch, so every approval fails with a mapped permission failure. `FirestoreVehicleRepository.bookingsOf` already shows the correct shape (adds `ownerId == me`).
- Fix: add `.where(FirestoreFields.ownerId, isEqualTo: ownerId)` and update `firestore.indexes.json` (vehicleId, ownerId, status, startDate).
- Status: open

## Major

### R2R-04 [severity: major] [kind: bug]
- Where: `lib/features/profile/data/firestore_account_eraser.dart:eraseAll`
- What: a batch may use at most 20 access calls (10 per op). Each booking contributes at least 2 distinct calls (`get(booking)` for checklists/private/claim/lock/block deletes, plus `existsAfter(booking)` for calendarBlock, claim and lock), each vehicle 1 (`get(vehicle)` for photos/documents). A user with more than about 10 bookings plus cars cannot delete the account; splitting by 450 does not help.
- Fix: batch per group of at most ~8 bookings (booking, its children and its lock/block/claim together), cars per group of ~15; rerunnable as it is now.
- Status: fixed (eraser now batches per booking/car, see round-2-phases-1-3.md fix log; emulator check pending)

### R2R-05 [severity: major] [kind: bug]
- Where: `firestore_account_eraser.dart:109-122` (split path when `plan.size >= 450`)
- What: `children` (calendarBlocks, cautionClaims, renterLocks) are deleted in a batch before their booking. Their rules use `!existsAfter(booking)`, which is then true only if the booking is already gone, so each is denied unless the booking is cancelled/expired/declined (blocks) or never (claims). The comment "accept ... in any booking status" is only true in the single-batch path.
- Fix: put those three in the same batch as their booking (combine with R2R-04 chunking).
- Status: fixed (eraser now batches per booking/car, see round-2-phases-1-3.md fix log; emulator check pending)

### R2R-06 [severity: major] [kind: bug]
- Where: `lib/features/handover/data/firestore_handover_repository.dart:619-634` (`confirmReturn`)
- What: `startReturn` deletes the renter lock so the renter can book again. When the second return confirmation lands, `confirmReturn` reads the lock and, if it now belongs to a new booking, returns `ValidationFailure('The renter lock belongs to another booking.')`, blocking the return/settlement of the old booking forever. The lock is not this booking's, so it should simply be left alone.
- Fix: skip (do not fail) when the lock's `bookingId` differs.
- Status: open

### R2R-07 [severity: major] [kind: gap]
- Where: rules `bookings` delete (:204), `transactions` delete (:325), `calendarBlocks`/`renterLocks`/`cautionClaims` delete
- What: "account deletion only" is not enforced. Any party can delete a booking at any status (active, in claim review), and either party can delete ledger rows (append-only breaks: a party can erase evidence of a charge or claim deduction). Once the booking is gone the `!existsAfter` branches let that party delete the block, lock and claim as well.
- Fix: only allow booking/ledger delete when the booking is terminal (cancelled, expired, declined, completed) or the caller is erasing (e.g. `before.status in [...]`); accept that a deleted account leaves rows, or mark them instead of deleting.
- Status: open

### R2R-08 [severity: major] [kind: gap]
- Where: rules `validTransition` rows for `return`/`review` (:110-127), `transactions` create (:307-322), `cautionClaims` update
- What: either party can move return -> review/completed and write `cautionDecision`, lateFee, lateFeeWaived, so the renter can waive its own late fee, complete the booking and append `refund` rows up to cautionFee, bypassing the owner's claim. Ledger rows have no uniqueness (any party can add unlimited `release`, `payout`, `refund`, `claim_deduction`, `late_fee` rows each up to the bound; after completion also). Claim `currentAmount` can be set by either party to any value 0..originalAmount with no `renterResponse`/status tie. The only checks are per-row bounds.
- Fix: per transition, restrict by role (owner settles/claims, renter agrees/acks), use deterministic ledger ids (`{bookingId}_{type}`) with a create-only rule so duplicates fail, tie settlement rows to `cautionDecision`/claim amount.
- Status: open

## Minor

### R2R-09 [severity: minor] [kind: gap]
- Where: rules users update (:141-147), `ratingChange` (:22-26), reviews create (:371-378)
- What: aggregates are bounded but not proven: any signed-in user can raise any user's or car's `ratingCount` by 1 repeatedly and set `ratingAvg` to any value 1..5, and bump any user's `completedCount` by 1 repeatedly. Reviews do not tie `subjectId` to the booking's other party or vehicle (a party of any completed booking can review any user or car).
- Fix: accept and document, or bind the subject (`subjectId in [bk.ownerId, bk.renterId, bk.vehicleId]`) in the review rule.
- Status: open

### R2R-10 [severity: minor] [kind: bug]
- Where: `lib/features/reviews/data/repositories/firestore_review_repository.dart:138-170` (`notifyReviewDue`); rule notifications read (:392)
- What: `transaction.get(ref)` on a notification that does not exist is evaluated with `resource == null`, so `resource.data.userId` errors and the read is denied. The first call therefore always fails (the result is ignored by `PostRentalCubit`, so it is silent); the review-due notification is never created this way (the batch in CompletionWriter creates one anyway, so it is also duplicated if it worked).
- Fix: drop the get and `set` with a fixed id (create-only), or allow `resource == null ||` in the read rule; remove the duplicate writer.
- Status: open

### R2R-11 [severity: minor] [kind: bug]
- Where: `firestore_booking_repository.dart:207,742-754` (`_isLockLive`); rule renterLocks update (:244-248)
- What: (a) the holder booking is read with `_readBooking`; if it belongs to a different owner the read is denied (`isParty`), the failure is not NotFound, so the lock is treated as live and the approval blocked. (b) the app treats an effective (time-based) expiry as dead, but the rule needs the stored status in expired/cancelled/declined, so the batch is rejected until the renter's own sweep updates it; the owner sees "already booked".
- Fix: treat read failures of other parties' bookings as "ask the rules"; or sweep the holder first; align the rule with `payDeadline`/`expiresAt` (`request.time > ...`).
- Status: open

### R2R-12 [severity: minor] [kind: bug]
- Where: `lib/features/booking/domain/services/cancellation_policy.dart` (`canCancel(pending)`) vs rules :51-55
- What: the repo lets an owner cancel a pending booking (owners decline instead); the rule only allows the renter for `pending -> cancelled`. If any owner UI exposes cancel on a pending request it is rejected.
- Fix: gate it in the repo/UI by role, or allow `isParty` in the rule.
- Status: open

### R2R-13 [severity: minor] [kind: gap]
- Where: rules `validTransition` pending/approved -> expired (:55-59, :70-74)
- What: no `request.time > expiresAt / payDeadline` check, so either party can expire a live pending/approved booking early (the owner can kill an approved booking before the renter's deadline, free of the cancel flow).
- Fix: add `request.time >= resource.data.expiresAt` (pending) and `>= payDeadline` (approved).
- Status: open

### R2R-14 [severity: minor] [kind: gap]
- Where: rules `cautionClaims` create (:330)
- What: no status check on the booking (a claim can be created for a pending or confirmed booking of the owner) and no check that the claim `status`/`renterResponse` start at open/none.
- Fix: require `bk(bid).status in ['return','review']` (note a claim is created in the same batch/transaction as the move to review, so use `bk` = return) and the initial field values.
- Status: open

### R2R-15 [severity: minor] [kind: bug]
- Where: rules bookings create (:201), `FirestoreRequestRepository.createBooking` (`expiresAt: now.add(24h)`)
- What: `expiresAt <= request.time + 25h` uses the client clock; a phone running more than 1 h ahead cannot create requests. Not wrong, but unforgiving; consider setting `expiresAt` from a server-derived value or widening.
- Status: open

### R2R-16 [severity: minor] [kind: bug]
- Where: rules bookings read (:187); `_readBooking`, `BookingLookup.byId`, finance lookups
- What: a get of a booking that no longer exists (e.g. erased by the other party) is denied (`resource` is null) rather than returning not-found, so callers that branch on `NotFoundFailure` (e.g. `_isLockLive`) see a permission failure.
- Fix: `allow read: if resource == null || isParty(resource.data)` (or `get` guarded).
- Status: open

### R2R-17 [severity: nit] [kind: gap]
- Where: rules vehicles create/delete (:156-165), calendarBlocks create (:229)
- What: any signed-in user (not only role owner) can create a car; an owner can delete a car with live bookings; a calendar block is not checked against the booking's vehicle/dates (only `bkafter(id)` party and status).
- Status: open

## Test file: tool/rules-test/firestore.rules.test.js

### R2R-T1 [severity: major] [kind: test-gap]
- Where: test `booking create` > "allows a renter to create a pending booking and its contact in one batch" (:128-150)
- What: the notification in the batch is `{userId, title}` without `read: false`; the rule `request.resource.data.read == false` errors on a missing field, so the batch is rejected and the test fails.
- Fix: add `read: false` (and `type`, `createdAt`).

### R2R-T2 [severity: major] [kind: test-gap]
- Where: `pickup (confirmed to active)` > "lets a party move to active with both pickup timestamps" (:263-285) and `ledger entries at pickup` > "commits pickup and the three rows in one batch" (:493-516)
- What: one party sets both `ownerPickupConfirmedAt` and `renterPickupConfirmedAt`. `ownPickupSideOnly` forbids touching the other side's stamp, so these now fail. The real second confirmation only adds its own stamp.
- Fix: seed the other side's stamp in the booking and send only the actor's stamp.

### R2R-T3 [severity: minor] [kind: test-gap]
- Where: `cautionClaims` fixture `claim()` (:632-638)
- What: includes `bookingId` while the app's `toMap` omits it (R2R-01) and lacks `evidenceUrls`/`history`/`status`, so the rules test passes while the app is rejected. Build the fixture from the real wire map.

### R2R-T4 [severity: nit] [kind: test-gap]
- Where: `reviews` > "lets the author, the subject and a booking party delete" (:914-935)
- What: still passes, but the title and comments are stale: the "booking party" case passes only because OWNER owns car-1. Add negatives: a booking party who is neither author nor subject (renter deleting the owner's review of them? n/a; renter deleting a car review by another renter) must fail; rename the test.

### R2R-T5 [severity: major] [kind: test-gap]
- What: no coverage for: users create (role, ratingCount/ratingAvg/completedCount == 0) and completedCount +1 (the seed lacks the field so "rejects `completedCount: 10`" passes only because of the missing field); vehicles create (status in published/paused, ratings == 0, ownerId == me); booking create negatives (unpublished car, own car, `rentalFee != days*dailyRateApplied`, `expiresAt` > now+25h, missing expiresAt); reviews create negatives (wrong id scheme, booking not completed, stars 0/6/2.5, non-party author); notifications create with `read: true`; the whole Phase 4 block (approve batch, renterLocks create/replace/delete, calendarBlocks create/delete, decline/cancel/expire transitions with and without `serverTimestamp`, agreement ack, charge/refund rows, booking private contact read by status); transactions delete; account-deletion batch (R2R-04/05); the `at == request.time` check with a client Date (must fail). `package.json` description still says "Phase 3 to 5".
