# Error handling and resilience

## Business outcomes vs technical failures

- **Business outcomes** are expected: wrong domain, report no longer editable, already voted, validation failed. Model them as typed results or sealed failure classes and show a friendly message.
- **Technical failures** are unexpected: network down, timeout, permission denied by rules, SDK exceptions. Map them to a small `AppError` hierarchy at the repository, show a generic message with Retry, and report them (see [observability.md](observability.md)).
- Adapters translate `FirebaseException`, `FirebaseAuthException`, `StorageException` and `SocketException` into our own types. Nothing above the data layer catches an SDK exception type.

## Rules

- Never swallow exceptions: no empty `catch`, no `catch (e) {}` that only prints. A failure is recorded as a failure, never as success.
- Catch the specific exception you can handle (`on FirebaseAuthException catch (e)`). Let the rest propagate to the Cubit, which turns it into a failure state.
- Do not use bare `catch (e)` without a reason. When you must catch broadly (the Cubit boundary), convert to a failure state and log once.
- Log an exception once, at the boundary that handles it. Keep the stack trace: `catch (e, stack)`, then pass both on.
- Use `rethrow` to preserve the stack trace. Do not `throw e`.
- Do not use exceptions for normal control flow. Return a result or nullable where absence is expected.
- Clean up in `finally` (hide progress, delete orphaned uploads).

## Specific cases in Veloce

- `permission-denied` from Firestore usually means a lost race or a state change (status moved, report deleted). Show "This report changed, please refresh" and reload. It is not a crash.
- `unavailable` and timeouts: offer Retry. Keep the user's input.
- Auth errors (`wrong-password`, `user-not-found`, `email-already-in-use`) map to field-level or form-level messages without revealing whether an account exists (see [security.md](security.md)).
- Photo upload failure stays on the form with input preserved, and removes any partial uploads.

## Timeouts and retries

- Every external call has a timeout (`.timeout(Duration(...))`) and a user-visible outcome. No unbounded waits.
- Retry only transient failures and only idempotent calls. Use exponential backoff with a cap on attempts. Do not hand-roll loops with `Future.delayed` scattered around. Put the policy in one helper used by the adapter.
- Do not auto-retry writes that are not idempotent. A retried batch must produce the same result (client-generated ids make W2 safe).

## Degrade gracefully

- If part of a screen fails (photos fail to load, a count fails), show the rest with a clear marker for the part that failed.
- Every screen handles loading, empty and error states (see [state-management.md](state-management.md)).

## Async hygiene

- Never leave a `Future` un-awaited without a reason. Use `unawaited(...)` explicitly where fire-and-forget is intended, and make sure it cannot throw unhandled.
- Cancel streams and timers on dispose so late callbacks cannot throw into a dead object.
- Use `runZonedGuarded` and `FlutterError.onError` once, in `main.dart`, as the last-resort handler.
