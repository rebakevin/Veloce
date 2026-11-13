# Phase 3 — Renter: discovery & request

| | |
| --- | --- |
| **Label** | `phase-3` |
| **Assignee** | _one person_ |
| **Branch** | `2-renter-discovery-request` (already created from the issue; use it, do not create another) |
| **Feature folder** | `lib/features/discovery/` |
| **Spec** | `SPECS.md` §5.2–5.4 · `TECHNICAL.md` §4.5, §5.1, §10 |
| **Depends on** | Nothing. Needs only Phase 0 (done) and the seed data |

---

## Goal

Let a renter find a car and ask to rent it: browse and search published cars, filter them, save favourites, open a car's detail page and send a booking request. When this is done, a renter can go from the home screen to a `pending` booking request that the owner will see.

## Features to implement

1. **Search and results:** published cars filtered by area, dates, type chip and filters, excluding cars not free in the window (`calendarBlocks`).
2. **Renter Home:** greeting, search card, type chips, car cards, Explore / Saved tabs, "how it works".
3. **Area + date range picker** (past days disabled) and **filters** (price min/max, type, transmission, seats, active count, reset).
4. **Results page** with count and empty state; **car card** with favourite heart.
5. **Car detail:** carousel, media screen, specs, features, rules (+ PDF link), owner block (info only), calendar with blocked days and window limit, live price breakdown, long-rental note, terms checkbox, "Request booking".
6. **Owner viewing their own car:** read-only preview with no booking UI.
7. **Favourites:** add/remove/watch; one source for hearts and the Saved count.
8. **Booking request:** review screen (breakdown without platform fee) → confirmation page `/booking/:id/requested`.
9. **`OwnerCarsSection` slot** on the public profile.
10. Hero transition on the car photo, loading skeletons, empty states.
11. **Firestore rules and indexes** for favourites, booking create and search.

## Acceptance criteria

**Behaviour**
- [ ] Search by area and dates returns only published cars that are free for the whole window; cars with a `calendarBlocks` overlap are excluded.
- [ ] Filters work together: price min/max, type, transmission, seats; the active-filter count is correct and reset clears them.
- [ ] Results show a count and an empty state; loading skeletons appear while loading.
- [ ] Past days cannot be picked; the request must lie inside the car's availability window and on free days.
- [ ] `SearchCubit` saves `last_search_area` and `last_type_chip` through `PreferencesService` and restores them on the next start.
- [ ] Tapping a heart toggles the favourite and **both** the card heart and the Saved count update from the same `FavouritesBloc`.
- [ ] Car detail shows a live price breakdown (days, rate applied, rental fee, platform fee, caution, total) and the long-rental note, e.g. "3+ days: RWF 80,000 per day", using `PricingCalculator`.
- [ ] "Request booking" is disabled until the terms checkbox is ticked.
- [ ] Owners viewing their own car see a read-only preview and cannot request it.
- [ ] `CreateBookingRequest` fails with a clear message for each of: dates outside the window or not free, own car, renter already holds a lock, `PendingReviewChecker` reports a pending review, email not verified.
- [ ] A successful request writes the booking with rate and totals locked from `PricingCalculator`, reference `VLC-####`, status `pending`, `expiresAt` = now + 24 h, the renter contact document, an audit-log entry and a notification to the owner, all in one atomic write.
- [ ] The confirmation page `/booking/:id/requested` opens with the reference.

**Security and data**
- [ ] Rules: `users/*/favourites` writable only by the user; `bookings` create allowed only for the renter with the correct initial state; `bookings/*/private/renter` writable only by the renter.
- [ ] Rule tests for favourites and booking create.
- [ ] Search indexes added to `firestore.indexes.json`.
- [ ] Only `users/*/favourites`, `bookings` (create only) and `bookings/*/private/renter` are written.

**Quality**
- [ ] Unit: search filtering and availability logic, request validation (each failure), favourites toggle.
- [ ] Bloc: `FavouritesBloc`, `ResultsBloc`, `RequestBloc`.
- [ ] Widget: car card heart toggles; request button disabled until terms are ticked.
- [ ] `dart format`, `flutter analyze`, `flutter test` all clean; no `setState`.
- [ ] Figma-vs-app screenshots in the PR.

**Docs and demo**
- [ ] Report sections: search algorithm, request flow, state-management example.
- [ ] Demo segment C (~2 min): search with filters, heart a car and show **two widgets updating**, send a request and show the new `bookings` doc in the console.

## Technical description

### Already in place (do not rebuild)

