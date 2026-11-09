# Veloce — Phases

Companion to `TECHNICAL.md` (section numbers like §5.4 refer to it). Tick a box only when the work is **merged to `main` via a reviewed PR** with tests passing.

| Phase | Scope | Owner |
| --- | --- | --- |
| **0** | Setup, architecture, shared contracts, all routes, seed data | Kevin (you) |
| **1** | Authentication (renter + owner) and profile | Kevin (you) |
| **2** | Owner: car listing, documents, availability, My cars | ____ |
| **3** | Renter: discovery, search, car detail, favourites, booking request | ____ |
| **4** | Booking decision, payment, My Activity, booking detail, agreement, cancel | ____ |
| **5** | Pickup, return, late fee, caution claims, repair costs | ____ |
| **6** | Reviews, notifications, owner finances, renter payment history | ____ |

## How phases 2–6 stay independent

1. **Contract = the ERD + Phase 0 code.** Entities, models, Firestore constants, core services and every route exist after milestone **M0** (the ★ tasks in Phase 0). After M0, nobody waits for anybody.
2. **Write only your own collections** (listed in each phase). Read anything else through the `core` lookups.
3. **No Phase 1 needed to work:** use `/dev-login` (debug builds) with the seeded accounts. The seed script creates cars and bookings in **every status**, so you can build against realistic data from day one.
4. **Code against interfaces, test with `mocktail`**; integrate when the other phase merges. Shared pages use **slots** (§10) so nobody edits the same file.
5. **You own your files:** `features/<yours>/`, your `*_injection.dart`, `*_routes.dart`, and your labelled block in `firestore.rules`. Need a shared change (ERD, entity, core service)? Open a PR titled `contract:` and get all owners to review.
6. **Every phase also delivers:** ≥ 3 unit tests, ≥ 2 bloc tests, ≥ 1 widget test, no `setState`, `dart format` + `flutter analyze` clean, Figma-vs-app screenshots in PRs, its report section, and its demo segment.

Branch naming: `phaseN/<feature>`. Commit often (small, descriptive). Review ring: P1→P2→P3→P4→P5→P6→P1.

---

## Phase 0 — Setup & foundation
**Owner:** Kevin · ★ = blocks the others (**M0 target: within ~2 days of starting**) · everything else can proceed while others build.

### 0.A Repository & tooling
- [ ] ★ Create GitHub repo; add all 6 members (and instructor/TA if private); protect `main` (PR + 1 review + CI)
- [ ] ★ `flutter create --platforms=android,ios` — confirm no web/desktop folders
- [ ] ★ `.gitignore` (env.json, key.properties, keystores, service-account JSON); commit `env.example.json`
- [ ] ★ `pubspec.yaml` with all packages in §2.2; `flutter pub get` works for everyone
- [ ] ★ `analysis_options.yaml` (flutter_lints); `flutter analyze` = 0
- [ ] GitHub Actions: `dart format --set-exit-if-changed .`, `flutter analyze`, `setState` grep, `flutter test`
- [ ] PR template, issue labels (`phase-0` … `phase-6`), `CONTRIBUTING.md` (branches, commits, review ring)
- [ ] Copy the **Group Contribution Tracker**, share with all, and agree weekly updates
- [ ] README skeleton (overview, setup, architecture, test commands)

### 0.B Firebase
- [ ] ★ Create Firebase project (Spark plan); add Android app; run `flutterfire configure`; commit `firebase_options.dart` + `google-services.json`
- [ ] ★ Collect **debug SHA-1/SHA-256 from all 6 machines** + the release keystore; register them (Google Sign-In)
- [ ] ★ Enable Email/Password and Google providers; add a team keystore for release builds
- [ ] Create Firestore database; commit `firestore.rules` skeleton (§8.1) and `firestore.indexes.json` (§4.4); deploy
- [ ] Share project access with all members

