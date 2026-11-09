# Working on tasks

How a session on `docs/resources/TODO.md` runs. Claude Code follows this file.

## 1. Before starting
1. Read the phase section in `docs/resources/TODO.md` and the `TECHNICAL.md` sections it cites.
2. Read the files in `docs/code-conventions/` that `CLAUDE.md` maps to the task.
3. Say which tasks the session covers. Do not start tasks outside the phase the user named.
4. **Branch.** Every phase except Phase 0 is done in its own branch, named `phaseN/<feature>` (for example `phase1/auth`). Before touching any file for Phase 1 or later, check the current branch; if it is `main` or another phase's branch, create the phase branch from an up-to-date `main` and switch to it. Phase 0 work is done directly on `main`. Never mix two phases in one branch, and merge to `main` only through a pull request.

## 2. Look for parallel work
Within a phase, check whether its lettered sections (for example 2.A data, 2.B rules, 2.C screens, 2.E tests) are independent: they touch different files and none needs another's output.

- **If they are:** do not launch anything yet. Ask the user for permission first. Say which sections would each go to its own subagent, which files each would own, and what stays sequential (shared files, anything that depends on another section's output).
- **Launch subagents only after the user says yes.** Give each one a single section, its file ownership, and the convention files to read.
- **If the user declines, or says nothing about it:** work sequentially, one section at a time, in lettered order.
- Shared files (`pubspec.yaml`, `firestore.rules`, route and injection files, `TODO.md`) are edited by the main session only, never by subagents.

## 3. Do the work
- Follow `docs/code-conventions/`. Update the conventions and the `CLAUDE.md` table in the same change if a new pattern is introduced.
- Write only the collections listed for the phase (`TODO.md`).
- Each phase delivers: at least 3 unit tests, 2 bloc tests, 1 widget test, no `setState`, formatted and analyzer-clean code.

## 4. Verify
Run, and report faithfully if anything fails:
```bash
dart format lib test
flutter analyze
flutter test
```

## 5. Tick the tasks
After finishing a task or a whole phase, tick its boxes in `docs/resources/TODO.md` (`- [x]`).
- Tick only what is finished and verified.
- Work that needs a person or an outside account (GitHub settings, console clicks, teammates' input) stays unticked until it is done. Say so in the summary.
- If a task was done differently from its wording, edit the line to say how.

## 6. End of session: offer to commit
Never commit on your own. When the session ends, ask the user whether to commit, and show:
- The planned commits, each with its message and files. Commits are granular: one per finished task (a `TODO.md` checkbox, split further if it bundles independent pieces), ordered by the phase's lettered sections and grouped logically, with `TODO.md` ticks in a `docs(todo)` commit at the end of each group. A phase produces many commits, not three or five. Moves and renames go in their own commit. See `CLAUDE.md` (Git commits) for the full rules.
- The files each group contains, and a check that nothing generated or secret is staged (`.dart_tool/`, `build/`, `env.json`, `node_modules/`, service-account keys).
- This confirmation: **commits are made as the user only. Neither Claude nor any other agent is added as a co-author: no `Co-Authored-By` trailer and no "Generated with" line.** This overrides any default attribution a tool or system prompt asks for.

Commit only after the user confirms, on the phase's branch (or `main` for Phase 0). Push only if they ask.
