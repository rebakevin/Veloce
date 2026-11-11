# Report draft: authentication, validation, preferences and account switching (Phase 1)

Raw material for the final report. Sources: `docs/resources/TECHNICAL.md` (§6, §8.2, §9), `lib/features/auth`, `lib/features/profile`, `lib/core/navigation/auth_redirect.dart`, `firestore.rules`. Rewrite in the team's own words before submission, and cite the references used.

Status note: everything below is implemented and covered by unit, bloc and widget tests where listed in `TODO.md` 1.F. Nothing here has been verified against the live Firebase project yet. Items marked "implemented, to be verified on device" (Google sign-in, Firestore writes from a device, the rules with a second account) must be checked and the note removed before submission.

## 1. Authentication

| Method | How it works in the code |
| --- | --- |
| Email and password | `RegisterWithEmail` creates the Firebase user, then `FirestoreRegistrationStore` writes `users/{uid}`, its `private` documents and an audit entry in one atomic write. `LoginWithEmail` signs in. Logout is `SignOut` through `AuthBloc`. |
| Google | `SignInWithGoogle` signs in with the Google ID token. If `users/{uid}` does not exist yet the state is `AuthNeedsProfile` and the user goes to role choice and the document steps (`CompleteGoogleRegistration`). A returning Google user goes straight Home. Implemented, to be verified on device. |
| Simulated OTP | `VerificationSim` (behind `VerificationProvider`) generates a 6-digit code per phone number. The register flow's step 3 shows it in a SnackBar ("Demo code for ..."). A wrong code returns "That code is not correct. Please try again." and `shouldSucceed = false` forces the failure and retry state. It is a simulation: no SMS is sent. |
| Email verification | `SendEmailVerification` sends the Firebase link. `VerifyEmailPage` has a resend button, and `AuthBloc` handles `EmailVerificationRefreshed` by reloading the Firebase user so `isEmailVerified` is current. |
| Password reset | `ForgotPasswordCubit` calls `SendPasswordReset` (`sendPasswordResetEmail`) from the forgot-password page. |
| Session restore | `AuthBloc` subscribes to the Firebase user stream on `AuthStarted`. The first event carries the user Firebase persisted, and the bloc then reads `users/{uid}` for the role. `SplashPage` waits for that and routes with `authDestination`. |

### Session states and routing

`AuthBloc` states: `AuthUnknown` (splash), `AuthUnauthenticated`, `AuthAuthenticated(user, account)` (role from the profile), `AuthNeedsProfile` (signed in, no profile yet) and `AuthProfileFailed` (profile read failed, retry or sign out). A stale profile read never overwrites a newer state (a generation counter). On every sign-out `AuthBloc` runs `clearCaches` so no cached profile, vehicle or booking outlives the session.

`authRedirect` (pure function in `lib/core/navigation/auth_redirect.dart`, unit-tested) decides every navigation:

- Signed out: any non-auth page goes to `/welcome`. Splash is skipped when the onboarding was seen: `authDestination` sends a signed-out user to `/login` instead of `/welcome`.
- Signed in with a role: auth pages redirect to that role's Home. The register flow stays reachable so a signed-in user can add another account.
- Role confinement: `/owner/...` only for owners, `/renter/...` only for renters; anyone else is sent to their own Home.
- Signed in without a role yet (registration or restore in progress): held on the auth pages or splash, except `/profile/accounts`, which the switcher needs.
- Dev tools routes are exempt.

### `EmailVerificationGate`

Unverified users are not blocked by the router: they can browse. `EmailVerificationGate` (`lib/features/auth/domain/email_verification_gate.dart`) reads `AuthSession.isEmailVerified` and exposes `check()` (an `AppFailure` or `null`) and `require()` (a `Result<void>`). Later phases call it at the start of sending a request, publishing a car and paying, and show "Verify your email address first. We sent you a link when you signed up." The gate exists and is tested in Phase 1; the three call sites arrive with Phases 2 to 4. Google users are reported as verified by Firebase.

## State management example

`AuthBloc` is the app-wide session bloc. Events: `AuthStarted`, `AuthUserChanged`, `AuthProfileRefreshed`, `EmailVerificationRefreshed`, `SignOutRequested`. It depends on use cases and the `RegistrationStore` interface, never on Firebase directly.

```
Firebase user stream ──AuthUserChanged──▶ AuthBloc ──▶ AuthUnknown
                                              │         → AuthUnauthenticated
                                              │         → AuthAuthenticated(user, account)
                                              ▼         → AuthNeedsProfile / AuthProfileFailed
                                   RouterRefreshListenable → authRedirect
```

The router listens to the bloc stream and re-runs `authRedirect` on every state, so login, logout, restore and role changes need no manual navigation. The same user with a refreshed token or verified flag keeps the loaded profile instead of reading Firestore again. Pages get their own route-level blocs (`LoginBloc`, `RegisterBloc`, `ForgotPasswordCubit`, `VerifyEmailCubit`) so they are disposed with the route.

## 2. Validation

