# Phase 5 findings: handover, return and caution settlement

Audited: `lib/features/handover`, `test/features/handover`, `firestore.rules`, `tool/rules-test`, seed scenarios, against TODO Phase 5, `docs/tasks/phase-5-handover-caution.md`, SPECS §4.1/§6.5/§3, TECHNICAL §5/§10.
Tooling: `flutter analyze` clean (no issues). `flutter test test/features/handover` all 83 tests pass. The green tests do not prove the flows work: every cubit and repository test uses fakes, and the rules tests use a claim wire shape the app never writes (F5-01).

## Verdict

The pure domain logic is right: `LateFeeCalculator` (ceil to day, 1.3^days, cap, 30,000 / 69,000 / 119,700 on 100,000, 36,000 / 82,800 capped to 80,000 on 120,000), `PickupReleaseCalculator` (release rentalFee, platform_fee 2,000, payout rentalFee-2,000), `CautionSettlementCalculator` (late fee + claim + refund always equals the caution, so held ends at 0 on every settle path) and `ClaimAmountPolicy` (ceiling = min(current, original, caution)). The pickup release batch is a single transaction and the repository logic is careful. But the feature does not work end to end against the real rules and UI. The whole claim flow (submit, dispute, agree, re-claim, refund) is rejected by `firestore.rules` because the client writes `originalAmount`/`currentAmount` while the rules require `amount` and `bookingId`. The no-issue completion is rejected because the renter increments a field on a vehicle document they do not own. The renter lock is released only on the no-issue path, so after an agreed or refunded claim the renter stays locked out of new bookings. The owner has no UI route to submit a claim and the renter has none to acknowledge no-issue (HandoverSection links point to the wrong screens). The owner cannot waive or reduce the late fee (no UI writes `lateFeeWaived`), and the return screen has no late-fee preview. Evidence is pasted URLs, not photos, and repair receipts go to Firebase Storage instead of the Supabase `MediaStorage` the rest of the app uses. The blockers below must be fixed before the demo segment.

## Task table (TODO Phase 5)

| Task | Status | Notes |
|---|---|---|
| 5.A Repositories | gap | No `ClaimRepository`/use cases (documented drift, accepted). Repair repo bypasses models, `Result`, `MediaStorage` (F5-11) |
| 5.A ChecklistCubit (5 items, photo required, video optional, MediaStorage, remove before confirm) | ok (with minor gaps) | Logic and tests fine. UI has no video and no camera (F5-13); retry quirks (F5-12) |
| 5.A ConfirmPickup (both sides, release batch) | ok in code, bug via rules | One transaction, correct amounts, tested through calculator. Rules let one party activate alone (F5-06); no notification on the first confirm (F5-10) |
| 5.A StartReturn / ConfirmReturn, release renterLocks, set returnedAt | bug | Lock not released at return (F5-03); `returnedAt` set at start, acceptable |
| 5.A LateFeeCalculator, owner waive/reduce | bug / gap | Calculator ok. No way for the owner to waive or reduce (F5-05) |
| 5.A SettleCaution: no issue, claim | bug | No-issue completion denied by rules (F5-02); claim create denied (F5-01); claim form unreachable (F5-04); evidence is URLs (F5-07) |
| 5.A Agree / dispute / re-claim / refund | bug | All writes to `cautionClaims` denied (F5-01); math and ceiling correct |
| 5.A LogRepairExpense (edit/delete) | gap | Works against rules shape, but Firebase Storage not Supabase (F5-11) |
| 5.A Completion `completedCount` and notifications | bug | Wrong document, blocked by rules, only on one path (F5-02, F5-08) |
| 5.B Cubits | ok | Cubits instead of Blocs (documented) |
| 5.C Pickup checklist and waiting state | ok | HandoverSection shows waiting; no video (F5-13) |
| 5.C Return checklist with late-fee preview | gap | No preview on the checklist page (F5-05) |
| 5.C Owner settle screen | bug | Only "no issue" button, no claim entry (F5-04) |
| 5.C Renter claim screen | bug | Evidence as URLs, not photos; renter no-issue ack routed away (F5-04, F5-07) |
| 5.C Repair-cost screen | ok | Reachable from the section (review, completed) |
| 5.C HandoverSection per status | bug | Wrong routes for owner (returning, review) and renter (review no-issue) (F5-04) |
| 5.D Rules | bug | See F5-01, F5-02, F5-06, F5-09 |
| 5.E Unit tests (late fee table, cap, release, ceiling, held invariant) | ok | Present and passing; held guard not wired to runtime (documented) |
| 5.E Cubit tests | ok | Fakes only (F5-14) |
| 5.E Widget test (button disabled until a photo) | ok | `checklist_page_test.dart` |
| 5.F Report | ok | `docs/report/phase-5-draft.md` exists |
| 5.F Demo segment E | gap (unchecked) | Cannot succeed until F5-01..04 are fixed |