### 0.C Supabase
- [ ] Create project; buckets `car-media`, `user-docs`, `checklist-media`, `receipts`; size/MIME limits; anon insert/select policies (`tool/supabase/storage.sql`)
- [ ] `env.json` + `Env` class; `MediaStorage` (upload with compression, delete) + unit test
- [ ] Share the real `env.json` privately with the team

### 0.D ERD
- [ ] ★ Finalise the ERD from §4.2 with the team; export PNG/SVG for the report
- [ ] ★ Tag `erd-v1`; agree the change process (`contract:` PRs)

### 0.E Core domain & data
- [ ] ★ Enums: `UserRole`, `BookingStatus`, `VehicleStatus`, `TransactionType`, `ChecklistKind`, …
- [ ] ★ Entities for every ERD entity (`core/domain/entities`) + models with `fromMap/toMap` (`core/data/models`)
- [ ] ★ `FirestorePaths`, `FirestoreFields`; `Result`, `AppFailure`; `Clock`
- [ ] ★ `Validators` (email, password, phone, MoMo, DOB 18+, National ID, licence, plate, year, price) and `Formatters` (RWF, dates, reference `VLC-####`)
- [ ] `UserLookup`, `VehicleLookup`, `BookingLookup` (cached read-by-id/stream)
- [ ] Unit tests: validators, formatters, model round-trips (≥ 8)

### 0.F Architecture skeleton
- [ ] ★ Folder structure for all 9 features (§3.2) with `*_injection.dart` and `*_routes.dart` each
- [ ] ★ `get_it` setup; `main.dart` initialises Firebase, Supabase, DI
- [ ] ★ `go_router` with **every route in §10** pointing at placeholder pages; role shells with bottom navigation; auth redirect hook (P1 completes it)
- [ ] ★ Slot host pages with placeholder slot widgets: `OwnerHomePage`, `BookingDetailPage`, `PublicProfilePage`
- [ ] ★ Theme (light/dark, contrast-checked palette from Figma), text styles, `Responsive` helpers
- [ ] ★ `AppMessenger` (SnackBars) and the shared widget kit (§12.4)
- [ ] ★ `AuthSession` interface (`currentUserId`, `role`) that blocs use instead of Firebase directly

### 0.G Core services
- [ ] ★ Abstract interfaces for `LedgerWriter`, `AuditLogger`, `NotificationWriter`, `MomoGateway`, `VerificationProvider`, `PendingReviewChecker`
- [ ] `PricingCalculator` (+ long-rental tiers) with unit tests
- [ ] `BookingStateMachine` (transition table + `effectiveStatus`) with unit tests
- [ ] `LedgerWriter` (+ held-balance invariant test), `AuditLogger`, `NotificationWriter` Firestore implementations
- [ ] `MomoGatewaySim` (success/failure toggle), `VerificationSim` (OTP + document check)
- [ ] `PreferencesService` (5 keys, §9) + `ThemeCubit`
- [ ] `PendingReviewChecker` stub (returns false) registered inside `reviews_injection.dart` for P6 to replace

### 0.H Dev tooling & seed data
- [ ] ★ `/dev-login` page (debug only) with buttons for the seeded accounts
- [ ] ★ `tool/seed/seed.js` (Firebase Admin SDK): 3 renters, 3 owners (email+password), users + private docs, 8 cars with photos/docs/availability, calendar blocks, one booking in **each status**, transactions matching the ledger rules, reviews, notifications, repair expenses, claims (agreed and disputed)
- [ ] ★ Seed README: how to run, reset, and the account list
- [ ] Run seed on the shared dev project; confirm the numbers reconcile (held balance ≥ 0)

### 0.I Rules & docs
- [ ] Firestore rules skeleton with labelled blocks per phase; Supabase SQL committed
- [ ] Architecture, setup and ERD ↔ Firestore sections drafted for the report
- [ ] M0 kickoff call: walk through folders, contracts, slots, seed accounts; assign phases 2–6

### 0.J Definition of done
- [ ] A fresh clone builds and runs on an emulator in < 15 minutes using only the README
- [ ] Every route opens a placeholder; `/dev-login` signs in as any seeded account
- [ ] CI green on `main`