- **Client-side validators** live in `lib/core/validation/validators.dart` (`Validators`): required text, email, password (at least `AppConstants.minPasswordLength` characters with a letter and a digit), Rwandan phone (`07[2389]` + 7 digits), MoMo number, date of birth (18+), National ID (16 digits), licence number and expiry. Each returns a user-facing message or `null`.
- **Inline errors**: forms show the message under the field. `LoginBloc` validates before it calls any use case and emits `LoginStatus.invalid` with `emailError` / `passwordError`; the register steps do the same per step.
- **Blank submissions are blocked**: an empty email gives "Enter your email address.", an empty password "Enter your password." and the use case is never called. Submitting is ignored while a request is in flight.
- **`FirebaseAuthException` mapping** (`mapAuthFailure`): `wrong-password`, `invalid-credential`, `user-not-found` and `invalid-login-credentials` share one message ("Wrong email or password.") so the app never reveals whether an account exists. Others: `invalid-email`, `weak-password`, `email-already-in-use`, `account-exists-with-different-credential`, `too-many-requests`, `user-disabled`, `requires-recent-login`, `network-request-failed`, `operation-not-allowed`. Google cancel or interruption gives "Google sign-in was cancelled." and a configuration problem gives "Google sign-in is not set up on this device. Use email instead." Unknown errors go through the shared failure mapper, which logs once and shows a generic message.
- **Firestore rules for `users`** (see "How the rules protect data").

## 3. Preferences

`PreferencesService` wraps `shared_preferences` with five typed keys. Three are used in Phase 1; the other two are reserved for Phase 3.

| Key | Used in Phase 1 | Written by | Restored on launch by |
| --- | --- | --- | --- |
| `theme_mode` (`system`, `light`, `dark`) | yes | `ThemeCubit.select` from the Settings theme selector | `ThemeCubit` reads it as its initial state, and `MaterialApp.router` uses it as `themeMode` |
| `notifications_enabled` (bool, default `true`) | yes | `SettingsCubit.setNotificationsEnabled` (the Settings switch) | `SettingsCubit` initial state. Phase 6 reads it. |
| `onboarding_seen` (bool, default `false`) | yes | `WelcomePage` marks it on the last slide or on skip | `SplashPage` passes it to `authDestination` |
| `last_search_area` | no (Phase 3) | `SearchCubit` | `SearchCubit` |
| `last_type_chip` | no (Phase 3) | `SearchCubit` | `SearchCubit` |

Changing the theme applies immediately, is saved, and survives a force-stop and relaunch (checked by the unit tests; to be confirmed in the demo on device).

## 4. Account switching

Spec §8.2 asks for switching between accounts on one device without typing the password again.

- **Linked accounts** are stored by `SecureLinkedAccountStore` in `flutter_secure_storage` (Keychain on iOS, Keystore on Android). One JSON entry (`linked_accounts`, encoded by `LinkedAccountCodec`) holds uid, email, name, role and auth type. Each email account's password is a separate key (`linked_password_<uid>`) and never appears in the JSON. Google accounts store no credential.
- **Add account**: `LinkCurrentAccount` saves the signed-in account (email accounts need the password re-entered once) after reading the role and name from `users/{uid}`.
- **Switch** (`SwitchAccount`): suspends the Firebase session (the linked list is kept), then signs the target in.
  - Email account: re-sign-in with the stored password.
  - Google account: a silent Google re-sign-in; it must return the same uid as the target.
- **Session-expired fallback**: the outcome is `SwitchOutcome.signInRequired` when the stored password is missing or rejected (a `ValidationFailure`), when Google needs interaction, or when Google restores a different account. `AccountsBloc` then shows the sign-in form (email) or the Google chooser so the user signs in again. Network and other technical errors come back as failures with a message, not as this outcome.
- **After a switch**: the caller resets route-level blocs and navigates to the new role's Home; `authRedirect` keeps `/profile/accounts` reachable while the profile is loading.
- **Remove from this device**: `RemoveLinkedAccount` deletes the list entry and the stored password after a confirmation dialog. The Firebase account itself is untouched.
- **Limitations**: the stored password is kept on the device until the account is removed, and a password changed elsewhere sends the user back to the sign-in form. Google switching depends on the platform's silent sign-in, so it may ask the user to choose the account. Only one Firebase session is active at a time (the secondary-`FirebaseApp` alternative in TECHNICAL.md §6.4 was not used). Implemented, to be verified on device with two real accounts.

## How the rules protect data (`users`)

`users/{uid}` can be read by any signed-in user because it holds only public fields (name, photo, role, rating aggregates, `verified`). It can be created only by its owner with a role of `renter` or `owner` and all rating counters at zero, so nobody starts with a fake rating. An update is allowed only for the owner and only if `role`, `verified`, `ratingAvg`, `ratingCount` and `completedCount` are unchanged, so the role is immutable and rating fields can only be changed by the review flow's own rules. Deleting a user is denied. Everything private (contact details, date of birth, licence, owner identity, payout) lives in `users/{uid}/private/{doc}`, because rules cannot hide single fields, and is readable and writable only by that user. A second signed-in account therefore sees the public profile but gets a permission error on the private documents. The rules are written; verifying this with a second account on the real project is still to do (`TODO.md` 1.E).

## Demo segment A (about 3 minutes)

Steps from `TODO.md` 1.G. Implemented, to be verified on device before recording.

- [ ] Cold start (app killed): splash, then welcome or login (0:15)
- [ ] Register a new account: role, details, simulated OTP (read the code from the SnackBar), welcome (0:50)
- [ ] Log out, then log in with the same credentials (0:25)
- [ ] Google sign-in (0:25)
- [ ] Validation error: submit the login form blank, then with a bad email; show the inline messages (0:20)
- [ ] Settings: change the theme, force-stop the app, relaunch, show it persisted (0:30)
- [ ] Account switcher: add a second account, switch without a password, show the Renter / Car owner labels and the current mark; optionally remove one (0:35)

## Still to add by hand

- Screenshots: login with errors, OTP step, verify-email page, settings theme, accounts page, Firestore console `users` documents.
- Result of the second-account check on the private documents, and the live Google sign-in result.
- Reference list (Firebase Auth, Google Sign-In, `flutter_secure_storage`, `shared_preferences`).
