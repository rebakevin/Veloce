# Architecture

## Feature-first, not layer-first

- Group code by business capability (`auth`, `reports`, `report_form`, `notifications`, `profile`), not by technical kind (`models/`, `screens/`, `cubits/`).
    - Related code is easy to find. Unrelated features can be ignored while working.
    - Design the boundary before creating the folder.
- A feature is not a Firestore collection. A boundary comes from business rules, ownership and change patterns, not from the number of entities. `reports` owns reports, history entries and votes because they change together.
- High cohesion: a feature contains only related code. Changing a feature's internals must not force changes in other features.
- Low coupling: features talk through a small public API (the feature's barrel file, see [file-structure.md](file-structure.md)), never through another feature's internals.
- Cross-feature data types (for example `Report`, `AppUser`) live in the feature that owns them and are exported from its barrel. Other features import the barrel only.

## Dependency direction

Dependencies point inward: `presentation -> application -> domain`. Domain depends on nothing, not on Flutter, Firebase or Supabase.

| Layer | Contains | May import |
|---|---|---|
| `domain` | Entities, value objects, enums, business rules, repository contracts | Dart core only |
| `application` | Cubits, states, use-case logic | `domain` |
| `data` | Repository implementations, Firestore/Supabase adapters, mappers | `domain`, SDKs |
| `presentation` | Screens and widgets | `application`, `domain`, `shared` |

- Screens never touch Firestore, Firebase Auth or Supabase.
- Cubits never import `cloud_firestore`, `firebase_auth` or `supabase_flutter`.
- Business rules (`canEdit(report, user)`, valid status transitions) live in `domain`, not in widgets or Cubits that only push data around.

## Interfaces only where they earn their place

- Not every class needs an abstract contract. Introduce one when:
    - an external system may be replaceable (Supabase Storage behind `PhotoStorage`),
    - a feature must expose a controlled contract to others,
    - different implementations are genuinely required (a fake in tests counts only if the real one cannot run in tests).
- Dart has implicit interfaces. Do not create `abstract class X` plus `class XImpl` for a single implementation.

## Domain-driven design, lightly

- **Entity**: has identity that survives attribute changes (`Report`, `AppUser`).
- **Value object**: defined by value (`Email`, `ReportTitle`, `Priority`). Immutable, validated on construction.
- **Aggregate**: a cluster with one consistency boundary. A `Report` with its history and votes is one aggregate.
- **Ubiquitous language**: names match the business words: report, reporter, triage, status, priority, "me too".
- Reference other aggregates by id (`reporterId`), not by embedding the object.
- Change one aggregate per write. Firestore batches that touch several documents must belong to one aggregate or one use case (see [data-and-firestore.md](data-and-firestore.md)).

## Wrap every external system

- Firebase Auth, Firestore, Supabase and `image_picker` sit behind our own repository or adapter. SDK types (`User`, `DocumentSnapshot`, `StorageException`) stop at the adapter and never appear in domain, Cubits or widgets (anti-corruption layer).
- Adapters translate SDK errors into our own error types.

## Composition root

- Wiring lives in one place: `app.dart` (providers) and `main.dart` (initialisation). Business code never constructs its own dependencies or reads global singletons such as `FirebaseFirestore.instance`.
- Repositories are created at the root and provided with `RepositoryProvider`. Cubits are created with `BlocProvider` at the narrowest scope that needs them.

## Decisions and scale

- Record significant decisions as ADRs in `docs/adr/`. The Supabase-instead-of-Firebase-Storage choice is the first one.
- Start as a single app with clean feature boundaries. Split into packages only for a concrete reason (a second app, independent ownership).