---

## Phase 1 — Authentication & profile
**Owner:** Kevin · Collections written: `users`, `users/*/private/*`, `auditLogs` (registration) · Spec §2, §5.1, §6.1, §8.2

### 1.A Domain & data
- [ ] `auth` domain: `AuthRepository`, use cases (`RegisterWithEmail`, `LoginWithEmail`, `SignInWithGoogle`, `SendPasswordReset`, `SendEmailVerification`, `SignOut`, `ObserveAuthState`)
- [ ] Firebase datasource; map `FirebaseAuthException` codes to clear messages
- [ ] `profile` domain: `ProfileRepository` (get/update profile, licence, owner identity, payout), photo upload via `MediaStorage`

### 1.B State & routing
- [ ] `AuthBloc` (global): `Unknown → Authenticated(user, role) | Unauthenticated`; session restored after restart
- [ ] Router redirect: unauthenticated → `/welcome`; roles confined to their shell; unverified-email gate for request/publish/pay
- [ ] Sign-out disposes route-level blocs and clears caches
- [ ] `LoginBloc`, `RegisterBloc` (multi-step), `ForgotPasswordCubit`, `ProfileBloc`, `AccountsBloc`, `SettingsCubit`

### 1.C Authentication screens
- [ ] Splash → welcome/onboarding (`onboarding_seen` pref)
- [ ] Login (email + password, Google button, "Forgot password?")
- [ ] Register: role → details (name, phone, email, password, DOB 18+, licence or National ID with photo) → OTP + email verification → welcome
- [ ] Google first sign-in → role choice → document steps; returning Google user → Home
- [ ] Forgot-password page; verify-email pending page (resend)
- [ ] Inline validation messages on every field; blank submissions blocked
- [ ] Simulated verification failure state with retry

### 1.D Profile screens
- [ ] Profile tab (name, role label, phone, email, identity status, photo, sign out)
- [ ] Edit profile (name, phone, DOB, photo)
- [ ] Owner: payout MoMo number; National ID view/replace
- [ ] Renter: driving licence add/change with simulated verification
- [ ] Settings: theme (light/dark/system) and notifications switch → saved via `PreferencesService`
- [ ] About page and Contact page (support email **r.kevin@alustudent.com**)
- [ ] Public profile `/user/:id` (name, photo, rating, past rentals, first-time flag; contact **never** shown) with the two slots for P3/P6
- [ ] **Account switcher**: list with Renter/Car owner labels and "current" mark; switch without password; add account (email or Google); remove from this device; expired session → asks sign-in again (§6.4)

### 1.E Rules & data
- [ ] `users` + `private` rules block (role immutable, rating fields protected)
- [ ] Verify with a second account that private docs are unreadable

### 1.F Tests
- [ ] Unit: register/login use cases (success + each failure code), validators used by forms, account-switch logic
- [ ] Bloc: `AuthBloc` (restore, logout), `LoginBloc`, `RegisterBloc`
- [ ] Widget: login page shows validation errors and calls the bloc

### 1.G Docs & demo
- [ ] Report: Authentication, validation, preferences, account switching sections
- [ ] Demo segment A (~3 min): cold start, register → logout → login, Google, validation error, theme change → restart → persisted, account switch

---

## Phase 2 — Owner: cars & availability
**Owner:** ____ · Collections written: `vehicles`, `vehicles/*/photos`, `vehicles/*/documents` · Spec §6.2–6.4 · Slot: `CarCountCard`

### 2.A Domain & data
- [ ] `VehicleRepository` (create/update/delete/watch own cars, photos, documents, availability, pause/resume)
- [ ] Use cases: `PublishVehicle`, `UpdateVehicle`, `RemoveVehicle` (blocked while open bookings exist), `SetAvailability`, `SetStatus`, `UpsertDocument`
- [ ] `RecomputeDocsValidUntil` (min of insurance and medical expiry) after any document change
- [ ] Photo upload/reorder/delete via `MediaStorage`

