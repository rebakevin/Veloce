# Phase 5: Handover, return & caution settlement

PR #15 `4-handover-return-caution-settlement` (draft, 6 commits ahead of the Phase 4 merge).

## Merge plan

- [x] Merge PR #16 on GitHub, `git pull origin main` locally
- [x] Merge `main` into the branch. Two conflicts:
  - `firestore.rules`: Phase 5 had rewritten the whole file with looser Phase 4 rules. Kept main's Phase 4 rules and added Phase 5's rows: pickup, return, review and settlement transitions, the ledger types `release`, `platform_fee`, `payout`, `claim_deduction`, `late_fee` and the caution `refund`, plus Phase 5's stricter `cautionClaims` and `repairExpenses` blocks. The Phase 5 rows do not require `serverUpdated()`, because its repository writes `updatedAt` with client time
  - `test/support/router_test_scope.dart`: kept both phases' mocks and registrations, merged the two `bookingLookup` mocks and kept one `AuthSession` registration
- [x] `flutter analyze` on the merged branch: 17 infos, all in Phase 5's own files
- [x] `flutter test`: 613 passed after the gaps below were fixed; `flutter analyze` clean; rules tests 51 passed on the emulator
- [ ] Push the branch after the gaps are closed, then merge PR #15 on GitHub

## What exists

All five screens and routes (pickup, return, settle, claim, repair cost), `HandoverSection`, `ChecklistCubit`, `CautionClaimCubit`, `LateFeeCalculator`, and one `FirestoreHandoverRepository` (confirm pickup with the release batch, start and confirm return, no-issue, claim, respond, revise, refund, completion with `completedCount`) and `FirestoreRepairExpenseRepository`. Tests exist for the late-fee table, the claim calculation, the claim model and `ChecklistCubit`. No `TODO.md` box is ticked yet.

## Gaps (closed in this session)

- [x] **A. Architecture and lint:** `setState` removed from the settlement and repair-cost pages (new `SettlementCubit`, `RepairExpenseCubit`, and the checklist and claim pages are stateless), the `cloud_firestore` import left `caution_claim_page.dart` (new `HandoverRepository.watchClaim`), all analyzer infos fixed
- [x] **B. Pure domain logic:** `PickupReleaseCalculator`, `CautionSettlementCalculator`, `ClaimAmountPolicy`, `HeldBalanceGuard` with 30 unit tests, and the repository calls them. `HeldBalanceGuard` is tested but not called at runtime, because the repository never reads the ledger; the held balance stays non-negative because the settlement total equals the caution and a dispute or re-claim writes no ledger entries
- [x] **C. Tests:** checklist submit (one side and both, failures, no photo), claim cubit (load, validation, agree, dispute, re-claim, refund), settlement and repair-expense cubits, and the widget test that confirm stays disabled until a photo is attached
- [x] **D. Rules tests:** 43 new cases in `tool/rules-test`, run on the local emulator: 51 passing. The first run found three bugs in `firestore.rules`, all fixed:
  - the `bookings/{id}/{sub}` wildcard also matched `private/{side}`, so a party could read and write the other side's contact document (a Phase 4 hole already on `main`); it is now two matches by name
  - `confirmed` to `active` needed only one pickup timestamp; it now needs both
  - dispute and re-claim (`review` to `review`, `updatedAt` only) had no rule
- [x] **E. Docs:** `docs/report/phase-5-draft.md`, `TODO.md` ticked. Late-fee wording decided: the fee is the increase (30,000 / 69,000 / 119,700 on a 100,000 rental for 1 / 2 / 3 days), as the code charges

**Left out on purpose:** use-case extraction and the separate `ClaimRepository`, `PickupBloc`, `ReturnBloc`, `ClaimBloc` (the branch uses one repository and cubits).

**Still open (none is code)**
- [ ] Demo segment E
- [ ] Figma-versus-app screenshots
- [ ] Manual check of the Phase 5 seed scenarios (`booking-confirmed`, `booking-p5-active-late`, disputed and agreed claims)
- [ ] `npm test` in `tool/rules-test` needs port 8080 free (it was held by an unrelated process on this machine)
- [ ] The Phase 4 contact-exposure bug existed on `main` until this PR merges, so merge #15 before relying on contact privacy
