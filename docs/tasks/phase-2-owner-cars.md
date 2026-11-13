# Phase 2 — Owner: cars & availability

|                    |                                                      |
|--------------------|------------------------------------------------------|
| **Label**          | `phase-2`                                            |
| **Assignee**       | _one person_                                         |
| **Branch** | `1-owner-cars-availability` (already created from the issue; use it, do not create another) |
| **Feature folder** | `lib/features/vehicles/`                             |
| **Spec**           | `SPECS.md` §6.2–6.4 · `TECHNICAL.md` §4.2, §4.4, §10 |
| **Depends on**     | Nothing. Needs only Phase 0 (done) and the seed data |

---

## Goal

Let a car owner publish and manage cars: list a car through a 7-step wizard, upload photos and
documents, set pricing and availability, and manage the "My cars" list. When this is done, an owner
can take a car from nothing to a published listing that renters can find, and keep it up to date.

## Features to implement

1. **Vehicle repository and use cases:** create, update, delete and watch own cars, photos,
   documents, availability, pause/resume.
2. **Listing wizard (7 steps)** at `/owner/cars/new` and `/owner/cars/:id/edit`, draft kept in
   `CarWizardBloc`:
    1. Media (3–6 photos, primary photo, optional video)
    2. Vehicle details
    3. Specifications
    4. Pricing, long-rental tiers and live preview
    5. Rental rules (+ optional PDF)
    6. Documents (photo, number, expiry, simulated verification; yellow paper skippable)
    7. Review and publish
3. **My cars list** (`/owner/cars`): photo, plate, price, status, availability line, next rental;
   actions edit / availability / pause-resume / remove (confirmation dialog).
4. **Availability screen**: one date range only; booked days locked.
5. **Documents screen**: add the yellow paper later, replace expired documents, "paused by expiry"
   banner.
6. **Car-published confirmation** page (`/owner/cars/:id/published`).
7. **`CarCountCard` slot** on the owner home page.
8. **Business rules** (pure and unit-tested): plate, year, price, caution, long-rental tiers, tier
   examples and 3-day preview, documents rule, `docsValidUntil`.
9. **Firestore rules and indexes** for `vehicles`.

## Acceptance criteria

**Behaviour**

- [ ] An owner can create a car through all 7 steps and it appears in "My cars" with status
  published.
- [ ] Next is blocked on each step until that step is valid; inline error messages show on every
  invalid field.
- [ ] Plate must match `RAB 123 A`; year 2005–2026; daily price ≥ 5,000; caution ≥ 0.
- [ ] At most 3 long-rental tiers; each from ≥ 2 days; prices strictly decreasing; each ≥ 5,000.
- [ ] Each tier shows its example text ("5 days: 5 × 75,000 = 375,000") and a 3-day preview shows
  what the renter pays and what the owner receives (fee − 2,000), computed with `PricingCalculator`.
- [ ] Insurance and medical documents are required; the yellow paper is optional and shows "Not
  added" on the review step when skipped; document plate must match; expiry must be in the future.
- [ ] `docsValidUntil` is recomputed after any document change as the earlier of insurance and
  medical expiry; an expired document pauses the car and shows the banner.
- [ ] Removing a car is blocked while it has open bookings, with a clear message.
- [ ] Availability allows one date range; days with bookings cannot be removed.
- [ ] Pause/resume changes the car's status and the list updates live.
- [ ] Photos upload through `MediaStorage`; failed uploads show an error and can be retried.
- [ ] Update the price in edit mode and the change is visible in My cars.

**Security and data**

- [ ] `vehicles` rules: only the owner can create, update or delete; vehicle documents are
  owner-only (read and write).
- [ ] Verified with a second account that another user cannot edit a car or read its documents.
- [ ] Indexes from `TECHNICAL.md` §4.4 for your queries added to `firestore.indexes.json`.
- [ ] Only `vehicles`, `vehicles/*/photos` and `vehicles/*/documents` are written.

**Quality**

- [ ] Unit: plate, tiers, documents rule, `docsValidUntil`, remove-blocked rule.
- [ ] Bloc: `CarWizardBloc` (step validation, publish success and failure), `MyCarsBloc`.
- [ ] Widget: a wizard step shows errors and blocks Next.
- [ ] `dart format`, `flutter analyze`, `flutter test` all clean; no `setState`.
- [ ] Figma-vs-app screenshots in the PR.

**Docs and demo**

- [ ] Report sections: vehicle data model, listing wizard, document rule.
- [ ] Demo segment B (~2 min) with Firebase Console open: **create** a car, **read** it in My cars,
  **update** the price, **delete** the car.

## Technical description

### Already in place (do not rebuild)

**Domain & data (`lib/core`)**

- Entities: `Vehicle`, `VehiclePhoto`, `VehicleDocument`, `LongRate`, `DocumentPhoto`.
- Models with `fromMap`/`toMap`: `VehicleModel`, `VehiclePhotoModel`, `VehicleDocumentModel`,
  `LongRateModel`.
- Enums: `VehicleStatus`, `VehicleType`, `FuelType`, `Transmission`, `DocumentKind`, `MediaType`,
  `StorageBucket`.
- Constants: `FirestorePaths`, `FirestoreFields`, `AppConstants` (platform fee 2,000, max long
  rates, min long-rate days).
- `VehicleLookup`: cached read-by-id/stream (use it for reads; write through your own repository).
- `Result`, `AppFailure`, `Clock`.

**Business rules**

- `Validators`: plate, year, price (reuse; add only what is missing).
- `PricingCalculator`: `quote`, `dailyRateFor`, `validateLongRates` (the tier rules already exist
  here; the wizard calls them).