## Findings

### F5-01 [severity: blocker] [kind: bug]
- Where: `firestore.rules` `match /cautionClaims/{bid}` (create/update); `lib/core/data/models/caution_claim_model.dart` `toMap`; `tool/rules-test/firestore.rules.test.js:630-720`
- What: Rules require `request.resource.data.amount is number` (and `bookingId == bid`). The client (`CautionClaimModel.toMap`) and the seed write only `originalAmount`, `currentAmount`, `reason`, `evidenceUrls`, `renterResponse`, `history`, `status`, `updatedAt`; no `amount`, no `bookingId`. Reading a missing field makes the rule error, which denies. So `submitClaim`, `respondToClaim` (agree or dispute), `reviseClaim` and `refundCaution` all fail on the claim `set`, rolling back the booking update too. The rules tests pass only because their fixture has an `amount` field.
- Evidence: read rules and `toMap`; seed `tool/seed/scenarios/phase-5.js:119-148` has the same shape. Not run on the emulator (needs-human to confirm, see F5-15).
- Fix: Rewrite the claim rules on the real shape: `currentAmount`/`originalAmount` positive and `<= bk(bid).cautionFee`, `currentAmount <= originalAmount`, `originalAmount` immutable on update, `status`/`renterResponse` enum values, renter may change only `renterResponse`/`status`/`history`/`updatedAt`. Fix the rules test fixture to the real shape.
- Status: fixed (client side unchanged: keeps originalAmount/currentAmount/bookingId; rules by main session)

### F5-02 [severity: blocker] [kind: bug]
- Where: `firestore_handover_repository.dart:1651-1653` (`acknowledgeNoIssue`); `firestore.rules` `match /vehicles/{vid}` and `match /users/{uid}`
- What: Completion increments `vehicles/{vehicleId}.completedCount` while signed in as the renter. Vehicle rules only let the owner update (not the rating-only branch for others), so the transaction is denied and the no-issue completion never happens. In addition `completedCount` is a `users` field (TECHNICAL §4/§449, `UserAccount.completedCount`, shown on the decision page), not a vehicle field, and `users` rules forbid any client from changing it. The agree and refund completion paths never update any count at all (TODO "completion updates completedCount").
- Evidence: code and rules read.
- Fix: Decide where the aggregate lives (users, per TECHNICAL). Add a narrow rule allowing a party to a booking that moves to `completed` to increment `completedCount` by exactly 1 for the two parties (cannot be tied exactly to the batch, like `ratingChange`), then increment both parties in one shared helper called from all three completion paths. Remove the vehicle increment.
- Status: fixed (client: users.completedCount +1 for both parties via CompletionWriter in all three completion paths, vehicle increment removed; needs the users rule from main session)

### F5-03 [severity: major] [kind: bug]
- Where: `firestore_handover_repository.dart` `startReturn`, `confirmReturn`, `respondToClaim`, `refundCaution`
- What: `renterLocks` is deleted only in `acknowledgeNoIssue`. `startReturn` and `confirmReturn` only read it. The agree-claim and refund-after-dispute paths leave the lock, so the renter stays locked out of new bookings forever (one booking at a time). TECHNICAL §557 says the lock is released when the rental enters return. Rules already allow deletion at `return`/`review`/`completed`.
- Evidence: grep `transaction.delete(lockRef)` gives one hit (line 1643).
- Fix: Delete the lock in `startReturn` (matches spec), keep the ownership check; drop the duplicate delete later.
- Status: fixed (lock deleted in startReturn, and in confirmReturn for returns started earlier)

