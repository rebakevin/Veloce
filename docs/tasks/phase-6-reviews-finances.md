# Phase 6 — Reviews, notifications & finances

| | |
| --- | --- |
| **Label** | `phase-6` |
| **Assignee** | _one person_ |
| **Branch** | `5-reviews-notifications-finances` (already created from the issue; use it, do not create another) |
| **Feature folders** | `lib/features/reviews/`, `lib/features/notifications/`, `lib/features/finances/` |
| **Spec** | `SPECS.md` §5.7, §7 · `TECHNICAL.md` §5.2, §8.1, §8.3 |
| **Depends on** | Nothing. Needs only Phase 0 (done) and the seed data |

---

## Goal

Close the loop around a rental: let both sides review each other and the car, tell users what is happening through notifications, give owners a clear view of their earnings and losses, and give renters a payment history. When this is done, completed bookings feed ratings, every important event reaches the right person, and money is explained per month, year and car.

## Features to implement

**Reviews**
1. `ReviewRepository`: create and edit only (never delete); id `bookingId_authorId_subjectType`; rating aggregates on `users`/`vehicles` updated in the same batch.
2. Real `PendingReviewChecker` replacing the Phase 0 stub (owner → renter; renter → owner and renter → car).
3. Screens: write/edit reviews `/booking/:id/review` (stars + comment, both mandatory), car reviews `/car/:id/reviews`, user reviews `/user/:id/reviews`, my reviews `/profile/reviews`.
4. `PostRentalSection` ("review due" prompts) and `ReviewsPreviewSection` slots.

**Notifications**
5. `NotificationsBloc`: stream, unread count, mark read, mark all read, delete/clear, deep link into the booking.
6. Icon per type, unread dot, bottom-nav badge, on/off setting read from `notifications_enabled`.

**Owner finances**
7. `FinancesRepository` computing **Total earned** and **Total losses** from `transactions` + `repairExpenses`, for *This month* / *This year*.
8. Finances screen: period toggle, two tiles, Chart/Table toggle, per-car list with share bar.
9. Chart (`fl_chart`): paired bars per day (month) or per month (year), legend, tap shows amounts.
10. Table: newest first, latest 5 rows + "View all transactions"; car finances screen and its transactions page; `FinancesCard` slot on the owner home.

**Renter payment history**
11. `/renter/payments`: payment, caution refund, claim deduction, late fee, cancellation refund — date, booking, amount, status.

**Rules**
12. Firestore rules and indexes for `reviews` and `notifications`; rating aggregate guard.

## Acceptance criteria

**Behaviour**
- [ ] Both stars and comment are mandatory on every review; blank submissions are blocked with inline errors.
- [ ] A review can be edited by its author but never deleted; the same author cannot review the same subject for the same booking twice.
- [ ] Rating aggregates on the user and vehicle are updated in the same batch as the review and the average is correct after an edit.
- [ ] `PendingReviewChecker` returns true while a completed booking is missing a required review (owner → renter; renter → owner and renter → car) and false afterwards; it is registered in place of the stub and blocks new requests and approvals as Phases 3 and 4 expect.
- [ ] `PostRentalSection` shows "review due" prompts and the written reviews afterwards; `ReviewsPreviewSection` shows the latest reviews on the public profile.
- [ ] Notifications list shows an icon per type, an unread dot, newest first; tapping opens the related booking and marks it read; "mark all read" and delete/clear work; the bottom-nav badge shows the unread count.
- [ ] Turning notifications off in Settings stops new notifications being shown (`notifications_enabled`).
- [ ] Event types are covered: request received/approved/declined/expired, payment deadline approaching, pickup/return confirmed by the other side, claim changed, late fee applied, review due.
- [ ] Finances: *Total earned* and *Total losses* follow `SPECS.md` §7 and `TECHNICAL.md` §5.2, including the caution offset; the period toggle switches This month / This year.
- [ ] Chart shows paired bars (per day or per month), two colours with a legend, tap shows amounts, empty periods are blank; the Table toggle shows the latest 5 rows newest first and "View all transactions" appears **only** when there are more than 5; the table total equals the tiles.
- [ ] Car finances screen shows the same layout filtered to one car; per-car list shows a share bar.
- [ ] Amounts are RWF with no decimals; empty states are shown; no export.
- [ ] `FinancesCard` shows this month's earned and losses and opens the finances screen.
- [ ] `/renter/payments` lists every renter money movement with date, booking, amount and status.

**Security and data**
- [ ] Rules: `reviews` cannot be deleted and only the author can edit; `notifications` writable by their owner only for read/clear; rating aggregates change only alongside a matching review.
- [ ] Indexes from `TECHNICAL.md` §4.4 for your queries added to `firestore.indexes.json`.
- [ ] Only `reviews` (+ rating aggregates on `users`/`vehicles`) and `notifications` (read/clear) are written; `transactions` and `repairExpenses` are read-only for you.

