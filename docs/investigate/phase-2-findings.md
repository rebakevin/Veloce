# Phase 2 findings: owner cars & availability

Audited: `lib/features/vehicles`, `test/features/vehicles`, the `vehicles` block of `firestore.rules`, `firestore.indexes.json`, against `docs/resources/TODO.md` (Phase 2), `docs/tasks/phase-2-owner-cars.md`, `docs/merging/phase-2.md`, SPECS §6.2-6.4 and the code conventions.

`flutter analyze`: no issues. `flutter test test/features/vehicles`: 119 passed, 0 failed.

## Verdict

The domain layer (validators, tier rules, wizard step rules, documents rule, `docsValidUntil`, removal rule, use cases) is solid and well tested, and the wizard, edit mode, availability and documents screens are wired end to end in the client. The weak points are at the Firestore boundary and in spec behaviour that the client alone cannot deliver. Three defects would break real use: (1) `bookingsOf` queries `bookings` by `vehicleId` only, which the `bookings` read rule (`isParty(resource.data)`) cannot satisfy for a list query, so Remove, Availability save/overview and the "next rental" line are likely to fail with permission-denied; (2) the Remove batch deletes `photos` and `documents` whose rules use `getAfter(vehicle).data.ownerId` while the vehicle is deleted in the same batch, so the rule errors and the delete is likely refused; (3) a newly published car has no availability range, so it is invisible to search while the "Your car is live" page says renters can find it. Also missing: automatic pause on document expiry (spec 6.2), optional video and rules PDF (steps 1 and 5), photo reorder (known), My cars photo, and any in-app link to the Documents screen. Both Firestore findings need confirmation on the emulator.

## TODO task table

| Task | Result | Notes |
|---|---|---|
| 2.A `VehicleRepository` | bug | Works for own-car reads; `bookingsOf` query likely denied by rules (F2-01); `remove` likely denied (F2-02) |
| 2.A Use cases Publish/Update/Remove/SetAvailability/SetStatus/UpsertDocument | bug | Logic correct; Remove and SetAvailability depend on F2-01; video/PDF never set (F2-05); plate edit not re-checked against documents (F2-09) |
| 2.A `RecomputeDocsValidUntil` | ok | Min of insurance and medical, null if either missing; called after every upsert |
| 2.A Photo upload/reorder/delete | gap | Upload and delete work (kept in edit, old files cleaned after save). Reorder not built (F2-06) |
| 2.B Plate / year / price / caution | ok | Validators and tests fine (plate normalised to upper case) |
| 2.B Tier validator | ok | Uses `PricingCalculator.validateLongRates` (max 3, >=2 days, strictly decreasing, >=5,000) |
| 2.B Tier example + 3-day preview | ok (test-gap) | Implemented in `PricingStep`; no widget or unit test on the text (F2-14) |
| 2.B Documents rule | ok | Required kinds, optional yellow paper, plate match, future expiry |
| 2.C Wizard shell | ok | Progress bar, back/next, per-step validation, edit mode skips documents |
| 2.C Step 1 media | gap | 3-6 photos and primary work; optional video missing (F2-05); no reorder (F2-06) |
| 2.C Steps 2, 3 | ok | |
| 2.C Step 4 pricing | ok | |
| 2.C Step 5 rules | gap | Optional rules PDF and `extras` have no UI (F2-05) |
| 2.C Step 6 documents | ok | |
| 2.C Step 7 review | ok (nit) | Yellow paper "Not added" shown; video/PDF not summarised (follows F2-05) |
| 2.C My cars list | gap | No photo (F2-07); no link to Documents (F2-08); next rental depends on F2-01 |
| 2.C Availability screen | bug | One range and locked days implemented; depends on F2-01; new cars have no range (F2-03) |
| 2.C Documents screen | gap | Works, but only reachable via the placeholder car page (F2-08); passive expiry not shown as paused (F2-04) |
| 2.C `CarCountCard` | ok | Counts published and paused |
| 2.D `vehicles` block + indexes | gap | Owner-only writes present; create does not constrain rating/status (F2-10); remove likely denied (F2-02); no booking check on delete (F2-11) |
| 2.D Other user cannot read/edit documents | needs-human | By reading the rule it holds (F2-12) |
| 2.E Unit tests | ok | Plate, tiers, documents, `docsValidUntil`, remove rule covered |
| 2.E Bloc tests | ok | `CarWizardBloc` (also edit mode), `MyCarsBloc`, `AvailabilityBloc`, `DocumentsBloc`, `CarCountCubit` |
| 2.E Widget test | ok | Wizard step error blocks Next (photos step only) |
| 2.F Report / demo | gap | Unticked, expected; demo needs a person (F2-13) |