### 2.B Business rules (pure, unit-tested)
- [ ] Plate `RAB 123 A` validator; year 2005–2026; price ≥ 5,000; caution ≥ 0
- [ ] Long-rental tier validator (≤ 3; ≥ 2 days; strictly decreasing; ≥ 5,000)
- [ ] Example text per tier ("5 days: 5 × 75,000 = 375,000") and 3-day preview (renter pays / owner receives = fee − 2,000) using `PricingCalculator`
- [ ] Documents rule: insurance + medical required, yellow paper optional, plate must match, expiry in future

### 2.C Screens (7-step wizard, `/owner/cars/new` and `/owner/cars/:id/edit`)
- [ ] Wizard shell with progress bar, back/next, per-step validation, draft kept in `CarWizardBloc`
- [ ] Step 1 media (3–6 photos, primary, optional video)
- [ ] Step 2 vehicle details · Step 3 specifications
- [ ] Step 4 pricing + long-rental tiers + live preview
- [ ] Step 5 rental rules (+ optional PDF)
- [ ] Step 6 documents (photo, number, expiry, simulated verification; yellow paper skippable)
- [ ] Step 7 review & publish ("Not added" for skipped yellow paper)
- [ ] My cars list: photo, plate, price, status, availability line, next rental, edit / availability / pause-resume / remove (confirmation dialog)
- [ ] Availability screen: one date range only; booked days locked
- [ ] Documents screen: add yellow paper later, replace expired documents; paused-by-expiry banner
- [ ] `CarCountCard` slot for owner home

### 2.D Rules & indexes
- [ ] `vehicles` block (owner-only writes; documents owner-only); add indexes from §4.4
- [ ] Verify another user cannot edit or read vehicle documents

### 2.E Tests
- [ ] Unit: plate, tiers, documents rule, `docsValidUntil`, remove-blocked rule
- [ ] Bloc: `CarWizardBloc` (step validation, publish success/failure), `MyCarsBloc`
- [ ] Widget: wizard step shows errors and blocks Next

### 2.F Docs & demo
- [ ] Report: vehicle data model, listing wizard, document rule sections
- [ ] Demo segment B (~2 min) with Firebase Console open: **create** a car, **read** in My cars, **update** the price, **delete** the car

---

## Phase 3 — Renter: discovery & request
**Owner:** ____ · Collections written: `users/*/favourites`, `bookings` (create only) + `bookings/*/private/renter` · Spec §5.2–5.4 · Slot: `OwnerCarsSection`

### 3.A Domain & data
- [ ] `SearchRepository`: published vehicles + filters + availability window + `calendarBlocks` check (§4.5)
- [ ] `FavouritesRepository` (add/remove/watch); `RequestRepository.createBooking`
- [ ] Use cases: `SearchVehicles`, `GetVehicleDetail`, `ToggleFavourite`, `CreateBookingRequest`
- [ ] `CreateBookingRequest` rules: dates inside window and free, own car blocked, renter has no lock, `PendingReviewChecker` is clear, email verified; writes booking (rate/totals locked via `PricingCalculator`), reference `VLC-####`, renter contact doc, `expiresAt` = +24 h, audit log, notification to the owner

### 3.B State
- [ ] `SearchCubit` (area, dates, type chip; saves `last_search_area`, `last_type_chip`), `FiltersCubit`, `ResultsBloc`, `CarDetailBloc`, `FavouritesBloc` (single source for hearts, Saved count), `RequestBloc`

### 3.C Screens
- [ ] Renter Home: greeting, search card, type chips, car cards, Explore / Saved tabs, "how it works"
- [ ] Area + date range picker (past days disabled); filters (price min/max, type, transmission, seats, active count, reset)
- [ ] Results with count and empty state
- [ ] Car card (photo, name/year, price, specs, owner rating, area, availability) with heart
- [ ] Car detail: carousel, media screen, specs, features, rules, rules PDF link, owner block (info only), calendar with blocked days + window limit, live price breakdown, long-rental note ("3+ days: RWF 80,000 per day"), terms checkbox, "Request booking"
- [ ] Owner viewing own car: read-only preview (no booking UI)
- [ ] Request review screen (breakdown without platform fee) → confirmation `/booking/:id/requested`
- [ ] `OwnerCarsSection` slot for the public profile
- [ ] Hero transition on car photo; loading skeletons; empty states