### F5-04 [severity: major] [kind: bug]
- Where: `lib/features/handover/presentation/widgets/handover_section.dart:104-152`; `caution_settlement_page.dart`; `caution_claim_page.dart`
- What: Routing is crossed. (a) Owner in `returning` with both returns confirmed goes to `/settle`, which has only "Confirm no issues"; the claim form lives only on `/claim` and nothing links to it. (b) Owner in `review` goes to `/settle`, which shows "not ready for this settlement action" for a claim; revise and refund exist only on `/claim`. (c) Renter in `review` goes to `/claim`; for a no-issue decision there is no claim doc and the page says "not ready for a caution claim", while the acknowledge button is only on `/settle`. Result: an owner cannot raise a claim, and a renter cannot acknowledge a no-issue, from the UI.
- Evidence: grep of route usage: only `HandoverSection` links to settle and claim.
- Fix: Single decision per status: owner returning goes to `/settle` with both "No issue" and "Make a claim" (push `/claim`); owner review goes to `/claim`; renter review goes to `/settle` when `cautionDecision == noIssue`, else `/claim`. Add widget tests per status.
- Status: fixed (handoverActionsFor routes per role/status; settle has No issue + Make a claim; unit tests per status)

### F5-05 [severity: major] [kind: gap]
- Where: `checklist_page.dart` (no late fee); no writer of `lateFeeWaived`; `LateFeeCalculator.ownerAdjustedFee` never called
- What: TODO and acceptance: the return screen previews the late fee, and the owner can waive or reduce it. The preview exists only on the settle page (and ignores a pending claim). No UI or repository method sets `lateFeeWaived` or an adjusted fee; the settlement always uses `booking.lateFeeWaived` (false). Rules already allow `lateFeeWaived` in the changed set.
- Evidence: grep of `lateFeeWaived`, `ownerAdjustedFee` across `lib`.
- Fix: Add a late-fee preview card to the return checklist (days, fee, cap) and an owner control on the settle screen (waive / reduce) that stores `lateFeeWaived` and an adjusted fee on the booking, used by all three settlement paths; test the cap with a claim.
- Status: fixed (late-fee preview card on the return checklist; owner waive/reduce/restore on the settle screen via adjustLateFee, stored in lateFeeWaived and booking.lateFee while returning; all settlement paths use it; needs the existing return rule row to keep allowing lateFee/lateFeeWaived)

### F5-06 [severity: major] [kind: bug]
- Where: `firestore.rules` `validTransition` (pickup rows)
- What: The second-confirmation rule checks only that both timestamps are non-null after the write and that the writer is a party. One party can set both `ownerPickupConfirmedAt` and `renterPickupConfirmedAt` in one write and activate the booking (and then write the release, platform_fee and payout entries) without the other side. The first-confirmation row also lets a party set the other side's timestamp. Same for return confirmations. The `return` to `review` row does not check both return confirmations.
- Evidence: rules read.
- Fix: Bind each timestamp to its side: renter may only set `renterPickupConfirmedAt` and owner `ownerPickupConfirmedAt`; activation requires the other timestamp already present in `before`. Same for return, and require both return timestamps for `return -> review/completed`. Add rules tests for the cheating cases.
- Status: open (rules: main session)

### F5-07 [severity: major] [kind: gap]
- Where: `caution_claim_page.dart` (`_ClaimForm`), `CautionClaimCubit._runClaimForm`
- What: Evidence is a text field of pasted URLs, not photo capture and upload through `MediaStorage`. The renter sees evidence as selectable URL text, not photos. The cubit accepts an empty list but the repository rejects it with a generic message.
- Evidence: page code.
- Fix: Reuse the checklist photo pick and upload flow (bucket `checklist-media` or a claims bucket), show thumbnails to both sides, require at least one photo in the cubit.
- Status: fixed (evidence photos via MediaStorage with camera or gallery, thumbnails for both sides, at least one required in the cubit)

