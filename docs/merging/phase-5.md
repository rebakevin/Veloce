# Phase 5: Handover, return & caution settlement

PR #15 `4-handover-return-caution-settlement` (draft, 6 commits ahead of the Phase 4 merge).

## Merge plan

- [x] Merge PR #16 on GitHub, `git pull origin main` locally
- [x] Merge `main` into the branch. Two conflicts:
  - `firestore.rules`: Phase 5 had rewritten the whole file with looser Phase 4 rules. Kept main's Phase 4 rules and added Phase 5's rows: pickup, return, review and settlement transitions, the ledger types `release`, `platform_fee`, `payout`, `claim_deduction`, `late_fee` and the caution `refund`, plus Phase 5's stricter `cautionClaims` and `repairExpenses` blocks. The Phase 5 rows do not require `serverUpdated()`, because its repository writes `updatedAt` with client time
  - `test/support/router_test_scope.dart`: kept both phases' mocks and registrations, merged the two `bookingLookup` mocks and kept one `AuthSession` registration
- [x] `flutter analyze` on the merged branch: 17 infos, all in Phase 5's own files
- [ ] `flutter test`: the architecture tests fail on Phase 5's code (see gaps A)
- [ ] Push the branch after the gaps are closed, then merge PR #15 on GitHub

## What exists

All five screens and routes (pickup, return, settle, claim, repair cost), `HandoverSection`, `ChecklistCubit`, `CautionClaimCubit`, `LateFeeCalculator`, and one `FirestoreHandoverRepository` (confirm pickup with the release batch, start and confirm return, no-issue, claim, respond, revise, refund, completion with `completedCount`) and `FirestoreRepairExpenseRepository`. Tests exist for the late-fee table, the claim calculation, the claim model and `ChecklistCubit`. No `TODO.md` box is ticked yet.

## Gaps

- [ ] **A. Architecture and lint (fails the build)**
  - `setState` in `caution_settlement_page.dart` and `repair_expense_page.dart` (move to cubits)
  - `caution_claim_page.dart` imports `cloud_firestore` from presentation
  - 17 analyzer infos (`prefer_initializing_formals`, directive order) in `firestore_handover_repository.dart`, `firestore_repair_expense_repository.dart`, `checklist_cubit.dart`, `caution_claim_cubit.dart`
- [ ] **B. Pure domain logic and its tests.** Release amounts, the held-balance invariant, and the re-claim ceiling live inside the 1,671-line repository. Extract them as pure services and unit-test them (late-fee table and cap already tested)
- [ ] **C. Bloc and widget tests.** Pickup with one side only versus both, claim agree / dispute / re-claim, and the widget test that confirm stays disabled until one photo is attached. Settlement and repair-cost cubits (from A) need tests too
- [ ] **D. Rules tests** in `tool/rules-test` for the Phase 5 rows I merged (both-confirmation pickup, ledger amounts, claim ≤ caution, append-only ledger). They cannot be run without the emulator
- [ ] **E. Docs.** Report sections (escrow and ledger worked example, claim flow, late-fee formula), tick `TODO.md`, demo segment E
- [ ] **Decision, not a gap yet:** the task wording asks for `HandoverRepository`, `ClaimRepository`, `RepairExpenseRepository`, use cases `ConfirmPickup`, `SettleCaution` and so on, and `PickupBloc`, `ReturnBloc`, `ClaimBloc`. The branch uses one repository and two cubits. Extracting use cases is a large refactor, so it is left open until you decide

## Parallel plan (ask before launching)

- **Agent 1, presentation (A, C):** the two pages with `setState`, the `cloud_firestore` import, new cubits, the lints in `checklist_cubit.dart` and `caution_claim_cubit.dart`, bloc and widget tests
- **Agent 2, domain (B):** new pure services under `domain/services/` with unit tests, and the lint cleanup in the two data files while it wires the repository to use them
- **Agent 3, rules and docs (D, E):** rules tests, the Phase 5 report draft. `TODO.md` stays with the main session
- Shared files stay with the main session: injection, routes, `firestore.rules`, `TODO.md`
