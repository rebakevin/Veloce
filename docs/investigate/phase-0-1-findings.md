# Phase 0 and 1 findings (foundation, auth, profile)

## Verdict

Phase 0 and Phase 1 are substantially built and consistent with the TODO: `flutter analyze` reports no issues and `flutter test test/core test/features/auth test/features/profile test/app test/architecture` passes (320 tests). The auth flow (register, login, Google, forgot password, verify email, splash, router redirect, `AuthBloc`) and the profile screens trace cleanly from UI to bloc to use case to repository to Firestore, and the `users` / `private` rules match what the code writes. The real problems are at the edges: (1) the account-deletion cascade conflicts with the Firestore rules (claims cannot be deleted at all, and several delete rules use `getAfter` or status checks that fail when a parent is deleted in the same batch), which is the very check the TODO leaves unticked; (2) the account switcher signs the current user out before signing the target in, which sends the router to `/welcome` and probably drops the "sign in again" sheet; (3) an unverified email user has no way back to the verify-email page after the first session, the cached `emailVerified` is never refreshed on restart, and the gate is wired only into booking requests (not publish or pay); (4) the rules do not actually keep `role` immutable (delete then re-create), and no rule checks the role for vehicle or booking creation. Nothing in `tool/rules-test` covers Phase 1 rules, and the Firestore emulator would not start in this environment (port 8080 reported not open, even with the sandbox disabled), so the rules findings below come from reading `firestore.rules` and are marked as such.

Commands run: `flutter analyze` (clean), the flutter test command above (320 passed). Rules emulator: attempted, could not start.

## TODO task status

Legend: ok = implemented and traced; gap = missing or incomplete; bug = implemented but wrong; human = needs a person/console/device.

### Phase 0

| Task | Status | Note |
| --- | --- | --- |
| 0.A repo, flutter create, .gitignore, pubspec, analysis_options, CI, PR template, tracker, README | ok | `.gitignore` covers env.json, key.properties, keystores, service-account; analyze clean |
| 0.B Firebase project, providers, rules/indexes, access | ok | |
| 0.B collect SHA-1/256 from all 6 machines | human | box correctly open (F0-05) |
| 0.C Supabase buckets and policies | ok / spec-drift | buckets are public with anon select (F0-03) |
| 0.C `Env`, `MediaStorage` + unit test | gap | only `StorageObjectPaths` is unit tested, `SupabaseMediaStorage` is not (F0-04) |
| 0.D ERD, tag `erd-v1` | ok | tag is local until pushed (noted in TODO) |
| 0.E enums, entities, models, paths, `Result`, `Clock` | ok | |
| 0.E `Validators`, `Formatters`, lookups | ok | tests: validators, formatters, model round trips |
| 0.F folders, get_it, `main.dart`, go_router with every route, slot hosts, theme, `AppMessenger`, widget kit, `AuthSession` | ok | roles confinement is partial (F1-06) |
| 0.G service interfaces, `PricingCalculator`, `BookingStateMachine` + tests | ok | |
| 0.G `LedgerWriter` + held-balance test, `AuditLogger`, `NotificationWriter` | ok | audit rule allows spoofed actor (F0-02) |
| 0.G `MomoGatewaySim`, `VerificationSim` | ok | |
| 0.G `PreferencesService` (5 keys) + `ThemeCubit` | ok | no `PreferencesService` unit test (F0-04), static controller (F0-06) |
| 0.G `PendingReviewChecker` stub | ok | replaced by Phase 6 |
| 0.H `/dev-login`, seed script, seed README, run seed | ok | `DevSignIn` registered in release too (F0-01) |
| 0.I rules skeleton, Supabase SQL, drafts, kickoff | ok | |
| 0.J fresh clone < 15 min, every route opens, CI green | ok / human | timing on a teammate machine not done (stated in TODO) |

### Phase 1

