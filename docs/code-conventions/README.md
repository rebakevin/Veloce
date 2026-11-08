# Code conventions

How we keep the Veloce codebase clean as it grows. Written for Dart and Flutter with Cubit (`flutter_bloc`), Firebase Auth, Cloud Firestore and Supabase Storage.

Read only the files relevant to the task. `CLAUDE.md` maps tasks to files.

## Scalability dimensions

1. **Codebase**: the code can grow without becoming incomprehensible.
2. **Team**: several developers work independently without stepping on each other.
3. **Delivery**: changes are easy to test, ship and roll back.

## Index

| File | Covers |
|---|---|
| [architecture.md](architecture.md) | Feature-first modules, boundaries, dependency direction, DDD, adapters, composition root |
| [principles.md](principles.md) | SOLID, composition, DRY, KISS, YAGNI, immutability, illegal states, value objects |
| [file-structure.md](file-structure.md) | Folders, barrels, naming, test layout, repo root |
| [state-management.md](state-management.md) | Cubits, states, repositories, streams, what screens may do |
| [ui-widgets.md](ui-widgets.md) | Widget design, `build`, theming, forms, async and `BuildContext`, performance |
| [data-and-firestore.md](data-and-firestore.md) | Firestore and Supabase: writes, batches, queries, indexes, rules, schema evolution |
| [models-and-mapping.md](models-and-mapping.md) | Domain models vs wire maps, `fromMap`/`toMap`, validation at the boundary |
| [error-handling.md](error-handling.md) | Exceptions, results, retries, timeouts, resilience |
| [testing.md](testing.md) | Test pyramid, Cubit tests, widget tests, rules tests, architecture checks |
| [security.md](security.md) | Auth, authorization, rules, secrets, input handling |
| [configuration.md](configuration.md) | `.env`, typed config, flags, fail-fast |
| [observability.md](observability.md) | Logging, diagnostics, crash reporting |
| [code-quality.md](code-quality.md) | Naming, comments, small functions, nulls, lints, formatting |
| [delivery-and-docs.md](delivery-and-docs.md) | Git flow, CI, commits, documentation, ADRs |
| [anti-patterns.md](anti-patterns.md) | What to look for and avoid |
| [refactoring.md](refactoring.md) | Behavior-preserving change rules |

## How this relates to the project plan

`docs/Veloce Specs.md` and `docs/Veloce Database Design.md` say **what** to build. These files say **how** to write it. If they disagree on structure, the conventions win, except where the Database Design is the authority on data (field names, rules, batches).
