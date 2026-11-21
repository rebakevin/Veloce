# Phase 4 findings: booking decision, payment, activity, detail, agreement, cancel

Audited: `lib/features/booking`, `test/features/booking`, the bookings / calendarBlocks / renterLocks / transactions / notifications blocks of `firestore.rules`, `firestore.indexes.json`, `tool/rules-test`.
Commands run: `flutter analyze` (no issues), `flutter test test/features/booking` (53 passed, 0 failed).

## Verdict

Phase 4 is broadly implemented and the write shapes match the rules: every batch (approve, decline, cancel, pay, expire, agreement) uses exactly the `changed().hasOnly(...)` key sets, `serverTimestamp` for `updatedAt`/`at`, and the refund/charge amounts the rules demand, so the happy paths should commit. Analyze and the 53 booking tests are green. The problems are in the edges. The most serious are: a same-day pickup is approved with a payment deadline already in the past (the booking expires instantly, against SPECS §4.1 step 5); the lazy-expiry sweep runs concurrently from several places and its losing writers surface a "conflict" as an error view; every bloc overwrites the live stream state with a stale snapshot after an action finishes (the list can stay stale after a cancel); the MoMo charge is not recoverable if the booking batch fails after the charge (orphan charge, double charge on retry); and there are no emulator rules tests at all for the Phase 4 rows (approve, locks, calendar blocks, contact read before/after payment, charge/refund). Repository code has no tests either (only use cases and blocs against mocks).

## TODO tasks

| Task | Verdict | Notes |
|---|---|---|
| 4.A BookingRepository (watch by role, watch one, batches) | ok | `FirestoreBookingRepository`. Reads happen outside the batch (not a transaction), see F4-06. |
| 4.A ApproveBooking | bug | Tick, pending-review, renter lock, overlap declining, owner contact doc, lock, block and notification all present. Deadline bug F4-01; stale-lock gap F4-07. |
| 4.A DeclineBooking / CancelBooking / ExpiryEngine | ok / bug | Decline ok. Cancel amounts correct (confirmed: `totalPayable` refund; approved/pending: none). Expiry deadline bug F4-01. |
| 4.A PayBooking | bug | Failure keeps `approved` and allows retry; but F4-05. |
| 4.A AcknowledgeAgreement | ok | Matches rule row; not a gate for payment (spec does not require it). |
| 4.A EffectiveStatus on every list | gap | Renter lists apply the lock; owner lists do not (F4-08). |
| 4.B ActivityBloc / BookingDetailBloc / DecisionBloc / PaymentBloc | bug | Stale-state overwrite F4-03; retry resubscribes F4-10. |
| 4.B ExpirySweeperCubit (start/resume/activity load) | bug | Races F4-02; start-up sweep before sign-in is a no-op F4-11. |
| 4.C My Activity | ok | Open/Active/Past, owner grouping by car, quick actions. Owner has no cancel quick action (F4-12). |
| 4.C Booking detail | ok | All sections, locked contact tile, slots hosted. Timeline for terminal states F4-13. |
| 4.C Owner decision page | ok | Tick gates the button, "You earn", decline reason. |
| 4.C Payment screen | ok | MoMo validation, breakdown, countdown, processing, success route, failure with message. |
| 4.C Rental agreement | ok | Nine sections, late-fee and cancellation text present (not re-counted section by section). |
| 4.C Cancel flow with dialog and refund note | ok | Dialog states refund for confirmed. |
| 4.C PendingRequestsCard / UpcomingRentalsCard | bug | Each creates its own `ActivityBloc`, so each runs its own sweep: feeds F4-02. |
| 4.D Rules (transitions, locks, calendar, contact lock, charge/refund) | ok / gap | Rules match the client. Weak refund rule F4-09. No emulator tests F4-04. |
| 4.D Demonstrate contact docs unreadable before, readable after | needs-human | F4-14. Open in TODO (correct). |
| 4.E Unit tests (approve conflict, overlap, deadline, refund, effective status) | gap | Use-case level only; repository conflict path untested (F4-06). Deadline test misses the midnight/same-day case (F4-01). |
| 4.E Bloc tests (Payment, Decision) | ok | Present. |
| 4.E Widget: locked tile to revealed | ok | `counterparty_contact_card_test.dart`. |
| 4.F Report sections | ok | `docs/report/phase-4-draft.md` exists (not audited). |
| 4.F Demo segment D | needs-human | Open in TODO (correct). |