### 3.D Rules & indexes
- [ ] `favourites` and booking-create rule tests; indexes for search

### 3.E Tests
- [ ] Unit: search filtering/availability logic, request validation (each failure), favourites toggle
- [ ] Bloc: `FavouritesBloc`, `ResultsBloc`, `RequestBloc`
- [ ] Widget: car card heart toggles; request button disabled until terms ticked

### 3.F Docs & demo
- [ ] Report: search algorithm, request flow, state-management example sections
- [ ] Demo segment C (~2 min): search with filters, heart a car and show **two widgets update** (card heart + Saved count), send a request and show the new `bookings` doc in the console

---

## Phase 4 — Booking decision & payment
**Owner:** ____ · Collections written: `bookings` (pending→approved/declined/cancelled/expired, approved→confirmed, confirmed→cancelled), `bookings/*/private/owner`, `calendarBlocks`, `renterLocks`, `transactions` (charge, refund), `notifications` · Spec §4.1 steps 3–6, §4.4, §5.5–5.6 · Slots: `PendingRequestsCard`, `UpcomingRentalsCard`

### 4.A Domain & data
- [ ] `BookingRepository` (watch my bookings by role, watch one, transitions in transactions/batches)
- [ ] `ApproveBooking`: owner tick required, `PendingReviewChecker`, creates `renterLocks`, writes `calendarBlocks`, declines the car's overlapping pending requests, writes owner contact doc, notifies renter
- [ ] `DeclineBooking` (reason required), `CancelBooking` (until pickup confirmed; refund everything via `LedgerWriter`, free block/lock), `ExpiryEngine` (lazy: pending 24 h, payment deadline = earlier of +24 h and pickup date)
- [ ] `PayBooking`: `MomoGateway.charge`, then `charge` ledger entry, status `confirmed`, contact unlock (rules), notifications; failure keeps `approved` and allows retry
- [ ] `AcknowledgeAgreement`
- [ ] `EffectiveStatus` applied to every list so cancelled-by-lock requests show correctly

### 4.B State
- [ ] `ActivityBloc` (Open / Active / Past), `BookingDetailBloc` (stream), `DecisionBloc`, `PaymentBloc`, `ExpirySweeperCubit` (runs at app start/resume and on activity load)

### 4.C Screens
- [ ] My Activity (renter and owner): Open (action required, pending), Active, Past; grouped by car for owners; quick actions
- [ ] Booking detail: reference, status headline, six-step timeline, car, dates, parties, price rows, payment/caution/agreement status, **locked contact tile** until payment, then phone/email/meeting point; hosts `HandoverSection` (P5) and `PostRentalSection` (P6) slots
- [ ] Owner request detail `/booking/:id/decision`: renter profile info (no contact), "You earn RWF X", "I reviewed their info" tick, approve / decline with reason
- [ ] Payment screen: MoMo 9-digit number, total breakdown, processing, success with reference, failure with retry; deadline countdown
- [ ] Rental agreement (nine sections; late-fee 30%/day text; cancellation text)
- [ ] Cancel flow with confirmation dialog and refund note
- [ ] `PendingRequestsCard` and `UpcomingRentalsCard` slots

### 4.D Rules
- [ ] `validTransition` for your rows of the §5.1 table; lock and calendar rules; contact lock; `transactions` create rules for `charge`/`refund` amounts
- [ ] Demonstrate: contact docs unreadable before payment, readable after

### 4.E Tests
- [ ] Unit: approve conflict (renter already locked), overlap declining, deadline calculation, cancel refund amounts, effective status
- [ ] Bloc: `PaymentBloc` (success/failure/retry), `DecisionBloc`
- [ ] Widget: locked contact tile switches to revealed data