| Task | Status | Note |
| --- | --- | --- |
| 1.A auth domain, use cases, repository | ok | |
| 1.A Firebase datasource, error-code mapping | ok | orphan Auth user on partial failure (F1-04) |
| 1.A `profile` domain, photo upload via `MediaStorage` | ok | |
| 1.B `AuthBloc` Unknown/Authenticated/Unauthenticated, session restore | ok | profile name goes stale (F1-08) |
| 1.B router redirect: unauthenticated to welcome | ok | |
| 1.B router redirect: roles confined to shells | gap | only `/owner`, `/renter` prefixes (F1-06) |
| 1.B unverified-email gate for request/publish/pay | gap | wired for request only; no path back to verify (F1-03) |
| 1.B sign-out clears caches, disposes route blocs | ok / bug | caches cleared on sign-out; account switch relies on a redirect side effect (F1-02) |
| 1.B `LoginBloc`, `RegisterBloc`, `ForgotPasswordCubit`, `ProfileBloc`, `AccountsBloc`, `SettingsCubit` | ok | |
| 1.C splash, onboarding pref, login, register, Google, forgot, verify-email, inline validation, verification failure retry | ok | |
| 1.D profile tab, edit profile, payout, National ID, licence, settings, about, contact, public profile + slots | ok | |
| 1.D account switcher (list, switch, add, remove) | bug | F1-02; stale name F1-08 |
| 1.D account switcher: expired session asks sign-in again | bug | F1-02 (likely never shown) |
| 1.D delete account | bug | F1-01 |
| 1.E `users` + `private` rules (role immutable, rating protected) | bug | role can be swapped by delete then create (F1-05) |
| 1.E deploy delete rules, delete a seeded account with real bookings | human | box open; F1-01 says it will fail |
| 1.E private docs unreadable by a second account | human | box open; rule reads correctly (`isSelf(uid)`), needs a real run |
| 1.F tests: use cases, blocs, login widget | ok | no tests for eraser, registration store, auth session, rules (F1-07) |
| 1.G report, demo A | human | boxes open |

## Findings

### F1-01 [severity: major] [kind: bug]
- Where: `lib/features/profile/data/firestore_account_eraser.dart:52-100`, `firestore.rules` (cautionClaims ~line 268, calendarBlocks ~line 190, renterLocks ~line 202, vehicles photos/documents ~line 148-155, bookings private ~line 175)
- What: the cascade plans deletes the rules do not allow. (a) `cautionClaims/{bid}` has `allow delete: if false` (and `tool/rules-test` asserts "rejects deleting a claim"), but the eraser deletes the claim of every booking that has one, so a user with a claim in any booking cannot delete the account. ADR 0002 point 4 does not list claims as deletable. (b) `calendarBlocks/{id}` delete requires `bkafter(id).status in [cancelled, expired, declined]`, so a block of an approved or confirmed booking is refused, and when the booking is deleted in the same batch `getAfter` returns a missing document and the rule errors. The eraser deletes `calendarBlocks/{bookingId}` for every booking (even when absent, the delete is still evaluated). (c) `renterLocks` delete has the same `bkafter(...).status in [...]` condition. (d) `vehicles/*/photos` and `documents` writes check `getAfter(vehicles/vid).data.ownerId`, and `bookings/*/private/*` writes check `bkafter(id)`; in the small-account path (`plan.size < 450`) the vehicle or booking is deleted in the same atomic batch, so `getAfter` cannot resolve the parent. The class comment ("Rules read the state before the batch, so parents may go with their children") is true for `get()` but not for `getAfter()`. Only the large-account branch orders children before parents, and even there (a), (b) and (c) still fail.
- Evidence: read the rules and the eraser; the TODO leaves "delete a seeded account with real bookings" unticked. Not confirmed on the emulator (it would not start here).
- Fix: add a rules emulator test that runs the eraser's batches. In the rules, allow account-deletion deletes explicitly: claims (`isParty(bk(bid))` for delete), calendar blocks and locks (`isParty(bk(...))` without the status condition), and make photo/document/private deletes use `get()` (pre-batch state) for `delete` while keeping `getAfter` for create/update. Alternatively always delete children first in a separate batch before parents, regardless of size.
- Status: open (client side adjusted; waits on main-session rules: claims delete, block/lock delete regardless of status, children-first batch. Eraser still deletes `cautionClaims/{bookingId}`, whose rule is `delete: if false`, so main session must allow party delete of claims or the eraser must stop deleting them)