## Findings

### F4-01 [severity: major] [kind: bug]
- Where: `lib/features/booking/data/firestore_booking_repository.dart:211` (`paymentDeadline(approvedAt: now, pickupAt: booking.startDate)`), `lib/features/booking/domain/services/expiry_engine.dart:20`
- What: `startDate` is a date at local midnight (`rules.day`, `renter_home_page.dart:71`, and `create_booking_request.dart:60` allows "from today onwards"). The deadline is `min(now + 24 h, startDate)`. Approving a request for a pickup today, or any time after midnight of the pickup day, gives a deadline in the past: the booking is approved, the renter lock and calendar block are written, and `effectiveStatus` immediately returns `expired`; pay is refused. SPECS §4.1 step 5 says the opposite ("approved on the pickup day itself, payment is due before handover"). Approving the evening before a next-day pickup also shortens the window to a few hours.
- Evidence: code trace; `expiry_engine_test.dart` only tests `pickupAt = now + 5 h`, never a midnight pickup.
- Fix: treat the pickup as end of the pickup day (or a fixed handover hour, e.g. startDate + 23:59 or a constant handover time) in `paymentDeadline`; reject approval only when that moment has passed; add the same-day test.
- Status: fixed

### F4-02 [severity: major] [kind: bug]
- Where: `activity_bloc.dart:_onStarted`, `expiry_sweeper_cubit.dart`, `app.dart:30`, `pending_requests_card.dart:22`, `upcoming_rentals_card.dart:22`, `firestore_booking_repository.dart:expireDueBookings`
- What: three or more sweeps can run at once on the owner home (app-start cubit, plus one `ActivityBloc` per slot card, plus the Activity tab). Each reads the same due booking and commits `pending -> expired`. The second batch fails the rule (no `expired -> expired` row) with `permission-denied`, which `_transitionFailure` maps to `ConflictFailure`; `expireDueBookings` returns that failure on the first one and stops, and `ActivityBloc._onStarted` turns it into `ActivityFailure` and never subscribes to the stream. A harmless duplicate shows as an error view with Retry. Even without a race, any single failing booking aborts the sweep for all later bookings and blocks the list.
- Evidence: code trace (the booking is read with `.get()` and the batch has no precondition).
- Fix: make the sweep idempotent (swallow conflict per booking and continue; or use a Firestore transaction that re-reads the status); never let a sweep failure block `watchMyBookings` (log and continue); share one in-flight sweep (single guarded call in the repository or cubit).
- Status: fixed

### F4-03 [severity: major] [kind: bug]
- Where: `activity_bloc.dart:_onCancelRequested`, `booking_detail_bloc.dart:_onCancel/_onAcknowledge`, `decision_bloc.dart:_onApproved/_onDeclined`, `payment_bloc.dart:_charge`
- What: after `await`, each handler emits `current.copyWith(action: ...)` where `current` was captured before the call. The Firestore stream normally emits the local (latency-compensated) snapshot before the commit future completes, so the stream-driven `bookings` / `view` is replaced by the stale pre-action copy. `snapshots()` does not emit a second event for the server ack, so the list or detail can stay stale (a cancelled booking still in Open, an approved request still pending) until the next real change. Blocs tests use immediate fakes so they do not catch it.
- Evidence: code trace; event handlers are concurrent by default so `_BookingsChanged` runs during the await.
- Fix: re-read `state` after the await (`final latest = state; if (latest is Loaded) emit(latest.copyWith(action: ...))`), and cover it with a bloc test that pushes a stream event during the action.
- Status: fixed

### F4-04 [severity: major] [kind: test-gap]
- Where: `tool/rules-test/firestore.rules.test.js`
- What: the emulator suite covers booking create, pickup/return, ledger at pickup and settlement, claims, reviews. It has no case for any Phase 4 rule: approve/decline/cancel/expire rows, `agreementAckAt` row, `renterLocks` create (once only, must be `approved`) and delete, `calendarBlocks` create/delete, `bookings/*/private/*` read before and after `confirmed`, `charge` and `refund` amounts, notifications. The TODO claims 4.D done and the merge doc says rules tests live there.
- Evidence: `grep describe/it` of the file.
- Fix: add Phase 4 describes (including a full approve batch with overlap decline, a pay batch, a cancel batch with refund, and the contact read before/after payment, which also closes 4.D "Demonstrate").
- Status: open

