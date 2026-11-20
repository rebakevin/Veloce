# Phase 4: Booking decision & payment

PR #16 `3-booking-decision-payment` (45 commits ahead of the Phase 3 merge).

## Merge plan

- [x] Merge PR #17 on GitHub, `git pull origin main` locally
- [x] Merge `main` into the branch. Two conflicts, both in shared test files:
  - `test/support/router_test_scope.dart`: kept both phases' mocks, imports and registrations
  - `test/app/router/app_router_test.dart`: kept Phase 4's `greaterThan(0)` floor (it replaces the `greaterThan(35)` I set in Phase 3)
- [x] `test/features/vehicles/domain/builders.dart`: dropped the `sendOtp` and `confirmOtp` overrides, because Phase 4 removed the OTP simulation from `VerificationProvider`
- [x] `flutter analyze`: no issues
- [x] `flutter test`: 530 passed
- [ ] Push the branch, then merge PR #16 on GitHub

## Gaps (compared with `docs/tasks/phase-4-booking-payment.md`)

The code covers every feature in the task: approve, decline, cancel, lazy expiry, pay, agreement, the activity, detail, decision, payment and agreement pages, the `PendingRequestsCard` and `UpcomingRentalsCard` slots on the owner home, and the rules. 15 of 17 `TODO.md` boxes are ticked and `docs/report/phase-4-draft.md` exists.

**Still open (none is code)**
- [ ] Demonstrate that contact documents are unreadable before payment and readable after (rules tests are in `tool/rules-test`, not run on the emulator)
- [ ] Demo segment D, including rotating the phone once (the no-overflow-on-rotation criterion is a manual check)
- [ ] Figma-versus-app screenshots
- [ ] Manual check of the Phase 4 seed scenarios

No gaps to implement before moving on, so no subagents are needed for this phase.
