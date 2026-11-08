# Observability

A mobile app has no server logs, so keep this proportionate. The goal is to be able to explain a failure during development and the demo, and to leave room for crash reporting later.

## Logging

- No `print`. `avoid_print` is a lint error. Use `dart:developer` `log(...)` or one small logger wrapper in `core/`, so levels and sinks can change in one place.
- Levels: `error` needs action, `warning` is unexpected but handled, `info` is business events (report submitted, status changed), `debug` is diagnostics and is stripped or silenced in release.
- Log an exception once, at the boundary that handles it, with its stack trace.
- Never log secrets, tokens, passwords, full emails or free-text user content. Sanitize user-supplied values.
- Use interpolation sparingly in hot paths and never log inside `build`.

## Diagnostics

- Cubit transitions can be observed with a `BlocObserver` registered in `main.dart`. In debug it logs state changes and errors. In release it only forwards errors.
- Register `FlutterError.onError` and `PlatformDispatcher.instance.onError` once in `main.dart` so uncaught errors are logged in one place.

## Crash reporting (optional)

- If added later (Firebase Crashlytics), it sits behind the logger wrapper. Feature code does not import it.
- Attach non-personal context only (screen, action, app version). No personal data.

## Background work

- Anything that runs outside user interaction (stream subscriptions, retries) logs start, outcome and failure at `info`/`error`, so a stuck state can be traced.

## Metrics and alerts

- Not applicable for this project's scale. If analytics are added, keep label cardinality low (no user ids as dimensions) and keep it behind an adapter.