### F5-08 [severity: minor] [kind: gap]
- Where: all handover notifications
- What: Every handover notification uses `NotificationType.returnConfirmed`, including claim submitted, revised, disputed, refunded and completion. `claimChanged` and `lateFeeApplied` exist but are never used, so Phase 6 icons and "claim changed" or "late fee applied" events are wrong or missing. Completion notifies, but the late fee never gets its own notification.
- Fix: Use `claimChanged` for claim events and `lateFeeApplied` when a late fee was charged.
- Status: fixed (claimChanged for claim events, lateFeeApplied on completion with a late fee, reviewDue to both parties)

### F5-09 [severity: minor] [kind: bug]
- Where: `firestore.rules` `transactions` settlement branches
- What: Settlement amounts are bounded individually (`<= cautionFee`) but not together: a party could write `claim_deduction` plus `refund` that sum above the caution, making held negative. The ledger rule does not tie `claim_deduction` to an agreed claim, and `late_fee` is not checked against the booking `lateFee`. Spec asks "money entries must match rentalFee, 2000, cautionFee".
- Fix: Require `claim_deduction` amount to equal `getAfter(claim).currentAmount`, `late_fee` to equal `bkafter.lateFee`, and `refund` to equal `cautionFee - lateFee - claimDeduction` (document where a rule cannot express it).
- Status: open (rules: main session)

### F5-10 [severity: minor] [kind: gap]
- Where: `confirmPickup` first-confirmation branch
- What: The first confirmer writes only an audit log. The other side is not notified that pickup is waiting on them (TODO 6.B "pickup confirmed by the other side").
- Fix: Send `pickupConfirmed` to the other party on the first confirmation.
- Status: fixed (pickupConfirmed sent to the other party on the first confirmation)

### F5-11 [severity: major] [kind: spec-drift]
- Where: `lib/features/handover/data/firestore_repair_expense_repository.dart`; `lib/app/di/injection_container.dart:42`
- What: Receipts upload to Firebase Storage (`repair-expenses/...`), not `MediaStorage` bucket `receipts` (Supabase). This is the only use of `firebase_storage` in the app. There is no storage rules file, and the default Firebase bucket may be unavailable on the free plan. The repository also uses raw strings, `throw`, `$error` in user messages and bypasses the models and `Result` (conventions: error-handling, models-and-mapping).
- Fix: Switch to `MediaStorage` (`StorageBucket.receipts`), return `Result`, use `FirestorePaths`/`FirestoreFields` and a `RepairExpenseModel`; delete the stored receipt via `MediaStorage.delete`. Remove the `firebase_storage` dependency.
- Status: fixed (MediaStorage receipts bucket, Result, core RepairExpense and RepairExpenseModel, FirestorePaths/Fields; needs DI change, see Needs main session; firebase_storage dependency can be removed)

### F5-12 [severity: minor] [kind: bug]
- Where: `ChecklistCubit.submit/_confirm`, `ChecklistPage`
- What: (a) `startReturnFirst` is fixed at cubit creation. If `startReturn` succeeds and `confirmReturn` fails (network), the retry calls `startReturn` again, which fails ("Only active bookings can start a return") until the user leaves and reopens the page. (b) Every submit generates fresh uuids for the five entries and re-saves media, so a retry after a failed confirm adds duplicate entries instead of overwriting. (c) The page does not preload existing entries or media (seed "partly ticked" checklists).
- Fix: Skip `startReturn` on a `returning` booking at call time (read status in the cubit), use stable ids (`kind_side_itemIndex`), preload saved entries.
- Status: fixed (retry skips startReturn after it succeeded, stable entry ids, saved entries and media preloaded)

### F5-13 [severity: minor] [kind: gap]
- Where: `checklist_page.dart` `_pickPhoto`
- What: Photo from gallery only (no camera), no video option. TODO says "photo/video capture". The cubit supports `MediaType.video`.
- Fix: Add a camera source and an optional video button.
- Status: fixed (camera and gallery photo, optional camera video)

