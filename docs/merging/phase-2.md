# Phase 2: Owner, cars & availability

PR #9 `1-owner-cars-availability` (56 commits ahead of `main`).

## Merge plan

- [x] Fetch `origin`, check for conflicts (none, `git merge-tree` was clean)
- [x] Merge with a merge commit into local `main` (`ef5fd02`)
- [x] `flutter analyze`: no issues
- [x] `flutter test`: 395 passed

## Gaps (compared with `docs/tasks/phase-2-owner-cars.md`)

`TODO.md` only has 2 of Phase 2's boxes ticked, but the code covers more. Status from reading the code:

**Done in the PR (tick in `TODO.md` after a manual check)**
- Wizard (7 steps, bloc, per-step validation, publish in one batch), My cars list, car-published page, `CarCountCard`
- Plate, year, price rules and tier validation via `PricingCalculator.validateLongRates`; tier example and 3-day preview in the pricing step
- `PublishVehicle`, `RemoveVehicle` (blocked by open bookings), `SetStatus`, `VerifyDocument`; `docsValidUntil` computed on publish
- `vehicles` rules block and 3 `vehicles` indexes

**Closed in this session** (analyze clean, 447 tests pass)
- [x] A. Edit mode: `UpdateVehicle`, `LoadVehicleDraft`, wizard edit mode, edit route wired (documents step skipped when editing)
- [x] B. Availability: `SetAvailability`, `WatchAvailability`, rules, `AvailabilityBloc`, page, route wired (booked days come from open bookings; calendar blocks are not read)
- [x] C. Documents: `UpsertDocument`, `RecomputeDocsValidUntil`, `DocumentsBloc`, page with paused-by-expiry banner, route wired
- [x] D. My cars card: next-rental line (`FindNextRentals`); the Availability action already existed
- [x] G. Tests: widget tests for the wizard and the availability and documents pages, bloc and unit tests for the new code

**Still open**
- [ ] E. Photo reordering is not built; a failed upload shows an error and can be retried in edit mode (not tried on a device)
- [ ] F. Rules: the `vehicles` block exists, but there is no rules test setup, so "another user cannot read or edit a car's documents" has not been checked. Do it in the manual test with `owner2` on `car-1`. Indexes: the owner queries only filter on `ownerId`, covered by the existing indexes
- [ ] H. Report sections and demo segment B (not written)
- [ ] `/owner/cars/:id` is still a placeholder page (it links to edit, availability and documents)
- [ ] Manual check of the seed scenarios in `docs/tasks/phase-2-owner-cars.md` (no scenario was run against the seed data)

## Parallel plan (used)

- Sequential first (shared files): repository interface additions (`update`, `setAvailability`, `upsertDocument`) and injection and routes.
- Then independent: **A** edit mode, **B** availability, **C** documents each own their pages, bloc and tests. **D**, **E** touch the card, the media step and the wizard, so they run after A.
- **F**, **G**, **H** run last.
