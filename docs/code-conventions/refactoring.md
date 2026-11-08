# Refactoring: end behavior must not change

Use these rules when a task is "clean up", "restructure" or "migrate", and whenever an existing feature is reshaped.

## What must stay the same

- User-visible behavior and screens.
- The Firestore data shape, `firestore.rules` and `firestore.indexes.json` (no schema change, no migration), unless the task explicitly is a data change. A refactor never modifies what is stored.
- The public contracts other features use (barrel exports, repository contracts), unless every caller changes in the same commit.

## How to work

- Refactor in small, behavior-preserving steps. Each step builds, passes `flutter analyze` and passes the tests.
- Write characterization tests before touching code that has none.
- Moves and renames go in separate commits from logic changes. A reviewer should be able to confirm a move by seeing identical content.
- Change one thing at a time: structure, then naming, then logic.
- Keep tests green after every step. Update the tests together with the code they cover.

## What to do with findings

- If you believe the schema, rules, an API or a screen should change, do not do it inside the refactor. Write it down in a short markdown file at `docs/proposals/<concept>.md` (one file per concept: `data-change.md`, `rules-change.md`, `ui-change.md`) saying what and why, and leave the change for a separate task.
- Apply [anti-patterns.md](anti-patterns.md) as the checklist for what to fix, and list the anti-patterns already present in the code you are touching.
