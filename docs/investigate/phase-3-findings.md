# Phase 3 findings: Renter discovery and request

## Verdict

Phase 3 is largely implemented and wired end to end (UI -> bloc -> use case -> repository -> Firestore). `flutter analyze` reports no issues and `flutter test test/features/discovery` passes (38 tests). The domain logic (window, `calendarBlocks` overlap, pricing via `PricingCalculator`, own car, lock, pending review, email gate, `expiresAt` = +24 h, `VLC-####`, renter contact doc, audit, owner notification in one batch) is correct as written. The real problems are: the Saved tab shows no count even though the TODO and demo promise one, the area search query very likely needs a composite index that is missing from `firestore.indexes.json`, the use case and rules never check that the car is still published or has valid documents, the booking-create rule does not enforce own-car, expiry or pricing consistency (the client is the only guard), search is a sequential N+1 (two reads per candidate car), and there are no tests for the Firestore repositories. The two unticked TODO boxes (rules emulator run, demo C) need a human. The merging doc is stale about the review checker stub.

## Task table

| Task | Result |
|---|---|
| 3.A SearchRepository (published, filters, window, calendarBlocks) | ok, see F3-02, F3-07, F3-08 |
| 3.A FavouritesRepository, RequestRepository.createBooking | ok |
| 3.A Use cases (Search, GetDetail, Toggle, CreateBookingRequest) | ok, see F3-03 |
| 3.A CreateBookingRequest rules and writes | gap (F3-03, F3-04, F3-09) |
| 3.B SearchCubit (saves last_search_area / last_type_chip) | ok (saved on search tap, tested) |
| 3.B FiltersCubit, ResultsBloc, CarDetailBloc, RequestBloc | ok, F3-06 (race) |
| 3.B FavouritesBloc single source for hearts and Saved count | gap (F3-01), F3-10 |
| 3.C Renter Home (greeting, search, chips, cards, tabs, how it works) | gap (F3-01 Saved count) |
| 3.C Area + date picker, filters | ok, F3-11 |
| 3.C Results with count and empty state | ok |
| 3.C Car card with heart | ok |
| 3.C Car detail (carousel, media, calendar, price, long-rental note, terms) | ok, F3-12 |
| 3.C Owner read-only preview | ok |
| 3.C Request review and confirmation | ok, F3-13 |
| 3.C OwnerCarsSection | ok (rules allow the ownerId query) |
| 3.C Hero, skeletons, empty states | ok (Hero on card and carousel, `CarCardSkeleton`); on-device check needs-human |
| 3.D favourites and booking-create rule tests, indexes | gap (F3-02, F3-04, F3-05); emulator run needs-human |
| 3.E Unit tests | ok, F3-14 for missing cases |
| 3.E Bloc tests | ok |
| 3.E Widget tests (heart, terms button) | ok |
| 3.F Report sections | ok (not re-read) |
| 3.F Demo segment C | needs-human (F3-15) |

## Findings

### F3-01 [severity: major] [kind: gap]
- Where: lib/features/discovery/presentation/pages/renter_home_page.dart:383-401 (`_TabHeader`), `FavouritesBloc`
- What: TODO 3.B and demo C say `FavouritesBloc` drives "hearts, Saved count" and that two widgets (card heart + Saved count) update. The tab bar is `const TabBar(tabs: [Tab(text: 'Explore'), Tab(text: 'Saved')])`: there is no count anywhere in lib (no use of `favouriteIds.length` outside the bloc). The only "Saved count" is in a widget test that builds its own widget.
- Evidence: grep for `favouriteIds.length` and `Saved` in lib/; read the tab header.
- Fix: make the tab header a `BlocBuilder<FavouritesBloc, ...>` showing `Saved (n)` from `state.favouriteIds.length`.
- Status: fixed

### F3-02 [severity: major] [kind: bug]
- Where: firestore.indexes.json (vehicles), lib/features/discovery/data/firestore_search_repository.dart:50-60
- What: with an area the query is `status ==`, `neighbourhood ==`, `docsValidUntil >=` (range). Indexes present: `(status, neighbourhood, dailyPrice)` and `(status, docsValidUntil DESC)`. The first is unused (there is no `orderBy dailyPrice`; sorting is client-side). No composite `(status, neighbourhood, docsValidUntil)` exists, so on real Firestore the area search will probably throw `failed-precondition` (index required) and surface as "Something went wrong". Without an area, `(status, docsValidUntil)` serves it. fake_cloud_firestore tests never need indexes, so this cannot show up in unit tests.
- Evidence: read both files; TECHNICAL §4.5 step 1 says the same query.
- Fix: add `vehicles (status ASC, neighbourhood ASC, docsValidUntil ASC)` and drop or justify the dailyPrice index. Verify on the console with an area search.
- Status: needs-human (confirm on a real project; high likelihood)

