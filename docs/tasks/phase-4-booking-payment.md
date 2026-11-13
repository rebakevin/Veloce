# Phase 4 — Booking decision & payment

| | |
| --- | --- |
| **Label** | `phase-4` |
| **Assignee** | _one person_ |
| **Branch** | `3-booking-decision-payment` (already created from the issue; use it, do not create another) |
| **Feature folder** | `lib/features/booking/` |
| **Spec** | `SPECS.md` §4.1 steps 3–6, §4.4, §5.5–5.6 · `TECHNICAL.md` §5.1–5.4, §10 |
| **Depends on** | Nothing. Needs only Phase 0 (done) and the seed data |

---

## Goal

Take a booking from `pending` to `confirmed`: the owner approves or declines a request, the renter pays through MoMo (simulated), and both sides see the booking in "My Activity" and the booking detail. When this is done, a request becomes a paid, confirmed booking with a calendar block, a renter lock and a ledger entry, and can be cancelled with a full refund until pickup.

## Features to implement

1. **Booking repository:** watch my bookings by role, watch one booking, transitions inside transactions/batches.
2. **Approve** (`ApproveBooking`): owner tick required, `PendingReviewChecker`, creates `renterLocks`, writes `calendarBlocks`, declines the car's overlapping pending requests, writes the owner contact doc, notifies the renter.
3. **Decline** (`DeclineBooking`): reason required.
4. **Cancel** (`CancelBooking`): until pickup is confirmed; refunds everything through `LedgerWriter`, frees the block and the lock.
5. **Lazy expiry** (`ExpiryEngine`): pending after 24 h; payment deadline = earlier of +24 h and the pickup date; `ExpirySweeperCubit` runs at app start/resume and on activity load.
6. **Pay** (`PayBooking`): `MomoGateway.charge`, then a `charge` ledger entry, status `confirmed`, contact unlock, notifications; failure keeps `approved` and allows retry.
7. **Agreement** (`AcknowledgeAgreement`).
8. **Effective status** applied to every list so requests cancelled by a lock show correctly.
9. **Screens:** My Activity (renter and owner), booking detail, owner request detail, payment, rental agreement, cancel flow.
10. **Slots:** `PendingRequestsCard`, `UpcomingRentalsCard` on the owner home.
11. **Firestore rules** for your transitions, locks, calendar blocks, contact lock and `charge`/`refund` transactions.

## Acceptance criteria

**Behaviour**
- [ ] My Activity shows Open (action required, pending), Active and Past for both roles; owners see requests grouped by car; quick actions work.
- [ ] Booking detail shows reference, status headline, six-step timeline, car, dates, parties, price rows, payment/caution/agreement status.
- [ ] The contact tile is **locked** until payment, then shows phone, email and meeting point.
- [ ] Owner request detail `/booking/:id/decision` shows renter profile info (no contact), "You earn RWF X", the "I reviewed their info" tick, approve and decline (reason required). Approve is disabled until the tick is set.
- [ ] Approve fails with a clear message when the renter already holds a lock or has a pending review; it declines the car's other overlapping pending requests in the same atomic write.
- [ ] The payment screen takes a 9-digit MoMo number, shows the total breakdown and a deadline countdown, processing state, success with reference, and failure with retry (booking stays `approved`).
- [ ] A successful payment writes the `charge` ledger entry, sets `confirmed`, unlocks contact and notifies the owner.
- [ ] Cancel before pickup refunds everything held and releases the block and the lock; the dialog states the refund.
- [ ] Pending requests expire after 24 h and unpaid approvals at the payment deadline, applied lazily and shown correctly in all lists (`effectiveStatus`).
- [ ] The rental agreement shows its nine sections, the late-fee 30%/day text and the cancellation text.
- [ ] The booking detail screen does not overflow when the phone is rotated.

**Security and data**
- [ ] Rules: `validTransition` for your rows of the §5.1 table; lock and calendar rules; contact documents unreadable before payment; `transactions` create rules for `charge` and `refund` amounts.
- [ ] Demonstrated: contact docs unreadable before payment and readable after.
- [ ] Only `bookings` (the transitions listed), `bookings/*/private/owner`, `calendarBlocks`, `renterLocks`, `transactions` (charge, refund) and `notifications` are written.

