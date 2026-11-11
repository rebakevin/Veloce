# Report draft: architecture, setup and ERD ↔ Firestore (Phase 0)

Raw material for the final report. Sources: `docs/resources/TECHNICAL.md` (§3, §4), `docs/resources/ER-DIAGRAM.md`, `docs/adr/0001-phase-0-decisions.md`. Rewrite in the team's own words before submission, and cite the references used.

## 1. Architecture

Veloce is feature-first with three layers per feature:

```
presentation  →  domain  ←  data
(pages, widgets,  (entities,   (models, datasources,
 blocs/cubits)     use cases,   repository implementations)
                   repository interfaces)
```

- `domain` is pure Dart: no Flutter and no Firebase imports.
- `data` implements the repository interfaces with Firestore and Supabase. Models map `Map<String, dynamic>` to entities (`fromMap` / `toMap`).
- `presentation` reaches data only through blocs and cubits. Business rules do not live in widgets, and `setState` is banned.
- Repositories return `Result<T>` (`Success` / `Failure(AppFailure)`) and never throw to the UI.
- `get_it` wires dependencies. Blocs are created by route-level `BlocProvider`s so they are disposed on navigation and sign-out.

Shared contracts live in `lib/core` (entities, enums, models, `FirestorePaths`, `FirestoreFields`, validators, formatters, core services, theme, widget kit). The composition root is `lib/app` (router, DI, root widget). Each of the nine features exposes one barrel file, `*_routes.dart` and `*_injection.dart`; other features import only the barrel. `test/architecture/import_rules_test.dart` fails the build when a layer or feature boundary is crossed.

Why BLoC: events and states are explicit and testable without a widget tree, one state source can feed several widgets (for example the favourite heart and the Saved count), and blocs are disposed with their route.

Phase 0 deviations from the generic conventions are recorded in ADR 0001.

## 2. Setup

1. Flutter stable and an Android emulator or phone.
2. `flutter pub get`.
3. Copy `env.example.json` to `env.json` and fill in the Supabase URL and key (shared privately).
4. `flutter run --dart-define-from-file=env.json`.
5. Seed the shared dev project once (`tool/seed/README.md`), then sign in through `/dev-login` (debug builds).

Firebase client config (`firebase_options.dart`, `google-services.json`) is committed on purpose: it is public and protected by the security rules. Google Sign-In needs each build machine's SHA-1 and SHA-256 registered in Firebase; release builds are signed with one shared team keystore kept outside git (`docs/resources/KEYSTORE.md`).

CI (GitHub Actions) runs `dart format --set-exit-if-changed`, `flutter analyze`, a `setState` grep and `flutter test` on every push and pull request.

## 3. ERD ↔ Firestore

Each ERD entity is one document or sub-collection. Private data sits in `private` sub-documents because security rules cannot hide single fields.

| ERD entity | Firestore path | Written by | Read by |
| --- | --- | --- | --- |
| USER | `users/{uid}` | Phase 1 | signed-in users (public info only) |
| CONTACT, LICENCE, OWNER_IDENTITY, PAYOUT_METHOD | `users/{uid}/private/{doc}` | Phase 1 | the owner of the document |
| FAVOURITE | `users/{uid}/favourites/{vehicleId}` | Phase 3 | that user |
| VEHICLE (+ availability window) | `vehicles/{id}` | Phase 2 | signed-in users |
| VEHICLE_PHOTO | `vehicles/{id}/photos/{photoId}` | Phase 2 | signed-in users |
| VEHICLE_DOCUMENT | `vehicles/{id}/documents/{kind}` | Phase 2 | the vehicle's owner |
| BOOKING | `bookings/{id}` | Phase 3 creates; Phases 4–5 update | the two parties |
| BOOKING_CONTACT | `bookings/{id}/private/{renter\|owner}` | each party writes their own | the other party after payment |
| CALENDAR_BLOCK | `calendarBlocks/{bookingId}` | Phase 4 | signed-in users (search) |
| RENTER_LOCK | `renterLocks/{renterId}` | Phases 4–5 | signed-in users |
| CHECKLIST_ENTRY / CHECKLIST_MEDIA | `bookings/{id}/checklistEntries`, `checklistMedia` | Phase 5 | the two parties |
| TRANSACTION | `transactions/{id}` | `LedgerWriter` (create-only) | the two parties |
| CAUTION_CLAIM | `cautionClaims/{bookingId}` | Phase 5 | the two parties |
| REPAIR_EXPENSE | `repairExpenses/{id}` | Phase 5 | the vehicle's owner |
| REVIEW | `reviews/{bookingId_authorId_subjectType}` | Phase 6 | signed-in users |
| NOTIFICATION | `notifications/{id}` | `NotificationWriter` | the recipient |
| AUDIT_LOG | `auditLogs/{id}` | `AuditLogger` (create-only) | nobody in the app |

### Intentional duplicates

| Duplicate | Reason |
| --- | --- |
| `ratingAvg`, `ratingCount`, `completedCount` on users; `ratingAvg`, `ratingCount` on vehicles | Cards and profiles avoid scanning reviews. Updated in the same batch as the review. |
| `vehicles.docsValidUntil` | Renters cannot read private vehicle documents, but search must hide cars with expired papers. |
| `BOOKING_CONTACT` | Rules cannot join; contact details unlock only after payment. |
| `calendarBlocks` | Renters cannot read other renters' bookings, yet search must exclude blocked dates. |
| `transactions.ownerId/renterId/vehicleId` | Finances and payment history query by user or vehicle without joins. |

Names and photos are not copied into bookings; lists resolve them through the cached `UserLookup` and `VehicleLookup`.

### Money

Escrow is bookkeeping: an append-only `transactions` ledger written by `LedgerWriter`. A booking's held balance (charges minus releases and refunds) must never go negative; a unit test and the seed script both check it.

## Still to add by hand

- ERD exported as PNG/SVG (Mermaid source is in `docs/resources/ER-DIAGRAM.md`) once the team signs off.
- Screenshots of the Firestore console and the rules once the seed has run.