### F1-02 [severity: major] [kind: bug]
- Where: `lib/features/auth/domain/usecases/switch_account.dart:37-45`, `lib/core/navigation/auth_redirect.dart:20-32`, `lib/features/profile/presentation/pages/accounts_page.dart:61-70`
- What: `SwitchAccount` calls `suspendSession()` (Firebase sign-out) before signing the target in. `FirebaseAuthSession` then reports `userId == null`, and `authRedirect` sends any non-auth location, including `/profile/accounts`, to `/welcome`. The Accounts page and its `AccountsBloc` are disposed, so (1) the `signInRequired` outcome ("Session expired, sign in again" sheet, TODO 1.D) is emitted to a closed bloc and never shown, leaving the user signed out on the welcome page, and (2) the `switched` handler's `context.go(home)` never runs; the user reaches the target Home only through the redirect after the new sign-in. The `role == null` branch has an exception for `/profile/accounts`, but the `userId == null` branch does not. The redirect path also means a flash of the welcome page and, if the stored credential is missing or wrong, a plain logout.
- Evidence: code trace only; `accounts_bloc_test` and `account_switching_test` test the bloc and use case, not the router interplay. Needs a device or a router-level test to confirm.
- Fix: keep the user on the accounts routes while a switch runs (let `authRedirect` return null for `userId == null` on `/profile/accounts*`, or set a "switching" flag in `AuthSession`), or do the target sign-in without signing out first. Add a router test that switches with a missing credential and expects the sheet.
- Status: fixed (SwitchAccount no longer signs out first, so the user stays on /profile/accounts and the sheet shows; AuthBloc clears caches when the uid changes). Still needs-human to confirm on a device

### F1-03 [severity: major] [kind: gap]
- Where: `lib/features/auth/auth_routes.dart:60`, `lib/features/auth/presentation/pages/register_welcome_page.dart:44`, `lib/core/data/services/firebase_auth_session.dart:34`, `lib/features/auth/domain/email_verification_gate.dart`
- What: TODO 1.B requires an unverified-email gate for request, publish and pay. (a) The gate is used only in `create_booking_request.dart`; `PublishVehicle` and the payment use case never call it (grep for `EmailVerificationGate` finds one consumer). (b) `/verify-email` is reachable only from the register welcome page. An unverified user who restarts the app or logs in later gets "Verify your email address first" with no screen to resend the mail or confirm. (c) `isEmailVerified` reads `FirebaseAuth.currentUser.emailVerified`, which is cached; it is refreshed only by the verify page's `reloadUser` or an hourly token refresh. A user who opened the link, then restarts, stays blocked.
- Evidence: grep `EmailVerificationGate|isEmailVerified|verifyEmail` over `lib`.
- Fix: reload the user on app start and on resume (`ReloadAuthUser` in `AuthBloc` start), add a "Verify email" entry (banner or the gate failure action) that opens `/verify-email`, and call the gate in `PublishVehicle` and the pay use case (Phase 2 and 4 owners, or a `contract:` change).
- Status: partly fixed (AuthBloc reloads an unverified user on restore/switch; profile tab shows a "Verify your email" banner to /verify-email). Open: gate not called in PublishVehicle or pay use case (other phases, main session)

### F1-04 [severity: minor] [kind: bug]
- Where: `lib/features/auth/data/firebase_auth_data_source.dart:30-39`, `lib/features/auth/domain/usecases/register_with_email.dart:51-60`
- What: `createEmailUser` creates the Auth user and then calls `updateDisplayName` and maps the user. If `updateDisplayName` throws or the 30 s timeout fires after creation, the repository returns a failure, `RegisterWithEmail` only discards the photo, and the Auth user stays (signed in, no profile). The retry then fails with `email-already-in-use`, and the app falls into `AuthNeedsProfile(needsRoleChoice: false)`, which the splash shows as "registration did not finish". Similarly `createProfile` has a 20 s timeout after which the use case deletes the Auth user although the batch may still commit later, leaving an orphan profile.
- Evidence: read the data source and use case.
- Fix: on failure after creation, delete the current user (as is done for the profile failure), and treat a display-name failure as non-fatal.
- Status: fixed (display-name failure after account creation is non-fatal, so no orphan signed-in user from that path). The createProfile timeout case stays open (batch may commit late)

### F1-05 [severity: major] [kind: spec-drift]
- Where: `firestore.rules:124-137`
- What: TECHNICAL.md section 5 (line 573) and section 8.2 state "role is immutable after creation". The rule blocks changing `role` on update, but `allow delete: if isSelf(uid)` plus `allow create: if isSelf(uid) && role in [...]` lets a user delete their own `users/{uid}` and recreate it with the other role while keeping the same uid and bookings. The create rule also accepts any `verified` value.
- Evidence: rule reading; not run on the emulator.
- Fix: restrict create to when no document existed and the user has no bookings/vehicles is not expressible cheaply; the simplest mitigation is to keep a `roles/{uid}` write-once document, or require `!exists(...)` plus a server-written tombstone. At minimum document that role immutability holds only against `update`, and add a rules test.
- Status: open