**Quality**
- [ ] Unit: earned/loss calculation incl. the caution offset, period bucketing, table total = tiles, pending-review detection, rating average.
- [ ] Bloc: `FinancesBloc` (period/view toggle), `NotificationsBloc`, `ReviewBloc`.
- [ ] Widget: finances table shows 5 rows and the "View all" link only when there are more than 5.
- [ ] `dart format`, `flutter analyze`, `flutter test` all clean; no `setState`.
- [ ] Figma-vs-app screenshots in the PR.

**Docs and demo**
- [ ] Report sections: finances formulas, reviews rule, notifications.
- [ ] Demo segment F (~2 min): leave both reviews, edit one, notification deep link, finances chart ↔ table, payment history.

## Technical description

### Already in place (do not rebuild)

**Domain & data (`lib/core`)**
- Entities: `Review`, `AppNotification`, `LedgerEntry`, `RepairExpense`, `Booking`, `UserAccount`, `Vehicle`.
- Models with `fromMap`/`toMap` for each.
- Enums: `SubjectType`, `NotificationType`, `TransactionType`, `TransactionStatus`, `Party`.
- Lookups: `BookingLookup`, `UserLookup`, `VehicleLookup`; `FirestorePaths`, `FirestoreFields`, `Result`, `AppFailure`, `Clock`.

**Business rules**
- `LedgerBalance`; `Formatters` (RWF, dates); `RatingStars` widget.
- `PendingReviewChecker` interface; stub `PendingReviewCheckerStub` (returns false) in `features/reviews/data/pending_review_checker_stub.dart`, registered in `reviews_injection.dart`; **you replace it**.

**Services**
- `NotificationWriter` (`FirestoreNotificationWriter`): other phases already write notification documents through it; you only read, mark read and clear.
- `PreferencesService`: `notifications_enabled`.
- `AtomicWrite` / `AtomicWriteFactory`, `AuthSession`.

**Screens and routing**
- Placeholder routes: `reviews_routes.dart` (`/booking/:id/review`, `/car/:id/reviews`, `/user/:id/reviews`, `/profile/reviews`), `notifications_routes.dart` (`/renter/notifications`, `/owner/notifications`), `finances_routes.dart` (`/owner/finances`, `/owner/finances/transactions`, `/owner/finances/car/:carId`, `/owner/finances/car/:carId/transactions`, `/renter/payments`).
- Slot placeholders: `FinancesCard` (owner home), `ReviewsPreviewSection` (public profile), `PostRentalSection` (booking detail).
- Bottom navigation bar exists with a bell action opening the notifications route (`app/router/main_bar.dart`); it has no unread badge yet, which you add.
- Settings page with the notifications switch is done (Phase 1); public profile `/user/:id` is done.
- Widget kit: `RatingStars`, `EmptyState`, `ErrorView`, `LoadingView`, `StatusChip`, `UserAvatar`, `SectionHeader`, `PrimaryButton`, `AppMessenger`.
- Package `fl_chart` already in `pubspec.yaml`.

**Data**
- Seed: reviews with matching rating aggregates, notifications of several types, ledger rows for every flow, repair expenses, completed bookings (one with an agreed claim). Accounts `owner1`–`owner3` and `renter1`–`renter4@veloce.test`, password `Veloce#2026`.
- `firestore.rules` has labelled `reviews` and `notifications` blocks.

### Dummy data for this task

Everything below is loaded by `tool/seed/scenarios/phase-6.js`, with ids prefixed `p6-`.

