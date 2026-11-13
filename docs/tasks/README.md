# Tasks

One file per phase (2–6). Each file is written to be pasted as the body of **one GitHub issue**, assigned to **one person**. Phases 0 and 1 are done and have no task file.

| File | Phase | Issue (title, no phase prefix) | Label | Branch |
| --- | --- | --- | --- | --- |
| [phase-2-owner-cars.md](phase-2-owner-cars.md) | 2 | Owner: cars & availability | `phase-2` | `1-owner-cars-availability` |
| [phase-3-renter-discovery.md](phase-3-renter-discovery.md) | 3 | Renter: discovery & request | `phase-3` | `2-renter-discovery-request` |
| [phase-4-booking-payment.md](phase-4-booking-payment.md) | 4 | Booking decision & payment | `phase-4` | `3-booking-decision-payment` |
| [phase-5-handover-caution.md](phase-5-handover-caution.md) | 5 | Handover, return & caution settlement | `phase-5` | `4-handover-return-caution-settlement` |
| [phase-6-reviews-finances.md](phase-6-reviews-finances.md) | 6 | Reviews, notifications & finances | `phase-6` | `5-reviews-notifications-finances` |

## Why the tasks are independent

- **Contract = ERD + Phase 0 code.** Entities, models, Firestore constants, core services, every route and the shared widget kit already exist. Nobody waits for another phase.
- **Write only your own collections** (listed in each task). Read everything else through the `core` lookups.
- **Realistic data from day one.** The seed script creates cars and bookings in every status; sign in with `/dev-login` (debug builds) using the seeded accounts in `tool/seed/README.md`.
- **No shared files.** Pages that several phases contribute to (`OwnerHomePage`, `BookingDetailPage`, `PublicProfilePage`) use **slots**: each phase fills its own slot widget in its own feature folder.
- **Interfaces + `mocktail`.** Where a task needs something another phase will deliver, it codes against the `core` interface and tests with a mock.
- **Shared change needed?** Open a PR titled `contract:` and get every owner to review (see `CONTRIBUTING.md`).

## Rules that apply to every task

Each task file repeats only what is specific to it. These apply to all of them:

- Read `docs/WORKING.md` and the `docs/code-conventions/` files mapped in `CLAUDE.md` before coding.
- Work on the branch GitHub created from your issue (listed in the table above; do **not** create another). Merge an up-to-date `main` into it before you start and whenever `main` gets new seed data. Open a PR, one review (ring: P1→P2→P3→P4→P5→P6→P1).
- No `setState`; `dart format lib test` and `flutter analyze` clean; `flutter test` green.
- At least 3 unit tests, 2 bloc tests and 1 widget test.
- Figma-vs-app screenshots in the PR; screens checked on small and large phones and in landscape.
- Report section and demo segment delivered (see the task's "Docs & demo" criteria).
- You own `features/<yours>/`, your `*_injection.dart`, your `*_routes.dart` and your labelled block in `firestore.rules`.

## How the issues work

Each GitHub issue holds the goal, the feature list and the acceptance criteria, and tells the developer to read the matching file here for the **technical description** (what already exists, what to build, dummy data). Branches were created from the issues; use them.

## Dummy data

Per-phase dummy data lives in `tool/seed/scenarios/phase-N.js` and is loaded by `npm run seed` (see `tool/seed/scenarios/README.md`). Each task file has a "Dummy data for this task" section with the accounts and ids to use. Reseed after testing to restore the seeded bookings.