## Findings

### F2-01 [severity: major] [kind: bug]
- Where: `lib/features/vehicles/data/firestore_vehicle_repository.dart` `bookingsOf` (line ~52); `firestore.rules` `match /bookings/{id}` read rule.
- What: `bookingsOf` runs `bookings.where('vehicleId' == id)`. The read rule is `isParty(resource.data)` (renterId or ownerId equals the user). Firestore only allows a query if the rule holds for every possible result, and a filter on `vehicleId` alone does not prove the caller is a party. The query is expected to fail with permission-denied. `RemoveVehicle`, `SetAvailability`, `WatchAvailability` (the whole availability page shows an error) and `FindNextRentals` (swallows the failure, so "No upcoming rental" always) all depend on it.
- Evidence: code reading of both files. The unit tests use a fake repository, so nothing exercises the real query against rules.
- Fix: add `.where('ownerId', isEqualTo: <current uid>)` to the query (the repository needs the owner id, or the use cases pass it), and re-test on the emulator.
- Status: fixed (repository now filters by vehicleId and ownerId; confirm on emulator; no composite index needed, two equality filters use merged single-field indexes)

### F2-02 [severity: major] [kind: bug]
- Where: `firestore.rules` `vehicles/{vid}/photos` and `documents/{kind}` write rules; `FirestoreVehicleRepository.remove`.
- What: `remove` deletes every photo and document and the vehicle in one batch. The subcollection rules use `getAfter(vehicles/vid).data.ownerId == me()`. After the batch the vehicle no longer exists, so `.data` errors and the rule denies. The batch is atomic, so the whole removal is expected to fail.
- Evidence: rule text plus batch construction in `remove`. Not run against the emulator.
- Fix: use `get(...)` (current state) for delete in those subcollections, e.g. `allow delete: if get(vehicle).data.ownerId == me()`, and keep `getAfter` for create/update. Add an emulator rules test.
- Status: open (rules, main session)

### F2-03 [severity: major] [kind: spec-drift]
- Where: `publish_vehicle.dart` (`availableFrom: null, availableTo: null`); `lib/features/discovery/domain/services/availability_rules.dart` `isWithinWindow` (null means false); `car_published_page.dart`.
- What: a new car is published with no availability range, and search treats no range as not bookable. The success page says "Renters can find it now" and does not send the owner to Availability. Until the owner finds the Availability action in My cars, the car never appears in results.
- Evidence: code reading of the three files.
- Fix: ask for the range in the wizard (or at least add a "Set availability" button on the published page and an availability hint on the card), and reword the success text.
- Status: fixed (published page says dates are needed and offers Set availability; card says "No dates set: hidden from search")

### F2-04 [severity: major] [kind: gap]
- Where: `document_status_rules.dart`, `documents_state.dart` (`pausedByExpiry`, `canResume`), `my_cars_bloc.dart`, `vehicle_card.dart`.
- What: SPECS 6.2 says a car with expired insurance or medical certificate is paused automatically. The only pausing happens inside `UpsertDocument`. Nothing pauses a car when an expiry date passes. Search hides it (it filters `docsValidUntil >= today`), but the car keeps `status = published`, My cars shows "Published", and the Documents page banner needs `status == paused && expired.isNotEmpty`, so no banner and no Resume appear for the passive case. The owner gets no explanation why the car is hidden. TECHNICAL assigns scheduled work to Cloud Functions; none exists for this.
- Evidence: code reading; the documents page test only covers a car already stored as paused.
- Fix: derive "expired" from `docsValidUntil` in the UI (show the banner and a "Paused by expiry" chip when status is published but docs are expired), and/or lazily write `paused` when My cars or Documents loads; ideally a scheduled function.
- Status: fixed (My cars and Documents pause a published car whose papers lapsed; card shows "Paused: documents expired" and Fix documents; a scheduled function is still the ideal)

### F2-05 [severity: minor] [kind: gap]
- Where: `media_step.dart`, `rules_step.dart`, `publish_vehicle.dart` (lines 104-105), `wizard_draft.dart` (`video`, `rulesPdf`, `extras`).
- What: the draft has `video`, `rulesPdf` and `extras`, but no step lets the owner set them, and `PublishVehicle` hard-codes `rulesFileUrl: null` and `videoUrl: null`. Discovery already renders both (`car_media_page.dart`, `car_detail_page.dart`, `booking_review_page.dart`) so those paths are dead. SPECS 6.2 lists optional video, optional rules PDF and extras. The TODO box ticks steps 1 and 5 as done.
- Evidence: grep of `rulesPdf|video|rulesFileUrl|videoUrl|extras` across `lib`.
- Fix: add the pickers (video and PDF) and an extras field, upload on publish/update, or untick and document the cut.
- Status: fixed in part (extras field and optional video added and uploaded; rules PDF still open, needs a file picker package in pubspec, main session)

