# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project state

Veloce is a Flutter/Dart app. The repo is freshly set up, so there is no code yet.

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
- Split work into several logical commits, and check that generated files like `.dart_tool/` are not staged.

## Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter test test/some_test.dart
```