### F1-06 [severity: minor] [kind: bug]
- Where: `lib/core/navigation/auth_redirect.dart:44-48`, `firestore.rules` (vehicles create ~line 143, bookings create ~line 160)
- What: role confinement is by path prefix only (`/owner`, `/renter`). Role-specific pages outside those prefixes (`/car/:id/book`, `/booking/:id/decision`, `/booking/:id/pay`, `/profile/payout`, `/profile/identity`, `/profile/licence`) are open to the other role by deep link or `/dev-routes`. The profile repository guards the writes (`_requireRole`), but the rules also never check the user's role: any signed-in user can create a vehicle (`ownerId == me()`) or a booking (`renterId == me()`).
- Evidence: reading `requiredRoleFor`, `profile_routes.dart`, and the rules.
- Fix: add role checks to the router for those patterns and a `get(users/me).data.role` condition in the vehicle and booking create rules.
- Status: open (router part is in lib/core/navigation/auth_redirect.dart `requiredRoleFor`; a per-route guard in profile_routes broke test/app router test, which opens every route as a renter, so it was not kept; rules role checks belong to main session)

### F1-07 [severity: minor] [kind: test-gap]
- Where: `test/features/profile/data`, `test/features/auth/data`, `tool/rules-test/firestore.rules.test.js`
- What: no tests for `FirestoreAccountEraser`, `FirestoreRegistrationStore.createProfile` (atomic write of user, private docs and audit log), or `FirebaseAuthSession` (role refresh after registration). `tool/rules-test` covers Phases 3 to 6 only: nothing for `users` create/update/delete, `private` read isolation (TODO 1.E), role immutability, or the delete cascade. The router test for account switching (F1-02) is also missing.
- Evidence: listing of the test folders and the `describe` blocks of the rules test.
- Fix: add emulator tests for the Phase 1 rules and the eraser batches; add a fake-firestore test for the registration store.
- Status: partly fixed (added eraser test, registration store test; still missing: FirebaseAuthSession test, rules-test for Phase 1 rules, router-level switch test)

### F1-08 [severity: minor] [kind: bug]
- Where: `lib/features/auth/presentation/bloc/auth_bloc.dart:75-82`, `lib/features/auth/domain/usecases/link_current_account.dart`, `lib/features/profile/presentation/bloc/accounts_bloc.dart:50-62`
- What: `AuthBloc` keeps the loaded account when the same uid emits again, and nothing dispatches `AuthProfileRefreshed` after an edit-profile save. The linked-account record stores the name once (`LinkCurrentAccount`), and `AccountsBloc` links only when the uid is missing, so a renamed account shows the old name in the account switcher and in anything reading `AuthBloc.account.name`.
- Evidence: read the three files; `ProfileBloc` updates only its own state.
- Fix: dispatch `AuthProfileRefreshed` after a successful profile update and refresh the linked record's name when it differs.
- Status: fixed (edit profile dispatches AuthProfileRefreshed; AccountsBloc re-links the current account on start, LinkCurrentAccount keeps the stored password, so the switcher name refreshes)

### F0-01 [severity: minor] [kind: gap]
- Where: `lib/features/auth/auth_injection.dart:48`, `lib/features/auth/domain/dev_account.dart:25`
- What: `DevSignIn` is documented as "registered in debug builds only" but registered unconditionally; the seeded accounts' shared password (`Veloce#2026`) is a constant reachable from release code, and the seed script uses the same password on the shared dev project. The dev routes are correctly gated by `kDebugMode`, but `authRedirect` skips all checks for `/dev-login` and `/dev-routes` regardless of build mode.
- Evidence: grep and reading.
- Fix: wrap the registration in `if (kDebugMode)` and make `isDevTool` check `kDebugMode`; rotate the shared project's seeded passwords before any release.
- Status: fixed (DevSignIn registered only under kDebugMode; authRedirect dev-tool bypass only under kDebugMode). Rotating seeded passwords stays needs-human

