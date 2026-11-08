# Code quality

## Comments

- **Tier 1**: code is self-explanatory by default. Prefer a better name over a comment.
- **Tier 2**: non-obvious decisions and complex logic get a short comment explaining *why* (a Firestore limitation, a rules requirement), not *what*.
- **Tier 3**: long explanations go in `docs/`, and the code links to them.
- Remove commented-out code and dead code. Git remembers.
- Dartdoc (`///`) on public APIs that are not obvious from the name. No doc comments that repeat the signature.

## Naming

- Intention-revealing names. No abbreviations, and no `data`, `info`, `temp`, `res`, `obj`.
- Follow Dart style: `UpperCamelCase` types, `lowerCamelCase` members, `snake_case` files, `lowercase_with_underscores` packages. Booleans read as questions (`isEditable`, `hasPhotos`).
- Private members start with `_`. Do not use `_` for locals to hide meaning.

## Functions and classes

- Small functions that do one thing at one level of abstraction. Few parameters. Use named parameters when there are more than two, and mark required ones `required`.
- No boolean flag parameters. Split into two methods or use an enum.
- No magic numbers or strings. Use enums and named constants.
- Prefer `final`. Prefer `const`. Prefer immutable value types.
- Prefer early returns over deep nesting.
- Use Dart 3 features where they simplify: records for small value groups, pattern matching and `switch` expressions for sealed types, `sealed` for closed hierarchies, `extension type` for typed ids.
- Exhaustive `switch` on enums and sealed classes with no `default`, so adding a case fails to compile where it matters.

## Null safety

- Avoid passing or returning `null` as a convenience. Use empty collections, explicit result types or sealed outcomes.
- No `!` (bang) on values that can plausibly be null. Check, or restructure so the type is non-null. A `!` needs a reason.
- Avoid `late` for values that can be provided in the constructor.
- Never use `dynamic` outside the mapper layer. Prefer `Object?` and cast at the boundary.

## Imports

- No unused imports. No wildcard-style `export` of whole packages from barrels.
- `package:` imports across features, relative imports inside one feature. Sorted by `dart format` and the `directives_ordering` lint.

## Lints and formatting

- `flutter_lints` is the baseline. Enable stricter rules in `analysis_options.yaml` as they come up, for example `avoid_print`, `prefer_const_constructors`, `prefer_final_locals`, `unawaited_futures`, `use_build_context_synchronously`, `always_declare_return_types`, `avoid_dynamic_calls`.
- `dart format .` and `flutter analyze` run before every commit and in CI. Style is never debated in review.
- Fix analyzer warnings. Do not ignore a lint with `// ignore:` without a comment saying why.

## Working habits

- Boy scout rule: leave the code a little cleaner than you found it, within the scope of the task.
- Small, focused changes. A PR or commit does one thing. Review for design, not just correctness.
