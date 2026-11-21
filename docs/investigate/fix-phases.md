# Fix phases

Built from `phase-*-findings.md` (round 1). Ownership: `firestore.rules`, `firestore.indexes.json`, `tool/rules-test`, `pubspec.yaml`, shared DI/router files and `TODO.md` are edited by the main session only. Feature agents own only their `lib/features/<x>/` and `test/features/<x>/`.
Needs-human items are not here; see `FOR-KEVIN.md`.

## Rules + indexes (main session)
- F5-01 `cautionClaims` rule to the real shape (`originalAmount`, `currentAmount`); F5-02 allow what the client needs for counts (see Phase 5 client).
- F2-02 photo/document/vehicle delete in one batch (use `get`, not `getAfter`); F2-10 vehicles create constraints; F2-11 delete needs no open bookings if expressible.
- F3-02 search composite index; F3-03/F3-04 booking-create rule: car published, own car, `expiresAt`, `rentalFee` vs days x rate.
- F6-03 `repairExpenses` list-query-safe read rule; F6-04 reviews no delete; F6-05 review create validation; F6-06 notification update only `read`.
- F5-06 pickup timestamps per side; F5-09 ledger settlement amounts; F4-07 refund rule only for confirmed bookings, no duplicates.
- F1-01 account-delete cascade vs rules; F1-05 role immutability on delete+recreate; F0-03 `user-docs` bucket policy (SQL file only; applying it is human).
- Extend `tool/rules-test` for phases 1, 4, 5 (F0-04, F4-04, F5-09).

## Phase 0/1: lib/core, lib/features/auth, lib/features/profile
- F1-02 account switcher: do not sign out before the sheet; F1-03 re-verify email path and reload `emailVerified` on restart, gate publish/pay.
- F1-04, F1-06, F1-08 minors; F0-02 `DevSignIn` and redirect bypass gated on `kDebugMode`; F0-06; tests F1-07.

## Phase 2: lib/features/vehicles
- F2-01 `bookingsOf` must filter by `ownerId`; F2-03 publish default availability or say so in UI; F2-04 pause on passive expiry; F2-08 route to Documents screen; F2-09 plate re-check; F2-05/06/07 video, PDF, reorder, photo on card; tests F2-14.

## Phase 3: lib/features/discovery
- F3-01 Saved count; F3-03 published/docs check; F3-06 stale bloc results; F3-07/F3-10 read fan-out; F3-08 chip vs filter; F3-09 unique VLC reference; F3-11..13; tests F3-14.

## Phase 4: lib/features/booking
- F4-01 same-day pickup deadline; F4-02 single-flight expiry sweep and tolerate permission-denied; F4-03 stale state after await; F4-05 charge vs batch failure; F4-07..F4-13; tests F4-06.
- Notifications (F6-01): write `paymentDeadline` approaching via the sweep.

## Phase 5: lib/features/handover
- F5-01 client/rule alignment; F5-02 move `completedCount` to the right doc via an allowed path; F5-03 release `renterLocks` at return; F5-04 HandoverSection routing by role; F5-05 late-fee preview + waive/reduce; F5-07 claim evidence upload; F5-11 repair receipts to `MediaStorage`; F5-08/F5-10 correct notification types (`claimChanged`, `lateFeeApplied`, pickup confirmed); F5-12, F5-13, F5-16; tests F5-14.

## Phase 6: lib/features/reviews, notifications, finances
- F6-07 aggregate in-batch and exact; F6-08 booking-complete/party checks; F6-09 payment history status + distinct labels; F6-10, F6-11; F6-01 `reviewDue`; tests F6-14 (use production code).

## Round 2
Re-audit each phase on the fixed code; leftovers in `round-2-findings.md`.