### F2-06 [severity: minor] [kind: gap]
- Where: `media_step.dart`, `update_vehicle.dart`.
- What: photo reordering is not built (known gap, TODO box rightly unticked). Order is append order; only the main photo can be changed.
- Evidence: `MediaStep` has tap-to-set-main and remove only.
- Fix: `ReorderableListView` or move left/right buttons that reorder across `keptPhotos` + `photos` and keep `primaryIndex` aligned; add a bloc/unit test.
- Status: fixed (arrows reorder photos; a newly picked photo cannot move in front of kept photos in edit mode)

### F2-07 [severity: minor] [kind: gap]
- Where: `vehicle_card.dart`.
- What: TODO and SPECS 6.4 list a photo on the My cars card; the card shows text only (plate, name, price, status, dates, next rental). The card also has no indicator for documents that are expired or expiring.
- Evidence: widget tree has no image.
- Fix: load the primary photo (store `primaryPhotoUrl` on the vehicle or read the first photo) and show it.
- Status: fixed (primary photo on the card via FindPrimaryPhotos; expired indicator added)

### F2-08 [severity: major] [kind: gap]
- Where: `vehicles_routes.dart` (`/owner/cars/:id` still a `PlaceholderPage`), `vehicle_card.dart`.
- What: the Documents screen (add yellow paper, replace expired papers, resume) has no entry point except a link on the placeholder page reached by tapping the card. The card actions are Edit, Availability, Pause/Resume, Remove. For an expired car the owner has no direct path to the fix. Known open item in `docs/merging/phase-2.md`.
- Evidence: grep shows `ownerCarDocuments` used only in `vehicles_routes.dart`.
- Fix: add a Documents action to the card (with an alert when expired) and replace the placeholder car page or point `onOpen` at documents.
- Status: fixed (Documents / Fix documents action on the My cars card)

### F2-09 [severity: minor] [kind: bug]
- Where: `update_vehicle.dart`, `upsert_document.dart`.
- What: in edit mode the plate can be changed, but existing documents keep the old plate and are not re-checked. The spec rule "the plate on every document must match the listing" is then broken silently. `UpsertDocument` only compares the plate typed at upload time.
- Evidence: `UpdateVehicle` validates up to the pricing/rules steps only and never reads documents.
- Fix: lock the plate field in edit mode, or flag documents as needing re-verification when the plate changes.
- Status: fixed (plate field locked in edit mode)

### F2-10 [severity: minor] [kind: bug]
- Where: `firestore.rules` `vehicles` create.
- What: create only checks `ownerId == me()`. A client can create a car with `ratingAvg`/`ratingCount` set, `status: published` without documents, a price below 5,000, or `docsValidUntil` in the future with no documents. Updates also let the owner set `status` and `docsValidUntil` freely, so the expiry rule is client-side only.
- Evidence: rule text.
- Fix: on create require `ratingCount == 0 && ratingAvg == 0`; consider validating price and plate shape, and forbidding the owner from raising `docsValidUntil` (or enforce through a function).
- Status: open (rules, main session)

### F2-11 [severity: minor] [kind: gap]
- Where: `firestore.rules` `vehicles` delete; `remove_vehicle.dart`.
- What: the "no removal with open bookings" rule exists only in the client (read bookings, then delete, not transactional). A booking created between the check and the delete, or a direct write, bypasses it. Rules do not look at bookings.
- Evidence: rule `allow delete: if signedIn() && resource.data.ownerId == me()`.
- Fix: acceptable for a student project if documented; otherwise enforce via function or rules.
- Status: open (rules, main session)

### F2-12 [severity: minor] [kind: needs-human]
- Where: `firestore.rules` `documents/{kind}`.
- What: by reading, `read, write` is owner-only (via `getAfter` on the vehicle; for reads it equals the current vehicle). Other users and renters cannot read documents. The TODO line "verify another user cannot edit or read vehicle documents" has not been run; there is no rules test setup.
- Evidence: rule text only.
- Fix: run with the emulator (or the seed users `owner2` on `car-1`), then tick the box.
- Status: needs-human

