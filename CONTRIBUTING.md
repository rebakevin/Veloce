# Contributing

The design lives in `docs/resources/TECHNICAL.md`; the plan in `docs/resources/TODO.md`;
how to write code in `docs/code-conventions/`.

## Branches
`phaseN/<feature>`, one task group per branch, rebased on `main` often. No direct
pushes to `main`: open a PR, get 1 approving review and green CI.

## Commits
Small and frequent, imperative, with a prefix: `feat(vehicles): add tier validation`.
Prefixes: `feat`, `fix`, `test`, `docs`, `refactor`, `chore`. No last-minute dumps.

## Review ring
P1 → P2 → P3 → P4 → P5 → P6 → P1 (the Phase 0 owner reviews alongside P1).

## Contract changes
Anything shared (ERD, entities, enums, core services, route names) goes in a PR
titled `contract:` and needs a review from every phase owner. Update in the same PR:
the ERD in `docs/resources/TECHNICAL.md`, `lib/core/constants/firestore_fields.dart`,
the model, `tool/seed/seed.js`, `firestore.rules` and `firestore.indexes.json`.

## You own
`features/<yours>/`, your `*_injection.dart`, `*_routes.dart` and your labelled
block in `firestore.rules`. Do not edit another phase's files.

## Before you push
```bash
dart format lib test
flutter analyze
flutter test
```

## Secrets
Never commit `env.json`, `key.properties`, keystores or service-account JSON.
