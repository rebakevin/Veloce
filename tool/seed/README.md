# Seed data

Fills the shared Veloce dev project (`veloce-1fe08`) with realistic data so every
phase can build against bookings in **every status** from day one, before the
authentication phase exists. It uses the Firebase Admin SDK, so it bypasses the
security rules.

## Run

1. Firebase console → Project settings → Service accounts → **Generate new private key**.
   Save it **outside the repo** (it is git-ignored if named `*service-account*.json`).
2. From this folder:

```bash
npm install
GOOGLE_APPLICATION_CREDENTIALS=/path/to/veloce-service-account.json npm run seed
```

The script refuses to run without that variable, and refuses a key for any other
project (your gcloud default login can point somewhere else).

## Per-phase dummy data

`scenarios/phase-N.js` adds the extra cars, bookings, reviews and notifications each phase needs, on top of the base data. `npm run seed` loads all of them. Each task file in `docs/tasks/` has a "Dummy data for this task" table. Rules for the files are in `scenarios/README.md`.

Check the data without credentials (validates ids, locks, calendar overlaps and the held balance, and counts documents):

```bash
node seed.js --dry-run
node seed.js --dry-run --scenarios=phase-3   # base + one scenario file
```

Extra accounts (same password): `owner4`, `owner5`, `p6-owner`, `renter5` to `renter15`. They are not on `/dev-login`, whose list is hard-coded in Dart; use the normal login form.

## Reset

`npm run reset` deletes **every document** in the Veloce collections first, then
seeds again. Tell the team before using it: it also removes their test data.
Plain `npm run seed` only overwrites the seeded ids, so it is safe to repeat.

## Accounts

Password for all: `Veloce#2026` (also `DevAccounts.password` in the app).

| Role | Email | Name |
| --- | --- | --- |
| Renter | `renter1@veloce.test` | Aline Uwase (approved booking, 3 favourites) |
| Renter | `renter2@veloce.test` | Eric Mugisha (confirmed booking, disputed claim) |
| Renter | `renter3@veloce.test` | Diane Ingabire (active booking) |
| Renter | `renter4@veloce.test` | Samuel Nshuti (pending request) |
| Owner | `owner1@veloce.test` | Patrick Habimana (cars 1–3) |
| Owner | `owner2@veloce.test` | Grace Mukamana (cars 4–6) |
| Owner | `owner3@veloce.test` | Jean Claude Niyonzima (cars 7–8, car 8 paused) |

There are four renters, not three: a renter holds at most one lock (approved,
confirmed or active booking), so the pending request needs a renter with none.

## What it creates

- 8 cars with 3 photos, insurance and medical documents (yellow paper on every
  other car), and an availability window.
- 11 bookings: pending, approved, declined, cancelled, expired, confirmed, active,
  returning, review, completed, and a completed one with an agreed claim.
- Calendar blocks and renter locks for the approved, confirmed and active ones.
- Ledger rows that match the escrow rules; the script prints the held balance of
  every booking and aborts if one is negative.
- Pickup and return checklists, two claims (agreed and disputed), a repair
  expense larger than its deduction, reviews with matching rating aggregates,
  and notifications.

Photos are placeholder URLs from picsum.photos, not Supabase files.

## Keeping it in sync

Field names and enum keys mirror `docs/resources/TECHNICAL.md` §4.2 and
`lib/core/domain/enums`. A change to the ERD updates the constants, the models
and this script in the same `contract:` pull request.
