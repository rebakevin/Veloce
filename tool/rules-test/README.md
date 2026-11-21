# Firestore rules tests

Covers the Phase 3 favourites, booking-create and renter-contact rules, the Phase 5 handover, ledger, claim and repair rules, and the Phase 6 reviews, rating aggregate and notifications rules.

Files:

- `firestore.rules.test.js`: per-rule tests (favourites, booking create, pickup, return, ledger, claims, repairs, reviews, ratings, notifications).
- `gaps.rules.test.js`: create rules and negatives (users, vehicles and the removal batch, booking create, reviews, notifications), `completedCount` +1, `at == request.time`, ledger and booking delete.
- `client-shapes.rules.test.js`: the writes and queries exactly as `lib/` issues them: Phase 4 batches (approve, decline, cancel, expire, pay, agreement, contact unlock, locks and blocks), the claim wire map (`CautionClaimModel.toMap`) through claim, dispute, re-claim, agree and refund, every list query with its `where` clauses (allowed for the right user, denied for an outsider), and a port of the account eraser run as the user.
- `support.js`: shared helpers.

Known gaps kept on purpose (R2R-07/08): a booking party can delete a booking at any status and its own ledger rows, because the account eraser deletes active bookings before the user document and rules cannot tell the eraser from a manual delete. Two tests document this.

Run from this folder:

```bash
npm install
npm test
```

`npm test` starts the local Firestore emulator through the Firebase CLI, uses
`../../firestore.rules`, and does not touch the real `veloce-1fe08` project.
The first run may download the emulator.