### F2-13 [severity: nit] [kind: needs-human]
- Where: TODO 2.F; `docs/tasks/phase-2-owner-cars.md` seed scenarios.
- What: report sections, demo segment B and the seed scenarios have not been run on a device. Also needing a device: image/video picking, upload failure retry in edit mode, wizard keyboard and layout at phone width.
- Status: needs-human

### F2-14 [severity: minor] [kind: test-gap]
- Where: `test/features/vehicles`.
- What: no test for the tier example text ("5 days: 5 × 75,000 = 375,000"), the 3-day preview in `PricingStep`, `DocumentStatusRules` directly, `FindNextRentals`, `VehicleCard`/`MyCarsPage` (remove confirmation dialog, pause/resume), `MediaStep` (primary index after removal), or the Firestore repository against the emulator. The wizard widget test covers only the photos step.
- Evidence: grep of `test` for those symbols.
- Fix: add widget tests for `PricingStep` and `MyCarsPage`, a unit test for `DocumentStatusRules`, and emulator tests for the repository and rules once F2-01/F2-02 are fixed.
- Status: fixed (tests for DocumentStatusRules, FindNextRentals, FindPrimaryPhotos, VehicleCard, PricingStep, MyCarsBloc, DocumentsBloc lapse, draft reorder, video; emulator tests for repository remain open)

### F2-15 [severity: nit] [kind: bug]
- Where: `wizard_step_rules.dart` (`DateTime.now()` in `_documents`), `document_rules.dart` (`expiry` uses `isAfter(now)`), `firestore_search_repository.dart` (compares by day).
- What: the wizard uses the system clock instead of the injected `Clock`, and the same expiry is "expired" in the owner rules the moment it passes midnight on the expiry day while search accepts documents through the expiry day. Minor edge inconsistency.
- Fix: inject the clock; compare by calendar day in one place.
- Status: fixed (wizard rules take the injected Clock; expiry compared by calendar day in DocumentRules.isValidOn)

### F2-16 [severity: nit] [kind: bug]
- Where: `my_cars_bloc.dart` `_toState`.
- What: next rentals are fetched once per vehicle snapshot (one query per car, sequential); they are not refreshed when bookings change, so the line goes stale until the car document changes. `MyCarsStatusToggled` flips any non-published status to published, including draft-like statuses.
- Fix: stream bookings, or refresh on resume; limit toggling to published/paused.
- Status: fixed (next rentals fetched in parallel, pull-to-refresh added; VehicleStatus has only published/paused so the toggle is already limited)

## Counts

blocker 0, major 5 (F2-01, F2-02, F2-03, F2-04, F2-08), minor 8 (F2-05, F2-06, F2-07, F2-09, F2-10, F2-11, F2-12, F2-14), nit 3 (F2-13, F2-15, F2-16). Needs-human: F2-12, F2-13 (and the emulator confirmation of F2-01 and F2-02).

## Fix log

- F2-01: `data/firestore_vehicle_repository.dart` (AuthSession injected, `ownerId` filter), `vehicles_injection.dart`.
- F2-03: `presentation/pages/car_published_page.dart`, `widgets/vehicle_card.dart`.
- F2-04: `domain/rules/document_status_rules.dart` (`hasLapsed`, `needsPausing`), `bloc/my_cars_bloc.dart`, `bloc/documents_bloc.dart`, `widgets/vehicle_card.dart`.
- F2-05: `widgets/video_picker.dart`, `widgets/media_step.dart`, `widgets/rules_step.dart`, `usecases/publish_vehicle.dart`, `usecases/update_vehicle.dart`.
- F2-06: `entities/wizard_draft.dart` (`canMovePhoto`, `movePhoto`), `widgets/media_step.dart`.
- F2-07/08: `usecases/find_primary_photos.dart`, `bloc/my_cars_*.dart`, `pages/my_cars_page.dart`, `widgets/vehicle_card.dart`.
- F2-09: `widgets/details_step.dart`, `widgets/draft_text_field.dart`.
- F2-15: `rules/document_rules.dart`, `rules/wizard_step_rules.dart`, `bloc/car_wizard_bloc.dart`, `usecases/set_status.dart`, `usecases/publish_vehicle.dart`.
- F2-16: `usecases/find_next_rentals.dart`, `MyCarsRefreshRequested`.
- Tests: new `document_status_rules_test`, `wizard_draft_test`, `find_next_rentals_test`, `find_primary_photos_test`, `vehicle_card_test`, `pricing_step_test`; extended my_cars/documents bloc, publish and update tests.
