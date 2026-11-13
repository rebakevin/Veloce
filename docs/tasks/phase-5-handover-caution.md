# Phase 5 — Handover, return & caution settlement

| | |
| --- | --- |
| **Label** | `phase-5` |
| **Assignee** | _one person_ |
| **Branch** | `4-handover-return-caution-settlement` (already created from the issue; use it, do not create another) |
| **Feature folder** | `lib/features/handover/` |
| **Spec** | `SPECS.md` §4.1 steps 7–9, §6.5, §3 (late fee) · `TECHNICAL.md` §5.1–5.4, §10 |
| **Depends on** | Nothing. Needs only Phase 0 (done) and the seed data |

---

## Goal

Run the physical rental: pickup and return checklists with photo evidence, the release of funds when both sides confirm pickup, the late fee, and the caution (deposit) settlement with claims and repair costs. When this is done, a `confirmed` booking can move to `active`, `returning` and `completed`, with every franc accounted for in the ledger.

## Features to implement

1. **Repositories:** `HandoverRepository`, `ClaimRepository`, `RepairExpenseRepository`.
2. **Checklists:** five items each for pickup and return, photos required, video optional, uploads via `MediaStorage`, remove media before confirming (`ChecklistCubit`).
3. **Confirm pickup** (`ConfirmPickup`): each side confirms separately; the **second** confirmation moves the booking to `active` and releases funds in one batch (`release`, `platform_fee`, `payout` of rentalFee − 2,000) and notifies the other side.
4. **Return** (`StartReturn`, `ConfirmReturn`): both sides confirm; release `renterLocks`; set `returnedAt`.
5. **Late fee** (`LateFeeCalculator`): ceil to whole days, 1.3^days compounding, capped so late fee + claim ≤ caution; the owner can waive or reduce.
6. **Settle caution** (`SettleCaution`): no issue → renter acknowledges → `refund` of the caution (minus any late fee); claim → `cautionClaims` with reason and evidence photos.
7. **Claim response:** renter agrees → `claim_deduction` to the owner and the remainder refunded; renter disputes → money stays held; the owner may re-claim the same or a lower amount (never above `originalAmount`) or refund.
8. **Repair costs** (`LogRepairExpense`): amount, description, receipt photo; edit and delete.
9. **Completion:** updates `completedCount` and writes notifications.
10. **Screens:** pickup checklist, return checklist (with late-fee preview), owner settle, renter claim, owner repair cost, and the `HandoverSection` for each status inside the booking detail.
11. **Firestore rules** for your transitions, ledger entries, `cautionClaims`, `repairExpenses`, checklists.

## Acceptance criteria

**Behaviour**
- [ ] Pickup and return checklists have five items each; a confirm button stays disabled until at least one photo is attached; media can be removed before confirming; uploads show progress and failures can be retried.
- [ ] After one side confirms pickup the screen shows "waiting for the other side"; the booking stays `confirmed` and money stays held.
- [ ] The second confirmation moves the booking to `active` and writes `release`, `platform_fee` (2,000) and `payout` (rentalFee − 2,000) in **one batch**; the other side is notified.
- [ ] Return needs both confirmations; the renter lock is released and `returnedAt` set.
- [ ] Late fee table holds: 100,000 → 130,000 → 169,000 → 219,700 for 1, 2, 3, 4 days late; it is capped so late fee + claim never exceeds the caution; the owner can waive or reduce; the return screen previews it.
- [ ] No issue: renter acknowledges and the caution is refunded (minus any late fee).
- [ ] Claim: owner enters amount (≤ caution), reason and evidence photos; renter sees them and can **agree** (claim deduction to owner, remainder refunded) or **not agree** (money stays held).
- [ ] After a dispute the owner can re-claim the same or a lower amount (never above `originalAmount`), or refund.
- [ ] Repair costs can be logged, edited and deleted; the amount can exceed the claim deduction.
- [ ] On completion `completedCount` is updated and both sides are notified.
- [ ] The held balance of a booking is never negative after any path.

**Security and data**
- [ ] Rules: `confirmed → active` requires both confirmation timestamps; money entries must match `rentalFee`, `2000` and `cautionFee`; claim ≤ caution; `cautionClaims` and `repairExpenses` blocks; the ledger is append-only (verified).
- [ ] Only `bookings` (the transitions listed), `bookings/*/checklistEntries`, `bookings/*/checklistMedia`, `cautionClaims`, `repairExpenses`, `transactions` (release, platform_fee, payout, refund, claim_deduction, late_fee) and `renterLocks` (release) are written.

