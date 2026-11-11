# Veloce

## Prerequisites

- Git
- Flutter SDK (stable channel, Dart ^3.13), with `flutter doctor` showing no Android errors
- Android Studio with the Android SDK, plus an Android emulator or an Android phone with USB debugging on
- Java JDK 17 or newer (the one bundled with Android Studio works)
- `env.json` from the team (shared privately)
- Access to the Firebase project `veloce-1fe08` (ask Kevin to add you)

## Set up

1. Clone the repo and open a terminal in it.
2. Run `flutter pub get`.
3. Put `env.json` in the repo root.
4. Run this and send the SHA-1 and SHA-256 lines to Kevin (needed for Google Sign-In):

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep -E "SHA1|SHA256"
```

5. Release builds only: get `veloce-release.jks` and `key.properties` from Kevin, save the `.jks` anywhere, set `storeFile` in `android/key.properties` to its path, and put the file at `android/key.properties`.

## Run the app

1. Start an emulator (or connect a phone), then check it appears as an Android device:

```bash
flutter emulators
flutter emulators --launch Pixel_8
flutter devices
```

2. Run:

```bash
flutter run --dart-define-from-file=env.json
```

3. To sign in as a test user, open `/dev-login` (debug builds only). Password for every seeded account: `Veloce#2026`.
