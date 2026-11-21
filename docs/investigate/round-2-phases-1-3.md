# Round 2 audit: Phases 1-3 (auth, profile, vehicles, discovery)

Scope: `lib/features/auth`, `profile`, `vehicles`, `discovery`, re-read after the round 1 fixes. Method: read the code (not the fix logs), then the TODO lines of Phases 1-3, then a widget review of the screens.

Commands: `flutter analyze` reports no issues. `flutter test test/features/auth test/features/profile test/features/vehicles test/features/discovery` passes (418 tests). `flutter test test/app test/architecture test/core` also passes (115). The Firestore emulator was not run, so rules findings come from reading `firestore.rules`.

## Round 1 fixes verified by reading the code

| Round 1 | Verdict |
| --- | --- |
| F1-02 switch without sign-out | Works for email accounts. Google mismatch path still signs the user out (R2A-03). |
| F1-03 unverified email | Reload on restore and the profile banner work. Publish and pay are still not gated (R2A-05). |
| F1-04, F1-08, F0-01 | Work as logged. `DevSignIn` is only registered under `kDebugMode`; `authRedirect` bypass is gated; no DI mismatch (analyzer and router test green). |
| F1-01 eraser | Client reordering is fine for small accounts, still fails for large ones and is untested against rules (R2A-01). TODO box still unticked, correctly. |
| F2-01 `bookingsOf` owner filter | Correct (rules need the `ownerId` filter; DI passes the session). No repository test. |
| F2-03, F2-04, F2-06, F2-07, F2-08, F2-09, F2-15, F2-16 | Work as logged (see R2A-06 and R2A-07 for side effects). |
| F2-05 video, extras | Work. Rules PDF is still absent (R2A-04). |
| F3-01, F3-03, F3-06, F3-07, F3-08, F3-10, F3-11, F3-13 | Work as logged. |
| F3-09 VLC number | Cosmetic only (R2A-10). |

## Findings

### R2A-01 [severity: major] [kind: bug]
- Where: `lib/features/profile/data/firestore_account_eraser.dart:111-122` against `firestore.rules:228-250, 345`
- What: two ways the cascade can still be denied. (a) Split path (plan of 450 or more documents): `children` (calendar blocks, `cautionClaims`, `renterLocks`) are deleted in a batch before their booking, but the rules allow those deletes only when `!existsAfter(booking)` (or the booking is already cancelled/expired/return/review/completed), so any active or pending booking denies the batch and the account can never be deleted. (b) Single-batch path: each booking adds roughly two rules access calls (`bk(id)`, `existsAfter`), vehicles add one, and Firestore caps a batched write at 20 access calls, so an owner or renter with about 10 or more bookings probably gets `permission-denied` even though the rules are correct per document.
- Evidence: read the eraser plan order and the rules. Cap of 20 is Firestore's documented per-request limit for batched writes; not run on the emulator.
- Fix: delete per booking in its own batch (booking + private side + block + claim + lock + checklist docs), per vehicle in its own batch (vehicle + photos + documents), then loose documents (notifications, reviews, transactions, favourites), user last. Add the emulator check from the unticked TODO line.
- Status: fixed (round 2, see fix log)

### R2A-02 [severity: minor] [kind: bug]
- Where: `lib/features/auth/presentation/bloc/auth_bloc.dart:60-80` (`_onUserChanged`)
- What: for an unverified user whose state is `AuthNeedsProfile` or `AuthProfileFailed`, every user event reloads the profile and then dispatches `EmailVerificationRefreshed`, which calls `reload()`. If `reload()` emits on `userChanges()` (it normally does), this loops with a network call each time until the profile exists. The early same-uid return only protects `AuthAuthenticated`.
- Evidence: code trace. Not run on a device.
- Fix: skip the refresh when the current state already has this uid, or only dispatch it once per uid (keep a `_reloadedUid`).
- Status: fixed (round 2, see fix log)

### R2A-03 [severity: minor] [kind: bug]
- Where: `lib/features/auth/domain/usecases/switch_account.dart:80-93`
- What: switching to a Google account that Google restores as a different account first signs that other account into Firebase, then `suspendSession()`. The user ends up signed out on `/welcome` instead of staying on the accounts page with the sign-in sheet, which is the F1-02 symptom for this path. The wrong account is also briefly the session (caches cleared, favourites loaded).
- Evidence: code trace.
- Fix: check the restored account against the target before `signInWithCredential`, or re-sign-in the previous user instead of suspending.
- Status: fixed (round 2, see fix log)

