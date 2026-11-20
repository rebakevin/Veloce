# Report draft: reviews, notifications and finances (Phase 6)

Raw material for the final report. Sources: `docs/resources/SPECS.md` (§5.7, §7), `docs/resources/TECHNICAL.md` (§5.2, §8.1, §8.3), `docs/tasks/phase-6-reviews-finances.md`, `lib/features/finances`, `lib/features/reviews`, `lib/features/notifications`, `firestore.rules`. Rewrite in the team's own words before submission, and cite the references used.

Status note: the code lives on branch `5-reviews-notifications-finances`, merged with `main` (Phase 5). Section 5 says exactly what was and was not verified. Numbers in the worked examples are computed by hand from the formulas below, not copied from a run of the app.

## 1. Finances formulas

Owner finances are computed on the client by `FirestoreFinancesRepository.getOwnerFinances` from two read-only collections, `transactions` and `repairExpenses`. Nothing is stored; the figures are recomputed each time for the chosen period.

**Total earned** (SPECS §7.1) is the sum of two kinds of entry:

```
earned(release row)  = max(0, release.amount - 2000)      // rental fee released at pickup, minus the platform fee
earned(late_fee row) = late_fee.amount                     // late fee collected at settlement
totalEarned = sum of both kinds, rows dated inside the period
```

A `release` row equals the booking's `rentalFee`, so earned equals `rentalFee - 2000`, which is the same amount as the `payout` row. `charge`, `refund`, `platform_fee` and `payout` rows are never counted (they are escrow bookkeeping), and a `claim_deduction` is not earned.

**Total losses** (SPECS §7.1) is the sum over repair expenses logged in the period:

```
deduction(booking) = sum of claim_deduction rows for that booking (any date)
loss(repair)       = max(0, repair.amount - deduction(booking))
totalLosses        = sum of loss(repair) where loss > 0, repairs dated inside the period
```

**The caution offset.** The caution money the owner received through an agreed claim does not count as earnings; it only reduces the loss. So a repair is a loss only for the part the claim did not cover. A repair with no claim is a full loss.

| Case | Rental fee | Repair | Claim deduction | Late fee | Earned | Loss |
| --- | --- | --- | --- | --- | --- | --- |
| Clean rental | 200,000 | none | none | none | 198,000 | 0 |
| Late return | 200,000 | none | none | 60,000 | 258,000 | 0 |
| Repair larger than the claim | 200,000 | 70,000 | 40,000 | none | 198,000 | 30,000 |
| Repair smaller than the claim | 200,000 | 60,000 | 100,000 | none | 198,000 | 0 (no row) |
| Repair, no claim | 200,000 | 120,000 | none | none | 198,000 | 120,000 |

These match the seeded cases `booking-p6-o1-m4` (repair 70,000, deduction 40,000, loss 30,000), `booking-p6-o2-m2` (repair 60,000, deduction 100,000, no loss row) and `booking-p6-o2-m4` (repair 120,000, no claim).

**Dating and periods.** Earnings are dated by the `at` of the `release` (or `late_fee`) row; losses by the `createdAt` of the repair expense, as SPECS §7.1 says. `_getPeriodRange` builds a half-open range on the device clock:

| Period | Start (included) | End (excluded) |
| --- | --- | --- |
| This month | 1st of the current month, 00:00 | 1st of the next month, 00:00 |
| This year | 1 January, 00:00 | 1 January of next year, 00:00 |

An entry on the 1st of next month at 00:00 belongs to the next period. The chart then buckets the same entries: in the month view one bucket per day (1 to the length of the month, for example 30 in November 2026), by `date.day`; in the year view one bucket per month (Jan to Dec), by `date.month`. Each bucket sums earned and losses separately (two bars); buckets with nothing stay empty.

