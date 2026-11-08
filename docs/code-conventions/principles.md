# Principles

## Encapsulation

- A feature exposes only what others need. Everything else stays private.
- Dart privacy is per library (file): prefix with `_` for file-private. Do not export internals from the barrel.
- Default to private. Making something public is a deliberate decision.

## SOLID

- **Single responsibility**: one coherent reason to change. Do not split every method into its own class. Isolate reasons for change, not lines of code.
- **Open/closed**: adding a feature should not touch many stable files. Adding a category or status should mean editing its enum and the places that genuinely differ, not hunting through widgets. Do not replace every `if` with polymorphism: two stable cases with no expected growth are clearer as a conditional.
- **Liskov**: an implementation works wherever its abstraction is expected. A fake repository in tests must honor the real contract.
- **Interface segregation**: consumers should not depend on methods they do not use. Avoid giant repository contracts: separate reads and writes if consumers differ.
- **Dependency inversion**: business policy does not depend on SDKs. Inject collaborators through constructors.

## Composition over inheritance

- Do not extend widgets or Cubits to share behavior. Compose small widgets, pass collaborators in, use mixins only for narrow, stateless capabilities.
- Never subclass a concrete Cubit.

## DRY, with judgment

- Duplicated knowledge is dangerous: one place for validation rules, enum labels, status transitions.
- Duplicated small code is fine. Wait for the third occurrence before abstracting (rule of three).
- Share stable, well-understood concepts. Keep genuinely different business rules separate, even if they look alike today.

## KISS and YAGNI

- Keep the design as simple as the problem permits.
- No plugin frameworks, generic form engines or extra abstraction layers because "it might support more later". Design for likely change, not imaginable change.

## Behavior and data

- **Separation of concerns**: business logic, I/O and presentation never mix in one method.
- **Tell, don't ask**: put behavior with the data it works on (`report.canBeEditedBy(user)`, not `if (report.status == submitted && report.reporterId == user.id)` repeated in widgets).
- **Law of Demeter**: talk to direct collaborators, not their internals (`a.b.c.doIt()`).
- **Command-query separation**: a method either changes state or returns data, not both. Cubit methods emit state; they do not also return results the caller must use.
- **Least surprise**: names and behavior match.

## Immutability and types

- Immutable by default: `final` fields, `const` constructors, `copyWith` for changes. Mutate only with a reason.
- **Make illegal states unrepresentable**: use enums, sealed classes and value objects instead of raw strings, flags and nullable combinations.
    - `ReportStatus.inProgress`, not `'inProgress'`.
    - A loading/loaded/error state is a sealed class, not `isLoading`, `data` and `error` fields that can disagree.
- **Avoid primitive obsession**: wrap meaningful values (`Email`, `ReportId`, `PhotoPath`) when they carry rules. Use Dart records or extension types for lightweight cases.
- **Fail fast**: validate at the boundary and reject bad input early.
