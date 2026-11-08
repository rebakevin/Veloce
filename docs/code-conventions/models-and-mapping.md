# Models and mapping

## Separate the representations

Do not use one class for everything. Practical distinction:

| Concept | What it is in Veloce |
|---|---|
| Wire map | The `Map<String, dynamic>` that Firestore reads and writes |
| Domain model | `Report`, `AppUser`, `HistoryEntry`: business state and rules |
| Command / input | What a use case needs (`NewReportDraft`, `StatusChange`) |
| Form state | What a screen edits before it is valid |

- You do not need a class for every conceivable transformation. Introduce a command or draft type when the input differs from the stored model (a draft has no id, no timestamps, no `upvoteCount`).
- Firestore types (`Timestamp`, `DocumentSnapshot`, `FieldValue`) never leave the data layer. Domain models use `DateTime`.

## Model rules

- Hand-written classes with `final` fields, a `const` constructor, `copyWith`, and `Equatable` or equivalent equality. No codegen.
- `fromMap` / `toMap` live next to the model, or in a `*_mapper.dart` in the `data` layer if the domain must stay SDK-free. If the model is in `domain`, put mapping in `data`.
- `toMap` writes exactly the keys in the Database Design, including explicit `null`s.
- `fromMap` is strict about required fields. A missing or wrongly typed required field throws a clear error naming the field. Do not silently default values that the rules guarantee.
- Enums are parsed from their stable string key through one function per enum (`ReportStatus.fromKey`). An unknown key is an error, not a default.
- Map between layers in dedicated mappers at the boundary, not inline in Cubits or widgets.

## Types, not strings

- Status, category, building, priority and role are enums with `key` and `label`. Use the enum everywhere in code and the key only at the wire.
- Wrap rule-bearing values (`Email`, `DisplayName`, `ReportTitle`) when validation rules attach to them, so an invalid value cannot be constructed.

## Validation at the boundary

- Validate user input in the form (UX) and again when constructing the draft or command (guard). The server rules are the final check.
- Reject bad input early and return a typed failure. Do not let a bad value travel to the repository.
- Trim and normalize in one place (for example `titleLower = title.toLowerCase()` inside the draft-to-map step), not at each call site.

## Never leak internals

- Error messages shown to users do not contain Firestore paths, stack traces, SDK exception text or document ids that mean nothing to them.
- Do not expose the raw wire map to widgets.