**Table total equals the tiles.** The two tiles, the chart and the table are all built from the single `transactions` list of one `FinanceSummary`: `totalEarned` is the sum of the `earned` entries and `totalLosses` the sum of the `loss` entries of that list. The table shows those same entries newest first, 5 inline plus a "View all transactions" link only when there are more than 5 (the link opens the full list for the same period). So the sum of the Earned rows equals the Total earned tile and the sum of the Loss rows equals the Total losses tile. Per-car share is `carEarned / totalEarned` (0 when nothing is earned), and the per-car screen runs the same code filtered to one `vehicleId`.

Known limits:

- A booking can have several repair expenses. The deduction is one budget per booking: `RepairLossAllocator` applies it to the repairs oldest first, so it is never offset twice and a booking's total loss is `max(0, repairs - deduction)`. (A first version subtracted the full deduction from every repair; the allocator and its tests fixed that.)
- The deduction is looked up across all time for the booking, so a repair logged in a later month than the claim is still offset by it.
- All of this runs on the device, with the owner's reads allowed by the rules. A server-side total would need a Cloud Function, which the project does not use.

## 2. Reviews rule

- **Id.** `bookingId_authorId_subjectType`, for example `booking-p6_renter4_user` and `booking-p6_renter4_vehicle` (`subjectType` is `user` or `vehicle`). The id makes a second review of the same subject for the same booking an edit of the same document, never a duplicate.
- **Create and edit, never delete.** `FirestoreReviewRepository.submitReview` creates the review, or edits it if the id exists (`editedAt` is set and `stars` and `comment` change). The app has no delete action. The rules still allow delete to the author, the subject and a booking party, because account deletion has to remove reviews; this is a rules allowance, not a feature.
- **Mandatory.** Stars (1 to 5) and a non-blank comment are both required; the repository returns a `ValidationFailure` otherwise and the page shows inline errors.
- **Who reviews whom.** After a completed booking: the owner reviews the renter (a `user` review); the renter reviews the owner (a `user` review) and the car (a `vehicle` review). Three reviews per booking.
- **Aggregates.** `ratingAvg` and `ratingCount` on the reviewed `users` or `vehicles` document are updated in the same batch as the review. New review: `count + 1`, `avg = (oldAvg * oldCount + stars) / newCount`. Edit: count unchanged, `avg = (oldAvg * count - oldStars + newStars) / count`. The average is rounded to one decimal. Example: a car at 4.0 with 2 reviews gets a 4-star review: `(4.0 * 2 + 4) / 3` = 4.0; a later edit of that review to 5 stars gives `(4.0 * 3 - 4 + 5) / 3` = 4.3.
- **The pending-review block.** `FirestorePendingReviewChecker` replaces the Phase 0 stub. `hasPendingReview(userId)` is true while any completed booking of the user is missing a review they owe (renter: owner and car; owner: renter). It is called when a renter creates a request (`create_booking_request.dart`) and when an owner approves one (`firestore_booking_repository.dart`), which then fail with "Write your pending review..." messages.
- **Rules.** `reviews`: read by any signed-in user; create only as the author (`authorId == uid`); update only by the author and never changing `authorId`, `bookingId`, `subjectId` or `subjectType`. Rating aggregates: a user who is not the document's owner may update `users/{id}` or `vehicles/{id}` only when the change is `ratingAvg` and `ratingCount` alone, the count stays or grows by exactly 1, and the average is between 1 and 5. A user cannot change their own `users` rating (the self-update rule forbids it).
- **The honest limit.** The rule bounds the change but cannot prove that a review was written in the same batch. A rule cannot compute the review id from the subject document, so a signed-in user could change another user's or car's aggregate by one step, or move the average anywhere in 1 to 5, without writing a review. Making the aggregate trustworthy needs a Cloud Function (not used in this project, see `docs/adr/0002-account-deletion.md`). Two related gaps: the review create rule does not check that the author took part in a booking with the subject, and the owner of a car can change that car's own aggregate freely (the owner update rule on `vehicles` has no field restriction). Both are accepted for the course scope and should be stated as such.
- **Tests.** `tool/rules-test/firestore.rules.test.js` covers create, read, edit and delete, the aggregate rule for users and cars (allowed steps, the bounds, extra fields, count +2 or down, average 0 or above 5, an owner changing their own rating), batches mirroring the repository for a user and a car subject, and unauthenticated access.

