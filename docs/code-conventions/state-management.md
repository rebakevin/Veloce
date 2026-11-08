# State management (Cubit)

## Roles

- **Screen**: reads Cubit state, calls Cubit methods, nothing else.
- **Cubit**: holds UI-facing state for one feature, orchestrates repository calls, turns failures into states.
- **Repository**: the only thing that talks to Firestore, Auth or Supabase (via adapters). Returns domain types.
- **Domain**: rules and types. No Flutter, no SDKs.

A Cubit never imports an SDK. A screen never imports a repository.

## States

- Model state as a sealed class so the compiler forces every case to be handled:

```dart
sealed class ReportsState extends Equatable {
  const ReportsState();
}
final class ReportsLoading extends ReportsState { /* ... */ }
final class ReportsLoaded extends ReportsState { final List<Report> reports; /* ... */ }
final class ReportsEmpty extends ReportsState { /* ... */ }
final class ReportsFailure extends ReportsState { final AppError error; /* ... */ }
```

- Every Cubit exposes loading, loaded, empty and error where relevant (Specs section 9). Screens render a spinner, an empty message with a call to action, or an error with Retry.
- States are immutable and extend `Equatable` so unchanged emissions do not rebuild.
- Do not use a bag of fields (`isLoading`, `data`, `error`) that can contradict each other.
- Form state that has independent fields (a submit status plus field values) may be one class with a status enum, but the status must be an enum, not booleans.

## Cubit rules

- One Cubit per feature or per screen with its own lifecycle. Do not build a god Cubit.
- Methods are verbs that describe intent: `submit`, `refresh`, `toggleVote`. They return `Future<void>` and emit state. Callers read results from state.
- Disable submit buttons while a request runs: the state carries the `submitting` status, and the Cubit ignores a second call while one is running.
- Always check `isClosed` before `emit` after an `await`, or cancel subscriptions in `close()`.
- Cancel every `StreamSubscription` in `close()`.
- No `BuildContext`, `Navigator` or `SnackBar` inside a Cubit. Emit state; the screen reacts with `BlocListener`.
- A Cubit receives its repositories through the constructor. It never calls `FirebaseFirestore.instance`.

## Streams

- Live data (feed, notifications, a report's votes) comes from repository streams. The Cubit subscribes once, maps to state, and cancels on close.
- Repositories expose domain streams (`Stream<List<Report>>`), not `QuerySnapshot`.
- Apply client-side filtering and sorting in the Cubit or domain, after the stream, only for what Firestore cannot do (see [data-and-firestore.md](data-and-firestore.md)).

## Scope and provisioning

- Repositories: `RepositoryProvider` at the root.
- App-wide Cubits (auth): `BlocProvider` at the root.
- Screen-level Cubits: provided at the route that needs them, so they are disposed with it.
- Use `BlocBuilder` for rendering, `BlocListener` for one-off effects (navigation, snackbars), `BlocConsumer` only when both are needed. Use `buildWhen`/`select` to limit rebuilds.

## Cross-Cubit communication

- Cubits do not call each other. Share data through repositories and their streams, or lift to a parent Cubit.
- Auth state changes flow through the auth Cubit to the auth gate. Other Cubits are created after login, so they never hold a stale user.