**Domain & data (`lib/core`)**
- Entities: `Vehicle`, `VehiclePhoto`, `Favourite`, `Booking`, `BookingContact`, `CalendarBlock`, `RenterLock`, `LongRate`, `AuditLogEntry`, `AppNotification`.
- Models with `fromMap`/`toMap` for each.
- Enums: `BookingStatus`, `VehicleStatus`, `VehicleType`, `Transmission`, `NotificationType`.
- Constants: `FirestorePaths`, `FirestoreFields`, `AppConstants`.
- Lookups: `VehicleLookup`, `UserLookup`, `BookingLookup` (cached read-by-id/stream).
- `Result`, `AppFailure`, `Clock`.

**Business rules**
- `PricingCalculator` (+ `PriceQuote`): chargedDays, long-rental tiers, quote with platform fee 2,000.
- `BookingStateMachine`: transitions and `effectiveStatus`.
- `Validators`, `Formatters` (RWF, dates, reference `VLC-####`).
- `PendingReviewChecker` interface; a stub returning `false` is registered in `reviews_injection.dart` (Phase 6 replaces it, so keep using the interface).
- `EmailVerificationGate` (auth feature) for the verified-email rule.

**Services**
- `AtomicWriteFactory` / `AtomicWrite` for batched writes; `AuditLogger` and `NotificationWriter` take the same `AtomicWrite`.
- `PreferencesService`: keys `last_search_area`, `last_type_chip`.
- `AuthSession`: `currentUserId`, `role`, `isEmailVerified`.

**Screens and routing**
- Placeholder routes in `discovery_routes.dart`: `/renter/home` (tab root), `/renter/search`, `/renter/filters`, `/renter/results`, `/car/:id`, `/car/:id/media`, `/car/:id/dates`, `/car/:id/book`, `/booking/:id/requested`.
- `OwnerCarsSection` placeholder slot (`features/discovery/presentation/widgets/owner_cars_section.dart`) used by `PublicProfilePage`.
- Widget kit: `DateRangeField`, `DatePickerField`, `PriceBreakdown`, `RatingStars`, `StatusChip`, `UserAvatar`, `EmptyState`, `ErrorView`, `LoadingView`, `PrimaryButton`, `SectionHeader`, `AppMessenger`.
- `PublicProfilePage` (`/user/:id`) is done and links from the owner block.

**Data**
- Seed: 8 cars across 3 owners with photos and availability, calendar blocks, 4 renters (`renter1`–`renter4@veloce.test`, password `Veloce#2026`). `renter4` has no lock, so it can send a new request; `renter1`–`renter3` already hold one (approved, confirmed, active), which tests the "already locked" failure.
- `firestore.rules` has labelled `favourites` and booking blocks.

### Dummy data for this task

The seed script loads everything this task needs (extra cars, an unverified renter, calendar blocks, favourites) from `tool/seed/scenarios/phase-3.js`. Nothing depends on another phase.

**Load it**
1. Merge the latest `main` into your branch first (so you have `tool/seed/` and the scenario file).
2. `cd tool/seed && npm install && GOOGLE_APPLICATION_CREDENTIALS=/path/to/veloce-service-account.json npm run seed`
3. Re-run the seed after testing: it restores any seeded booking you changed (for example the `pending` one after a request test). It only overwrites its own ids, so it is safe to repeat.

**Accounts** (sign in via `/dev-login`, password `Veloce#2026`): `renter1@veloce.test` ... `renter5@veloce.test`, `owner1@veloce.test` ... `owner3@veloce.test`.

This phase adds 9 cars to the 7 published base cars (16 published; `p3-car-docs-expired` must be hidden, so 15 show in results; `car-8` is paused). Other phases may add a few more cars, so count only `car-*` and `p3-car-*`. Photos (3 per car) are generated automatically. Day offsets are relative to the day you seed.

