# Veloce

Peer-to-peer car rental for Kigali. Renters ask, owners approve who drives. Flutter
(Android and iOS only), Firebase Auth and Firestore, Supabase Storage for files.

Design: `docs/resources/TECHNICAL.md` · Plan: `docs/resources/TODO.md` · Spec:
`docs/resources/SPECS.md` · Code rules: `docs/code-conventions/`

## Set up

1. Flutter stable (Dart ^3.13) and an Android emulator or phone.
2. `flutter pub get`
3. `cp env.example.json env.json` and fill in the Supabase values (the team shares the real file privately).
4. Run with the config: `flutter run --dart-define-from-file=env.json`
5. Seed the dev project once (see `tool/seed/README.md`), then open `/dev-login` (debug builds) and pick an account.

`lib/firebase_options.dart` and `android/app/google-services.json` are committed on
purpose: Firebase client config is public and protected by the security rules.

### Google Sign-In
Every machine that builds a debug app must have its SHA-1 and SHA-256 registered in
Firebase (Project settings → Your apps → `rw.veloce.veloce`):

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep -E "SHA1|SHA256"
```

### Firebase and Supabase
- Rules and indexes: `firebase deploy --only firestore --project veloce-1fe08`
- Storage buckets and policies: run `tool/supabase/storage.sql` in the Supabase SQL editor.

## Architecture

Feature-first, three layers per feature (`domain`, `data`, `presentation`), shared contracts in
`lib/core`, composition root in `lib/app`. Cubits and blocs only; `setState` is banned.
See `docs/adr/0001-phase-0-decisions.md` for where this deviates from the generic conventions.

```
lib/
  main.dart            initialise Firebase, Supabase, DI; runApp
  app/                 router, DI, root widget, owner dashboard
  core/                entities, enums, models, services, theme, validators, widget kit
  features/<name>/     <name>.dart (barrel), <name>_routes.dart, <name>_injection.dart
test/                  mirrors lib/ (plus architecture/ import rules)
tool/seed/             Admin SDK seed script
tool/supabase/         storage.sql
```

## Commands

```bash
flutter analyze
dart format lib test
flutter test
flutter test --coverage
flutter build apk --release --dart-define-from-file=env.json
```