**Quality**
- [ ] Unit: approve conflict (renter already locked), overlap declining, deadline calculation, cancel refund amounts, effective status.
- [ ] Bloc: `PaymentBloc` (success, failure, retry), `DecisionBloc`.
- [ ] Widget: locked contact tile switches to revealed data.
- [ ] `dart format`, `flutter analyze`, `flutter test` all clean; no `setState`.
- [ ] Figma-vs-app screenshots in the PR.

**Docs and demo**
- [ ] Report sections: booking state-machine diagram, lazy expiry and lock design, ledger invariants.
- [ ] Demo segment D (~2.5 min): owner approves, renter pays, console shows `confirmed` and a `charge` row, contact unlocks, **rotate the phone once**.

## Technical description

### Already in place (do not rebuild)

**Domain & data (`lib/core`)**
- Entities: `Booking`, `BookingContact`, `CalendarBlock`, `RenterLock`, `LedgerEntry`, `AppNotification`, `AuditLogEntry`, `UserAccount`, `Vehicle`.
- Models with `fromMap`/`toMap` for each.
- Enums: `BookingStatus`, `BookingActor`, `TransactionType`, `TransactionStatus`, `Party`, `NotificationType`.
- Lookups: `BookingLookup`, `UserLookup`, `VehicleLookup`.
- `FirestorePaths`, `FirestoreFields`, `Result`, `AppFailure`, `Clock`, `AppConstants`.

**Business rules**
- `BookingStateMachine`: the full transition table, `canTransition`, `isTerminal`, `effectiveStatus(booking, now, renterLock)`; unit-tested.
- `PricingCalculator`, `PriceQuote`; `Formatters`, `Validators` (MoMo 9 digits).
- `LedgerBalance` and the held-balance invariant test.

**Services**
- `LedgerWriter` (`FirestoreLedgerWriter`): `record(write, booking, type, amount, from, to, reference)`.
- `AuditLogger`, `NotificationWriter` (Firestore implementations), `AtomicWrite` / `AtomicWriteFactory`.
- `MomoGateway` (`MomoGatewaySim`): `charge`, with a success/failure toggle.
- `PendingReviewChecker` interface (stub returns `false`; Phase 6 replaces it).
- `AuthSession`, `Clock`.

**Screens and routing**
- Placeholder routes in `booking_routes.dart`: `/renter/activity` and `/owner/activity` (tab roots), `/booking/:id`, `/booking/:id/decision`, `/booking/:id/pay`, `/booking/:id/pay/result`, `/booking/:id/agreement`, `/owner/cars/:id/requests`.
- `BookingDetailPage` exists as the **host page** with slots for `HandoverSection` (Phase 5) and `PostRentalSection` (Phase 6); keep the slots in place.
- `PendingRequestsCard` and `UpcomingRentalsCard` placeholder slots under `features/booking/presentation/widgets/`.
- Widget kit: `LockedContactTile`, `PriceBreakdown`, `StatusChip`, `UserAvatar`, `RatingStars`, `EmptyState`, `ErrorView`, `LoadingView`, `PrimaryButton`, `AppMessenger`.
- Public profile (`/user/:id`) for the renter info on the decision page.

**Data**
- Seed: 11 bookings, one in each status (pending, approved, declined, cancelled, expired, confirmed, active, returning, review, completed, completed with agreed claim), with matching calendar blocks, renter locks and ledger rows. Accounts: `owner1`–`owner3` and `renter1`–`renter4@veloce.test`, password `Veloce#2026`. `renter1` has the approved booking (pay it), `renter4` the pending one (approve it).
- `firestore.rules` has labelled booking, lock, calendar and transaction blocks.

### Dummy data for this task

Extra bookings for every scenario below live in `tool/seed/scenarios/phase-4.js` and are loaded by the normal seed script, so you need nothing from other phases.

**Load it:** merge the latest `main` into your branch first (it carries `seed.js` and the scenario files), then:

```bash
cd tool/seed && npm install && GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json npm run seed
```

The seed only overwrites its own ids, so run it again whenever testing has consumed a booking (approved, paid, cancelled) to restore the original state.

**Accounts** (sign in through `/dev-login`, password `Veloce#2026`): owners `owner1`, `owner2`, `owner3` and renters `renter1`, `renter2`, `renter3`, `renter4`, `renter6` ... `renter11`, all `@veloce.test`. Booking ids are `booking-<key>`.

