# Phase 3: Renter, discovery & request

PR #17 `2-renter-discovery-request` (55 commits ahead of the Phase 2 merge).

## Merge plan

- [x] Merge PR #9 on GitHub, `git pull origin main` locally
- [x] Fast-forward the stale local branch to `origin/2-renter-discovery-request`
- [x] Merge `main` into the branch (clean, no conflicts)
- [x] `flutter analyze`: no issues
- [x] `flutter test`: 485 passed. One fix was needed: the router test's placeholder-link floor (`tapped`) dropped from 41 to 40 when Phase 2 replaced placeholder pages, so it is now `greaterThan(35)`
- [ ] Push the branch, then merge PR #17 on GitHub

## Gaps (compared with `docs/tasks/phase-3-renter-discovery.md`)

The code covers every feature in the task: search with filters and the `calendarBlocks` check, results, car card with heart, car detail with the price breakdown and long-rental note, the terms checkbox, the owner's read-only preview, `FavouritesBloc` as the single source for hearts and the Saved count, the request review and confirmation pages, the `OwnerCarsSection` slot, skeletons, rules and 14 indexes. 18 `TODO.md` boxes are ticked, and `docs/report/phase-3-draft.md` has the three report sections.

**Still open (none is code)**
- [ ] `favourites` and booking-create rules: the tests are written (`tool/rules-test`) but have not been run on the emulator
- [ ] Demo segment C is not recorded
- [ ] Figma-versus-app screenshots
- [ ] Manual check of the Phase 3 seed scenarios in `docs/tasks/phase-3-renter-discovery.md`

**Known stub, belongs to Phase 6**
- `PendingReviewChecker` is `PendingReviewCheckerStub` (`features/reviews/data/`), so "renter has a pending review" never blocks a request until Phase 6 is merged.

No gaps to implement before moving on, so no subagents are needed for this phase.