### 4.F Docs & demo
- [ ] Report: booking state machine diagram, lazy expiry and lock design, ledger invariants sections
- [ ] Demo segment D (~2.5 min): owner approves, renter pays, console shows `confirmed` + `charge` row, contact unlocks, **rotate the phone once**

---

## Phase 5 — Handover, return & caution settlement
**Owner:** ____ · Collections written: `bookings` (confirmed→active, active→return, return→review/completed, review→completed), `bookings/*/checklistEntries`, `bookings/*/checklistMedia`, `cautionClaims`, `repairExpenses`, `transactions` (release, platform_fee, payout, refund, claim_deduction, late_fee), `renterLocks` (release at return) · Spec §4.1 steps 7–9, §6.5, §3 late fee · Slot: `HandoverSection`

### 5.A Domain & data
- [ ] `HandoverRepository`, `ClaimRepository`, `RepairExpenseRepository`
- [ ] `ChecklistCubit`: five items each for pickup and return; **photos required**, video optional; uploads via `MediaStorage`; remove media before confirming
- [ ] `ConfirmPickup`: each side confirms separately; the **second** confirmation moves to `active` and releases funds in one batch (`release`, `platform_fee`, `payout` for rentalFee − 2,000), notifies the other side; money stays held until both confirm
- [ ] `StartReturn` / `ConfirmReturn` (both sides); release `renterLocks`; set `returnedAt`
- [ ] `LateFeeCalculator` (ceil to day, 1.3^days compounding, cap with claim ≤ caution); owner can waive/reduce
- [ ] `SettleCaution`: no issue → renter acknowledges → `refund` caution (minus late fee if charged); claim → `cautionClaims` with reason + evidence photos
- [ ] Renter agrees → `claim_deduction` to owner, remainder `refund`; disputes → stays held; owner may re-claim same or lower (never above `originalAmount`) or refund
- [ ] `LogRepairExpense` (amount, description, receipt photo; edit/delete)
- [ ] Completion updates `completedCount` and writes notifications

### 5.B State
- [ ] `PickupBloc`, `ReturnBloc`, `ClaimBloc` (owner + renter views), `RepairExpenseBloc`

### 5.C Screens
- [ ] Pickup checklist `/booking/:id/pickup` with photo/video capture and "waiting for the other side" state
- [ ] Return checklist `/booking/:id/return` with late-fee preview
- [ ] Owner settle screen `/booking/:id/settle` (no issue / claim amount, reason, evidence)
- [ ] Renter claim screen `/booking/:id/claim` (see amount, reason, photos; agree / do not agree)
- [ ] Owner repair-cost screen `/booking/:id/repair-cost`
- [ ] `HandoverSection` for each status inside booking detail

### 5.D Rules
- [ ] `confirmed→active` requires both confirmation timestamps; money entries must match `rentalFee`, `2000`, `cautionFee`; claim ≤ caution; `cautionClaims` and `repairExpenses` blocks; ledger append-only verified

### 5.E Tests
- [ ] Unit: late fee table (100,000 → 130,000 → 169,000 → 219,700), cap logic, release amounts, claim re-claim ceiling, held-balance invariant after each path
- [ ] Bloc: `PickupBloc` (one side only vs both), `ClaimBloc` (agree / dispute / re-claim)
- [ ] Widget: confirm button disabled until ≥ 1 photo attached

### 5.F Docs & demo
- [ ] Report: escrow/ledger worked example, claim flow, late-fee formula sections
- [ ] Demo segment E (~2.5 min): both confirm pickup (release in console), return, claim and agree, repair cost logged

---

## Phase 6 — Reviews, notifications & finances
**Owner:** ____ · Collections written: `reviews` (+ rating aggregates on `users`/`vehicles`), `notifications` (read/clear), reads `transactions`/`repairExpenses` · Spec §5.7, §7, §8.1, §8.3 · Slots: `FinancesCard`, `ReviewsPreviewSection`, `PostRentalSection`

