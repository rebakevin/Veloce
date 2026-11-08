# File structure

## Layout

Feature-first at the top level. Inside each feature, layers as folders:

```
lib/
  main.dart                     Initialisation only
  app.dart                      Composition root: providers, MaterialApp, auth gate
  core/                         Cross-cutting and tiny: theme, env, constants shared by all features
  features/
    reports/
      reports.dart              Barrel: the feature's public API
      domain/                   Entities, value objects, rules, repository contract
      application/              Cubits and states
      data/                     Repository implementation, Firestore mapping
      presentation/             Screens and widgets
    auth/ report_form/ notifications/ profile/
  shared/widgets/               Truly generic widgets (loading, error, empty views)
test/                           Mirrors lib/ exactly
```

- A small feature may skip layers it does not need. Do not create empty folders.
- The layout in `docs/Veloce Specs.md` (section 7) groups models and repositories under `lib/data/`. Prefer placing them in the owning feature. A model used by several features is exported from its owner's barrel.

## Public API per feature

- Each feature has one barrel file (`reports/reports.dart`) that `export`s only what other features may use.
- Other features import the barrel, never a file inside another feature.
- Inside a feature, use relative imports. Across features and for packages, use `package:` imports.

## Shared code

- `core/` and `shared/` stay small and hold only truly cross-cutting concerns (theme, env, generic widgets).
- No `utils`, `common`, `helpers`, `misc`. Put code with the feature that uses it. If two features need it, it belongs to the owner and is exported, or it is genuinely generic and goes in `shared/` with a specific name.

## Files and names

- One public top-level type per file. The file name is the `snake_case` of the type: `ReportsCubit` in `reports_cubit.dart`. A Cubit's state may share its file or live in `*_state.dart`.
- Name classes by role and intent. Avoid `Manager`, `Handler`, `Helper`, `Processor`, `Service` without a qualifier.
- Suffixes: `*Cubit`, `*State`, `*Repository`, `*Screen` (routable page), `*View` or plain noun (embedded widget), `*Mapper` where mapping is not on the model.
- Test files end in `_test.dart` and mirror the path of the file under test.

## Repo root

- Root holds only build files, platform folders, `README.md`, config (`firebase.json`, rules, indexes) and CI.
- Docs go in `docs/`. Scripts go in `scripts/`. Deployment and infrastructure files go in `deploy/` if they appear.
- Generated files (`firebase_options.dart`, `*.g.dart` if ever used) are committed only when the tooling expects it. Never commit `.dart_tool/` or `build/`.
