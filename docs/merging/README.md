# Merging the phase PRs

How the open phase PRs are merged into local `main`, one phase at a time, before the manual end-to-end test. The technical-docs PR (#12) is not merged here.

## Order

| Phase | PR | Branch | Status | File |
|---|---|---|---|---|
| 2 Owner: cars & availability | #9 | `1-owner-cars-availability` | merged, code gaps closed; E, F, H open | [phase-2.md](phase-2.md) |
| 3 Renter: discovery & request | #17 | `2-renter-discovery-request` | waiting | |
| 4 Booking decision & payment | #16 | `3-booking-decision-payment` | waiting | |
| 5 Handover, return & caution | #15 | `4-handover-return-caution-settlement` | waiting (draft) | |
| 6 Reviews, notifications & finances | #13 | `5-reviews-notifications-finances` | waiting | |

## Process for each phase

1. **Merge plan.** Keep it simple: the PR, its branch, the conflicts expected (usually `firestore.rules`, `firestore.indexes.json`, `docs/resources/TODO.md`, injection or route files), and the check to run after the merge.
2. **Merge** the branch into local `main` with a merge commit (no push).
3. **Verify:** `flutter analyze` and `flutter test`.
4. **List the open tasks.** Compare the phase's `docs/resources/TODO.md` section and `docs/tasks/phase-N-*.md` acceptance criteria with the code. Record what is missing in the phase file.
5. **Checklist.** Turn the gaps into a checklist in the phase file, grouped so independent groups can run in parallel.
6. **Implement the gaps** following `docs/WORKING.md`: ask before launching subagents, shared files (`pubspec.yaml`, `firestore.rules`, route and injection files, `TODO.md`) are edited by the main session only.
7. **Close the phase:** tick the boxes here and in `TODO.md`, then start the next phase.

After all phases: manual end-to-end test, then fix the bugs it finds.

## Rules

- Commits follow `CLAUDE.md` (granular, no co-author, show the list and wait for confirmation).
- Nothing is pushed unless asked.
- Do not start a phase before the previous one has no open gaps.