### R2A-04 [severity: major] [kind: gap]
- Where: `lib/features/vehicles/domain/usecases/publish_vehicle.dart:123` (`rulesFileUrl: null`), `lib/features/vehicles/domain/entities/wizard_draft.dart:70,101,168,195`, `lib/features/discovery/presentation/pages/car_detail_page.dart:296`, `booking_review_page.dart:123`
- What: the optional rules PDF does not exist. `WizardDraft.rulesPdf` is never set or uploaded and `rulesFileUrl` is always null, so the "Open rental instructions PDF" buttons on car detail and the review page can never appear. TODO 2.C ("Step 5 rental rules (+ optional PDF)") and 3.C ("rules PDF link") are ticked but the feature is unreachable. `rulesPdf` is dead state.
- Evidence: `grep rulesPdf lib` shows only the draft class; no picker in `rules_step.dart`.
- Fix: add a file picker dependency and upload via `MediaStorage`, or untick both lines and remove `rulesPdf` and the two dead buttons.
- Status: open (needs human: pubspec has only `image_picker`, which cannot pick a PDF; a `file_picker` dependency is needed. Dead buttons left in place, nothing hidden)

### R2A-05 [severity: minor] [kind: gap]
- Where: `lib/features/vehicles/domain/usecases/publish_vehicle.dart` (no gate), only user of `EmailVerificationGate` is `create_booking_request.dart:31`
- What: TODO 1.B says the unverified-email gate covers request, publish and pay. Only request is gated. An unverified user can publish a car; payment (Phase 4) also has no gate.
- Evidence: `grep EmailVerificationGate lib` shows one use.
- Fix: inject the gate into `PublishVehicle` and the pay use case.
- Status: open

### R2A-06 [severity: minor] [kind: bug]
- Where: `lib/features/vehicles/presentation/pages/my_cars_page.dart:46-53`
- What: pull to refresh awaits `bloc.stream.first`, but `MyCarsLoaded` is Equatable, so a refresh that finds nothing new emits nothing and the spinner stays until the 5 second timeout.
- Evidence: code trace (`Bloc.emit` drops equal states).
- Fix: add a `refreshedAt`/counter prop to the state, or complete the `RefreshIndicator` from an event that carries a `Completer`.
- Status: fixed

### R2A-07 [severity: minor] [kind: bug]
- Where: `lib/features/vehicles/presentation/bloc/my_cars_bloc.dart:60-77`, `documents_bloc.dart:79-89`
- What: `_pauseLapsed` ignores failed writes and still shows the car as paused, while Firestore keeps it published (search hides it anyway because of `docsValidUntil`, so this is a display lie, not a leak). Each stream emission retries the failed writes, and every emission also runs `FindNextRentals` and `FindPrimaryPhotos` (N reads each), so a small status write causes a full reload.
- Evidence: code trace.
- Fix: only mark paused when the write succeeded; skip reloading rentals and photos when the vehicle ids did not change.
- Status: fixed

### R2A-08 [severity: minor] [kind: bug]
- Where: `lib/features/discovery/presentation/bloc/favourites_bloc.dart:50-58, 80-96`
- What: on `FavouritesStarted` (auth change) the loading state keeps the previous user's `favouriteIds` and `cars`, so after an account switch the next user briefly sees the old hearts and Saved list. Hydration is sequential (4 reads per car) and reruns for the whole list on every toggle. A removed car is skipped but its favourite document is never deleted.
- Evidence: code trace. No test covers a uid change.
- Fix: emit an empty `FavouritesLoading()` when the uid changes; hydrate with `Future.wait` and cache details by id; delete the dangling favourite on `NotFoundFailure`.
- Status: fixed

### R2A-09 [severity: minor] [kind: gap]
- Where: `lib/features/discovery/presentation/pages/filters_page.dart:80-84`, `results_page.dart` empty state
- What: Apply is disabled when min is above max but no message says why (the filter cubit knows). The results empty state has no "Reset filters" action even when filters caused the empty list.
- Evidence: code read.
- Fix: show an error text under the price fields; add `actionLabel: 'Clear filters'`.
- Status: open

### R2A-10 [severity: minor] [kind: bug]
- Where: `lib/features/discovery/data/firestore_request_repository.dart:41-47`
- What: the `VLC-####` number is a hash of the booking id modulo 9000. About 110 bookings give a 50 percent chance of two sharing a reference, so the reference shown to users is not unique (F3-09 stays open, as logged).
- Evidence: arithmetic.
- Fix: use a counter document in the batch, or show the reference as `VLC-` plus the last 6 characters of the booking id.
- Status: open

