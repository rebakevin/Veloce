# Scenario files

Extra dummy data for one phase each. `seed.js` loads every `phase-N.js` in this folder (sorted) on top of the base data, so a dev only runs `npm run seed` once and finds the data their task needs.

Each file exports a plain object; every key is optional:

```js
module.exports = {
  people:   [{ uid: 'renter5', role: 'renter', name: '...', phone: '0788100005', emailVerified: false }],
  cars:     [{ id: 'p2-car-expired', ownerId: 'owner3', plate: 'RAJ 909 J', make: '...', model: '...', year: 2018,
               type: 'sedan', transmission: 'manual', fuel: 'petrol', seats: 5, dailyPrice: 50000, longRates: [],
               cautionFee: 100000, neighbourhood: 'Kimihurura', status: 'paused',
               insuranceDays: -10, medicalDays: 200, yellowPaper: false, availableFromDay: -5, availableToDay: 120 }],
  bookings: [{ key: 'p4-pending-overlap', status: 'pending', car: 'car-2', renter: 'renter6', start: 6, days: 2 }],
  reviews:  [{ id: 'booking-x_owner1_user', bookingId: 'booking-x', authorId: 'owner1', subjectType: 'user',
               subjectId: 'renter6', stars: 4, comment: '...' }],
  docs(ctx) { /* ctx.set(path, data), ctx.notify(...), ctx.day(offset), ctx.ts, ctx.photo, ctx.PEOPLE, ctx.CARS, ctx.BOOKINGS */ },
};
```

## Rules

- **Own file only.** Phase N edits `phase-N.js` and nothing else in this folder.
- **Prefix every id you add** with `pN-` (cars `p3-car-...`, booking keys `p4-...`, docs ids `p5-...`). New people use the reserved uids from `docs/tasks/`.
- **Never change base data** (`seed.js`): add, don't edit. Other phases rely on it.
- **Day offsets** are relative to today (`start: 6` = in 6 days, `-40` = 40 days ago), so the data stays realistic whenever it is seeded.
- **Booking fields:** `key`, `status`, `car`, `renter`, `start`, `days`; optional `reason`, `paidThenRefunded`, `payDeadlineHours` / `expiresInHours` (hours from seeding; negative = already past, for lazy-expiry tests), `pickupConfirmed` / `returnConfirmed` (`'owner'` | `'renter'`, one side only),  `lateDays`, `decision` (`no_issue` | `claim`), `claim`, `claimAmount`, `extraLedger: [[type, amount, fromParty, toParty, dayOffset]]`. Id is `booking-<key>`.
- **Invariants checked by the seed** (it aborts otherwise): unique ids, known owners and renters, one lock per renter, no overlapping calendar blocks on a car, held balance never negative.
- Booking status drives what is generated: lock, calendar block, contact docs, ledger rows, checklists (see `seed.js`). Anything beyond that goes in `docs(ctx)`.

## Check your file

```bash
cd tool/seed
node seed.js --dry-run --scenarios=phase-N    # base data + your file only, no credentials needed
node seed.js --dry-run                        # everything together
```

Load it for real with `npm run seed` (needs the service-account key, see `../README.md`). The seed only overwrites its own ids, so it is safe to repeat and restores any seeded booking that was changed while testing.
