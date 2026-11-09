## What and why

## Screenshots
Figma vs app side by side (small phone, large phone, landscape) for any UI change.

## Tests added

## Checklist
- [ ] `dart format lib test` and `flutter analyze` are clean
- [ ] `flutter test` passes
- [ ] No `setState`; no SDK imports in `presentation/` or `domain/`
- [ ] Only my own collections are written (TECHNICAL.md §4.1)
- [ ] Rules and indexes updated and deployed if the data shape changed
- [ ] Contract change (ERD, entity, core service)? PR title starts with `contract:` and all owners are reviewers
