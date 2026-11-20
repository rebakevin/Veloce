# Firestore rules tests

Covers the Phase 3 favourites, booking-create and renter-contact rules, the Phase 5 handover, ledger, claim and repair rules, and the Phase 6 reviews, rating aggregate and notifications rules.

Run from this folder:

```bash
npm install
npm test
```

`npm test` starts the local Firestore emulator through the Firebase CLI, uses
`../../firestore.rules`, and does not touch the real `veloce-1fe08` project.
The first run may download the emulator.
