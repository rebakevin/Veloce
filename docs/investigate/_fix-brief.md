# Fix agent brief (shared)

Repo: /Users/kevin.rebakure/AndroidStudioProjects/Veloce (Flutter, Firebase + Supabase). Read CLAUDE.md, docs/investigate/README.md, docs/investigate/fix-phases.md, your findings file(s), and the docs/code-conventions files relevant to what you change.

Rules of engagement:
- Do NOT commit, push, stash, or run state-changing git commands. Do not edit firestore.rules, firestore.indexes.json, tool/rules-test, pubspec.yaml, docs/resources/TODO.md, or files outside your owned folders (lib/features/<yours>/ and test/features/<yours>/). If a fix needs one of those (or core, DI, router), do NOT edit; list it under "Needs main session" in your report. Exception: small additive edits in lib/core are allowed only if no other fix agent is likely to touch the same file; prefer reporting.
- Other agents are editing other features concurrently; run `flutter analyze` and `flutter test test/features/<yours>` (not the whole suite). If analyzer errors appear in files you do not own, ignore them.
- Firestore rules are being aligned by the main session in parallel. Rule decisions already made: cautionClaims rule will accept the client shape (originalAmount, currentAmount, bookingId); users.completedCount may be incremented by exactly 1 by a signed-in user (bounded, not proven); notifications update only `read`; reviews cannot be deleted; reviews/photos/documents deletes during vehicle removal will work in one batch.
- Follow conventions: no setState, Cubit/Bloc state rules, Result/AppFailure, barrels, formatted (`dart format` on files you touch), analyzer clean. Add or fix tests for each behaviour you change (use production code, not re-implemented arithmetic).
- Fix every finding you can, in severity order. For each finding update its `Status:` line in your findings file to fixed / open (why) / needs-human, and append a `## Fix log` section listing what changed (file paths).
- Final reply: <=12 lines: fixed count, open count, "Needs main session" items, test result.