### F3-03 [severity: major] [kind: bug]
- Where: lib/features/discovery/domain/usecases/create_booking_request.dart:41-117, firestore.rules bookings create
- What: `CreateBookingRequest` never checks `vehicle.status == published` or valid documents. `detail()` returns any vehicle, so a car paused, expired or unpublished after the renter opened it (or reached by a stale favourite or deep link) can still receive a request. The rules do not check it either.
- Evidence: use case reads `detail.vehicle` and only checks owner, dates, window, blocks, lock, review.
- Fix: add `vehicle.status != published || !rules.hasValidDocs(...)` -> `ConflictFailure('This car is no longer available.')`, with a test. Optionally mirror `get(vehicles/..).data.status == 'published'` in the create rule.
- Status: fixed

### F3-04 [severity: major] [kind: gap]
- Where: firestore.rules:162-171 (`bookings` create)
- What: the create rule checks renterId == me, status pending, platformFee 2000, total == rentalFee + cautionFee, ownerId matches the vehicle. It does not check: `renterId != ownerId` (own car), `expiresAt` (a client can set a far-future or null expiry, so the request never lazily expires), `rentalFee == days * dailyRateApplied`, or that `startDate/endDate` are ordered. The own-car and expiry guards exist only in the client. The rules-test file has no case for any of these (only: other renter, not pending, owner mismatch, happy path).
- Evidence: read the rule and tool/rules-test/firestore.rules.test.js describes "booking create".
- Fix: add `request.resource.data.renterId != request.resource.data.ownerId`, `expiresAt <= request.time + duration.value(24,'h')`, `endDate >= startDate`; add rule tests. Renter lock cannot be enforced in create (lock exists only after approval), which is consistent with TECHNICAL §5.4 and SPECS "one booking at a time" (approved/confirmed/active).
- Status: open

### F3-05 [severity: minor] [kind: needs-human]
- Where: TODO 3.D, docs/merging/phase-3.md
- What: `favourites` and booking-create rule tests exist in tool/rules-test but were never run on the emulator. I did not run them.
- Fix: `cd tool/rules-test && npm test` with the emulator, tick 3.D.
- Status: needs-human

### F3-06 [severity: minor] [kind: bug]
- Where: lib/features/discovery/presentation/bloc/results_bloc.dart:20-24
- What: `on<...>` handlers use the default (concurrent) transformer in bloc 9. Changing filters twice quickly (or query then filter) starts two overlapping searches, and the slower, older one can emit last and show stale results with the wrong filters in state. Same risk for `FavouritesBloc._onSnapshot` (loops with awaits, so two snapshots interleave).
- Fix: use `restartable()` (bloc_concurrency) for results and `sequential()`/`restartable()` for favourites snapshots.
- Status: fixed

### F3-07 [severity: minor] [kind: bug]
- Where: firestore_search_repository.dart:62-79, `_blocksFor`, `_photos`
- What: for every candidate car after the window filter, the code awaits one `calendarBlocks` read then one `photos` read sequentially. With dozens of cars this is slow (hurts the demo) and each read has a 20 s timeout. Photos are also fetched for cars not shown because a block failed late? No, photos are fetched after the block check, so only for kept cars, but still sequential.
- Fix: run per-car work with `Future.wait`, or take only the primary photo (`where isPrimary`, limit 1).
- Status: fixed

### F3-08 [severity: minor] [kind: spec-drift]
- Where: firestore_search_repository.dart:73-75
- What: SPECS says cars need to be "free for the whole range"; the block query uses `endDate > start` then client overlap, matching TECHNICAL §4.5. OK. However the `type chip` (query.typeChip) and `filters.type` are two independent filters; if they disagree the result is silently empty and the filter-count badge does not show the chip. Price filter compares the base `dailyPrice` and ignores long-rental rates, so a 5-day search can include or exclude cars by a price the renter will not pay.
- Fix: sync chip and filter type in one place; document the base-price rule or filter by the applied rate.
- Status: fixed

### F3-09 [severity: minor] [kind: bug]
- Where: firestore_request_repository.dart:68-70
- What: reference is `VLC-` + `1000 + millis % 9000`. It is not unique (9000 values, time-derived, no check), so two bookings can share a reference. SPECS says "VLC-####" only, so uniqueness is a quality issue, not a spec break. Also the repository pre-reads `private/contact` outside the batch; a missing contact fails with a validation message (good) but there is a small race with edits.
- Fix: derive from a random or counter and retry on a collision, or accept and document.
- Status: open (client batch cannot enforce uniqueness; number now derived from the random booking id, not the clock)

### F3-10 [severity: minor] [kind: bug]
- Where: favourites_bloc.dart:62-92
- What: the Saved list is hydrated by `GetVehicleDetail` per favourite (owner read + photos + all blocks = 4 reads each, repeated on every snapshot, including each toggle). If a car was deleted or its owner doc is missing, the card is silently dropped but its id stays in `favouriteIds`, so a heart/count derived from ids would disagree with the visible list. Paused cars are still listed with no marker.
- Fix: hydrate with a cheap card read (vehicle + primary photo), cache by id, and prune or flag ids that fail with NotFound.
- Status: fixed (NotFound ids pruned; hydration still 4 reads per car, not cached)