### F4-05 [severity: major] [kind: bug]
- Where: `firestore_booking_repository.dart:489-541` (`pay`)
- What: the MoMo charge happens first, then the batch. If the batch fails (offline, timeout 20 s, rule conflict because the booking expired or was cancelled in between), the renter was charged with no ledger row and the booking is still `approved`; the UI shows a failure and Retry calls `charge` again: double charge. The `isPaymentExpired` check before the charge is client-clock only and the deadline can pass during the charge.
- Evidence: code trace.
- Fix: keep the receipt and retry only the batch when a charge already succeeded (idempotent reference per booking), or re-check/commit status before treating the charge as final; at minimum surface a distinct "payment taken, recording failed" state.
- Status: fixed

### F4-06 [severity: minor] [kind: test-gap]
- Where: `firestore_booking_repository.dart` (whole class), `test/features/booking/domain/*`
- What: the repository is untested. "Approve conflict (renter already locked)", "overlap declining", "cancel refund amounts" are tested only as use-case pass-through (`approve_booking_test.dart`) and as pure services (`booking_overlap_test.dart`, `cancellation_policy_test.dart`). Reads and writes are separate (no `runTransaction`), so approve relies on the rules (`!exists` on the lock, `status == approved`) to arbitrate races; that works but returns the generic message "This renter is already booked, or the request changed."
- Fix: add repository tests with `fake_cloud_firestore` (or the emulator) for approve (locked, overlap, expired), cancel refund, pay, expiry.
- Status: open (repository tests need `fake_cloud_firestore`, a pubspec change for the main session; domain, bloc and engine tests added)

### F4-07 [severity: minor] [kind: bug]
- Where: `firestore_booking_repository.dart:185-193`
- What: approve refuses whenever any `renterLocks/{renterId}` exists, without checking whether the locking booking is itself lazily expired (deadline passed, not yet swept). A renter whose approved booking expired but who has not opened the app blocks every other owner's approval, with "already booked", until their own sweep runs (an owner only sweeps their own bookings).
- Fix: load the locking booking and ignore the lock if its effective status is expired/cancelled.
- Status: open (client side done: a lock whose holder is expired/cancelled/missing is ignored; the rules must also allow it, see Fix log)

