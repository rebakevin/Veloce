# Anti-patterns

Look for these in existing code and avoid them in new code. Fix the ones you touch.

## Structure

- **God Cubit or giant widget**: one class owning a whole app's behavior, or a `build` method of hundreds of lines.
- **Global `utils` / `common` / `helpers` folders**: code with no owner.
- **Layer-first folders** that scatter one feature across `models/`, `screens/`, `cubits/`.
- **Circular feature dependencies**, or one feature importing another's internal files.
- **Excessive interfaces**: `abstract class X` plus a single `XImpl`.
- **Premature abstraction and speculative generality**: generic form engines, plugin systems nobody asked for.
- **Shotgun surgery**: one change touches many files because knowledge is duplicated.
- **Feature envy**: a class mostly uses another class's data. Move the behavior to the data.

## Layer violations

- Screens or Cubits calling `FirebaseFirestore.instance`, `FirebaseAuth.instance` or `Supabase.instance` directly.
- Business logic in widgets, in `build`, in mappers or in the rules-adjacent glue.
- **Leaky abstractions**: `DocumentSnapshot`, `User` or SDK exceptions flowing into domain, Cubits or widgets.
- Cubits using `BuildContext`, `Navigator` or `ScaffoldMessenger`.

## State and types

- **Stringly-typed code and primitive obsession**: raw `'inProgress'` strings, untyped `Map<String, dynamic>` passed around.
- **Contradictory state fields**: `isLoading`, `data` and `error` that can all be set at once.
- **Anemic model**: classes that are only fields, with all rules in services or widgets.
- **Static or global mutable state** and singletons read from anywhere.
- **Long parameter lists and boolean flag parameters.**
- **Magic strings and numbers.**
- Overuse of `!`, `dynamic` and `late`.

## Errors and async

- **Swallowed exceptions**, empty `catch`, and catch-all handlers that only print.
- Marking a failed operation as success, or hiding a failure from the user.
- Un-awaited futures, missing `mounted` checks after `await`, subscriptions never cancelled, controllers never disposed.
- Hand-rolled retry or caching loops next to a standard approach.

## Data

- **N+1 reads**: a Firestore read per list item.
- Unbounded lists with no `limit`.
- Splitting a documented batch into separate writes, which breaks the rules' preconditions.
- Client-side `DateTime.now()` for fields the rules require to be `request.time`.
- Querying with a combination that has no index.
- Business rules duplicated between widgets and the rules file and left to drift.

## Hygiene

- **Copy-paste duplication** (the same screen or pipeline per role).
- Commented-out code, dead code, unused imports.
- `print` for diagnostics.
- Secrets or personal data in code, logs or commits.
- Mixing two mechanisms for the same problem (two state managers, two navigation styles).