## 3. Notifications

- **Types** (`NotificationType`, stored as the key): `request_received`, `request_approved`, `request_declined`, `request_expired`, `booking_cancelled`, `payment_received`, `payment_deadline`, `pickup_confirmed`, `return_confirmed`, `claim_changed`, `late_fee_applied`, `review_due`. The page shows one icon per type. Other phases write the documents through `NotificationWriter`; Phase 6 only reads, marks read and deletes.
- **List.** `NotificationsBloc` listens to the signed-in user's notifications stream (newest first). Each tile has an icon, an unread dot, the text and the age.
- **Unread count.** `unreadCount` is the number of notifications with `read == false`. It is part of `NotificationsLoaded`.
- **Deep link.** Tapping a tile marks it read (only if it was unread) and, when the notification has a `bookingId`, pushes `/booking/:id`.
- **Mark read and clear.** Mark one read, mark all read, dismiss one, clear all. The rules let only the owner (`userId`) read, update and delete; any signed-in user may create one, because the writer is the other party of the booking.
- **Badge.** `role_shell.dart` passes the unread count to the bell in `main_bar.dart`, which shows a `Badge.count` when above 0.
- **notifications_enabled setting.** When the Settings switch is off, the bloc emits an empty list with `notificationsEnabled: false`, the page shows a "notifications are off" view and the badge shows 0. The documents are still written by the other phases; they are hidden, not discarded, so turning the switch on again shows them.
- Tests: the rules above are in the rules tests; the bloc has `bloc_test` cases.

## 4. Security rules and indexes added in Phase 6

- `reviews` and `notifications` blocks as in sections 2 and 3, the `ratingChange()` helper and two extra `update` rules for `users` and `vehicles`.
- Two composite indexes in `firestore.indexes.json`: reviews by `subjectType` + `subjectId` + `createdAt`, and by `authorId` + `createdAt`.
- `tool/rules-test/firestore.rules.test.js`: 33 new cases for reviews, the aggregate rule, review batches, notifications and unauthenticated access.

## 5. Verification status

Run on 2026-11-20 on the development machine:

- **Firestore rules tests:** run against the local Firestore emulator (firebase-tools, no login or real project), on a temporary port because 8080 was in use by another process (`npm test` uses 8080). 86 tests, all passing: the 51 from Phases 3 to 5, 33 for Phase 6 and 2 for the owner-rating rule. While writing them it turned out the `vehicles` owner update rule let an owner set their own car's `ratingAvg` and `ratingCount`; it now forbids that, as the `users` rule already did.
- **Flutter checks:** `flutter analyze` clean and `flutter test` 699 passing on the merged branch. Not run: the seeded end-to-end flows on a device and the Firebase deploy of the rules and indexes.
- **Tests added after the first draft:** `PendingReviewRule` (11 unit tests), the finances transactions table widget (5 tests: 5 rows, the link only above 5) and `RepairLossAllocator` (7 tests). The table total is not asserted by a widget test, because the table renders no total; it equals the tiles by construction (one `transactions` list).
- The worked examples in section 1 and the average example in section 2 were calculated by hand and are not asserted by a test.

## 6. Still to add by hand

- Screenshots: finances month chart and table, year chart, per-car share list, transactions page, review form with inline errors, edited review, notifications list with badge, renter payment history.
- Demo segment F (about 2 minutes): leave both reviews, edit one, open a notification deep link, finances chart and table toggle, payment history.
- Live run of the seeded Phase 6 scenarios (`tool/seed/scenarios/phase-6.js`): `owner1` and `owner2` finances (this month, this year, late fee, claim and repair cases), `owner5` empty finances, `renter14` payment history, `renter14` and `p6-owner` blocked by a pending review, `renter4` and `owner3` edit, notifications for `owner1` and `renter14`.
- Figma-vs-app comparison and the `TODO.md` ticks.