### R2A-11 [severity: minor] [kind: bug]
- Where: `lib/features/vehicles/presentation/widgets/media_step.dart:96-134`, `video_picker.dart`, `update_vehicle.dart:65-80`
- What: video handling gaps. Video bytes are read fully into memory with only a 30 second cap and no size limit. In edit mode an existing video is not shown and cannot be removed (the draft only holds a newly picked one; `copyWith(videoUrl: null)` keeps the old one). On a 320 px wide phone the two-column photo tile (about 140 px) is too narrow for the "Main photo" chip plus two arrow buttons, so they overlap.
- Evidence: code read.
- Fix: check the file length before reading; carry `existingVideoUrl` in the draft with a remove action; stack the chip above the arrows or use one overflow menu.
- Status: partly fixed (existing video shown and removable in edit mode; photo tile chip moved to top; video size limit still open)

### R2A-12 [severity: minor] [kind: bug]
- Where: `lib/features/auth/presentation/pages/welcome_page.dart:128-134`, `vehicles/presentation/widgets/vehicle_card.dart:83-100`
- What: layout risks on small phones. Welcome in portrait puts `actions` in a non-scrolling Column under `Expanded(slides)`, so short screens or large fonts overflow the buttons (landscape is handled with a scroll view). `VehicleCard` header Row puts a non-flexible `StatusChip` ("Paused: documents expired") next to the title column and can overflow at 320 px with a long make/model.
- Evidence: code read; not run at small sizes.
- Fix: wrap `actions` in a `SingleChildScrollView` in both layouts; wrap the chip in `Flexible` or move it under the title.
- Status: partly fixed (VehicleCard chip is Flexible; Welcome page is auth-owned, still open)

### R2A-13 [severity: nit] [kind: bug]
- Where: `lib/features/discovery/presentation/pages/renter_home_page.dart:62-72, 262`, `results_page.dart:83-90`, `availability_calendar.dart:41`
- What: these read `DateTime.now()` directly instead of the injected `Clock`, so "today" cannot be controlled in tests and a day boundary can differ from the bloc's clock. Also dead noise: `if (vehicle.rulesFileUrl == null) const SizedBox.shrink()` in `car_detail_page.dart:317`.
- Evidence: code read.
- Fix: read the clock from `GetIt`; delete the empty branch.
- Status: fixed (discovery and vehicles pages read the injected Clock)

### R2A-14 [severity: nit] [kind: gap]
- Where: `lib/features/reviews/data/pending_review_checker_stub.dart`
- What: `PendingReviewCheckerStub` is no longer referenced anywhere in `lib` or `test`. It is a leftover from Phase 3 (F3-16 said it was left in place on purpose; it is now dead).
- Evidence: `grep PendingReviewCheckerStub` finds only its own file.
- Fix: delete it (reviews owner).
- Status: open

### R2A-15 [severity: minor] [kind: test-gap]
- Where: `test/features/*`
- What: still missing: repository tests (no `fake_cloud_firestore`, so `bookingsOf` owner filter, search and request writes are untested); `AvailabilityCalendar` widget test (including the new return-day rule); `FavouritesBloc` uid change; `MyCarsPage` refresh; account switch at router level; Phase 1 rules in `tool/rules-test`. The eraser test uses a fake doc source, so it cannot catch the rule ordering problem in R2A-01.
- Evidence: listed test files.
- Fix: add the tests above; run the unticked emulator checks (1.E, 2.D, 3.D).
- Status: open

## TODO line check

- 1.E: the cascade and second-account lines are rightly unticked; R2A-01 says the cascade will still fail in some cases.
- 1.B: "unverified-email gate for request/publish/pay" is ticked but only request is gated (R2A-05).
- 2.A: "Photo upload/reorder/delete" is unticked, but reorder now exists in `media_step.dart`; the line can be ticked and its note removed.
- 2.C step 5 "(+ optional PDF)" and 3.C "rules PDF link" are ticked but unreachable (R2A-04).
- 2.C My cars list: all listed elements are now on the card (photo, plate, price, status, availability, next rental, edit, availability, pause, remove).
- 3.C/3.D/3.F: unticked items are emulator or demo work only.

## Checked and fine

