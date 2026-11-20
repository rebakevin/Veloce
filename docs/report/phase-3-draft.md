# Phase 3 draft — renter discovery and request

Raw material for the final report. Sources: `SPECS.md` §5.2–5.4,
`TECHNICAL.md` §4.5, §5.1 and §10, `lib/features/discovery`, `firestore.rules`
and `test/features/discovery`. Rewrite in the team's own words before submission.

## Search algorithm

Search is a pipeline rather than one enormous Firestore query.

1. Firestore returns published vehicles whose `docsValidUntil` is today or
   later, optionally narrowed to one neighbourhood.
2. `FirestoreSearchRepository` removes the viewer's own cars.
3. `AvailabilityRules` keeps only cars whose `availableFrom`–`availableTo`
   window contains the whole requested range.
4. The home type chip and `VehicleFilters` apply price, type, transmission and
   seats on the client. Firestore allows only one range field, so these are
   cheaper and clearer on the client.
5. For each remaining car, `calendarBlocks` is queried with
   `vehicleId == car.id && endDate > requestedStart`; the client then drops any
   block with `startDate < requestedEnd`.

Dates are compared by calendar day. A block that ends on the pickup day is
free; a block that starts on the return day is free too. Pending bookings do
not create a block, so they do not hide a car; approved, confirmed and active
bookings do.

The main indexes are:

- `vehicles(status, neighbourhood, docsValidUntil)` for a neighbourhood search;
- `vehicles(status, docsValidUntil)` for an anywhere search;
- `calendarBlocks(vehicleId, endDate)` for the overlap check;
- `vehicles(ownerId, createdAt)` for the owner-cars slot.

## Request flow

`CreateBookingRequest` checks, in order:

1. the email is verified (`EmailVerificationGate`);
2. the car exists and is not the renter's own car;
3. the pickup is not in the past and the range is inside the availability window;
4. no `calendarBlocks` overlap;
5. the renter holds no `renterLocks/{uid}` document;
6. `PendingReviewChecker` reports no unpaid review.

It then builds the quote with `PricingCalculator`: charged days, the long-rental
tier with the largest `fromDays <= days`, rental fee, platform fee, caution and
total payable. The quote is passed to the repository and never recomputed.

`FirestoreRequestRepository` writes one batch:

- `bookings/{id}` with status `pending`, reference `VLC-####`,
  `expiresAt = now + 24h`, and the locked rate and totals;
- `bookings/{id}/private/renter` with the renter's contact copy;
- an `auditLogs` entry for the new state;
- a `notifications` entry for the owner.

The contact rule uses `getAfter()` for the same batch, because a plain `get()`
cannot see a booking created in that batch. This is the main security subtlety
of the phase.

## State-management example

- `SearchCubit` owns the area, date range and home type chip, restores
  `last_search_area` and `last_type_chip`, and saves them when a search starts.
- `ResultsBloc` owns one query plus filters and emits loading, loaded, empty and
  failure states. The page never filters a list in `build`.
- `CarDetailBloc` loads one car and recomputes the quote when dates change. It
  also decides whether the viewer is the owner, which switches the page to a
  read-only preview.
- `FavouritesBloc` is the single source for hearts and the Saved tab. Toggling
  updates the ids optimistically, then the Firestore stream reconciles the full
  saved list.
- `RequestBloc` holds the terms checkbox and submit status for the review
  screen.

The home, results and car detail pages share one `SearchCubit` and one
`FavouritesBloc` through `DiscoveryScope`. That is why a heart on a result card
and the Saved count cannot disagree. No screen uses `setState`.

## Verification status

- `dart format lib test`, `flutter analyze` (no errors or warnings on the CI
  Flutter version), and the full `flutter test` suite pass locally.
- Unit and bloc tests cover availability, filters, every request failure,
  favourites, results and request state.
- Widget tests cover the shared heart/count source and the terms-gated request
  button.
- Firestore rules tests are written in `tool/rules-test`; they have not been run
  against the emulator in this session.
- Figma-versus-app screenshots and the two-minute demo segment are still to be
  captured on a device.
