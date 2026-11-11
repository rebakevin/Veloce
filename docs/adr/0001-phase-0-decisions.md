# 0001. Phase 0 decisions

Date: 2026-11-09 · Status: accepted

## Context
`docs/code-conventions/` was written generically and `docs/resources/TECHNICAL.md` is the
Veloce-specific design the six-person plan is built on. They disagree in a few places. Phase 0
had to pick one so the other phases can start.

## Decisions

1. **Layers.** Each feature uses `domain / data / presentation` with blocs in `presentation/bloc`
   (TECHNICAL.md §3.2), not a separate `application/` folder. The rule that blocs never import an
   SDK still holds and is enforced by `test/architecture/import_rules_test.dart`.
2. **Barrels.** Each feature exposes one barrel (`<name>.dart`). Other features import only the
   barrel; the architecture test fails otherwise. Inside `core/`, relative imports are used.
3. **Config.** `--dart-define-from-file=env.json` and a typed `Env` that fails fast (TECHNICAL.md §2.3),
   not `.env` with `flutter_dotenv`. `env.example.json` documents the keys.
4. **Route names** live in `core/navigation/route_names.dart` (not `app/`), so features can link to
   each other without depending on the composition root.
5. **No `utils/`.** Validators, formatters and layout helpers live in `core/validation`,
   `core/formatting` and `core/layout`.
6. **Tests without `fake_cloud_firestore`.** It cannot resolve against `cloud_firestore` 7 and
   `equatable` 3. Repositories are tested through interfaces and `mocktail`; rules need the emulator.
7. **`MediaStorage.delete` is best effort.** The anon role has no delete policy
   (TECHNICAL.md §7), so a delete may leave the file. Replacing a file uploads a new path.
8. **Image compression** happens at pick time (`image_picker` `imageQuality: 80`), not inside
   `MediaStorage`, which only uploads bytes.
9. **Four seeded renters**, not three: a renter holds one lock (approved, confirmed or active), so a
   pending request needs a renter with none.
10. **Generated code.** Entities, models, enums and `FirestoreFields` were generated from the ERD once and
    are now hand-maintained. Change them together in a `contract:` pull request.
11. **Shells follow the mock.** `docs/resources/MOCK.html` has one bottom bar for both roles: a side
    action, three tabs (Home, My Activity, Profile) and a notifications bell. Notifications and My cars are
    full-screen pages, not tabs. Six screens the mock has were missing from §10 and were added
    (`/car/:id/dates`, `/owner/cars/:id`, `.../published`, `.../requests`, `/profile/licence/change`,
    `.../verify`). Placeholders carry the mock's outgoing links (`PlaceholderLink`).

## Consequences
Phases 1–6 follow TECHNICAL.md's layout. If the team prefers the generic conventions, decisions 1–3
are the ones to revisit.