| Scenario | Account | Car / booking id | What to test |
| --- | --- | --- | --- |
| Many cars, varied filters | any renter | all `car-*` and `p3-car-*` | Types: sedan, SUV, hatchback, minivan, pickup. Transmission: manual and automatic. Seats: 4 (`p3-car-kimironko-2`), 5, 7 (`p3-car-minivan-7`, `p3-car-nyarutarama-2`), 14 (`car-6`). Fuel includes electric (`p3-car-electric`). Price RWF 25,000 (`p3-car-kimironko-2`) up to 250,000 (`p3-car-nyarutarama-2`). |
| Same neighbourhood | any renter | Kacyiru: `car-1`, `p3-car-kacyiru-2`, `p3-car-kacyiru-3`. Nyarutarama: `car-2`, `p3-car-nyarutarama-2` | Area search returns several cars; other areas: Kimironko, Remera, Kicukiro, Nyamirambo, Gisozi, Kibagabaga, Kimihurura, Kabeza (paused). |
| Short availability window | any renter | `p3-car-short-window` (available day +5 to +9) | Dates 5-9 find it; a window wider than that, or starting before day 5, does not; the date picker/detail limits the request to the window. |
| Blocked days in the middle of a window | any renter | `p3-car-block-mid`: blocked day +20 to +23 and +30 to +32. `p3-car-electric`: blocked +12 to +15 | Search +18 to +26 excludes it; +12 to +15 includes it; +23 to +25 includes it (a block ending on your start day does not overlap). The detail calendar greys the blocked days and the request fails on them. |
| Blocks from existing bookings | any renter | `booking-approved` (`car-4`, +4 to +7), `booking-confirmed` (`car-7`, +3 to +7), `booking-active` (`car-6`, -1 to +2), `booking-returning` (`car-1`, -4 to -1), `booking-review` (`car-2`, -8 to -5) | Search overlapping those days excludes the car. `booking-pending` (`car-2`, +5 to +8) does **not** block: `car-2` stays visible for those days. |
| Expired documents hidden | any renter | `p3-car-docs-expired` (insurance expired 3 days ago) | Never appears in results (`docsValidUntil >= today`). |
| Paused car hidden | any renter | `car-8` | Never appears in results. |
| Own car preview, hidden from results | `owner1` (cars `car-1` to `car-3`, `p3-car-kimironko-2`, `p3-car-electric`) | `/car/car-1` | Read-only preview with no booking UI; own cars never appear in the owner's search results. Other owners: `owner2` (`car-4` to `car-6`, `p3-car-kacyiru-2`, `p3-car-minivan-7`, `p3-car-block-mid`), `owner3` (`car-7`, `car-8`, `p3-car-kacyiru-3`, `p3-car-nyarutarama-2`, `p3-car-short-window`, `p3-car-docs-expired`). |
| Successful request | `renter4` (no lock) | any free car, e.g. `car-3` or `p3-car-kacyiru-2` | Booking `pending`, `VLC-####`, `expiresAt` +24 h, contact doc, audit log, notification to the owner. (`renter4` already has `booking-pending` and an expired one, which do not lock.) |
| Already holds a lock | `renter1` (`booking-approved`), `renter2` (`booking-confirmed`), `renter3` (`booking-active`) | any free car | Request fails with the "already locked" message. |
| Email not verified | `renter5` (email NOT verified, no lock, no bookings) | any free car | Request fails with the verify-email message; `EmailVerificationGate` blocks it. |
| Many favourites | `renter1` | 7 hearts: `car-2`, `car-4`, `car-7`, `p3-car-kacyiru-2`, `p3-car-nyarutarama-2`, `p3-car-electric`, `p3-car-minivan-7` | Saved tab count and list; un-heart and see card heart and Saved count update together. |
| Favourite of an unavailable car | `renter3` | `car-8` (paused) | Saved tab with a car that is no longer published. |
| No favourites | `renter4`, `renter5` | n/a | Empty Saved tab. |
| Long-rental note and breakdown | any renter | `car-2` (3+ days 85,000; 7+ days 80,000), `p3-car-nyarutarama-2` (3+ 230,000; 7+ 210,000), `car-3` (no tiers) | `PricingCalculator` tiers, platform fee 2,000, caution. |

Not covered by seed data: a pending-review failure for `PendingReviewChecker` (a stub returning `false` until Phase 6); test it with a fake in a unit test.

### To build in this phase

- `features/discovery/domain`: `SearchRepository`, `FavouritesRepository`, `RequestRepository.createBooking`, use cases `SearchVehicles`, `GetVehicleDetail`, `ToggleFavourite`, `CreateBookingRequest`.
- `features/discovery/data`: Firestore implementations (search per `TECHNICAL.md` §4.5).
- `features/discovery/presentation`: `SearchCubit`, `FiltersCubit`, `ResultsBloc`, `CarDetailBloc`, `FavouritesBloc`, `RequestBloc`, pages and widgets above.
- Register in `discovery_injection.dart`; replace placeholders in `discovery_routes.dart`.

### Cross-phase notes (no waiting needed)

- The owner's decision and payment (`pending` → `approved` → `confirmed`) are Phase 4; you only create the `pending` booking. Use seeded bookings to see later states.
- Car listing is Phase 2; until it merges you read the seeded cars.
- Car reviews and the owner rating come from Phase 6 (`/car/:id/reviews` stays a placeholder link; show the rating fields already on the vehicle/user document).
