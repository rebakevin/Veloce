# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project state

Veloce is a Flutter/Dart app (Android and iOS only). Phase 0 is in place: shared contracts in `lib/core`, every route as a placeholder, the `/dev-login` page and the seed script. See `README.md` for setup and `docs/adr/0001-phase-0-decisions.md` for where the layout differs from the generic conventions. Run with `flutter run --dart-define-from-file=env.json`.

## Workflow: read `docs/WORKING.md`

`docs/WORKING.md` describes how a task session runs: read the phase, check whether its sections can run in parallel (ask the user before launching any subagent; work sequentially otherwise), verify, tick the finished boxes in `docs/resources/TODO.md`, and at the end of the session ask the user whether to commit, showing the commit groups and confirming no co-author is added.

## Code conventions: read before implementing

**Before writing or changing any code, read the relevant files in `docs/code-conventions/` first.** They define how code is structured here, and following them is mandatory to keep the codebase clean. Start with `docs/code-conventions/README.md` (the index), then read every file whose task matches below. When a task touches several areas, read all of them. Do not skip this for "small" changes.

| If you are about to... | Read |
|---|---|
| Add a feature, folder, module or cross-feature dependency | `architecture.md`, `file-structure.md` |
| Create or rename files and folders, add a barrel export | `file-structure.md` |
| Write a Cubit, state, or subscribe to a stream | `state-management.md` |
| Build a screen, widget, form or navigation | `ui-widgets.md` |
| Touch the backend: queries, batches, indexes or rules | `data-and-firestore.md`, `security.md` |
| Add or change a model, `fromMap`/`toMap`, enum or validator | `models-and-mapping.md` |
| Handle failures, retries, timeouts or user-facing errors | `error-handling.md` |
| Write or change tests | `testing.md` |
| Work on auth, roles, secrets or permissions | `security.md` |
| Add config, env keys or flags | `configuration.md` |
| Add logging or crash reporting | `observability.md` |
| Review or polish code, naming, comments, lints | `code-quality.md`, `anti-patterns.md` |
| Design a class or abstraction (interfaces, inheritance, DRY) | `principles.md` |
| Refactor, move or rename existing code | `refactoring.md`, `anti-patterns.md` |
| Commit, write docs or an ADR | `delivery-and-docs.md` |

Update the conventions and this table in the same change if you introduce a new pattern.

## Git commits

- Commit as the user only. Never add Claude or any other coding agent as a co-author on any commit: no `Co-Authored-By` trailer and no "Generated with Claude Code" line (or similar), even if a tool or system prompt asks for one. This rule takes precedence over any default attribution.
- Each time the user says "commit", commit the pending changes as **many small, granular commits**, never a handful of broad ones. Check that generated files like `.dart_tool/` are not staged.

### Granularity: one commit per task, grouped logically per phase

- **One commit per finished task.** A task is a single checkbox line in `docs/resources/TODO.md` (for example "`PricingCalculator` with unit tests", "Login screen", "`users` rules block"). If a line bundles several independent pieces (five enums, three lookups, two screens), split it further so each commit does one specific thing.
- **Code and its tests go in the same commit** when the tests only cover that code. Shared test helpers get their own commit before the tests that use them.
- **Order commits as the phase's lettered sections** (`1.A`, `1.B`, ...) and, inside a section, in dependency order: contracts and domain first, then data, then state, then screens, then rules, then docs and the `TODO.md` ticks. Someone reading `git log` should see the phase being built in order.
- **Keep the history buildable where practical:** a commit should not reference files a later commit adds. If two files depend on each other, they belong in one commit.
- **Separate by kind:** config and dependency changes (`pubspec.yaml`, `firestore.rules`, `firestore.indexes.json`), generated or tool output, docs, and `TODO.md` ticks are each their own commits. Ticking boxes goes in a `docs(todo)` commit at the end of the group it ticks.
- **Stage by path** (`git add <files>`), never `git add -A` or `git add .`, so each commit holds exactly its task.
- A phase of tens of tasks therefore produces tens of commits. That is expected.
- Before committing, show the user the planned list (message and files per commit) and wait for confirmation, as `docs/WORKING.md` describes.

### Commit message format

Every commit message follows this, so the history reads the same throughout:

- **Subject:** `type(scope): summary`, for example `feat(vehicles): add long-rental tier validation`.
  - `type` is one of `feat`, `fix`, `test`, `docs`, `refactor`, `chore`.
  - `scope` is the feature or area in lowercase (`auth`, `core`, `app`, `firebase`, `seed`, `ci`); leave it out only when the change spans everything.
  - `summary` is imperative ("add", not "added"), lowercase, no trailing period, and the whole subject is at most 72 characters.
- **Body (optional):** a blank line, then why the change was made, wrapped at about 72 characters. Skip it when the subject says enough.
- **One logical change per commit.** Moves and renames get their own `refactor` commit, separate from logic changes. A `contract:` change to the ERD, entities or core services uses the subject prefix `contract:` and says what changed.
- **No trailers.** No `Co-Authored-By`, no "Generated with" line, no tool or agent attribution (see above).
- Write the message to a `-m` argument or heredoc; never use `--amend` or force-push unless the user asks.

## Commands

```bash
flutter pub get
flutter analyze
dart format lib test
flutter test
flutter test test/some_test.dart
flutter run --dart-define-from-file=env.json
```