**Quality**
- [ ] Unit: late-fee table, cap logic, release amounts, re-claim ceiling, held-balance invariant after each path.
- [ ] Bloc: `PickupBloc` (one side only vs both), `ClaimBloc` (agree, dispute, re-claim).
- [ ] Widget: confirm button disabled until at least one photo is attached.
- [ ] `dart format`, `flutter analyze`, `flutter test` all clean; no `setState`.
- [ ] Figma-vs-app screenshots in the PR.

**Docs and demo**
- [ ] Report sections: escrow/ledger worked example, claim flow, late-fee formula.
- [ ] Demo segment E (~2.5 min): both confirm pickup (release in the console), return, claim and agree, repair cost logged.

## Technical description

### Already in place (do not rebuild)

**Domain & data (`lib/core`)**
- Entities: `Booking`, `ChecklistEntry`, `ChecklistMedia`, `CautionClaim`, `ClaimHistoryEntry`, `RepairExpense`, `LedgerEntry`, `RenterLock`, `AppNotification`.
- Models with `fromMap`/`toMap` for each.
- Enums: `BookingStatus`, `BookingActor`, `ChecklistKind`, `ChecklistSide`, `ClaimStatus`, `ClaimResponse`, `CautionDecision`, `TransactionType`, `Party`, `MediaType`, `StorageBucket` (`checklist-media`, `receipts`).
- Lookups: `BookingLookup`, `UserLookup`, `VehicleLookup`; `FirestorePaths`, `FirestoreFields`, `Result`, `AppFailure`, `Clock`, `AppConstants`.

**Business rules**
- `BookingStateMachine`: all transitions (`confirmed→active`, `active→returning`, `returning→review/completed`, `review→completed`), unit-tested.
- `LedgerBalance` and the held-balance invariant test.
- `Formatters`, `Validators`.

**Services**
- `LedgerWriter` (`FirestoreLedgerWriter`) for all money entries; `AuditLogger`; `NotificationWriter`; `AtomicWrite` / `AtomicWriteFactory`.
- `MediaStorage` (`SupabaseMediaStorage`), compression at pick time.
- `AuthSession`, `Clock`.

**Screens and routing**
- Placeholder routes in `handover_routes.dart`: `/booking/:id/pickup`, `/booking/:id/return`, `/booking/:id/settle`, `/booking/:id/claim`, `/booking/:id/repair-cost`.
- `HandoverSection` placeholder slot (`features/handover/presentation/widgets/handover_section.dart`) hosted inside `BookingDetailPage` (Phase 4).
- Widget kit: `PhotoPicker`, `ImagePickerTile`, `PriceBreakdown`, `StatusChip`, `EmptyState`, `ErrorView`, `LoadingView`, `PrimaryButton`, `AppMessenger`.

**Data**
- Seed: bookings in `confirmed`, `active`, `returning`, `review` and `completed` states, pickup and return checklists, two caution claims (one agreed, one disputed), a repair expense larger than its deduction, ledger rows that already reconcile. Sign in with `renter2` (confirmed booking, disputed claim), `renter3` (active booking) and the matching owners (password `Veloce#2026`).
- `firestore.rules` has labelled blocks for your collections.

### Dummy data for this task

Extra bookings for every case below live in `tool/seed/scenarios/phase-5.js` (ids start with `p5-`).

**Load it:** merge the latest `main` into your branch first (so the seed and its scenario files are current), then:

```bash
cd tool/seed && npm install && GOOGLE_APPLICATION_CREDENTIALS=/path/to/veloce-service-account.json npm run seed
```

The seed only overwrites its own ids, so after testing (bookings moved to `active`, `completed`, and so on) run it again to restore them. Do not use `npm run reset` without telling the team.

**Accounts:** sign in through `/dev-login` as `<uid>@veloce.test`, password `Veloce#2026`. New: `renter12@veloce.test` (Emmanuel Kayitare) and `renter13@veloce.test` (Jeanne Uwamahoro). Owners are `owner1`, `owner2`, `owner3` (the owner of each booking is in the table).