**How to load.** Merge the latest `main` into your branch first (the seed and the other phases' data change), then:

```bash
cd tool/seed && npm install && GOOGLE_APPLICATION_CREDENTIALS=/path/to/veloce-service-account.json npm run seed
```

Reseed after testing: it restores every seeded document you changed or deleted. Day offsets are relative to the day you seed, so the "this month" data shifts with the date: seed after about the 12th of the month to see a full month chart, and reseed to refresh it.

**Accounts.** Password `Veloce#2026`. `owner1`-`owner3` and `renter1`-`renter4` are on `/dev-login`; `owner5`, `renter14` and `p6-owner` are not, so sign in with the normal login form (`owner5@veloce.test`, `renter14@veloce.test`, `p6-owner@veloce.test`).

| Scenario | Account | Ids | What to test |
| --- | --- | --- | --- |
| Finances, this month | `owner1` (cars 1-3), `owner2` (cars 4-6) | `booking-p6-o1-m1`..`m6`, `booking-p6-o2-m1`..`m5` (released 2-11 days ago, different days) | Month chart with paired bars per day; table with more than 5 rows, so "View all transactions" shows; table total equals the tiles |
| Finances, this year | `owner1`, `owner2` | `booking-p6-o1-y1`..`y11`, `booking-p6-o2-y1`..`y11` (one per month from January) | Year chart per month, empty months blank; period toggle |
| Per-car share | `owner1` (cars 1, 2, 3 all have bookings) | `car-1`, `car-2`, `car-3`; `owner2` has `car-4`, `car-5`, `car-6` | Per-car list share bars; car finances screen and its transactions page |
| Late fees | `owner1`, `owner2` | `booking-p6-o1-m3`, `o1-y6`, `o2-m3`, `o2-y7` (`late_fee` ledger rows) | Late fee counted in Total earned and shown as a table row |
| Claim deduction and repair larger than it | `owner1`, `owner2` | `booking-p6-o1-m4` (repair 70,000 vs deduction 40,000, loss 30,000), `o1-y4`, `o2-y5` (loss 80,000) | Total losses non-zero; deduction is not earned but offsets the loss (caution offset) |
| Repair smaller than the deduction | `owner2` | `booking-p6-o2-m2` (`p6-repair-` 60,000 vs deduction 100,000) | Loss is `max(0, ...)` = 0, no loss row |
| Repair with no claim | `owner1`, `owner2` | `booking-p6-o1-y8` (30,000), `booking-p6-o2-m4` (120,000, created yesterday) | Full repair cost is a loss |
| Cancelled with refund | `renter2`, `renter3` (owners `owner1`, `owner2`) | `booking-p6-cancel-1`, `booking-p6-cancel-2` | Charge and refund rows are not earnings; renter payments shows the cancellation refund |
| Empty finances | `owner5` | car `p6-car-new`, no bookings | Empty states on the finances screen (both periods and views), tiles at 0; screen is reachable |
| Renter payment history | `renter14` | `booking-p6-r9-ok` (payment + caution refund), `r9-claim` (claim deduction + partial refund), `r9-late` (late fee + partial refund), `r9-cancel` (cancellation refund) | `/renter/payments`: every type with date, booking, amount, status |
| Reviews missing (pending-review) | `renter14` and `p6-owner` | `booking-p6-pending-all` (car `p6-car-review`): no review at all | Checker returns true for both; "review due" in `PostRentalSection`; both are blocked from new requests/approvals (expected) |
| Only renter side reviewed | `renter1` (done) and `p6-owner` (owes owner to renter) | `booking-p6-pending-owner` | `p6-owner` still blocked, `renter1` is not; `PostRentalSection` shows the written reviews and one due |
| All three reviews, edit | `renter4` / `owner3` | `booking-p6-reviewed` (the `renter4` to car review is already edited) | Edit by author, average recomputed, no second review for the same subject |
| Many reviews, lists and averages | any | cars `car-1`, `car-2` (7 reviews each), `car-3` (6); users `owner1`, `owner2`, `renter1`-`renter4` | `/car/:id/reviews`, `/user/:id/reviews`, `/profile/reviews`, `ReviewsPreviewSection`, rating average and count |
| Notifications, owner | `owner1` | `p6-owner1-01`..`18`: every type, 12 unread (badge shows), 6 read, from 2 hours to 50 days old, most with a `bookingId` | Icon per type, unread dot, newest first, deep link, mark read, mark all read, delete/clear |
| Notifications, renter | `renter14` | `p6-renter14-01`..`18`: same mix, links to `renter14`'s bookings | Same as above from the renter side |

`PendingReviewChecker` note: all bookings of `renter1`-`renter4` and `owner1`-`owner3` have the reviews they owe, so the real checker does not block the other phases' base accounts. Only `renter14` and `p6-owner` are blocked, by design. `renter14`, `owner5` and `p6-owner` are new accounts (`renter9` belongs to Phase 4).

### To build in this phase

- `features/reviews`: `ReviewRepository`, `ReviewBloc`, real `PendingReviewChecker`, pages, `PostRentalSection`, `ReviewsPreviewSection`.
- `features/notifications`: `NotificationsRepository`, `NotificationsBloc`, pages, unread badge wiring.
- `features/finances`: `FinancesRepository`, `FinancesBloc`, finances and car-finances pages, transactions pages, renter payments page, `FinancesCard`.
- Register in each `*_injection.dart` (replace the stub binding in `reviews_injection.dart`); replace placeholders in each `*_routes.dart`.

### Cross-phase notes (no waiting needed)

- Phases 4 and 5 already **write** notification documents and money entries; you only read them. Until they merge, the seeded data covers every case.
- Replacing `PendingReviewChecker` changes behaviour for Phases 3 and 4 by design; they only call the interface, so no edits to their files are needed.
- The `notifications` route is opened from the shared bottom bar; the unread badge needs a small change in `main_bar.dart`; open a `contract:` PR for it and keep the change minimal, since the file is shared.