- `Formatters`: RWF, dates.

**Services**

- `MediaStorage` (`SupabaseMediaStorage`): upload and best-effort delete; compression happens at
  pick time. Buckets `car-media` (photos/video) and `user-docs` (documents).
- `VerificationProvider` (`VerificationSim`): `verifyDocument` for the document step.
- `AuditLogger`, `AuthSession` (`currentUserId`, `role`).

**Screens and routing**

- Placeholder routes for every page, in `vehicles_routes.dart`: `/owner/cars`, `/owner/cars/new`,
  `/owner/cars/:id`, `/owner/cars/:id/published`, `/owner/cars/:id/requests`,
  `/owner/cars/:id/edit`, `/owner/cars/:id/availability`, `/owner/cars/:id/documents` (
  `RouteNames`).
- `CarCountCard` placeholder slot (`features/vehicles/presentation/widgets/car_count_card.dart`)
  used by `OwnerHomePage`.
- Shared widget kit: `PhotoPicker`, `ImagePickerTile`, `DocumentPhotoField`, `DatePickerField`,
  `DateRangeField`, `AppTextField`, `PriceBreakdown`, `StatusChip`, `EmptyState`, `ErrorView`,
  `LoadingView`, `PrimaryButton`, `SectionHeader`, `AppMessenger`.
- `vehicles_injection.dart` and `vehicles.dart` barrel exist and are empty.

**Data**

- Seed: 8 cars (owner1: cars 1–3, owner2: 4–6, owner3: 7–8, car 8 paused) with 3 photos each,
  insurance + medical documents (yellow paper on every other car) and an availability window. Sign
  in as `owner1@veloce.test` via `/dev-login` (password `Veloce#2026`).
- `firestore.rules` has a labelled `vehicles` block skeleton.

### Dummy data for this task

The extra data for this phase lives in `tool/seed/scenarios/phase-2.js` (every id starts with
`p2-`) and is loaded together with the base seed. Merge the latest `main` into your branch first,
then:

```bash
cd tool/seed && npm install && GOOGLE_APPLICATION_CREDENTIALS=/path/to/veloce-service-account.json npm run seed
```

The key comes from the Firebase console (see `tool/seed/README.md`). The seed is safe to repeat.
Sign in through `/dev-login` (password `Veloce#2026`) as `owner1@veloce.test` for almost
everything, and as `owner4@veloce.test` for the empty state.

| Scenario | Account | Car / booking id | What to test |
|---|---|---|---|
| New owner, zero cars | `owner4@veloce.test` | none | Empty "My cars" state, then list the first car through the wizard |
| Paused by expiry (insurance expired 10 days ago) | `owner1@veloce.test` | `p2-car-expired` (RAJ 909 J) | "Paused by expiry" banner, replace the insurance on the Documents screen, `docsValidUntil` recomputed, resume |
| Insurance + medical only, no yellow paper | `owner1@veloce.test` | `p2-car-noyellow` (RAK 111 K) | Review shows "Not added"; add the yellow paper later |
| Three long-rental tiers (3, 7, 14 days) | `owner1@veloce.test` | `p2-car-tiers` (RAL 222 L) | Tier examples, 3-day preview, edit tiers, tier limit (max 3), strictly decreasing prices |
| Short availability window (today-2 to today+14) | `owner1@veloce.test` | `p2-car-window` (RAM 333 M) | One date range only; availability line in the list |
| Open booking on a car (calendar block, status returning) | `owner1@veloce.test` | `booking-p2-window-returning` on `p2-car-window` | Remove is blocked with a clear message; booked days locked on the Availability screen; next rental line |
| Future booked days (confirmed, +10 to +14 days) | `owner1@veloce.test` | `booking-p2-tiers-confirmed` on `p2-car-tiers` | Booked days locked and not removable on the Availability screen; remove blocked; next rental line |
| More open bookings (base data) | `owner1@veloce.test` | `car-2` (pending), `car-1` (returning) | Remove blocked while open bookings exist |
| Paused by the owner, no expiry (base data) | `owner3@veloce.test` | `car-8` | Pause/resume and live list update |
| Car with no open bookings (base data) | `owner1@veloce.test` | `car-3` (only an expired request) | Remove succeeds with the confirmation dialog, edit price and see it in My cars |
| Another owner's car (base data) | `owner2@veloce.test` | `car-4` to `car-6` | Second-account check: cannot edit a car or read its documents |

Re-run the seed to restore any seeded car
or booking you changed while testing (`car-3` included if you delete it).

### To build in this phase

- `features/vehicles/domain`: `VehicleRepository`, use cases `PublishVehicle`, `UpdateVehicle`,
  `RemoveVehicle`, `SetAvailability`, `SetStatus`, `UpsertDocument`, `RecomputeDocsValidUntil`.
- `features/vehicles/data`: Firestore data source and repository implementation (batched writes for
  car + photos + documents).
- `features/vehicles/presentation`: `CarWizardBloc`, `MyCarsBloc`, availability and documents state,
  the pages above.
- Register everything in `vehicles_injection.dart` and replace the placeholders in
  `vehicles_routes.dart`.

### Cross-phase notes (no waiting needed)

- Renter-facing car detail is Phase 3; "View as renter" in My cars just navigates to `/car/:id`.
- The booking-side "requests for a car" page (`/owner/cars/:id/requests`) belongs to Phase 4; keep
  its placeholder.
- Phase 3 reads your `vehicles` documents; keep field names exactly as in the ERD. Changes to the
  ERD need a `contract:` PR.