| Scenario | Renter / owner | Booking id | What to test |
| --- | --- | --- | --- |
| Confirmed, nobody confirmed pickup | `renter2` / `owner3` | `booking-confirmed` (base) | Both sides confirm pickup: the first shows "waiting", the second makes it `active` |
| Confirmed, only the owner confirmed pickup | `renter12` / `owner2` | `booking-p5-pickup-one-side` | `owner2` sees "waiting for the other side"; `renter12` confirms second: booking becomes `active`, `release`, `platform_fee` (2,000), `payout` written in one batch. Owner checklist is complete; the renter's is 3 of 5 ticked with no photo, so confirm stays disabled until a photo is added |
| Active, not late | `renter3` / `owner2` | `booking-active` (base) | Return screen with no late fee; start return |
| Active, 1-2 days past its end date | `renter13` / `owner1` | `booking-p5-active-late` | Late fee preview on a 120,000 rental: 36,000 for 1 day, 82,800 for 2 days, which the cap lowers to 80,000 (the caution); owner can waive or reduce. Return checklists are partly ticked, no photo |
| Returning, only one side confirmed return | `renter12` / `owner3` | `booking-p5-return-one-side` | Renter already confirmed, owner has not (owner checklist 2 of 5, no photo); the second confirmation completes the return |
| Returning, owner has not decided | `renter12` / `owner2` | `booking-p5-return-undecided` | Both confirmed the return; owner chooses no issue (refund of the caution) or claim |
| Returning, return checklists done | `renter1` / `owner1` | `booking-returning` (base) | Extra returning booking for the settle screen |
| Open claim, renter has not responded | `renter12` / `owner1` | `booking-p5-claim-open` | Claim of 60,000 (caution 100,000), `renterResponse` `none`; renter sees reason and photos, agrees (deduction + refund of 40,000) or disputes |
| Disputed, then re-claimed lower | `renter12` / `owner1` | `booking-p5-claim-reclaim` | Original 120,000, now 70,000, history of two entries; owner may re-claim at most 120,000, or refund; renter agrees or disputes again |
| Disputed claim | `renter2` / `owner1` | `booking-review` (base) | Claim of 80,000 already disputed |
| Late fee already charged | `renter12` / `owner2` | `booking-p5-late-charged` | 1 day late: `late_fee` of 54,000 in the ledger and an open claim of 80,000; held balance is 96,000, so late fee + claim stays within the 150,000 caution |
| Late fee waived by the owner | `renter12` / `owner1` | `booking-p5-late-waived` | `lateDays` 2, `lateFeeWaived` true, no `late_fee` row, full caution refunded |
| Repair costs: none logged | `renter12` / `owner1` | `booking-p5-repair-none` | Log a first expense (amount, description, receipt photo) |
| Repair costs: two logged | `renter12` / `owner2` | `booking-p5-repair-two` | Edit and delete `p5-repair-1` (40,000) and `p5-repair-2` (65,000); together they exceed the 50,000 deduction |
| Repair cost above the deduction | `renter1` / `owner2` | `booking-claimed` (base) | One expense of 85,000 against a 60,000 deduction |

Notes: `booking-p5-active-late` is "1 or 2 days late" depending on the hour you seed, because the end date is stored at 09:00 UTC. A renter holds one lock (approved, confirmed or active) and `renter12` and `renter13` hold one each; every other `p5-` booking is `returning`, `review` or `completed`, so it needs no lock. `renter5` to `renter11` belong to phases 3 and 4.

### To build in this phase

- `features/handover/domain`: repositories above, use cases `ConfirmPickup`, `StartReturn`, `ConfirmReturn`, `SettleCaution`, `LogRepairExpense`, `LateFeeCalculator`.
- `features/handover/data`: Firestore implementations; money entries always through `LedgerWriter` in a single `AtomicWrite`.
- `features/handover/presentation`: `ChecklistCubit`, `PickupBloc`, `ReturnBloc`, `ClaimBloc` (owner and renter views), `RepairExpenseBloc`, pages and the `HandoverSection`.
- Register in `handover_injection.dart`; replace placeholders in `handover_routes.dart`.

### Cross-phase notes (no waiting needed)

- Booking creation, approval and payment are Phases 3–4; use the seeded `confirmed` booking to start pickup.
- `HandoverSection` is rendered by Phase 4's booking detail; you own the widget and its content per status.
- Review prompts after `completed` are Phase 6 (`PostRentalSection`); do not build them here.
