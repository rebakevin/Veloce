# Phase 6: Reviews, notifications & finances

PR #13 `5-reviews-notifications-finances` (1 commit, 8,000+ lines, ahead of the Phase 5 merge).

## Merge plan

- [x] Merge PR #15 on GitHub, `git pull origin main` locally
- [x] Merge `main` into the branch. One conflict, `lib/app/app.dart`: kept both the `NotificationsBloc` provider and the booking `ExpirySweeperCubit` provider and observer
- [x] `flutter test`: 677 passed before the gap work, 699 after
- [x] `flutter analyze`: was 60 infos in Phase 6's own files; fixed (49 by `dart fix`, the rest by hand), now clean
- [ ] Push the branch, then merge PR #13 on GitHub

## What exists

Reviews (repository with create and edit, the real `FirestorePendingReviewChecker` replacing the stub, four pages, `PostRentalSection`, `ReviewsPreviewSection`), notifications (bloc, page, bottom-nav badge in `role_shell.dart`), finances (repository, owner finances page with chart and table, per-car and transactions pages, `FinancesCard`, renter payments page). 16 test files cover the domain rules, the blocs and cubits, and the pages.

## Gaps

- [x] **Rating aggregates were denied by the rules.** `FirestoreReviewRepository` writes `ratingAvg` and `ratingCount` on the reviewed user or car in the same batch as the review, but the `users` and `vehicles` rules let only the document's owner update it, so a review would fail on a real project. Phase 6 had not changed `firestore.rules`. Fixed: a non-owner may change only `ratingAvg` and `ratingCount`, the count moving by 0 or 1 and the average staying in 1..5. A rule cannot derive the review id from the subject document, so this bounds the change but cannot prove a review was written in the same batch. A Cloud Function would be needed for that
- [x] **Indexes:** the review queries by `subjectType` + `subjectId` and by `authorId`, both ordered by `createdAt`, had no composite index. Two added to `firestore.indexes.json`
- [x] **Lint:** the 60 infos fixed
- [x] **Rules tests:** 35 new cases in `tool/rules-test` (reviews, the aggregate rule for users and cars, review batches, notifications, unauthenticated access); 86 passing on the emulator
- [x] **Pending-review detection:** extracted `PendingReviewRule` (pure) and unit-tested it (11 tests); `FirestorePendingReviewChecker` uses it with the same result
- [x] **Widget test:** the finances table shows 5 rows and the "View all" link only above 5 (5 tests). "Table total equals tiles" is not widget-testable because the table renders no total; both come from one list
- [x] **Docs:** `docs/report/phase-6-draft.md`, `TODO.md` ticked
- [x] **Found while testing, fixed:**
  - the `vehicles` owner rule let an owner set their own car's `ratingAvg` and `ratingCount`; it now forbids it (the `users` rule already did)
  - the owner finances offset the claim deduction once per repair, so a booking with two repairs offset it twice; `RepairLossAllocator` now spends one deduction budget per booking, oldest repair first. The earlier "calculation" tests re-implemented the arithmetic inline and tested no production code; the loss one was removed and replaced by real tests (the other two inline tests remain and also test nothing real)
- [ ] Demo segment F

## Still open (none is code)
- [ ] Figma screenshots, manual check of the Phase 6 seed scenarios
- [ ] The review create rule does not require a completed booking between the author and the subject. It is not in the task, so it is left as is

## Parallel plan (used)

- **Agent 1:** the pending-review detection extraction and unit test, and the finances table widget test (files under `lib/features/reviews/data`, `lib/features/reviews/domain`, `test/features/reviews`, `test/features/finances`)
- **Agent 2:** the rules tests (`tool/rules-test`) and the Phase 6 report draft
- Shared files stay with the main session: `firestore.rules`, `firestore.indexes.json`, injection, `TODO.md`