### F4-08 [severity: minor] [kind: gap]
- Where: `firestore_booking_repository.dart:105` (`applyLock: role == UserRole.renter`)
- What: the task says `EffectiveStatus` is applied "to every list so cancelled-by-lock requests show correctly". Owners do not get it: a request from a locked renter shows Pending with a "Review request" action; approve then fails. Also the lock-cancelled request is never persisted, so it stays `pending` in Firestore until its 24 h expiry.
- Fix: acceptable if documented; otherwise let the owner view flag it (read the renter's lock) and offer decline.
- Status: fixed

### F4-09 [severity: minor] [kind: gap]
- Where: `firestore.rules:216-` (`transactions`, `refund` branch)
- What: a refund row only requires the booking to be `cancelled` after the batch and `amount == totalPayable`. It does not require the booking to have been `confirmed` before, and nothing prevents a second refund row for the same booking or a refund on a never-paid booking. The client does not do this, but the rule is the stated safeguard ("ledger invariants").
- Fix: require `bk(id).status == 'confirmed'` for the refund branch; require the refund to be written only in the cancelling batch.
- Status: open (rules, main session)

### F4-10 [severity: nit] [kind: bug]
- Where: `activity_bloc.dart:_onStarted` (and detail/decision/payment equivalents)
- What: the Retry buttons re-add `*Started`; handlers are concurrent, so the previous `emit.onEach` subscription stays alive and a second one is added (duplicate events, duplicate work).
- Fix: use `restartable()` transformer on the Started events.
- Status: fixed

### F4-11 [severity: nit] [kind: bug]
- Where: `app.dart:30`, `expiry_sweeper_cubit.dart:48`
- What: the app-start sweep runs before sign-in (session null yields `Done(0)`); the resume observer covers later opens, and the Activity page sweeps on load, so only the "on start after login" case is uncovered.
- Fix: also sweep when `AuthBloc` becomes authenticated.
- Status: fixed

### F4-12 [severity: nit] [kind: gap]
- Where: `activity_page.dart:_actions`, `_OwnerGroup`
- What: owners have no cancel quick action (Approved, Active tabs); cancel is only in the detail page. Task says "quick actions work" (renter has cancel/pay, owner has Review request); acceptable, note only.
- Status: fixed

### F4-13 [severity: nit] [kind: spec-drift]
- Where: `booking_timeline.dart:_completedSteps`
- What: declined, cancelled and expired map to "1 done" and the second step is drawn as the current step, which reads as "waiting for approval". The headline carries the real status, but the timeline is misleading for terminal states. A booking cancelled after payment also resets to step 1.
- Fix: mark terminal-bad statuses with an end marker or hide the current ring.
- Status: fixed

### F4-14 [severity: major] [kind: needs-human]
- Where: TODO 4.D "Demonstrate", 4.F demo segment D, phase doc open items
- What: need a person: run `tool/rules-test` against the emulator (and the new Phase 4 cases from F4-04), run the seed (`tool/seed`, scenarios in `phase-4.js`) and walk approve / overlap decline / locked renter / pay / failure toggle and retry / cancel refund / countdown on a device; rotate the phone once on booking detail (overflow check); Figma-vs-app screenshots. Also confirm on the real project that the `bookings` composite index (`vehicleId, status, startDate`) is deployed: it exists in `firestore.indexes.json`, the approve overlap query depends on it.
- Status: needs-human

### F4-15 [severity: nit] [kind: spec-drift]
- Where: `firestore_booking_repository.dart:231`
- What: the meeting point written to the owner contact doc is the hardcoded string `'<neighbourhood> roundabout'`; the owner is not asked for one. SPECS says "exact meeting point". Acceptable for a mock, but worth stating in the report.
- Status: open (accepted for the mock; no owner meeting-point input exists, state it in the report)

## Counts

blocker 0, major 5 (F4-01, F4-02, F4-03, F4-04, F4-05; F4-14 is needs-human, major), minor 4 (F4-06 to F4-09), nit 5 (F4-10 to F4-13, F4-15).

## Fix log

- F4-01: `lib/features/booking/domain/services/expiry_engine.dart` (`pickupDeadline`, deadline = earlier of now + 24 h and the end of the pickup day); `firestore_booking_repository.dart` approve refuses only when that moment has passed. Tests in `expiry_engine_test.dart`.
- F4-02: `expireDueBookings` is single-flight per user (`_sweeps`), skips unreadable bookings and conflicts per booking and continues; `ActivityBloc` no longer shows or blocks on a sweep failure.
- F4-03: all four blocs rebuild the final action state from `state` after the await. Tests in `activity_bloc_test.dart`, `decision_bloc_test.dart`.
- F4-05: `pay` keeps the MoMo receipt in `_unrecordedCharges` until the batch commits; Retry records that charge instead of charging again; a rule conflict after the charge returns a message with the MoMo reference.
- F4-07 (client): `_isLockLive` reads the holding booking and ignores the lock when it is expired, cancelled, declined or gone. A read denied counts as live.
- F4-08: owner lists and detail apply the renter lock to open bookings (`_viewFromBooking`).
- F4-10: blocs keep one `StreamSubscription` and cancel it on a new Started and on close.
- F4-11: `ExpirySweeperCubit` sweeps again on `AuthSession.changes` when a user is signed in.
- F4-12: owner cancel quick action for Approved and Active-confirmed rows in `activity_page.dart`.
- F4-13: `booking_timeline.dart` shows no "next" ring for declined, cancelled or expired.
- F6-01 (payment deadline): the renter's sweep writes `paymentDeadline` notification `payment-deadline-<bookingId>` once, when the deadline is within 6 h (`ExpiryEngine.reminderWindow`); it checks for an existing one first and ignores a refused duplicate.
- Needs main session: rules for the stale lock (renterLocks create must allow replacing a lock whose booking is expired; other owners cannot read the holder booking if `bookings` read is party-only, so a `payDeadline` copy on the lock or a looser read would make F4-07 complete); notification create with a fixed id must stay allowed (update only `read` means a second write of that id is refused, which the client expects).
