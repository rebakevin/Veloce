# Testing

```
         /\
        /  \
       / E2E\          Few    integration_test on the emulator, key flows
      /------\
     / Widget \        Some   screens with fake Cubits or repositories
    /----------\
   /   Cubit    \      Many   state transitions with fake repositories
  /--------------\
 /  Unit (domain) \    Many   validators, rules, mappers, value objects
/__________________\
```

Specs section 9 sets the minimum for this project: validators, `canEdit`, and the report form widget test, plus the Firestore rules Playground cases. Go beyond it where logic is non-trivial.

## Principles

- Test behavior, not implementation. A test should survive a refactor.
- Fast, deterministic, independent. No real network, no `Future.delayed` sleeps, no shared mutable state, no order dependence. Use fakes and `fakeAsync`/`pump`.
- One reason to fail per test. Arrange, Act, Assert.
- Test names say the scenario and the expected outcome: `submit with empty title emits validation failure`.
- Use test data builders for models (`aReport(status: ReportStatus.resolved)`) instead of long constructors repeated in every test.
- Cover failure paths: timeout, empty results, bad input, permission denied, partial failure.
- Write a characterization test before refactoring untested code.
- Test layout mirrors `lib/` exactly.

## What to test where

- **Domain**: pure Dart tests, no Flutter. Validators, `canEdit`, status transitions, value objects, enum parsing. These are the cheapest and most valuable.
- **Mappers**: round-trip `toMap`/`fromMap`, exact key sets (including explicit `null`), unknown enum keys fail.
- **Cubits**: use `bloc_test`. Given a fake repository, assert the sequence of states. Cover loading, loaded, empty, error, double-submit ignored, `close()` cancels subscriptions.
- **Widgets**: pump the screen with a fake Cubit or a Cubit over a fake repository. Assert what the user sees and which Cubit method a tap calls. Do not assert on widget internals.
- **Repositories**: prefer testing against the Firebase emulator suite for rules-sensitive code. `fake_cloud_firestore` can be used for simple queries, but it does not enforce security rules, so it is not a substitute for rules tests.
- **Security rules**: run the 23 Playground cases from the Database Design, and automate them with the Firestore emulator and `@firebase/rules-unit-testing` if time allows.

## Fakes over mocks

- Prefer hand-written fakes that implement the repository contract over `mockito` verify-heavy tests. Mocks that assert on call order tie tests to implementation.
- Use mocks only for interaction that is the behavior (for example "a second tap does not call submit twice").

## Architecture rules (checked by tests)

Add a small test that scans `lib/` imports (or use `import_lint`/`dart_code_metrics`) and fails on:

- Anything under `presentation/` importing `cloud_firestore`, `firebase_auth` or `supabase_flutter`.
- Anything under `domain/` or `application/` importing those SDKs or `package:flutter/material.dart`.
- A feature importing a file inside another feature instead of its barrel.
- Cyclic feature dependencies.

## CI

- Tests, `flutter analyze` and `dart format --set-exit-code` run on every PR. A red build blocks merge.
- Also update the tests whenever behavior or a contract changes. A change without matching test updates is incomplete.
