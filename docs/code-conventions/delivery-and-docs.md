# Delivery and documentation

## Delivery

- Trunk-based flow with short-lived branches.
- CI gates: `flutter pub get`, `dart format --set-exit-code`, `flutter analyze`, `flutter test`. A red build blocks merge.
- Builds are repeatable: `flutter build apk` from a clean checkout plus `.env` produces the app.
- Firestore rules and indexes are deployed from the repo (`firebase deploy --only firestore`) in the same change as the code that needs them. Deploy rules before shipping the client that depends on them, and keep changes backward compatible so older installed clients keep working.
- Separate deploy from release with feature flags for risky behavior (see [configuration.md](configuration.md)).
- Roll back is one step: revert the commit and redeploy. Do not ship a client change that cannot coexist with the previous rules.

## Commits and pull requests

- Conventional, descriptive commit messages that explain why. Match the existing short lowercase style in the log.
- Commit as the repository owner only. No tool co-author lines.
- Split work into several logical commits: scaffold, config, feature code, scripts, docs. Moves and renames go in separate commits from logic changes (see [refactoring.md](refactoring.md)).
- Never stage generated or ignored files (`.dart_tool/`, `build/`, `.env`).
- PR descriptions say what changed and why, and how it was verified.

## Documentation

- `README.md`: what the app is, how to set it up, run it and test it.
- `docs/`: specs, database design, the phased plan, code conventions, ADRs, runbooks (for example seeding staff).
- Docs live next to the code and change in the same commit as the behavior they describe.
- Record significant decisions as ADRs in `docs/adr/`: context, decision, consequences. Examples: Supabase for photo storage, Cubit over other state managers, no Cloud Functions.
- Update `docs/Veloce Todo.md` checkboxes when tasks finish.
- Update `CLAUDE.md` when commands, architecture or conventions change.
