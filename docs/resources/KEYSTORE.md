# Keystore, fingerprints and Firebase sign-in: to do

Evening checklist for Phase 0 (`TODO.md` section 0.B). Nothing here contains a secret; the keystore password is only in `android/key.properties` on Kevin's Mac.

## Why this matters

- Google Sign-In only works for an app whose **signing fingerprint (SHA-1 and SHA-256)** is registered in Firebase for `rw.veloce.veloce`.
- Each computer has its own **debug key**, so every teammate who runs the app from their own machine needs their debug fingerprint registered.
- The demo uses a **release APK** on a physical phone. It must be signed with **one shared release key**, and that key's fingerprint must be registered. Otherwise Google login fails only in the release build.
- The release key is a secret. Anyone who holds it can sign an app Firebase treats as ours. Never put it in git.

## Already done

- Release keystore created at `~/veloce-keystore/veloce-release.jks` (outside the repo, alias `veloce`).
- `android/key.properties` points to it and is git-ignored.
- `android/app/build.gradle.kts` signs release builds with it, and falls back to the debug key when `key.properties` is missing.
- A release APK built successfully with it.
- Registered in Firebase (4 fingerprints): Kevin's debug SHA-1 and SHA-256, and the release SHA-1 and SHA-256.

Release fingerprints (public, safe to share):

```
SHA1:   21:0E:DD:2B:5C:46:60:6B:94:22:82:E2:E8:10:8D:3F:64:9D:B8:1D
SHA256: 7C:DA:EA:0E:26:6E:9D:4D:DD:BE:26:61:49:52:BB:EF:85:F9:9F:28:19:35:E0:6E:64:25:B6:DA:72:55:2E:86
```

## To do

### 1. Enable Authentication (console, needed first)
- [ ] Firebase console → project `veloce-1fe08` → **Authentication → Get started**
- [ ] Enable **Email/Password**
- [ ] Enable **Google**, and set the project support email
- [ ] Tell Claude, so it re-downloads `google-services.json` (it only gains the Google OAuth client once Google is enabled) and commits it

### 2. Share the release keystore with the team (private channel only)
- [ ] Send `~/veloce-keystore/veloce-release.jks` and `android/key.properties` through a private channel (never git, never a public chat or email attachment you cannot revoke)
- [ ] Tell teammates to save the `.jks` anywhere, and set `storeFile` in **their** `android/key.properties` to its path
- [ ] Back the keystore up somewhere safe. If it is lost, the same key cannot be recreated.

### 3. Collect the other 5 debug fingerprints
- [ ] Ask each teammate to run:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep -E "SHA1|SHA256"
```

- [ ] Collect SHA-1 and SHA-256 from each of the 5 (track them below)
- [ ] Register each pair: send the values to Claude, or run

```bash
firebase apps:android:sha:create 1:765515995845:android:1d14d2ba029732153daeac <SHA> --project veloce-1fe08
```

or paste them in Firebase console → Project settings → Your apps → Add fingerprint.

| Teammate | SHA-1 received | SHA-256 received | Registered |
| --- | --- | --- | --- |
| Kevin | yes | yes | yes |
| 2 | | | |
| 3 | | | |
| 4 | | | |
| 5 | | | |
| 6 | | | |

### 4. Share Firebase access
- [ ] Firebase console → Project settings → **Users and permissions** → add the teammates (Editor is enough)

### 5. Verify
- [ ] `flutter build apk --release --dart-define-from-file=env.json` works on a teammate's machine with the shared keystore
- [ ] Google Sign-In works in a **release** build on a physical phone (do this once Phase 1 adds the Google button)

## When done

Tell Claude, and it will tick in `TODO.md`:
- "Collect debug SHA-1/SHA-256 from all 6 machines + the release keystore"
- "Enable Email/Password and Google providers; add a team keystore"
- "Share project access with all members"

Related: `README.md` (Google Sign-In section), `TECHNICAL.md` §2.3.