### 6.A Reviews
- [ ] `ReviewRepository`: create/edit only (never delete); id `bookingId_authorId_subjectType`; aggregates updated in the same batch
- [ ] `PendingReviewChecker` real implementation (replaces the Phase 0 stub): completed bookings missing required reviews (owner→renter; renter→owner and renter→car)
- [ ] Screens: write/edit reviews `/booking/:id/review` (stars + comment, both mandatory), car reviews `/car/:id/reviews`, user reviews `/user/:id/reviews` and `/profile/reviews`
- [ ] `PostRentalSection` ("review due" prompts) and `ReviewsPreviewSection`; rating widgets reused from the kit

### 6.B Notifications
- [ ] `NotificationsBloc` (stream, unread count, mark read, mark all read, delete/clear), deep link into the booking
- [ ] Icon per type; unread dot; bottom-nav badge; on/off setting read from `notifications_enabled`
- [ ] Event types: request received/approved/declined/expired, payment deadline approaching, pickup/return confirmed by the other side, claim changed, late fee applied, review due

### 6.C Owner finances (spec §7)
- [ ] `FinancesRepository` computing **Total earned** and **Total losses** from `transactions` + `repairExpenses` (§5.2), for *This month* / *This year*
- [ ] Finances screen: period toggle, two tiles, Chart/Table toggle, per-car list with share bar
- [ ] Chart (`fl_chart`): paired bars per day (month) or per month (year), two colours + legend, tap shows amounts, empty periods blank
- [ ] Table: newest first, latest 5 rows + "View all transactions" → full page; total equals the tiles
- [ ] Car finances screen (same layout filtered) and its transactions page
- [ ] `FinancesCard` slot (this month earned / losses) opening the screen
- [ ] Empty states; RWF no decimals; no export

### 6.D Renter payment history
- [ ] `/renter/payments`: payment, caution refund, claim deduction, late fee, cancellation refund — date, booking, amount, status

### 6.E Rules & indexes
- [ ] `reviews` (no delete, edit by author only), `notifications` blocks; indexes from §4.4
- [ ] Rating aggregate update guarded in rules (aggregates change only alongside a matching review)

### 6.F Tests
- [ ] Unit: earned/loss calculation incl. the caution offset, period bucketing, table total = tiles, pending-review detection, rating average
- [ ] Bloc: `FinancesBloc` (period/view toggle), `NotificationsBloc`, `ReviewBloc`
- [ ] Widget: finances table shows 5 rows and the "View all" link only when > 5

### 6.G Docs & demo
- [ ] Report: finances formulas, reviews rule, notifications sections
- [ ] Demo segment F (~2 min): leave both reviews, edit one, notification deep link, finances chart ↔ table, payment history

---

## Final team checklist (everyone, last week — not a phase)
Do **not** leave these to the last night: schedule them in advance.
- [ ] Integration pass on `main`: seed → full happy path → cancel path → claim path on a physical phone
- [ ] Every screen checked on small + large phone and **landscape** (no overflow)
- [ ] `dart format .` and `flutter analyze` = 0 issues (screenshot both)
- [ ] `flutter test --coverage` ≥ 70% (screenshot summary); all tests pass
- [ ] Release APK built (`flutter build apk --release --dart-define-from-file=env.json`), Google Sign-In verified on release build
- [ ] README finished: setup, screenshots, architecture, seed accounts
- [ ] Git balance check: every member within the target share, PRs reviewed, no dump commits
- [ ] Contribution Tracker complete and matches Git stats
- [ ] Demo video: two rehearsals, then one continuous ≥ 1080p take (phone + Firebase Console visible), 10–15 min
- [ ] Report PDF: `Group#_Final_Project_Submission.pdf`, Times New Roman 12/14, repo link, ERD, rules explanation, testing screenshots, AI-use disclosure (< 40%), citations ↔ references
- [ ] Repo accessible to reviewers; `env.json` included in the submission package
