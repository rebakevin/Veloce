# Pixel 8

One-time setup: Settings > About phone > tap **Build number** 7 times, then Developer options > turn on **USB debugging**.

## Run while developing

```bash
flutter run -d <device-id> --dart-define-from-file=env.json
```

Find the id with `flutter devices`.

## Install so it works without the cable

```bash
flutter build apk --release --dart-define-from-file=env.json
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Run both again to update the app. The dev button only exists in debug builds, so it is not in this release APK. For a cable-free build that keeps it, use `flutter build apk --debug --dart-define-from-file=env.json` and `build/app/outputs/flutter-apk/app-debug.apk`.
