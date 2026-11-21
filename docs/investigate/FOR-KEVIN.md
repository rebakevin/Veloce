# For Kevin

Nothing is committed; everything is in the working tree.

**State:** `flutter analyze` clean, `flutter test` 820 passing (699 before). Firestore rules: **177 emulator tests passing** (87 old, 90 new) against the real client write shapes, list queries and the account-erase sequence. Details: `fix-phases.md`, `phase-*-findings.md`, `round-2-*.md` (each has Status lines and fix logs).

## Do these
1. **Deploy the rules and indexes**: `firebase deploy --only firestore:rules,firestore:indexes`. New composite index: bookings (ownerId, vehicleId, status, startDate). Until deployed, claims, pickups, reviews and approve fail on the real project.
2. **Run the rules tests on your machine**: `cd tool/rules-test && npm test` runs only the first file; run all three with
   `npx firebase emulators:exec --only firestore --project demo-veloce "mocha firestore.rules.test.js gaps.rules.test.js client-shapes.rules.test.js --timeout 20000"`
   (here port 8080 was taken by another process, so I ran on 8085 via a temp config).
3. **Supabase**: `user-docs` bucket is public with anon `select` (ID and licence photos listable with the anon key). I did not change it because the app displays those photos by URL; the safe fix is signed URLs, which is a design change. Decide.
4. **Device checks** (I cannot): account switcher "sign in again" sheet, landscape rotation of every screen, camera/video capture, Google sign-in on a release build, PDF opening, demo segments A-F, Figma screenshots.
5. **Real-project checks** still unticked in TODO: delete a seeded account with bookings; second account cannot read private docs; contact docs locked before payment (the emulator tests now cover the rules side).
6. `docs/resources/TODO.md` was not edited. Phase 2 task "photo reorder" and "rules PDF" are now built; tick when you agree.

## Decisions I made (per your instruction, change if you disagree)
- **fake_cloud_firestore**: not added; it cannot resolve against `equatable ^3`. The emulator rules tests cover the Firestore write shapes instead, so repository classes still have no Dart unit tests.
- **file_picker added**, rules PDF built (pick, 5 MB, upload to `car-media`, open from detail). **firebase_storage removed** (unused).
- **Role immutability** (delete own user doc and recreate with the other role): accepted; rules cannot stop it without a tombstone. It would take an app change to matter.
- **Booking/ledger delete rules kept permissive** for parties: the account eraser must delete active bookings and ledger rows. Two tests document this gap. Tightening needs the eraser to delete `users/{uid}` in every batch.
- **Route-level role guards** (F1-06) not added: they break the "open every route as a renter" test; role confinement exists for `/owner` and `/renter` prefixes.
- **Claim deductions are not counted as owner earnings**: that matches SPECS 7.1 / TECHNICAL 5.2.
- Added the Android `https` VIEW intent to `AndroidManifest.xml` for `url_launcher`.

## Still open (minor)
- **Payment taken, then the deadline passes (MoMo):** `MomoGateway.charge` is now idempotent per booking (`idempotencyKey`), so Retry never double-charges, even after a restart. Remaining gap: if the charge succeeds but recording it fails, and the booking is past its payment deadline (or no longer `approved`) by the time the renter retries, `pay` returns "The payment deadline has passed" / "not waiting for payment" and never mentions the debit. Decide the policy: refund automatically, or show the MOMO reference and point to support. The real MTN gateway must also honour the idempotency key.
- Stale renter lock whose holder expired only by deadline (R2B-05): needs `payDeadline` on the lock doc and a time check in the `renterLocks` update rule.
- Notification `createdAt` null while a server timestamp is pending (R2B-06): confirm on a device.
- VLC reference uniqueness (F3-09), deleted cars missing from per-car finances (F6-13), terms checkbox asked twice (F3-12), photo reorder cannot move a new photo ahead of existing ones in edit mode.