- No `setState` in these features; every `TextEditingController` has a `dispose`.
- Loading, empty and error states exist for Home (Explore and Saved), Results, Car detail, My cars, Accounts and Splash (with retry and sign out).
- Router and session: `authRedirect` keeps `/profile/accounts` reachable while the role is loading, then converges to the target's home after a switch.
- DI: constructors match for `AuthBloc`, `FirestoreVehicleRepository`, `MyCarsBloc`, `CarWizardBloc`, `FirestoreAccountEraser`; no unused stubs in `lib/features/vehicles` or `discovery`.

## Counts

blocker 0, major 2 (R2A-01, R2A-04), minor 11 (R2A-02, 03, 05, 06, 07, 08, 09, 10, 11, 12, 15), nit 2 (R2A-13, 14). Total 15.

## Round 2 fix log (auth / profile agent)

- R2A-01: fixed in code, Status: fixed (not run on the emulator). `lib/features/profile/data/firestore_account_eraser.dart` now commits one batch per booking (checklist docs first, then booking + own contact copy + calendar block + caution claim + renter lock that points at it), one per car (photos, documents, received reviews, then the car), then ledger/repair/notification/review rows in chunks of 450, then favourites and private docs, then the user document alone. Tests: `test/features/profile/data/firestore_account_eraser_test.dart`.
- R2A-02: fixed. `auth_bloc.dart` keeps `_reloadedUid` and requests the verified-flag reload once per uid (reset on sign-out). Test in `test/features/auth/presentation/bloc/auth_bloc_test.dart`.
- R2A-03: fixed. `signInWithGoogleSilently` takes `expectedEmail`; the data source returns null before `signInWithCredential` when Google restores another account, so the current session stays. Files: `auth_repository.dart`, `firebase_auth_repository.dart`, `firebase_auth_data_source.dart`, `switch_account.dart`, tests `account_switching_test.dart`, `auth_fakes.dart`.
- R2A-05: open, outside my folders. `EmailVerificationGate` is already exported from `auth.dart`; it still has to be injected into `PublishVehicle` (vehicles) and the pay use case (booking).
- R2A-08 (favourites reset on uid change): lives in discovery `favourites_bloc.dart`, not changed here.
- R2A-12 (welcome page portrait overflow): still open, not touched.

## Round 2 fix log (vehicles/discovery)

- R2A-06: `MyCarsLoaded.refreshCount` (bumped by `MyCarsRefreshRequested`) so a no-change refresh always emits and the indicator finishes. Files: `lib/features/vehicles/presentation/bloc/my_cars_state.dart`, `my_cars_bloc.dart`.
- R2A-07: `_pauseLapsed` marks a car paused only when its write succeeded; the rentals and photo reads are reused when the set of car ids did not change. File: `my_cars_bloc.dart`. (`documents_bloc` was already correct.)
- R2A-08: `FavouritesBloc` emits an empty `FavouritesLoading` when the user id changes, drops in-flight hydrations, hydrates with `Future.wait`, and deletes the favourite of a removed car. File: `lib/features/discovery/presentation/bloc/favourites_bloc.dart`.
- R2A-11: `WizardDraft.existingVideoUrl` (loaded from the car), "Remove video" and "Replace video" in `media_step.dart`, `UpdateVehicle` keeps or clears the video and deletes the old file; "Main photo" chip moved to the top of the tile. Small additive core edit: `Vehicle.copyWith(clearVideoUrl:)` in `lib/core/domain/entities/vehicle.dart`. Files: `wizard_draft.dart`, `load_vehicle_draft.dart`, `update_vehicle.dart`. Not done: size limit before reading video bytes.
- R2A-12: `VehicleCard` status chip wrapped in `Flexible` with a gap.
- R2A-13: `DateTime.now()` replaced by `GetIt.I<Clock>().now()` in `renter_home_page`, `results_page`, `renter_search_form`, `availability_calendar`, vehicles `availability_page`, `document_editor_sheet`, `documents_step`; removed the empty `rulesFileUrl` branch in `car_detail_page`. Widget tests that build these must register a `Clock`.
- R2A-04: not fixed. No PDF picker in `pubspec.yaml` (only `image_picker`); needs `file_picker` plus a rules step control and upload in `PublishVehicle`/`UpdateVehicle`. R2A-10 (VLC reference) not changed.
- Tests: added to `my_cars_bloc_test`, `favourites_bloc_test` (account switch, dangling favourite), `update_vehicle_test` (video kept/removed); `availability_page_test` registers a `Clock`; fakes in `test/features/*/support|domain` extended.