### F0-02 [severity: minor] [kind: bug]
- Where: `firestore.rules:341-344`
- What: `auditLogs` create is `signedIn()` only, so any user can write entries with an arbitrary `actorId`, `entityId` and states. The log is meant to be a trustworthy append-only trail.
- Evidence: rule reading; the spec skeleton has the same rule.
- Fix: require `request.resource.data.actorId == me()` and `request.resource.data.at == request.time`.
- Status: open (it is the auditLogs rule, not DevSignIn; rules are the main session's)

### F0-03 [severity: major] [kind: spec-drift]
- Where: `tool/supabase/storage.sql:8-31`
- What: SPECS.md line 371 says ID and licence photos are "readable only by their owner and Veloce". The `user-docs` bucket is `public = true` and the anon role has `select` on all four buckets, so anyone holding the anon key (shipped in `env.json` and the app) can list and download every National ID and licence photo. Decision D-3 relies on URL secrecy, but the select policy removes it by allowing listing.
- Evidence: SQL and spec text.
- Fix: make `user-docs` private with signed URLs (or at least drop the anon `select` policy for it so URLs cannot be enumerated), or record the deviation in the ADR and the report.
- Status: open (needs-human decision)

### F0-04 [severity: minor] [kind: test-gap]
- Where: `test/core/data`
- What: TODO 0.C says "`MediaStorage` ... + unit test"; only `StorageObjectPaths` is tested, not `SupabaseMediaStorage` upload/delete/error mapping. `PreferencesService` and `FirestoreAuditLogger` / `FirestoreNotificationWriter` also have no direct tests.
- Evidence: test listing.
- Fix: add a mocktail test for `SupabaseMediaStorage` and a `SharedPreferences.setMockInitialValues` test for `PreferencesService`.
- Status: open

### F0-05 [severity: minor] [kind: needs-human]
- Where: `docs/resources/TODO.md` 0.B, 1.E, 1.G
- What: items that need a person: the last machine's SHA-1/SHA-256 for Google sign-in, deploying the delete rules and running the cascade against the real project (see F1-01), the two-account check that private documents are unreadable, Google sign-in on a real device, the 15-minute fresh-clone timing, and the report and demo segment.
- Evidence: TODO checkboxes.
- Fix: do on device/console; run `npm test` in `tool/rules-test` on a machine where the emulator starts (it did not here: "port 8080 is not open").
- Status: needs-human

### F0-06 [severity: nit] [kind: bug]
- Where: `lib/core/data/services/preferences_service.dart:17-18`
- What: `_notificationsEnabledController` is `static` and never closed, so it is shared by every `PreferencesService` instance (tests that build two instances see each other's events).
- Evidence: reading.
- Fix: make it an instance field closed with the service, or accept as a singleton and document it.
- Status: open

## Counts

blocker 0, major 5 (F1-01, F1-02, F1-03, F1-05, F0-03), minor 8 (F1-04, F1-06, F1-07, F1-08, F0-01, F0-02, F0-04, F0-05 needs-human), nit 1 (F0-06). Kinds: bug 7, gap 2, spec-drift 2, test-gap 2, needs-human 1 (F1-02 also needs a device).

## Fix log

- F1-02: `lib/features/auth/domain/usecases/switch_account.dart` (no suspend before sign-in), `lib/features/auth/presentation/bloc/auth_bloc.dart` (clear caches on uid change); tests `test/features/auth/domain/account_switching_test.dart`, `test/features/auth/presentation/bloc/auth_bloc_test.dart`.
- F1-03: `auth_bloc.dart` (reload unverified user after loading the profile), `lib/features/profile/presentation/pages/profile_tab_page.dart` (verify banner); tests in `auth_bloc_test.dart`, `test/features/profile/presentation/pages/profile_tab_page_test.dart`.
- F1-04: `lib/features/auth/data/firebase_auth_data_source.dart` (display name failure non-fatal, with timeout).
- F1-08: `edit_profile_page.dart`, `profile_action_listener.dart` (onSuccess), `link_current_account.dart`, `accounts_bloc.dart`; `AuthBloc._loadProfile` keeps the signed-in state when a refresh fails; tests updated (`accounts_bloc_test.dart`, `edit_profile_page_test.dart`, `account_switching_test.dart`).
- F0-01: `lib/features/auth/auth_injection.dart`, `lib/core/navigation/auth_redirect.dart` (kDebugMode gates).
- F1-01 (client): `lib/features/profile/data/firestore_account_eraser.dart` now reads through `ErasableDocSource` (`FirestoreDocSource` in DI, `profile_injection.dart`) so it is testable without sealed Firestore classes; children-first batch order documented.
- F1-07: `test/features/profile/data/firestore_account_eraser_test.dart`, `test/features/auth/data/firestore_registration_store_test.dart`.
