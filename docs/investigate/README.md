# Investigate

Overnight audit of every phase. Not committed.

## Process
1. Round 1: each phase is checked end to end against `docs/resources/TODO.md`, `SPECS.md` and `TECHNICAL.md`: is every task implemented, and does it work (code trace, tests, rules)?
2. Gaps and bugs are logged in `phase-N-findings.md` (one file per phase), never silently skipped.
3. `fix-phases.md` lists the issues to fix per phase, built from the findings.
4. Fixes are applied; `flutter analyze` and `flutter test` must stay green.
5. Round 2 repeats the audit on the fixed code; leftovers go in `round-2-findings.md`.
6. `FOR-KEVIN.md` is the short list of what needs a person (consoles, emulators, devices, decisions).

## Finding format
```
### F<phase>-<nn> [severity: blocker|major|minor|nit] [kind: bug|gap|spec-drift|test-gap|needs-human]
- Where: file:line
- What: ...
- Evidence: how it was verified
- Fix: proposed fix
- Status: open | fixed | needs-human
```