### F5-14 [severity: minor] [kind: test-gap]
- Where: `test/features/handover`, `tool/rules-test`
- What: No test exercises the Firestore repository (confirm pickup batch contents, settlement ledger rows for each path, lock release, `completedCount`). The held-balance test calls the guard on hand-built entries, not on what the repository writes. Rules tests use a claim shape the app does not write (F5-01) and have no case for the renter vehicle/user count update, one-party activation or return confirmations.
- Fix: Add `fake_cloud_firestore` (or emulator) repository tests per path asserting the ledger rows and `LedgerBalance.held == 0`; align rules fixtures with `toMap` output (generate fixtures from the model).
- Status: open (partly: CompletionWriter tested for ledger rows summing to the caution, counts and notification types; Firestore repository transactions are not tested because fake_cloud_firestore is not in pubspec, needs main session)

### F5-15 [severity: major] [kind: needs-human]
- What: Needs the emulator or console and a device: (1) run `npm test` in `tool/rules-test` after F5-01/02/06 fixes with a client-shaped claim document; (2) confirm in the Firebase console that Firebase Storage is enabled for repair receipts (or after F5-11 that Supabase `receipts` bucket policy allows the owner); (3) walk the seed scenarios (`booking-p5-pickup-one-side`, `booking-p5-claim-open`, `booking-p5-claim-reclaim`, `booking-p5-late-charged`, `booking-p5-repair-two`) on a device; (4) check the held balance in the console after each path; (5) Figma screenshots and demo segment E.
- Status: needs-human

### F5-16 [severity: nit] [kind: spec-drift]
- Where: `CautionSettlementPage` preview
- What: Shows "Caution refund = caution - late fee" even when the booking is in `review` with a claim; the claim deduction is not part of the preview.
- Fix: Reuse `CautionSettlementCalculator` for the preview and show claim, late fee and refund rows.
- Status: fixed (SettlementBreakdown uses CautionSettlementCalculator and shows claim, late fee, refund; used on settle and claim pages)

## Counts

blocker 2 (F5-01, F5-02) · major 6 (F5-03, 04, 05, 06, 07, 11; F5-15 needs-human is major) · minor 6 (F5-08, 09, 10, 12, 13, 14) · nit 1 (F5-16). Total 16.

## Fix log

- `lib/features/handover/data/completion_writer.dart` (new): shared ledger rows, `users.completedCount` +1 for both parties, notifications (claimChanged, lateFeeApplied, reviewDue) for the three completion paths (F5-02, F5-08).
- `lib/features/handover/data/firestore_handover_repository.dart`: lock release at return, completion through `CompletionWriter`, pickupConfirmed on first confirm, `claimChanged` on claim events, `loadChecklist`, `adjustLateFee`, owner-adjusted fee used by every settlement (F5-03, 02, 05, 08, 10, 12).
- `lib/features/handover/domain/repositories/handover_repository.dart`, `domain/services/caution_settlement_calculator.dart`, `late_fee_calculator.dart`: new methods and `ownerAdjustedFee` parameter. A positive `booking.lateFee` during the return means the owner's reduced ceiling.
- `lib/features/handover/presentation/widgets/handover_actions.dart`, `handover_section.dart`, `settlement_breakdown.dart`, `late_fee_preview_card.dart` (F5-04, 05, 16).
- `presentation/pages/caution_settlement_page.dart`, `caution_claim_page.dart`, `checklist_page.dart` and the claim, settlement and checklist cubits and state (F5-04, 05, 07, 12, 13).
- Repair expenses: `data/firestore_repair_expense_repository.dart`, `domain/repositories/repair_expense_repository.dart`, repair cubit, state and page; registration moved to `handover_injection.dart` (F5-11).
- Tests: `test/features/handover/data/completion_writer_test.dart`, `presentation/widgets/handover_actions_test.dart`, updated claim, repair, checklist, settlement cubit and calculator tests.