| Scenario | Account | Booking id | What to test |
| --- | --- | --- | --- |
| Approve (base) | owner1 / renter4 | `booking-pending` | Approve with the review tick; it declines `booking-p4-pending-overlap` (same car, overlapping days) in the same write and leaves `booking-p4-pending-no-overlap` pending. |
| Overlapping pending | owner1 / renter6 | `booking-p4-pending-overlap` | Approve this one instead and the base request is declined. |
| Non-overlapping pending | owner1 / renter4 | `booking-p4-pending-no-overlap` | Stays pending after either approval above. |
| Approve fails, renter locked | owner1 / renter7 | `booking-p4-pending-locked-renter` | Approve fails with a clear message (renter7 holds the lock of `booking-p4-approved-pay`). In renter7's activity its `effectiveStatus` is `cancelled`. |
| Pay (base) | renter1 | `booking-approved` | Pay with a 9-digit MoMo number: charge row, `confirmed`, owner contact unlocks. Toggle the gateway to failure for retry. |
| Pay (second) | renter7 | `booking-p4-approved-pay` | Same flow on a separate renter and car, once the base one is consumed. |
| Lazy expiry of a pending request | owner2 / renter4 | `booking-p4-pending-expired` | 24 h window already passed: shows `expired` in every list and is written as expired by the sweeper. |
| Payment deadline passed | renter8 | `booking-p4-approved-pastdue` | Approved but the deadline passed 2 h ago: shows `expired`, pay is refused, the lock and block are released. |
| Countdown | renter9 | `booking-p4-approved-1h` | Deadline in about 1 hour: countdown on the payment screen. |
| Deadline = pickup date | renter10 | `booking-p4-approved-pickup-soon` | Pickup tomorrow 09:00 UTC, so the deadline is the earlier of +24 h and the pickup (less than 24 h from now). |
| Cancel with refund | renter11 / owner3 | `booking-p4-confirmed-cancel` | Confirmed and paid (charge of the full total, RWF 580 000 held): cancel before pickup, dialog states the refund, a `refund` row is written, block and lock released. Contact tile is unlocked. |
| My Activity grouped by car | owner1 | `booking-pending`, `booking-p4-pending-overlap`, `booking-p4-pending-no-overlap`, `booking-p4-pending-locked-renter`, `booking-p4-pending-car3`, `booking-p4-pending-car1-b` | Requests on car-1, car-2 and car-3 appear grouped under each car. |
| My Activity grouped by car | owner2 | `booking-p4-pending-car4`, `booking-p4-pending-car6`, `booking-p4-pending-expired` | Requests on car-4, car-5 and car-6. |
| My Activity, one car | owner3 | `booking-p4-pending-car7`, `booking-p4-confirmed-cancel` | A pending request and an upcoming rental on car-7. |
| Past tab (declined) | renter6 / owner1 | `booking-p4-declined` | Declined with a reason. |
| Past tab (cancelled) | renter4 | `booking-p4-cancelled-unpaid`, `booking-p4-cancelled-refunded` | Cancelled without payment, and cancelled after payment with the full refund in the ledger. |
| Past tab (expired) | renter6 | `booking-p4-expired-payment` | Expired because payment was not made. |

The owner contact document (`bookings/*/private/owner`) exists for every booking that is not pending, declined or expired. Before payment (`approved`) it must stay unreadable through your rules and the UI tile; after payment (`confirmed`) it is readable.

### To build in this phase

- `features/booking/domain`: `BookingRepository`, use cases `ApproveBooking`, `DeclineBooking`, `CancelBooking`, `PayBooking`, `AcknowledgeAgreement`, `ExpiryEngine`.
- `features/booking/data`: Firestore implementations (transactions/batches via `AtomicWrite`).
- `features/booking/presentation`: `ActivityBloc`, `BookingDetailBloc`, `DecisionBloc`, `PaymentBloc`, `ExpirySweeperCubit`, pages and the two slot widgets.
- Register in `booking_injection.dart`; replace placeholders in `booking_routes.dart`.

### Cross-phase notes (no waiting needed)

- Creating a request is Phase 3; use the seeded `pending` booking.
- Pickup, return, claims and the money release are Phase 5; from `confirmed` onward the booking detail only hosts their slot.
- Reviews and notifications UI are Phase 6; you only **write** notification documents (through `NotificationWriter`).