### F3-11 [severity: nit] [kind: bug]
- Where: availability_calendar.dart:_selectable (about line 119)
- What: `_selectable` tests a single day `[d, d+1)` against blocks, so the return day cannot be set to a day that a later booking starts on, although the overlap rule allows it (block.start == requested end is free). The search form picker allows a max of 365 days ahead; the detail picker uses the owner window. Both fine.
- Fix: allow the end day when `block.startDate == day`.
- Status: fixed

### F3-12 [severity: nit] [kind: bug]
- Where: car_detail_page.dart (_RequestBar), request_bloc.dart, booking_review_page.dart
- What: the terms checkbox is required twice: on the detail page (`canRequest` needs `termsAccepted`) and again on the review page (`RequestBloc.termsAccepted`, disabled button). The TODO only asks for it before "Request booking". Not wrong, but redundant, and the second tick state is independent of the first.
- Fix: seed the review page's terms from the detail state or drop one.
- Status: open (needs router/DI change to pass the detail terms to the review page; redundant but harmless)

### F3-13 [severity: nit] [kind: gap]
- Where: booking_review_page.dart
- What: the review page uses the draft quote from the detail page; the real price is recomputed in the use case, so if the owner changed price between the two screens the renter confirms one price and a different one is written, with no warning.
- Fix: compare `booking.totalPayable` with the draft total on success, or reload the car on the review page.
- Status: fixed

### F3-14 [severity: minor] [kind: test-gap]
- Where: test/features/discovery
- What: no tests for `FirestoreSearchRepository`, `FirestoreRequestRepository` or `FirestoreFavouritesRepository` (fake_cloud_firestore): area query, docsValidUntil filter, calendarBlocks overlap on real documents, batch contents (expiresAt = +24 h, `VLC-` format, renter contact doc, audit, notification), favourites add/remove/watch. No test of long-rental tier pricing in the use case (only the "locked quote" case), no test for paused/unpublished car (F3-03), no widget test for `AvailabilityCalendar` or the owner read-only bar, no filters-page min > max case (no validation exists; min 200 000 / max 100 000 silently yields zero cars).
- Fix: add repository tests with fake_cloud_firestore and the cases above.
- Status: open (fake_cloud_firestore is not a dev dependency, so no repository tests; added use case, bloc, filters and race tests; no AvailabilityCalendar widget test)

### F3-15 [severity: minor] [kind: needs-human]
- Where: TODO 3.F demo C; docs/merging/phase-3.md
- What: demo segment, Hero transition feel, skeletons, the seed scenarios and Figma comparison need a device and the Firebase console. Not verified.
- Status: needs-human

### F3-16 [severity: nit] [kind: spec-drift]
- Where: docs/merging/phase-3.md:21-23
- What: says `PendingReviewChecker` is the stub. In code `reviews_injection.dart` registers `FirestorePendingReviewChecker`; the stub file is no longer registered, so the pending-review block works. The doc is stale.
- Fix: update the doc; delete `pending_review_checker_stub.dart` if unused.
- Status: fixed

## Checked and fine
- `AvailabilityRules`: day-level comparison, inclusive window, return-day and pickup-day edge cases covered by tests.
- Price: use case calls `PricingCalculator.quote` with the vehicle's `longRates`, same as the detail bloc; tier rules match TECHNICAL §5.1.
- Rules for `users/{uid}/favourites/{vid}` (self only), `vehicles` read (signed in, so `ownerCars` works), `calendarBlocks` read, `notifications` and `auditLogs` create (cross-user owner notification is allowed), `bookings/{id}/private/renter`.
- Email gate runs first in the use case; lock read via `renterLocks/{uid}`; pending review via the real checker.
- `SearchCubit` saves `last_search_area` and `last_type_chip` on search (home and search page); restored on start.

## Commands
- `flutter analyze`: No issues found.
- `flutter test test/features/discovery`: 38 passed, 0 failed.

## Fix log
- F3-01: renter_home_page.dart tab header shows `Saved (n)` from FavouritesBloc.
- F3-03: create_booking_request.dart rejects non-published or expired-docs cars; tests in create_booking_request_test.dart.
- F3-06: results_bloc.dart and favourites_bloc.dart use a generation counter so only the newest load emits (bloc_concurrency is not a dependency); race test in results_bloc_test.dart.
- F3-07: firestore_search_repository.dart runs per-car block and photo reads in parallel with Future.wait.
- F3-08: search_vehicles.dart drops the home chip when a type filter is set; base-price rule documented on VehicleFilters.matches; test in search_vehicles_test.dart.
- F3-09: firestore_request_repository.dart derives the VLC number from the random booking id.
- F3-10: favourites_bloc.dart prunes NotFound ids; test added.
- F3-11: availability_calendar.dart allows a return day on the day another booking starts.
- F3-13: RequestSuccess.priceChanged plus snackbar in booking_review_page.dart; tests in request_bloc_test.dart.
- F3-14 (partial): filters_page.dart disables Apply when min > max (`VehicleFilters.hasValidPriceRange`, tested).
- F3-16: docs/merging/phase-3.md corrected. `pending_review_checker_stub.dart` is in features/reviews (not owned), left in place.
